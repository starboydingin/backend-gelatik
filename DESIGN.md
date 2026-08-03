# 🎨 Design System — Modern Minimalist "Siger & Pesisir" (Gelatik Flutter)

## 0. Informasi Dokumen

| Item | Detail |
|---|---|
| **Nama Desain** | Gelatik — Clean & Trustworthy (Material Design 3) |
| **Terkait Dokumen** | `prd.md`, `srs.md` (migrasi Gelatik ke Flutter) |
| **Versi** | 1.0 |
| **Mode** | Light Mode & Dark Mode |
| **Palet** | "Siger & Pesisir" — identitas Navy & Emas khas Provinsi Lampung |

---

## 1. Konsep & Rasional Desain

Gaya ini mengutamakan **kepercayaan, formalitas pemerintahan, dan aksesibilitas tinggi**, mengikuti kaidah Material Design 3 (M3) milik Google: sudut membulat lembut, elevasi bayangan halus, komponen yang familiar bagi pengguna Android/iOS pada umumnya. Palet "Siger & Pesisir" mengambil warna khas kelembagaan Lampung — Navy (Siger) dan Emas (Pesisir) — sehingga aplikasi terasa resmi tanpa kaku, modern tanpa kehilangan kredibilitas sebagai layanan publik.

Prinsip: *"tenang, jelas, dan dapat dipercaya di setiap interaksi."*

---

## 2. Color Palette (M3 Role Mapping)

### 2.1 Light Mode

| Role M3 | Token | Hex | Deskripsi |
|---|---|---|---|
| Primary | `primary` | `#1E3A8A` | Navy — header, tombol aksi utama (FAB), ikon aktif |
| On Primary | `on-primary` | `#FFFFFF` | Teks/ikon di atas primary |
| Primary Container | `primary-container` | `#DBEAFE` | Latar chip/ikon terkait aksi utama (mis. highlight menu aktif) |
| On Primary Container | `on-primary-container` | `#1E3A8A` | Teks di atas primary container |
| Secondary/Accent | `accent-gold` | `#F59E0B` | Siger Gold — notifikasi, badge "Pending", tombol peringatan |
| On Secondary | `on-accent-gold` | `#1F2937` | Teks di atas gold (kontras lebih baik dgn dark text) |
| Background | `background` | `#F8FAFC` | Off-White — latar aplikasi |
| On Background | `on-background` | `#0F172A` | Teks utama |
| Surface | `surface` | `#FFFFFF` | Pure White — card riwayat peminjaman/konsultasi |
| On Surface | `on-surface` | `#1E293B` | Teks di atas card |
| Surface Variant | `surface-variant` | `#EEF2F6` | Latar input field, chip non-aktif |
| Outline | `outline` | `#CBD5E1` | Border tipis komponen (jika diperlukan selain elevasi) |
| Success | `status-success` | `#16A34A` | Badge "Selesai" |
| Warning | `status-warning` | `#F59E0B` | Badge "Diproses" (selaras Siger Gold) |
| Error/Danger | `status-error` | `#DC2626` | Badge "Ditolak", validasi form |
| Info | `status-info` | `#0284C7` | Notifikasi informatif netral |

### 2.2 Dark Mode

> Mengikuti pedoman M3 dark theme: warna primary/secondary "dinaikkan" (lighter tone) agar kontras memadai di atas surface gelap, bukan sekadar invert warna.

| Role M3 | Token | Hex | Deskripsi |
|---|---|---|---|
| Primary | `primary` | `#93C5FD` | Navy dinaikkan ke blue-300 agar kontras di latar gelap |
| On Primary | `on-primary` | `#1E3A8A` | Teks/ikon di atas primary (navy gelap di atas biru muda) |
| Primary Container | `primary-container` | `#1E3A8A` | Latar chip terkait aksi utama di dark mode |
| On Primary Container | `on-primary-container` | `#DBEAFE` | Teks di atas primary container gelap |
| Secondary/Accent | `accent-gold` | `#FBBF24` | Gold dinaikkan ke amber-400 |
| On Secondary | `on-accent-gold` | `#1F2937` | Teks di atas gold |
| Background | `background` | `#0F172A` | Navy sangat gelap — konsisten dengan identitas, bukan hitam pekat |
| On Background | `on-background` | `#F1F5F9` | Teks utama |
| Surface | `surface` | `#1E293B` | Card riwayat — sedikit lebih terang dari background |
| On Surface | `on-surface` | `#E2E8F0` | Teks di atas card |
| Surface Variant | `surface-variant` | `#334155` | Latar input field |
| Outline | `outline` | `#475569` | Border tipis komponen |
| Success | `status-success` | `#4ADE80` | Badge "Selesai" |
| Warning | `status-warning` | `#FBBF24` | Badge "Diproses" |
| Error/Danger | `status-error` | `#F87171` | Badge "Ditolak" |
| Info | `status-info` | `#38BDF8` | Notifikasi informatif netral |

