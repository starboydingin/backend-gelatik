# Design System & Redesign Specification — Aplikasi Mobile Gelatik

**Versi:** 3.1 (Mandatory Full Redesign — Bento Grid + Friendly Illustrative Civic)
**Platform:** Flutter (Mobile)
**Gaya Desain:** Bento Grid Modular Dashboard dengan sentuhan Friendly Illustrative Civic
**Disusun untuk:** Diskominfotik Provinsi Lampung

> **Perubahan dari v2.0:** Fitur, modul, dan requirement fungsional tetap sama persis dengan spesifikasi sebelumnya (lihat §6). Yang berubah total adalah filosofi visual, struktur layout (terutama dashboard), gaya komponen, dan nada komunikasi (copywriting) — dari gaya formal-kaku (Civic Formal Minimalist) menjadi gaya modular-hangat yang lebih approachable namun tetap kredibel sebagai aplikasi resmi pemerintahan.

> **Perubahan v3.1:** dokumen ini bukan lagi sekadar referensi visual. Seluruh spesifikasi di bawah adalah **instruksi implementasi wajib untuk Codex**. Codex harus melakukan **FULL REDESIGN presentation layer**, bukan restyle kecil pada UI lama. Business logic, API contract, authentication, authorization, state management, route, dan fitur existing harus dipertahankan, tetapi composition, hierarchy, layout, navigasi, card/list/form, empty state, loading state, dan pengalaman interaksi boleh dan harus dibangun ulang bila UI lama menghambat kualitas desain.

---

## 0. Instruksi Wajib untuk Codex — FULL REDESIGN, Bukan Restyle

### 0.1 Definisi pekerjaan

Codex harus memahami prinsip berikut:

> **PRESERVE FUNCTIONALITY — REBUILD THE EXPERIENCE.**

Yang **bukan** full redesign:
- hanya mengganti warna;
- hanya mengganti border radius;
- hanya menambah shadow;
- hanya mengganti icon;
- hanya mengecilkan/membesarkan padding;
- hanya memindahkan card lama;
- hanya membuat `DESIGN.md` lalu berhenti;
- hanya membuat satu dashboard baru sementara layar lain tetap memakai visual lama.

Yang **dimaksud** full redesign:
1. audit seluruh presentation layer Flutter aktif;
2. pertahankan business logic dan kontrak API;
3. evaluasi kembali information hierarchy setiap screen;
4. rebuild composition halaman;
5. refactor/rebuild reusable component system;
6. redesign navigation, list, detail, form, search, filter, dialog, bottom sheet, loading, empty, error, success, dan offline state;
7. migrasikan screen utama ke satu visual language yang konsisten;
8. jalankan aplikasi dan review hasil visual, bukan hanya membaca kode;
9. lanjutkan perbaikan apabila hasil masih terlihat seperti UI lama dengan “cat baru”.

Jika screenshot sebelum dan sesudah masih terlihat seperti aplikasi yang sama hanya dengan warna/radius berbeda, maka **redesign dianggap belum selesai**.

### 0.2 Larangan desain generik / “AI slop”

Hasil desain **tidak boleh terlihat seperti UI generik hasil generator/AI**. Hindari pola berikut:
- semua konten dimasukkan ke white card identik;
- penggunaan gradient dekoratif tanpa fungsi;
- terlalu banyak pill/chip;
- giant hero/card yang memakan layar;
- ilustrasi “corporate people” generik;
- icon campur gaya;
- shadow berlebihan;
- font terlalu besar untuk sekadar membuat tampilan terlihat “modern”;
- copywriting generik yang terasa seperti template SaaS;
- layout simetris monoton tanpa hierarchy informasi;
- dekorasi yang tidak mempunyai hubungan dengan Lampung/Gelatik;
- seluruh screen menggunakan pola komponen yang sama meskipun kebutuhan informasinya berbeda.

Setiap screen harus mempunyai alasan visual yang jelas berdasarkan kebutuhan user, bukan berdasarkan template.

### 0.3 Mobile-first mutlak — bukan website yang diperkecil

Aplikasi Flutter **tidak boleh terlihat seperti website yang dimobile-kan**.

Jangan:
- memindahkan sidebar web menjadi drawer lalu menganggap desain mobile selesai;
- menggunakan tabel desktop pada layar kecil;
- menumpuk card desktop secara vertikal;
- mempertahankan density, hierarchy, dan interaction pattern desktop;
- menggunakan CTA kecil seperti link web untuk action utama.

Gunakan pola native/mobile-first:
- bottom navigation yang sederhana;
- app bar yang ringkas;
- search yang mudah dijangkau;
- card/list yang dapat dipindai dengan satu tangan;
- bottom sheet untuk filter/action kontekstual;
- confirmation dialog untuk action kritis;
- pull-to-refresh;
- sticky/near-thumb primary action bila relevan;
- touch target minimum 44x44dp;
- screen detail yang dibagi section, bukan tabel;
- progressive disclosure agar informasi tidak menumpuk sekaligus.

### 0.4 Definition of Done visual

