<?php

namespace App\Services;

use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

class ServiceReportQuery
{
    public function build(string $type, array $filters): Builder
    {
        $query = match ($type) {
            'peminjaman' => $this->loanQuery(),
            'konsultasi' => $this->consultationQuery(),
            'usulan-email' => $this->emailQuery(),
            default => throw new \InvalidArgumentException('Jenis laporan tidak valid.'),
        };

        $dateColumn = match ($type) {
            'peminjaman' => 'p.tanggal_mulai',
            'konsultasi' => 'k.created_at',
            'usulan-email' => 'e.created_at',
        };

        $query
            ->when($filters['start_date'] ?? null, fn (Builder $builder, string $date) => $builder->whereDate($dateColumn, '>=', $date))
            ->when($filters['end_date'] ?? null, fn (Builder $builder, string $date) => $builder->whereDate($dateColumn, '<=', $date))
            ->when($filters['status'] ?? null, function (Builder $builder, string $status) use ($type): void {
                $alias = match ($type) {
                    'peminjaman' => 'p.status',
                    'konsultasi' => 'k.status',
                    'usulan-email' => 'e.status',
                };
                $builder->where($alias, $status);
            })
            ->when($filters['user_id'] ?? null, function (Builder $builder, int|string $userId) use ($type): void {
                $builder->where($type === 'usulan-email' ? 'e.created_by' : ($type === 'peminjaman' ? 'p.user_id' : 'k.user_id'), $userId);
            })
            ->when($filters['opd'] ?? null, fn (Builder $builder, string $opd) => $builder->where('u.nama_opd', $opd));

        if ($type === 'konsultasi' && ! empty($filters['topik_id'])) {
            $query->where('k.faq_id', $filters['topik_id']);
        }
        if ($type === 'peminjaman' && ! empty($filters['asset_id'])) {
            $query->whereExists(function ($subquery) use ($filters): void {
                $subquery->selectRaw('1')
                    ->from('pinjam_item as pi_filter')
                    ->whereColumn('pi_filter.pinjam_id', 'p.id')
                    ->where('pi_filter.item_id', $filters['asset_id']);
            });
        }

        return $query->orderByDesc($dateColumn);
    }

    public function headings(string $type): array
    {
        return match ($type) {
            'peminjaman' => ['ID', 'Pemohon', 'NIP', 'OPD', 'Tanggal Mulai', 'Tanggal Selesai', 'Status', 'Keperluan', 'Aset'],
            'konsultasi' => ['ID', 'Pemohon', 'NIP', 'OPD', 'Topik', 'Judul', 'Status', 'Tanggal Dibuat'],
            'usulan-email' => ['ID', 'Pengaju', 'NIP Pengaju', 'OPD', 'ID Pegawai BKD', 'Email Pribadi', 'Email Resmi', 'Status', 'Tanggal Diajukan'],
            default => [],
        };
    }

    private function loanQuery(): Builder
    {
        return DB::table('tr_permintaan_pinjam as p')
            ->leftJoin('users as u', 'u.id', '=', 'p.user_id')
            ->whereNull('p.deleted_at')
            ->select([
                'p.id', 'u.name as pemohon', 'u.nip', 'u.nama_opd', 'p.tanggal_mulai',
                'p.tanggal_selesai', 'p.status', 'p.keterangan',
                DB::raw("COALESCE((SELECT GROUP_CONCAT(CONCAT(mi.nama, ' x', pi.quantity) SEPARATOR ', ') FROM pinjam_item pi JOIN master_item mi ON mi.id = pi.item_id WHERE pi.pinjam_id = p.id), '-') as aset"),
            ]);
    }

    private function consultationQuery(): Builder
    {
        return DB::table('tr_konsultasi as k')
            ->leftJoin('users as u', 'u.id', '=', 'k.user_id')
            ->leftJoin('master_topik as t', 't.id', '=', 'k.faq_id')
            ->whereNull('k.deleted_at')
            ->select(['k.id', 'u.name as pemohon', 'u.nip', 'u.nama_opd', 't.topik', 'k.judul', 'k.status', 'k.created_at']);
    }

    private function emailQuery(): Builder
    {
        return DB::table('usulan_email as e')
            ->leftJoin('users as u', 'u.id', '=', 'e.created_by')
            ->select([
                'e.id', 'u.name as pengaju', 'u.nip as nip_pengaju', 'u.nama_opd', 'e.id_peg_bkd',
                'e.email_pribadi', 'e.email_resmi', 'e.status', 'e.created_at',
            ]);
    }
}
