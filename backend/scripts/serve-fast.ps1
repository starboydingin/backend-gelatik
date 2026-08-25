param(
    [int]$Port = 8000,
    [string]$HostAddress = '127.0.0.1'
)

$ErrorActionPreference = 'Stop'
$backendPath = Split-Path -Parent $PSScriptRoot
$scanPath = Join-Path $backendPath 'php-conf.d'

if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
    throw 'PHP tidak ditemukan pada PATH.'
}

if (-not (Test-Path -LiteralPath (Join-Path $scanPath '10-opcache-dev.ini'))) {
    throw 'Konfigurasi OPcache development tidak ditemukan.'
}

$previousScanPath = $env:PHP_INI_SCAN_DIR
$env:PHP_INI_SCAN_DIR = $scanPath

try {
    $opcacheEnabled = php -r "echo extension_loaded('Zend OPcache') ? 'yes' : 'no';"
    if ($opcacheEnabled -ne 'yes') {
        throw 'Zend OPcache gagal dimuat. Periksa lokasi php_opcache.dll pada instalasi PHP.'
    }

    Push-Location $backendPath
    try {
        php artisan serve --host=$HostAddress --port=$Port
    }
    finally {
        Pop-Location
    }
}
finally {
    $env:PHP_INI_SCAN_DIR = $previousScanPath
}

