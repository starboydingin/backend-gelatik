<?php

namespace Database\Seeders;

use App\Models\PegawaiBelumPunyaEmail;
use App\Models\UsulanEmail;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Schema;

class EmailPresentationSeeder extends Seeder
{
    /** Seed clearly-labelled, idempotent demonstration data for local presentation only. */
    public function run(): void
    {
        if (! app()->environment(['local', 'testing'])) {
            throw new \RuntimeException('EmailPresentationSeeder hanya boleh dijalankan pada environment local atau testing.');
        }

        if (! Schema::hasTable('PegawaiBelumPunyaEMail')) {
            throw new \RuntimeException('Tabel PegawaiBelumPunyaEMail belum tersedia. Jalankan migration terlebih dahulu.');
        }

        $owner = User::query()->oldest('id')->first();
        if (! $owner) {
            throw new \RuntimeException('Buat akun development terlebih dahulu sebelum menjalankan seeder presentasi.');
        }

        $pegawai = [
            [
                'ID_Peg' => '990001',
                'NIP_Baru' => '199001012020121001',
                'Nama' => 'DEMO - Aulia Pratama',
                'Unit_Kerja' => 'BKD Provinsi Lampung',
                'NJab' => 'Analis Kepegawaian',
                'NUnKer' => 'Bidang Pengadaan dan Mutasi',
                'EmailUsulan' => 'aulia.pratama@lampungprov.go.id',
                'EmailPribadi' => 'aulia.pratama.demo@example.test',
            ],
            [
                'ID_Peg' => '990002',
                'NIP_Baru' => '199205152021011002',
                'Nama' => 'DEMO - Bima Saputra',
                'Unit_Kerja' => 'Dinas Komunikasi, Informatika dan Statistik',
                'NJab' => 'Pranata Komputer Ahli Pertama',
                'NUnKer' => 'Bidang Aplikasi Informatika',
                'EmailUsulan' => 'bima.saputra@lampungprov.go.id',
                'EmailPribadi' => 'bima.saputra.demo@example.test',
            ],
            [
                'ID_Peg' => '990003',
                'NIP_Baru' => '198812102019031003',
                'Nama' => 'DEMO - Citra Lestari',
                'Unit_Kerja' => 'Dinas Kesehatan Provinsi Lampung',
                'NJab' => 'Perencana Ahli Muda',
                'NUnKer' => 'Sekretariat',
                'EmailUsulan' => 'citra.lestari@lampungprov.go.id',
                'EmailPribadi' => 'citra.lestari.demo@example.test',
            ],
        ];

        foreach ($pegawai as $data) {
            PegawaiBelumPunyaEmail::updateOrCreate(['ID_Peg' => $data['ID_Peg']], $data);
        }

        $now = now();
        $usulan = [
            [
                'id' => 990001,
                'id_peg_bkd' => 990001,
                'email_pribadi' => 'aulia.pratama.demo@example.test',
                'email_resmi' => null,
                'status' => 'diajukan',
                'tanggal_verifikasi' => null,
                'diverifikasi_oleh' => null,
                'catatan' => 'DEMO PRESENTASI: menunggu verifikasi data BKD.',
                'created_by' => $owner->id,
                'updated_by' => $owner->id,
                'created_at' => $now->copy()->subDays(2),
                'updated_at' => $now->copy()->subDays(2),
            ],
            [
                'id' => 990002,
                'id_peg_bkd' => 990002,
                'email_pribadi' => 'bima.saputra.demo@example.test',
                'email_resmi' => 'bima.saputra@lampungprov.go.id',
                'status' => 'disetujui',
                'tanggal_verifikasi' => $now->copy()->subDay(),
                'diverifikasi_oleh' => 'Admin Development',
                'catatan' => 'DEMO PRESENTASI: alamat email resmi telah diterbitkan.',
                'created_by' => $owner->id,
                'updated_by' => $owner->id,
                'created_at' => $now->copy()->subDays(4),
                'updated_at' => $now->copy()->subDay(),
            ],
            [
                'id' => 990003,
                'id_peg_bkd' => 990003,
                'email_pribadi' => 'citra.lestari.demo@example.test',
                'email_resmi' => null,
                'status' => 'ditolak',
                'tanggal_verifikasi' => $now->copy()->subHours(8),
                'diverifikasi_oleh' => 'Admin Development',
                'catatan' => 'DEMO PRESENTASI: dokumen pendukung perlu dilengkapi.',
                'created_by' => $owner->id,
                'updated_by' => $owner->id,
                'created_at' => $now->copy()->subDays(3),
                'updated_at' => $now->copy()->subHours(8),
            ],
        ];

        foreach ($usulan as $data) {
            UsulanEmail::updateOrCreate(['id' => $data['id']], $data);
        }
    }
}