FULL REDESIGN baru boleh dinyatakan selesai jika:
1. App shell/navigation terlihat baru dan konsisten.
2. Dashboard mempunyai composition baru sesuai §7.
3. Login/Register mempunyai composition baru.
4. Screen layanan utama tidak lagi memakai struktur visual lama yang buruk.
5. Whitespace berlebihan berkurang secara nyata.
6. Information hierarchy lebih jelas.
7. Data penting muncul lebih awal.
8. Komponen reusable baru benar-benar digunakan.
9. Search, filter, form, detail, empty/error/loading/success state konsisten.
10. Semua fitur existing tetap dapat digunakan.
11. Hasil mobile terasa native/mobile-first, bukan adaptasi website.
12. Hasil visual tidak generik/AI-slop.
13. Codex sudah menjalankan aplikasi/build/test yang memungkinkan dan melakukan visual review.


---

## 1. Latar Belakang & Tujuan Redesign

Sama seperti v2.0: mengakomodasi revisi PKL dari Pak Peri, Pak Arif, Pak Tian, dan Pak Wahyu. Perbedaan pada versi ini: pendekatan visual diubah total agar (a) mengatasi keluhan "space kosong" secara lebih struktural lewat layout modular, dan (b) memberi kesan lebih ramah/manusiawi untuk pengguna ASN lintas usia — bukan sekadar formal kaku.

---

## 2. Filosofi Desain — Bento Grid + Friendly Illustrative Civic

Dua prinsip digabung:

**A. Bento Grid Modular**
Dashboard dan sebagian besar halaman ringkasan disusun sebagai grid blok-blok berukuran variatif (ada blok besar, sedang, kecil) — bukan list kartu seragam vertikal. Setiap blok merepresentasikan satu unit informasi/modul yang bisa "dipindai" sekaligus oleh mata pengguna, sehingga banyak fitur (peminjaman aset, konsultasi TIK, email ASN, infografis, dst.) tetap terasa ringkas dan tidak membosankan meski jumlahnya banyak.

**B. Friendly Illustrative Civic**
- Ilustrasi custom sederhana bertema kedaerahan (siger, motif Lampung, karakter muli & meghanai bergaya ilustrasi/animasi ringan — sesuai revisi Pak Peri) dipakai di titik-titik penting: splash, onboarding, empty state, dan pesan sukses/error.
- Bentuk elemen lebih membulat (radius besar), warna lebih hidup namun tetap dalam batas kredibel untuk instansi resmi.
- Nada komunikasi (copywriting) lebih personal dan hangat, menyapa pengguna dengan nama, bukan label formal kaku.

**Kenapa cocok untuk Gelatik:** aplikasi ini dipakai ASN lintas usia dan latar belakang teknis yang beragam — pendekatan yang terlalu kaku berisiko terasa "menakutkan" atau tidak ramah bagi sebagian pengguna, sementara pendekatan yang terlalu playful berisiko mengurangi kesan kredibel. Kombinasi bento grid (terstruktur, jelas) + ilustrasi ramah (personal, hangat) menyeimbangkan keduanya.

---

## 3. Design Tokens

### 3.1 Palet Warna

Palet inti dipertahankan dari sistem sebelumnya (navy, gold, teal) — namun aturan pemakaiannya diperluas agar lebih hidup, sesuai gaya Bento + Friendly Illustrative:

| Token | Warna | Peran | Perubahan dari v2.0 |
|---|---|---|---|
| `colorPrimary` (Navy) | `#1E3A8A` | Identitas utama, app bar, header, 1-2 blok bento kategori "resmi/informasi" | Tetap, tapi tidak lagi dominan ~60% — kini berbagi ruang lebih merata dengan gold & teal per blok. |
| `colorAccent` (Gold) | `#F59E0B` | Blok bento kategori "penting/highlight", CTA utama, elemen ilustrasi hangat | Boleh dipakai lebih luas sebagai warna identitas 1 blok bento penuh (bukan hanya elemen kecil). |
| `colorSecondary` (Teal) | `#0F766E` / `#2DD4BF` | Blok bento kategori "layanan/proses", grafik, ilustrasi pendukung | Boleh jadi warna identitas blok bento, bukan hanya aksen interaktif kecil. |
| `colorBackground` | `#FFFFFF` / `#F8FAFC` | Latar utama | Boleh pakai off-white sangat halus (`#F8FAFC`) sebagai canvas grid agar blok putih bento tetap terlihat menonjol. |
| `colorSurface` | `#FFFFFF` | Isi blok bento | — |
| `colorBorder` | `#E2E8F0` | Border tipis (opsional) | Bento grid mengandalkan spacing & warna blok untuk pemisahan, border boleh dihilangkan pada sebagian besar blok. |
| `colorTextPrimary` | `#111827` | Teks di atas surface putih | — |
| `colorTextOnPrimary` | `#FFFFFF` | Teks di atas blok navy/gold/teal solid | — |
| `colorTextMuted` | `#111827` @ 60% | Caption, teks sekunder | — |
| `colorSuccess` / `colorWarning` / `colorError` / `colorInfo` | `#16A34A` / gold / `#DC2626` / navy | Status | Tetap sama seperti v2.0. |

