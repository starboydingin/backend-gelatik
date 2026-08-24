<?php

namespace App\Exports;

use App\Services\ServiceReportQuery;
use Maatwebsite\Excel\Concerns\FromQuery;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class ServiceReportExport implements FromQuery, WithHeadings, WithMapping
{
    public function __construct(
        private string $type,
        private array $filters,
        private ServiceReportQuery $reportQuery,
    ) {
    }

    public function query()
    {
        return $this->reportQuery->build($this->type, $this->filters);
    }

    public function headings(): array
    {
        return $this->reportQuery->headings($this->type);
    }

    public function map($row): array
    {
        return array_values((array) $row);
    }
}