---

## 3. Tipografi

| Peran M3 | Font | Weight | Ukuran (mobile) |
|---|---|---|---|
| Display (judul besar, mis. Splash) | **Inter** (fallback Roboto) | 700 | 28–32sp |
| Headline (judul screen) | Inter | 600 | 22sp |
| Title (judul card/section) | Inter | 600 | 16–18sp |
| Body Large (form, deskripsi) | Inter | 400 | 16sp |
| Body Medium | Inter | 400 | 14sp |
| Label (tombol, badge) | Inter | 500 (Medium) | 13–14sp |
| Caption | Inter | 400 | 12sp |

> Inter dipilih sebagai proxy Roboto yang lebih optimal keterbacaannya untuk form panjang (peminjaman, konsultasi) lintas usia, sesuai brief. Roboto tetap dapat dipakai sebagai fallback jika ingin 100% selaras M3 default.

---

## 4. Layout & Komponen Struktural

### 4.1 Prinsip Layout
- **Card putih lega** (padding 16–20dp) untuk membungkus setiap item riwayat peminjaman/konsultasi — bukan grid rapat, memberi ruang napas.
- **Elevasi bayangan lembut**: `elevation: 1–2dp` (shadow blur besar, opacity rendah, mis. `rgba(15, 23, 42, 0.06)`), bukan garis stroke tegas.
- **Sudut membulat sedang**: radius 12–16dp pada card, 8dp pada input field, full-round pada FAB.
- Grid konten: single-column list untuk riwayat (mengutamakan kejelasan per-item), 2-column grid hanya untuk menu layanan cepat di Home (grid standar simetris, berbeda dari pendekatan bento asimetris).

### 4.2 Spacing Scale
`4 / 8 / 16 / 24 / 32 / 40` dp — mengikuti 8dp grid system M3.

### 4.3 Radius

| Elemen | Radius |
|---|---|
| Card | 16dp |
| Input field | 8dp |
| Tombol utama | 24dp (stadium/rounded, bukan full pill tajam) |
| FAB | Full round |
| Badge status | Full round (stadium) |
| Bottom Sheet / Dialog | 20dp (top corners) |

---

## 5. Komponen UI Kunci

| Komponen | Spesifikasi |
|---|---|
| **App Bar** | Background `primary` (navy) di layar utama, teks putih; atau `surface` dengan judul `on-surface` untuk layar sekunder (mengikuti konvensi M3 top-level vs detail screen). Elevasi 0–1dp saat idle, naik saat scroll (M3 scrolled-state behavior). |
| **Bottom Navigation** | 3 tab, ikon **solid** (bukan outline), indikator pill di belakang ikon aktif memakai `primary-container`, warna ikon aktif `primary`, tidak aktif `on-surface-variant`. Elevasi 2–3dp. |
| **Card Riwayat (Peminjaman/Konsultasi)** | `surface` putih, padding lega 16–20dp, radius 16dp, elevasi lembut 1–2dp (bukan border). Header card: ikon kategori + judul bold; body: 2–3 baris detail; footer: badge status di kanan bawah. |
| **Badge Status** | Pill (stadium), warna solid sesuai `status-success`/`status-warning`/`status-error`, teks putih atau kontras tinggi, 12sp medium. |
| **FAB (Aksi Utama)** | Warna `primary` (navy), ikon putih, shadow M3 standar (elevasi 3–6dp), posisi bottom-right pada layar list (Peminjaman, Konsultasi, Email). |
| **Form Input** | Filled style M3: latar `surface-variant`, radius 8dp (top corners jika underline, atau semua sudut jika boxed), label mengambang (floating label) saat fokus, warna border fokus `primary`. |
| **Snackbar/Toast** | Latar `on-surface` gelap dengan teks `surface` terang (kontras terbalik, standar M3), radius 8dp, muncul dari bawah. |
| **Empty State** | Ilustrasi flat sederhana 2 warna (navy + gold), judul title-style, deskripsi body-style, opsional tombol aksi (mis. "Ajukan Sekarang"). |