**Prinsip baru — "1 blok, 1 warna identitas":** setiap blok bento boleh punya warna latar solid (navy/gold/teal/putih) sebagai identitas kategorinya, alih-alih semua blok putih dengan ikon kecil berwarna. Ini yang membuat dashboard terasa hidup dan mudah dipindai, sekaligus mengisi ruang kosong secara natural.

### 3.2 Tipografi

| Peran | Font | Weight | Catatan |
|---|---|---|---|
| Heading autentikasi | Montserrat | 700–800 | Tetap, namun copy lebih personal (lihat §3.4). |
| Heading blok bento | Montserrat | 600–700 | Ukuran lebih besar dari v2.0 agar judul blok langsung terbaca tanpa perlu ikon penjelas tambahan. |
| Body/teks umum | Inter | 400–500 | Tetap. |
| Caption/teks kecil | Inter | 400 | Tetap. |

### 3.3 Ikonografi & Ilustrasi

- Ikon fungsional tetap mengikuti sistem token warna (`AppIconTheme`) seperti v2.0 — tidak berubah.
- **Baru — Set Ilustrasi Kustom:**
  - Karakter **Muli** dan **Meghanai** bergaya siger, dibuat dalam bentuk ilustrasi/animasi ringan (Lottie atau ilustrasi statis bertahap), menggantikan aset `SIGER.png` polos di titik-titik berikut: splash screen (opsional, bergantian dengan logo), onboarding, empty state (mis. "belum ada pengajuan", "belum ada notifikasi"), dan pesan sukses (mis. setelah pengajuan berhasil dikirim).
  - Ilustrasi disimpan di `assets/images/illustrations/` (folder baru, terpisah dari `assets/images/` agar tidak tercampur dengan aset logo/ikon fungsional) — untuk kedua platform (website dan mobile) sesuai revisi Pak Peri #4.
  - Gaya ilustrasi: flat/semi-flat dengan palet warna dari §3.1 (navy, gold, teal) agar tetap terasa satu kesatuan brand, bukan ilustrasi generik "flat corporate people" ala stok gratis.

### 3.4 Nada Komunikasi (Copywriting)

- Sapaan personal: *"Halo, {nama}! Ini rangkuman aktivitasmu hari ini."* menggantikan label statis *"Dashboard"*.
- Empty state ramah: *"Belum ada pengajuan aset nih. Yuk ajukan yang pertama!"* dengan ilustrasi Muli/Meghanai, menggantikan teks kosong generik *"Tidak ada data"*.
- Pesan sukses/error tetap informatif namun hangat, tidak kaku birokratis.

### 3.5 Struktur Komponen

- **Border radius:** 16–20px untuk blok bento & tombol (naik dari 8–12px di v2.0) — mendukung kesan ramah/rounded dari Friendly Illustrative.
- **Elevation/shadow:** shadow lembut tipis (elevation 1), dipakai minim — pemisah utama antar blok adalah warna & spacing, bukan shadow tebal.
- **Grid bento:** grid 2 kolom fleksibel (span 1 atau 2 kolom per blok, tinggi bervariasi 1x atau 2x unit) — lihat contoh layout di §7.
- **Spacing:** gap antar blok 12–16px, padding dalam blok 16–20px.

---

## 4. Aset & Penempatan Logo

| Aset | Penempatan | Catatan |
|---|---|---|
| `logo-nobackground&teksgelatik.png` | App bar/navbar semua layar utama | Disandingkan dengan teks "Gelatik" di sampingnya, sama seperti v2.0 — elemen identitas ini tidak berubah meski gaya visual di sekitarnya berubah. |
| `logo-tanpabackground.png` | Splash screen | Tetap di tengah, namun kini bisa dikombinasikan dengan ilustrasi Muli/Meghanai muncul bertahap (animasi splash) alih-alih statis polos. |
| `icon lampung.png` | Layar informatif (splash pendukung, login, register, halaman info resmi) | Tetap dipakai sebagai identitas kedaerahan; berdampingan dengan ilustrasi baru Muli/Meghanai bergaya siger — bukan saling menggantikan, keduanya melengkapi. |
| **[Baru]** Ilustrasi Muli/Meghanai bergaya siger | Onboarding, empty state, pesan sukses, aksen splash | Lihat §3.3. Menggantikan penggunaan `SIGER.png` polos di konteks yang butuh kesan hangat/personal (bukan konteks formal/dokumen resmi, yang tetap pakai `icon lampung.png`). |

---

## 5. Struktur Navigasi

Bottom navigation tetap 4 tab (Beranda, Layanan, Notifikasi, Profil) — tidak berubah dari v2.0, karena pola ini sudah familiar dan tidak perlu diubah hanya demi "beda". Perubahan style difokuskan pada **konten dan layout di dalam tiap tab**, terutama Beranda.

---

## 6. Spesifikasi Layar per Modul

Seluruh modul, fitur, dan revisi fungsional berikut **identik dengan v2.0** — hanya gaya visual dan sebagian layout yang berubah:

