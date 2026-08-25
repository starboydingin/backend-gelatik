# Gelatik performance audit

## Laravel cold and warm requests

Pengukuran dilakukan pada Windows dengan PHP 8.4 CLI dan `curl`, menggunakan
endpoint `/up` (tanpa query bisnis) dan `/api/opd` (satu query database).

Baseline sebelum dependency runtime diselaraskan:

| Skenario | Request pertama | Request hangat |
|---|---:|---:|
| `/up`, PHP CLI tanpa OPcache | 1.603 s | 1.096–1.188 s |
| `/api/opd`, PHP CLI tanpa OPcache | 1.861 s | 1.240–1.326 s |

Profil in-process `/api/opd` memisahkan 1.927 s menjadi 346 ms sebelum
bootstrap, 1.371 s bootstrap framework, 210 ms request handling, dan hanya
13.52 ms untuk satu query. Jadi database dan cache data bukan penyebab utama.

`composer install --dry-run` juga menemukan 32 paket yatim di `vendor`
(Filament, Livewire, dan Inertia termasuk di antaranya). Setelah `vendor`
diselaraskan dengan `composer.lock`, `/up` tanpa OPcache menjadi 1.055 s pada
request pertama dan 0.855–0.934 s pada request hangat.

Dengan OPcache CLI dan dependency yang sudah selaras:

| Skenario | Request pertama | Request hangat |
|---|---:|---:|
| `/up`, `composer serve:fast` | 0.444-1.706 s | 0.066-0.120 s |
| `/api/opd`, fresh `composer serve:fast` process | 0.430 s | 0.116-0.125 s |

Cold request tetap perlu mengompilasi class untuk pertama kali. Rentang cold
di atas berasal dari proses server PHP baru yang diulang; variasinya mengikuti
file cache/antivirus Windows, sedangkan warm request stabil. Warm `/up` turun
sekitar 90% dibanding runtime tanpa OPcache. Gunakan:

```powershell
cd backend
composer install
composer serve:fast
```

Konfigurasi development tetap memakai `opcache.validate_timestamps=1` dan
`opcache.revalidate_freq=0`, sehingga perubahan source langsung terdeteksi.
Jangan menyamakan hasil Vite cold transform dengan Laravel TTFB; ukur keduanya
secara terpisah.

## Fetching and cache behavior

Website menggunakan cache GET per token, URL, query/filter, dan pagination.
Entry fresh dirender langsung. Entry stale yang masih layak kini juga dirender
langsung, lalu direvalidasi di background dengan single-flight. Setelah REST
response baru tiba, hanya route aktif yang membaca ulang cache tersebut.

Seluruh FAQ aktif tetap dimuat sebagai knowledge base chatbot, tetapi disimpan
sebagai array portabel pada cache backend selama 10 menit. Setiap pesan melakukan
ranking terhadap knowledge tersebut tanpa query ulang ke database. Mutation admin
menaikkan versi cache agar FAQ terbaru langsung digunakan.

Pertanyaan yang memiliki kecocokan FAQ kuat dijawab langsung dari FAQ resmi.
Gemini/Groq hanya digunakan bila FAQ tidak cukup atau saat pengguna memberikan
follow-up troubleshooting. Benchmark lokal retrieval dan ranking FAQ menghasilkan
39,48 ms pada cache miss dan 6 ms pada cache hit.

Cache menyimpan array, bukan objek Eloquent terserialisasi. Ini memperbaiki error
`__PHP_Incomplete_Class` yang sebelumnya menyebabkan endpoint chatbot menjadi 500
setelah cache dibaca oleh proses PHP baru. Provider AI memakai timeout terbatas dan
circuit breaker singkat agar outage berulang segera memakai fallback lokal.