---

## 6. Ikonografi

- Set ikon **Material Symbols** (rounded/filled variant) — konsisten dengan filosofi M3, familiar bagi pengguna Android.
- Ikon aktif memakai `primary`, ikon non-aktif `on-surface-variant`.
- Ikon kategori layanan (Pinjam Aset, Konsultasi, dll.) memakai kombinasi navy sebagai warna dasar dan aksen gold pada state highlight/notifikasi.

---

## 7. Splash Screen

| Aspek | Light Mode | Dark Mode |
|---|---|---|
| **Background** | `background` off-white `#F8FAFC`, dengan panel `primary` navy `#1E3A8A` mengisi ±60% area atas layar (M3-style hero panel, sudut bawah membulat 24dp) | `background` navy gelap `#0F172A`, panel atas memakai `surface` `#1E293B` dengan aksen garis tipis `outline` `#475569` |
| **Logo/Wordmark** | "Gelatik" dalam Inter Bold, warna putih `#FFFFFF`, ditempatkan center pada panel navy, didampingi ikon Siger sederhana (garis emas) di atasnya | Wordmark `on-background` `#F1F5F9`, ikon Siger warna `accent-gold` dinaikkan `#FBBF24` |
| **Motif Siger (ikon Lampung)** | Ikon Siger flat/solid style (bukan line-art), warna Siger Gold `#F59E0B`, ukuran sedang, center-top di atas wordmark — komposisi simetris dan formal, selaras identitas kelembagaan | Warna `#FBBF24`, tetap simetris |
| **Panel Bawah** | Area `surface` putih `#FFFFFF` di ⅓ bawah layar berisi tagline "Layanan TIK Provinsi Lampung" (Inter Medium, `on-background` `#0F172A`) dan indikator loading | Area `surface` `#1E293B`, tagline `on-background` `#F1F5F9` |
| **Loading Indicator** | Circular progress indicator M3 standar, warna `primary` navy `#1E3A8A`, di tengah bawah panel putih | Warna `primary` dinaikkan `#93C5FD` |
| **Layout** | Simetris penuh (center-aligned) — selaras prinsip M3 "tenang dan formal", tanpa elemen dekoratif berlebih, hanya panel dua-warna + logo + ikon Siger + tagline | Sama, dengan warna versi dark |
| **Durasi/Transisi** | Splash tampil saat proses cek token (`GET /me`) berjalan di background; transisi ke Login/Home memakai M3 shared-axis fade-through transition | Sama |

---

## 8. Penerapan pada Fitur Baru

| Fitur | Penerapan Style |
|---|---|
| **F-WA (Notifikasi WhatsApp)** | Section di halaman Profil dengan card `surface` lega, M3 Switch component untuk opt-in (thumb `primary` saat aktif), input filled untuk nomor WhatsApp, ikon WhatsApp mengikuti warna brand asli hanya pada logo (bukan pada UI chrome) agar tidak menabrak identitas navy-gold. |
| **F-BOT (Chatbot Native)** | Chat bubble user: `primary-container` dengan teks `on-primary-container`, radius 16dp (sudut dekat pengirim 4dp — pola chat bubble M3 umum). Bubble bot: `surface` dengan elevasi 1dp. FAB entry point terpisah dari FAB Chatbot lama, memakai badge kecil gold bertuliskan "Baru". |

---

## 9. Prompt untuk Google Stitch — Modern Minimalist (Material Design 3, Semua Layar, Satu Kali Generate)

> Gunakan prompt berikut di Google Stitch (mode **Experimental/Thinking**, gunakan fitur **multi-screen generation** agar seluruh layar dibuat **dalam satu kali generate** dan otomatis konsisten satu sama lain — bukan di-generate satu-satu secara terpisah). Disusun dengan framework *zoom-out → zoom-in*: konteks produk & design system dulu, baru daftar lengkap layar yang harus dihasilkan sekaligus.