- Autentikasi: Login, Register, Forgot/Reset Password, Splash — fitur show/hide password, checklist syarat password, validasi email domain dinas, info "cara membuat akun" tetap ada, kini disajikan dengan radius lebih besar, ilustrasi pendukung, dan copy lebih personal.
- Dashboard (lihat §7 — perubahan layout utama ada di sini).
- Peminjaman Aset: daftar, detail, pengajuan, pilih aset, status pengajuan (stepper), info aset sedang dipinjam (nama aset, tanggal pinjam, peminjam, status) — kini ditampilkan sebagai kombinasi blok bento (ringkasan) + list detail di bawahnya.
- Konsultasi TIK: daftar, detail, discovery/topik, buat konsultasi — topik discovery kini ditampilkan sebagai blok bento berwarna per kategori topik, bukan list ikon seragam.
- Pengajuan Email ASN: daftar pegawai (difilter OPD login), form pengajuan, daftar & detail usulan — tidak berubah secara fungsional.
- Informasi aset/perangkat, layanan internet/router OPD, self-assessment gangguan — tidak berubah secara fungsional; halaman self-assessment bisa memakai ilustrasi Muli/Meghanai di tiap step wizard agar tidak terasa seperti form birokratis.
- Chatbot Native AI (alur auto-consultation setelah 3 respons gagal, keterangan cara menjawab iya/tidak, pengambilan data dari profil + keluhan terakhir) dan Chatbot WebView lama — alur logic identik dengan v2.0 §6.7, tampilan bubble chat kini pakai radius besar & warna sesuai identitas (bubble AI = navy/teal, bubble user = putih/abu).
- Kritik-saran, rating layanan, notifikasi, profil (edit profil, ubah password, activity log, subscription WhatsApp) — tidak berubah secara fungsional, gaya visual mengikuti radius & warna baru.
- Fitur lintas-layar: Search (ikon selalu terlihat di app bar), offline cache (indikator badge pada data cache), responsivitas mobile, helper text pada form kompleks — semua tetap seperti v2.0 §8.

---

## 7. Layout Dashboard — Bento Grid (Perubahan Utama)

Ini adalah perbedaan paling signifikan dari v2.0. Alih-alih list vertikal (header → infografis carousel → pengumuman → grid ikon → status), dashboard kini disusun sebagai **grid bento 2 kolom** dengan blok berukuran variatif:

```
┌─────────────────────────────────────────────┐
│  App Bar (navy) — Logo Gelatik + teks,       │
│  ikon search, ikon notifikasi                │
├─────────────────────────────────────────────┤
│  "Halo, {nama}! Ini rangkuman aktivitasmu    │
│   hari ini." (sapaan personal, bukan judul   │
│   statis "Dashboard")                        │
├───────────────────────┬───────────────────────┤
│ BLOK BESAR (span 2)   │                       │
│ Infografis Trafik OPD │                       │
│ (navy solid, bar chart│                       │
│  teal, highlight gold │                       │
│  untuk OPD user)      │                       │
├───────────────────────┼───────────────────────┤
│ BLOK SEDANG           │ BLOK SEDANG           │
│ Pemakaian Bandwidth   │ Status Pengajuan      │
│ Saya (teal solid,     │ Terakhir (putih,      │
│ mini line chart)      │ badge status)         │
├───────────────────────┴───────────────────────┤
│ BLOK BESAR (span 2) — Pengumuman & Kalender   │
│ (putih, scroll horizontal card di dalamnya)   │
├───────────────────────┬───────────────────────┤
│ BLOK KECIL            │ BLOK KECIL            │
│ Peminjaman Aset       │ Konsultasi TIK        │
│ (gold solid, ikon +   │ (teal solid, ikon +   │
│  jumlah aktif)        │  jumlah aktif)        │
├───────────────────────┼───────────────────────┤
│ BLOK KECIL            │ BLOK KECIL            │
│ Email ASN             │ Internet/Router OPD   │
│ (navy solid)          │ (putih, border tipis) │
├───────────────────────┴───────────────────────┤
│ BLOK KECIL (span 2) — Kritik-Saran & Rating   │
│ (putih, ilustrasi kecil Muli/Meghanai)        │
└─────────────────────────────────────────────┘
```

**Prinsip penyusunan grid:**
1. Blok informasi (infografis) mendapat ukuran terbesar dan posisi teratas — memenuhi keluhan "informasi harus di depan".
2. Blok shortcut modul (peminjaman aset, konsultasi TIK, dst.) diberi warna solid berbeda-beda sebagai identitas kategori, sekaligus mengisi ruang secara visual tanpa terasa kosong.
3. Setiap blok menampilkan **data ringkas** (jumlah aktif, status terakhir), bukan hanya ikon+label statis — bento grid dipakai untuk membawa informasi, bukan sekadar dekorasi grid.
4. Susunan ini bisa di-reorder di masa depan (drag-to-customize) sebagai pengembangan lanjutan, karena struktur grid modular secara alami mendukung personalisasi tata letak per pengguna.

---

## 8. Fitur Lintas-Layar (Cross-Cutting)

### 8.1 Search Mobile
- Fitur pencarian harus **mudah ditemukan**, terutama pada screen dengan data banyak.
- Search icon/entry point tidak boleh tersembunyi.
- Terapkan pada modul yang secara nyata membutuhkan pencarian, seperti aset, FAQ, pengumuman, pegawai, peminjaman, atau data lain yang didukung backend.
- Gunakan debounce untuk pencarian berbasis API.
- Sediakan clear action, loading state, empty state, dan error state.
- Jangan membuat global search palsu jika API belum mendukung pencarian lintas-modul.

### 8.2 Offline Cache
- Data yang pernah berhasil dibuka harus dapat ditampilkan kembali saat offline untuk data yang aman dicache.
- Prioritas cache: dashboard/ringkasan, FAQ, pengumuman, daftar peminjaman user, konsultasi, dan data ringan yang relevan.
- REST API tetap source of truth; cache hanya fallback/offline copy.
- Saat menampilkan cache, berikan indikator ringan seperti **“Menampilkan data tersimpan”**.
- Ketika online kembali, lakukan refresh/sinkronisasi.
- Jangan menyimpan password, secret, token mentah di storage data biasa, atau data sensitif yang tidak perlu.
- Mutation penting seperti verifikasi administratif tidak boleh dipaksakan offline.

### 8.3 Responsivitas Mobile
- Layout harus diuji pada beberapa lebar smartphone.
- Bento grid boleh berubah span/urutan bila ruang sempit.
- Tidak boleh overflow, text clipping, card terlalu sempit, atau chart tidak terbaca.

### 8.4 Helper Text & Form Guidance
- Form kompleks wajib mempunyai label dan helper text singkat pada field yang berpotensi membingungkan.
- Hindari paragraf instruksi panjang.
- Validation message harus spesifik dan dapat ditindaklanjuti user.

### 8.5 State Wajib
Setiap screen data utama harus mempunyai:
- loading;
- content;
- empty;
- error;
- cached/offline state bila relevan;
- success feedback setelah mutation.


---

## 9. Referensi Implementasi Kode

- `lib/core/theme/app_colors.dart`, `app_typography.dart`, `auth_typography.dart` — perbarui nilai radius (16-20px) dan tambahkan definisi warna blok bento jika berbeda dari token dasar.
- Widget baru yang perlu dibuat:
  - `BentoBlock` — widget dasar untuk 1 blok grid (menerima `size` (small/medium/large), `colorVariant`, `child`).
  - `BentoDashboardGrid` — layout grid yang menyusun daftar `BentoBlock` sesuai §7.
  - `IllustrationAsset` — widget untuk menampilkan ilustrasi Muli/Meghanai (statis atau Lottie) di berbagai konteks (splash, empty state, sukses).
  - `PersonalGreeting` — widget sapaan personal di header dashboard, mengambil nama dari profil user.
- Widget dari v2.0 yang tetap dipakai tanpa perubahan besar: `AppLogo`, `LampungIconBadge`, `StatusBadge`, `AppIconTheme`.

---

## 10. Prioritas Implementasi

### Prioritas 1 — Fungsionalitas
1. Validasi email dinas untuk registrasi baru.
2. Filter pegawai sesuai OPD akun login pada pengajuan email ASN.
3. Informasi aset yang sedang dipinjam.
4. Search/pencarian mobile.
5. Penyamaan informasi FAQ dan Chatbot.
6. Auto-escalation Chatbot ke konsultasi setelah 3 saran gagal.
7. Helper text pada form.
8. Show/Hide Password.
9. Konsistensi password policy antara Flutter dan backend.

### Prioritas 2 — Infografis & Data
1. **Infografis trafik/bandwidth internet setiap OPD.**
2. **Infografis penggunaan bandwidth masing-masing user.**
3. Ringkasan informasi jaringan/bandwidth di dashboard.
4. Data informatif lain yang relevan untuk user pada bagian awal dashboard.
5. Jangan membuat data dummy seolah data real; gunakan empty/unavailable state bila source belum ada.

### Prioritas 3 — Full UI/UX Redesign
1. Bangun/refactor design foundation dan reusable component.
2. Rebuild App Shell, App Bar, bottom navigation, dan navigation flow.
3. Rebuild Dashboard Bento sesuai §7 dan §12.
4. Rebuild Login/Register/Forgot/Reset.
5. Redesign screen layanan utama.
6. Redesign detail/form/search/filter/loading/empty/error/success state.
7. Integrasikan ilustrasi Muli/Meghanai.
8. Kurangi whitespace berlebihan dan tingkatkan information density.
9. Pastikan hasil tidak generik/AI-slop.

### Prioritas 4 — Pengembangan Mobile
1. Offline cache.
2. Optimisasi loading dan request berulang.
3. Perbaikan responsivitas mobile.
4. Visual QA pada device/emulator nyata.
5. Drag-to-customize bento hanya opsional/jangka panjang dan bukan prioritas sebelum requirement utama selesai.


---

## 11. Aksesibilitas