```
Design a complete, consistent multi-screen mobile app called "Gelatik" for Indonesian government employees (Diskominfotik Lampung Province) to manage IT services: borrowing IT equipment, IT consultations, internet service reports, and official email requests, plus a native chatbot and WhatsApp notifications. The design must feel trustworthy, formal-but-approachable, and highly accessible for users of all ages, following Google's Material Design 3 guidelines.

IMPORTANT: Generate ALL the screens listed below together in a single pass, as one unified screen set sharing the exact same design system (colors, typography, spacing, corner radius, elevation style, app bar style, bottom navigation). Do not restyle or drift between screens — every screen must look like it belongs to the same app.

Visual direction: Clean & Trustworthy, Material Design 3 style — soft rounded corners, gentle drop shadows for elevation (not hard borders), generous padding, high accessibility contrast. Overall feel should be premium, modern, mobile-first, similar to a well-designed banking or government services app.

Design system (apply identically to every screen):
- Light mode colors, "Siger & Pesisir" palette: primary Navy Blue #1E3A8A (app bar, primary buttons, FAB, active icons — conveys trust and security), accent Siger Gold #F59E0B (notification badges, pending status, warning elements), background Off-White #F8FAFC, surface Pure White #FFFFFF for cards. Status badges: green #16A34A (Selesai), gold #F59E0B (Diproses), red #DC2626 (Ditolak).
- Dark mode colors, following Material Design 3 dark theme principles (lighten primary/accent tones for contrast on dark surfaces, don't just invert colors): background deep navy #0F172A, surface #1E293B, primary lifted to light blue #93C5FD, accent gold lifted to #FBBF24, status colors lifted to #4ADE80 / #FBBF24 / #F87171.
- Typography: clean proportional sans-serif (Roboto or Inter), highly readable at all sizes, especially for long forms.
- Components: bottom navigation bar with solid (filled) icons and a pill-shaped active indicator behind the selected icon; white cards with soft shadow elevation (not borders) and generous 16-20px padding for history lists; pill-shaped colorful status badges; a circular floating action button in navy for primary actions; 16px card corner radius, 24px primary button radius.

Generate this full, consistent screen set in one pass:
1. Splash screen (light mode) — a navy #1E3A8A hero panel covering the top ~60% of the screen with rounded bottom corners, centered white "Gelatik" wordmark with a small gold Siger (Lampung traditional headdress) icon above it, a white bottom panel with the tagline "Layanan TIK Provinsi Lampung" and a centered navy circular Material Design 3 loading indicator. Fully symmetric, calm, formal composition.
2. Splash screen (dark mode) — same symmetric composition with dark mode colors (dark navy surface panel, lifted light-blue wordmark accent, lifted gold Siger icon, lifted loading indicator color).
3. Home dashboard (light mode) — navy app bar with app name in white, banner slider, a symmetric 2-column grid of 6 service menu icons (Pinjam Aset TIK, Konsultasi TIK, Layanan Internet, Request Email, Kritik & Saran, Info Alat TIK), a white elevated card showing the latest asset borrowing request with a status badge.
4. Home dashboard (dark mode) — same layout, dark mode colors.
5. Asset borrowing history list screen — list of soft-shadow white cards (spacious padding), each showing asset icon, name, date, and a pill-shaped status badge (green/gold/red), with a navy circular FAB "+" button bottom-right.
6. Profile screen with a WhatsApp notification section: a Material Design 3 style switch toggle, a filled-style text input for the WhatsApp number with floating label, using navy and gold accents consistently.
7. Native chatbot screen — chat bubbles: user messages in navy-tinted primary container color with dark navy text, rounded corners except near the sender's edge; bot messages in white surface with soft shadow elevation; navy app bar matching the global header style.

Keep the whole interface calm, spacious, and highly legible across every screen — this is a government service app, so prioritize clarity and trust over visual flair, while still feeling premium and current for 2026 mobile users, and perfectly consistent from the splash screen through every other screen.
```

---

## 10. Ringkasan

> Modern Minimalist "Siger & Pesisir" menghadirkan identitas navy-gold khas Lampung dalam kerangka Material Design 3 — sudut membulat lembut, elevasi bayangan halus, komponen familiar (bottom navigation solid, card putih lega, badge status tegas). Sistem warna, tipografi, dan komponen telah dilengkapi varian **light** dan **dark mode** sesuai kaidah M3 (lighten-on-dark, bukan invert), dipetakan langsung ke dua fitur baru (F-WA, F-BOT), serta dilengkapi prompt siap-pakai untuk Google Stitch.