- Karena blok bento kini banyak memakai warna solid (navy/gold/teal) sebagai latar penuh, **wajib** cek kontras teks di atas tiap warna solid tersebut secara individual (WCAG AA, rasio ≥ 4.5:1) — risiko lebih tinggi dibanding v2.0 karena warna solid dipakai lebih luas.
- Ilustrasi tidak boleh menjadi satu-satunya penanda status/aksi (harus selalu didampingi teks) — ilustrasi bersifat pendukung emosional, bukan pengganti informasi fungsional.
- Ukuran target sentuh minimum tetap 44x44dp; blok bento kecil (2 kolom) harus tetap memenuhi ukuran ini meski dalam grid padat.

---

## 12. Dashboard Mobile — Informasi Harus Ada di Depan

Dashboard adalah **information hub**, bukan sekadar kumpulan shortcut.

User harus bisa membuka aplikasi dan langsung mengetahui:
- kondisi/summary bandwidth OPD;
- penggunaan bandwidth miliknya;
- aktivitas/pengajuan terbaru;
- pengumuman penting;
- layanan yang paling sering digunakan;
- status layanan/pengajuan yang sedang berjalan;
- informasi jaringan atau layanan TIK yang relevan;
- notifikasi penting.

Urutan prioritas dashboard:

1. **Personal greeting + identitas ringkas**
   - nama user;
   - OPD bila tersedia;
   - notifikasi/search access.

2. **Infografis Trafik/Bandwidth OPD — PRIORITAS UTAMA**
   - diletakkan pada area atas dashboard;
   - span besar;
   - harus memberikan ringkasan yang dapat dipahami tanpa masuk halaman detail.

3. **Infografis Penggunaan Bandwidth User — PRIORITAS UTAMA**
   - diletakkan berdampingan/tepat setelah ringkasan OPD;
   - tampil sebagai compact mini-chart + angka/ringkasan bila data tersedia.

4. **Status aktivitas/pengajuan terbaru**
   - peminjaman;
   - konsultasi;
   - pengajuan email ASN;
   - tampilkan hanya data milik user.

5. **Pengumuman & informasi penting**
   - jangan disembunyikan terlalu dalam;
   - tampilkan preview ringkas.

6. **Shortcut layanan**
   - Peminjaman Aset;
   - Konsultasi TIK;
   - Email ASN;
   - Internet/Router OPD;
   - FAQ;
   - Chatbot.

7. **Informasi pendukung**
   - kritik/saran;
   - rating;
   - kalender bila relevan;
   - FAQ populer atau tips TIK bila data tersedia.

Prinsip:
- data > dekorasi;
- summary > ikon kosong;
- progressive disclosure: ringkas di dashboard, detail di screen khusus;
- jangan membuat blok besar hanya karena ingin memenuhi ruang.

---

## 13. Spesifikasi Wajib Infografis Bandwidth

### 13.1 Infografis Trafik/Bandwidth Internet Setiap OPD

Codex **wajib menambahkan area/fitur infografis trafik atau bandwidth OPD**.

Tujuan:
- user dapat memahami kondisi/kapasitas/penggunaan internet OPD secara cepat;
- informasi tersebut tampil di bagian awal dashboard, bukan tersembunyi di menu belakang.

Sebelum implementasi, audit:
- endpoint router OPD;
- model/tabel router;
- sumber monitoring jaringan;
- service/backend yang sudah tersedia;
- field bandwidth existing;
- apakah tersedia data time-series trafik atau hanya nilai bandwidth statis.

Jika time-series tersedia, gunakan visual seperti:
- line chart;
- area/mini line chart;
- bar chart per interval;
- summary current/peak bila field tersedia.

Jika hanya bandwidth statis tersedia:
- jangan mengarang trafik;
- tampilkan summary kapasitas/status sesuai data asli;
- siapkan component/API abstraction agar time-series dapat ditambahkan kemudian.

Jika data belum tersedia:
- tampilkan state seperti **“Data trafik OPD belum tersedia”**;
- jangan membuat angka dummy/random.

### 13.2 Infografis Penggunaan Bandwidth Masing-Masing User

Codex **wajib menambahkan area/fitur infografis penggunaan bandwidth user** apabila backend/source data dapat menyediakan metrik tersebut.

Tujuan:
- user dapat melihat ringkasan penggunaan bandwidth miliknya sendiri;
- data user lain tidak boleh terlihat.

Visual yang disarankan sesuai tipe data:
- mini line chart untuk penggunaan terhadap waktu;
- progress/utilization bar bila berupa persentase;
- summary usage card bila hanya tersedia agregat.

Jika sumber data tidak dapat mengatribusikan penggunaan sampai level user:
- jangan melakukan estimasi palsu;
- dokumentasikan gap data;
- buat UI state yang jujur;
- jangan menyimpulkan bandwidth user dari bandwidth OPD tanpa dasar data.

### 13.3 Tampilan Infografis

Infografis harus:
- ringkas dan readable pada smartphone;
- tidak terlalu banyak axis/legend;
- mempunyai label satuan yang jelas;
- menggunakan navy/teal sebagai warna utama chart dan gold untuk highlight;
- tetap aksesibel;
- tidak memakai 3D chart;
- tidak memakai chart hanya untuk dekorasi;
- dapat dibuka ke detail bila memang ada detail data.

---

## 14. Revisi Fitur & Sistem Wajib

### 14.1 Chatbot — Auto Consultation setelah 3 Saran Tidak Berhasil

Setelah sekitar **3 respons/saran bantuan chatbot** dan user masih menunjukkan masalah belum selesai, chatbot harus menawarkan secara eksplisit:

> “Jika semua cara dari saran saya masih tidak bisa, maukah saya buatkan konsultasi kepada admin secara langsung? (iya/tidak)”

Di bawah/bersamaan dengan pesan tersebut tampilkan helper:

> “Anda hanya perlu menjawab ‘iya’ atau ‘tidak’.”

Jika user menjawab **“iya”** atau **“ya”**:
- buat konsultasi melalui backend;
- ambil data identitas yang diperlukan dari profile user;
- jangan meminta ulang data profile yang sudah tersedia;
- isi keterangan konsultasi dibuat otomatis berdasarkan **keluhan terakhir user yang relevan**, bukan seluruh chat;
- AI boleh merapikan keluhan terakhir menjadi kalimat formal tetapi tidak boleh mengarang detail;
- success hanya ditampilkan setelah backend benar-benar berhasil.

Jika user menjawab **“tidak”**:
- jangan membuat konsultasi;
- balas sopan, misalnya:
  *“Baik, terima kasih. Jika nanti masih membutuhkan bantuan atau memiliki pertanyaan lain, silakan tanyakan kembali melalui Gelatik.”*
- reset state eskalasi agar percakapan baru dapat dilanjutkan.

Cegah:
- double submit;
- konsultasi duplikat;
- klaim berhasil sebelum transaksi;
- penggunaan seluruh conversation history sebagai isi tiket.

### 14.2 FAQ dan Chatbot
- Informasi FAQ dan Chatbot harus konsisten.
- FAQ aktif dari backend menjadi sumber jawaban cepat untuk pertanyaan yang cocok.
- Jangan hardcode dua basis FAQ berbeda pada mobile.
- Pertanyaan yang tidak cocok dengan FAQ baru diteruskan ke provider AI sesuai arsitektur existing.

### 14.3 Show/Hide Password & Password Policy
- Login dan Register wajib mempunyai Show/Hide Password.
- Password policy di Flutter harus mengikuti validator final backend.
- Tampilkan checklist/helper syarat password secara jelas.
- Jangan membuat rule berbeda antara web, mobile, dan backend.

### 14.4 Validasi Email Resmi Dinas
- Registrasi **baru** dibatasi pada email resmi dinas sesuai ketentuan/sumber resmi yang benar.
- User existing tidak dipaksa migrasi dan tetap dapat dipakai testing.
- Jangan mengarang domain resmi.
- Validasi final tetap di backend.
- Jika integrasi resmi Pemerintah Lampung belum tersedia/reliable, buat integration point/configuration yang maintainable dan tampilkan error yang jujur.

### 14.5 Filter Pegawai Berdasarkan OPD
Pada pengajuan email ASN:
- hasil pencarian pegawai hanya menampilkan pegawai sesuai OPD akun login;
- backend wajib enforce filter/authorization;
- frontend tidak boleh mengandalkan filter lokal saja;
- empty state: **“Tidak ditemukan pegawai pada OPD Anda.”**

### 14.6 Informasi Aset Sedang Dipinjam
Pada daftar/detail peminjaman tampilkan minimal:
- nama/barang aset;
- tanggal peminjaman;
- tanggal selesai bila tersedia;
- informasi peminjam sesuai hak akses;
- status peminjaman/aset yang benar-benar tersedia.

User tidak boleh melihat data privat peminjam lain.

---

## 15. Login & Registrasi — Redesign dan Edukasi User

Login/Register harus dibangun ulang sebagai pengalaman mobile, bukan form web yang ditumpuk vertikal.

Wajib:
- logo Gelatik existing tetap digunakan;
- heading dan copy personal tetapi profesional;
- Show/Hide Password;
- helper password;
- validation yang jelas;
- CTA Login/Register yang mudah dijangkau;
- informasi **“Belum punya akun?”** dan cara membuat akun.

Informasi cara membuat akun dapat dibuat sebagai compact information panel/bottom sheet:
1. pilih Daftar;
2. isi identitas;
3. pilih OPD;
4. gunakan email resmi dinas;
5. buat password sesuai ketentuan;
6. login setelah registrasi berhasil.

Jangan membuat layar login terlalu penuh atau memakai hero/dekorasi yang mengorbankan form.

---

## 16. Ilustrasi Muli & Meghanai — Anti-Generic

Karakter Muli & Meghanai harus:
- menggunakan unsur siger/Lampung secara jelas;
- memakai palet brand navy/gold/teal;
- terasa seperti identitas Gelatik;
- bukan “corporate people” generik;
- tidak terlalu childish;
- tidak menyerupai aset stok;
- digunakan secara selektif untuk onboarding, empty state, success, error ringan, atau supporting visual.

Ilustrasi tidak boleh menjadi pengganti data atau primary action.

Struktur asset:
- Flutter: `assets/images/illustrations/`
- Website: folder asset ilustrasi ekuivalen pada project Vue.

Jika Codex tidak mempunyai aset final berkualitas:
- jangan membuat placeholder jelek lalu menganggap selesai;
- siapkan folder, naming convention, widget, dan integration point;
- gunakan aset final yang diberikan/desain terpisah ketika tersedia.

---

## 17. Catatan Revisi Website yang Harus Dikoordinasikan

Walaupun dokumen ini berfokus pada Flutter Mobile, perubahan berikut harus dicatat agar implementasi lintas-platform konsisten:
- website perlu landing page yang lebih lengkap, informatif, dan tidak kosong;
- UI website perlu lebih compact;
- navigasi website perlu grouped/sub-navigation agar tidak penuh;
- login website perlu informasi cara membuat akun;
- Show/Hide Password dan password policy harus konsisten;
- FAQ/Chatbot, validasi email dinas, filter OPD, peminjaman, dan infografis menggunakan kontrak backend yang sama;
- ilustrasi Muli/Meghanai disimpan juga pada assets website;
- business rule tidak boleh dibuat berbeda khusus Flutter atau Vue.

---

## 18. Acceptance Criteria Codex

Sebelum menyatakan pekerjaan selesai, Codex harus melakukan checklist:

### Visual
- [ ] UI benar-benar berubah secara struktural, bukan hanya restyle.
- [ ] Dashboard mengikuti bento/information-first composition.
- [ ] Tidak terlihat seperti website yang diperkecil.
- [ ] Tidak terlihat generik/AI-slop.
- [ ] Whitespace berlebihan berkurang.
- [ ] Navigation dan app shell terasa native mobile.
- [ ] Typography, spacing, radius, iconography, dan color usage konsisten.
- [ ] Screen utama memakai visual language yang sama.

### Fitur
- [ ] Infografis trafik/bandwidth OPD ditambahkan atau mempunyai honest unavailable state bila source data belum ada.
- [ ] Infografis penggunaan bandwidth user ditambahkan atau gap datanya didokumentasikan tanpa data palsu.
- [ ] Informasi penting tampil di dashboard.
- [ ] Search mobile mudah ditemukan.
- [ ] Offline cache bekerja untuk data yang aman.
- [ ] Show/Hide Password tersedia.
- [ ] Password policy konsisten.
- [ ] Registrasi baru mempunyai validasi email dinas.
- [ ] User existing tetap dapat dipakai testing.
- [ ] Pegawai pengajuan email difilter OPD.
- [ ] Informasi aset sedang dipinjam tersedia.
- [ ] FAQ dan Chatbot konsisten.
- [ ] Chatbot menawarkan konsultasi setelah 3 saran gagal.
- [ ] Helper cara menjawab iya/tidak tampil jelas.

### Engineering
- [ ] Fitur existing tidak hilang.
- [ ] REST API tetap source of truth.
- [ ] Business rule final tetap di backend.
- [ ] Tidak ada data dummy yang ditampilkan sebagai data real.
- [ ] Tidak ada secret/credential di frontend.
- [ ] `flutter analyze` dijalankan.
- [ ] `flutter test` dijalankan bila tersedia.
- [ ] Build/run pada device/emulator dilakukan jika environment memungkinkan.
- [ ] Hasil visual direview setelah aplikasi dijalankan.
- [ ] Codex tidak berhenti hanya dengan memperbarui `DESIGN.md`.

---

## 19. Instruksi Eksekusi Terakhir untuk Codex

Setelah membaca dokumen ini:

1. **Jangan hanya menjelaskan rencana.**
2. Audit source Flutter aktif terlebih dahulu.
3. Mapping screen, reusable widget, route, provider, repository, service, dan API yang terdampak.
4. Buat/refactor design foundation.
5. Rebuild presentation layer sesuai dokumen ini.
6. Mulai dari App Shell + Navigation + Dashboard + Authentication sebagai visual foundation.
7. Lanjutkan ke screen layanan utama sampai visual language konsisten.
8. Terapkan revisi fungsional §14 dan cross-cutting feature §8.
9. Jalankan analyze/test/build yang memungkinkan.
10. Jalankan aplikasi dan review hasil visual.
11. Jika hasil masih mirip UI lama hanya dengan theme baru, **lanjutkan redesign dan jangan menyatakan selesai**.
12. Jika hasil terlihat lebih buruk, perbaiki sebelum final report.
13. Jangan menghapus business logic existing hanya demi mempermudah redesign.

**Final command:**

> **IMPLEMENT THE FULL REDESIGN DIRECTLY INTO THE SOURCE CODE. DO NOT STOP AT DESIGN.md. DO NOT RETURN THE OLD UI WITH NEW COLORS. PRESERVE FUNCTIONALITY, REBUILD THE MOBILE EXPERIENCE.**

