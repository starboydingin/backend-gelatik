<script setup>
import BrandMark from '../components/BrandMark.vue'
import FaqSection from '../components/FaqSection.vue'
import {
    ArrowRightIcon,
    ChatBubbleLeftRightIcon,
    CheckIcon,
    EnvelopeIcon,
    BuildingOffice2Icon,
    MapPinIcon,
    SparklesIcon,
    StarIcon,
    WifiIcon,
    WrenchScrewdriverIcon,
} from '@heroicons/vue/24/outline'

const guideImage = '/assets/images/muli-meghanai-guides.png'
const governmentLogo = '/assets/images/LOGO%20DISKOMINFO.png'
const services = [
    {
        title: 'Peminjaman aset TIK',
        text: 'Ajukan perangkat, ruang rapat virtual, dan dukungan operasional acara.',
        icon: WrenchScrewdriverIcon,
        accent: 'bg-blue-50 text-blue-800',
        audience: 'Pegawai dan perangkat daerah Pemerintah Provinsi Lampung.',
        to: '/login',
    },
    {
        title: 'Konsultasi TIK',
        text: 'Sampaikan kebutuhan jaringan, aplikasi, hosting, domain, atau tanda tangan elektronik.',
        icon: ChatBubbleLeftRightIcon,
        accent: 'bg-teal-50 text-teal-800',
        audience: 'Pegawai atau OPD yang membutuhkan dukungan teknis TIK.',
        to: '/login',
    },
    {
        title: 'Email resmi ASN',
        text: 'Ajukan dan pantau pembuatan alamat email kedinasan secara transparan.',
        icon: EnvelopeIcon,
        accent: 'bg-amber-50 text-amber-800',
        audience: 'ASN Pemerintah Provinsi Lampung melalui proses verifikasi yang tersedia.',
        to: '/login',
    },
    {
        title: 'Internet & router OPD',
        text: 'Lihat informasi bandwidth, kondisi jaringan, router OPD, dan panduan penanganan awal.',
        icon: WifiIcon,
        accent: 'bg-cyan-50 text-cyan-800',
        audience: 'Pegawai dan pengelola layanan jaringan di setiap perangkat daerah.',
        to: '/login',
    },
    {
        title: 'Asisten Gelatik',
        text: 'Dapatkan jawaban cepat dari FAQ layanan dan bantuan membuat konsultasi saat kendala berlanjut.',
        icon: SparklesIcon,
        accent: 'bg-violet-50 text-violet-800',
        audience: 'Seluruh pengguna yang membutuhkan panduan layanan TIK secara cepat.',
        to: '/login',
    },
    {
        title: 'Kritik, saran & rating',
        text: 'Sampaikan pengalaman dan penilaian untuk membantu peningkatan kualitas layanan Gelatik.',
        icon: StarIcon,
        accent: 'bg-rose-50 text-rose-800',
        audience: 'Pengguna yang telah berinteraksi dengan layanan dan ingin memberi evaluasi.',
        to: '/login',
    },
]

function scrollToServices() {
    document.getElementById('layanan')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}
</script>
<template>
    <div class="landing-page no-scrollbar h-dvh overflow-y-auto bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]">
        <nav class="relative z-10 w-full border-b border-[var(--color-border)] bg-[var(--color-surface)]">
            <div class="mx-auto flex w-full max-w-[1440px] items-center justify-between px-4 py-3 sm:px-6 lg:px-8">
                <BrandMark />
                <div class="flex gap-2">
                    <RouterLink to="/login" class="btn-secondary">Masuk</RouterLink
                    ><RouterLink to="/register" class="btn-primary hidden sm:inline-flex"
                        >Buat akun</RouterLink
                    >
                </div>
            </div>
        </nav>
        <main>
            <section
                class="relative mx-auto grid max-w-7xl items-center gap-7 px-4 py-10 sm:px-6 lg:grid-cols-2 lg:py-14"
            >
                <div class="relative">
                    <span class="badge bg-amber-100 text-amber-900"
                        >Portal layanan digital terpadu</span
                    >
                    <h1
                        class="relative mt-4 max-w-3xl font-brand text-4xl font-bold leading-[1.02] tracking-tight sm:text-5xl lg:text-6xl"
                    >
                        Layanan TIK Lampung, <span class="text-[var(--color-accent)]">lebih mudah.</span>
                    </h1>
                    <p class="mt-5 max-w-xl border-l-4 border-[var(--color-brand-primary)] pl-4 text-base leading-7 text-[var(--color-text-secondary)]">
                        Ajukan kebutuhan, pantau progres, dan terhubung dengan tim Diskominfotik
                        dalam satu portal yang aman dan mudah digunakan.
                    </p>
                    <div class="mt-6 flex flex-wrap gap-2.5">
                        <RouterLink to="/login" class="btn-primary">Mulai menggunakan</RouterLink
                        ><a
                            href="#layanan"
                            class="services-cta btn-secondary"
                            @click.prevent="scrollToServices"
                            >Lihat layanan <ArrowRightIcon class="size-4" /></a
                        >
                    </div>
                    <div
                        class="mt-7 flex flex-wrap gap-x-6 gap-y-2 border-y border-[var(--color-border)] py-3 text-sm font-semibold text-[var(--color-text-secondary)]"
                    >
                        <span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Status transparan</span>
                        <span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Notifikasi terpadu</span>
                        <span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Dukungan responsif</span>
                    </div>
                </div>
                <div
                    class="relative z-10 w-full rounded-xl border border-[var(--color-border)] border-t-4 border-t-[var(--color-brand-primary)] bg-[var(--color-surface)] p-5 shadow-[var(--shadow-surface)] sm:p-6"
                >
                    <p class="eyebrow">Alur layanan</p>
                    <h2 class="mt-1.5 font-brand text-2xl font-bold leading-tight tracking-tight">
                        Satu akun untuk seluruh proses
                    </h2>
                    <div class="mt-5 grid items-end gap-5 sm:grid-cols-[minmax(0,1fr)_9.5rem]">
                        <ol class="divide-y divide-[var(--color-border)]">
                            <li
                                v-for="(step, index) in [
                                    [
                                        'Ajukan kebutuhan',
                                        'Pilih layanan dan lengkapi data yang diperlukan.',
                                    ],
                                    [
                                        'Pantau proses',
                                        'Status dan tanggapan petugas tersedia pada akun Anda.',
                                    ],
                                    [
                                        'Terima hasil',
                                        'Dapatkan pembaruan setelah layanan selesai diproses.',
                                    ],
                                ]"
                                :key="step[0]"
                                class="flex gap-3 py-3.5 first:pt-0 last:pb-0"
                            >
                                <span
                                    class="grid size-9 shrink-0 place-items-center rounded-lg bg-amber-100 text-sm font-bold text-amber-900"
                                    >{{ index + 1 }}</span
                                >
                                <div>
                                    <h3 class="font-bold">{{ step[0] }}</h3>
                                    <p
                                        class="mt-1 text-sm leading-6 text-[var(--color-text-secondary)]"
                                    >
                                        {{ step[1] }}
                                    </p>
                                </div>
                            </li>
                        </ol>
                        <figure
                            class="flex items-center gap-3 rounded-lg bg-blue-50 p-3 sm:block sm:text-center"
                        >
                            <img
                                :src="guideImage"
                                alt="Muli dan Meghanai sebagai pemandu layanan Gelatik"
                                class="h-28 w-24 shrink-0 object-contain sm:mx-auto sm:h-44 sm:w-full"
                            />
                            <figcaption
                                class="text-xs font-semibold leading-5 text-[var(--color-text-secondary)]"
                            >
                                Muli dan Meghanai siap memandu Anda menggunakan layanan Gelatik.
                            </figcaption>
                        </figure>
                    </div>
                </div>
            </section>
            <section class="marquee-shell" aria-label="Dinas penyelenggara">
                <div class="marquee-track">
                    <div v-for="index in 6" :key="index" class="marquee-item" :aria-hidden="index > 1">
                        <img :src="governmentLogo" alt="" class="marquee-logo" />
                        <span>Dinas Komunikasi, Informatika, dan Statistik Provinsi Lampung</span>
                    </div>
                </div>
            </section>
            <section class="border-y border-[var(--color-border)] bg-[var(--color-surface)] py-11 sm:py-14">
                <div class="mx-auto max-w-7xl px-4 sm:px-6">
                    <div class="grid gap-5 lg:grid-cols-[1.15fr_.85fr]">
                        <article class="section-panel p-5 sm:p-7">
                            <p class="eyebrow">Tentang penyelenggara</p>
                            <h2 class="mt-1.5 max-w-4xl font-brand text-2xl font-bold leading-tight sm:text-3xl">
                                Dinas Komunikasi, Informatika, dan Statistik Provinsi Lampung
                            </h2>
                            <div class="mt-4 max-w-4xl space-y-3 text-sm leading-7 text-[var(--color-text-secondary)]">
                                <p>
                                    Diskominfotik Provinsi Lampung menyelenggarakan layanan komunikasi,
                                    informatika, persandian, dan statistik sektoral untuk mendukung tata
                                    kelola pemerintahan yang terhubung, aman, dan responsif.
                                </p>
                                <p>
                                    Melalui Gelatik, kebutuhan layanan TIK pegawai dan perangkat daerah
                                    dihimpun dalam satu alur digital sehingga setiap pengajuan lebih mudah
                                    ditelusuri, prosesnya transparan, dan komunikasi dengan petugas tercatat
                                    dengan baik.
                                </p>
                            </div>
                        </article>
                        <dl class="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
                            <div class="card flex items-start gap-3">
                                <MapPinIcon class="mt-0.5 size-5 shrink-0 text-[var(--color-accent)]" />
                                <div>
                                    <dt class="text-xs font-bold uppercase tracking-wider text-[var(--color-text-muted)]">Wilayah layanan</dt>
                                    <dd class="mt-1 font-semibold">Pemerintah Provinsi Lampung</dd>
                                    <p class="mt-1 text-xs leading-5 text-[var(--color-text-secondary)]">Mendukung pegawai dan perangkat daerah dalam mengakses layanan TIK kedinasan.</p>
                                </div>
                            </div>
                            <div class="card flex items-start gap-3">
                                <BuildingOffice2Icon class="mt-0.5 size-5 shrink-0 text-[var(--color-accent)]" />
                                <div>
                                    <dt class="text-xs font-bold uppercase tracking-wider text-[var(--color-text-muted)]">Fungsi portal</dt>
                                    <dd class="mt-1 text-sm font-semibold leading-6">
                                        Satu akun untuk menemukan informasi, mengajukan kebutuhan, memantau progres, menerima tanggapan dan notifikasi, hingga memberikan evaluasi layanan TIK dengan lebih praktis.
                                    </dd>
                                </div>
                            </div>
                        </dl>
                    </div>
                </div>
            </section>
            <section id="layanan" class="scroll-mt-4 bg-[var(--color-bg-primary)] py-11 sm:py-14">
                <div class="mx-auto max-w-7xl px-4 sm:px-6">
                    <div class="flex flex-col justify-between gap-3 sm:flex-row sm:items-end">
                        <div>
                            <p class="eyebrow">Layanan utama</p>
                            <h2 class="mt-1.5 max-w-2xl font-brand text-2xl font-bold leading-tight tracking-tight sm:text-3xl">
                                Semua kebutuhan TIK dalam satu pintu
                            </h2>
                        </div>
                        <p class="max-w-md text-sm leading-6 text-[var(--color-text-secondary)]">
                            Pilih layanan sesuai kebutuhan Anda, kirim pengajuan, lalu ikuti setiap pembaruannya dari akun yang sama.
                        </p>
                    </div>
                    <div class="mt-7 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                        <article v-for="(service, index) in services" :key="service.title" class="service-card card group flex flex-col">
                            <div class="mb-4 grid size-11 place-items-center rounded-lg" :class="service.accent">
                                <component :is="service.icon" class="size-6 stroke-2" />
                            </div>
                            <p class="eyebrow">Fitur 0{{ index + 1 }}</p>
                            <h3 class="mt-1.5 font-brand text-xl font-bold leading-tight">{{ service.title }}</h3>
                            <p class="mt-2 text-sm leading-6 text-[var(--color-text-secondary)]">{{ service.text }}</p>
                            <p class="mt-3 border-t border-[var(--color-border)] pt-3 text-xs leading-5 text-[var(--color-text-muted)]"><strong>Untuk:</strong> {{ service.audience }}</p>
                            <RouterLink :to="service.to" class="mt-auto inline-flex items-center gap-2 pt-4 text-sm font-bold text-[var(--color-brand-primary)]">
                                Buka layanan <ArrowRightIcon class="size-4 stroke-[3]" />
                            </RouterLink>
                        </article>
                    </div>
                </div>
            </section>
            <FaqSection />
        </main>
        <footer class="border-t border-[var(--color-border)] bg-[var(--color-surface)]">
            <div
                class="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-3 px-4 py-5 text-sm font-semibold text-[var(--color-text-secondary)] sm:px-6"
            >
                <p>&copy; {{ new Date().getFullYear() }} Diskominfotik Provinsi Lampung</p>
                <p>Gelatik &mdash; Gerbang Layanan TIK</p>
            </div>
        </footer>
    </div>
</template>

<style scoped>
/* Landing owns its viewport: it stays full-page at every size while content
   remains scrollable for short screens without exposing a browser scrollbar. */
.landing-page {
    scrollbar-width: none;
    -ms-overflow-style: none;
    scroll-behavior: smooth;
}

.landing-page::-webkit-scrollbar {
    display: none;
}

.services-cta {
    gap: 0.5rem;
    transition:
        transform 180ms ease,
        border-color 180ms ease,
        background-color 180ms ease;
}

.services-cta:hover {
    transform: translateY(-2px);
}

.services-cta svg,
.service-card a svg {
    transition: transform 180ms ease;
}

.services-cta:hover svg,
.service-card:hover a svg {
    transform: translateX(4px);
}

.service-card {
    transition:
        transform 200ms ease,
        box-shadow 200ms ease,
        border-color 200ms ease;
}

.service-card:hover {
    transform: translateY(-4px);
    border-color: rgb(30 64 175 / 0.28);
    box-shadow: 0 18px 36px rgb(15 23 42 / 0.08);
}

.marquee-shell {
    overflow: hidden;
    border-block: 1px solid var(--color-border);
    background: linear-gradient(90deg, #eff6ff 0%, #ffffff 45%, #ecfeff 100%);
    padding-block: 0.7rem;
}

.marquee-track {
    display: flex;
    width: max-content;
    animation: institution-marquee 30s linear infinite;
    will-change: transform;
}

.marquee-item {
    display: flex;
    min-width: max-content;
    align-items: center;
    gap: 0.7rem;
    padding-inline: clamp(1.75rem, 4vw, 4rem);
    color: #172554;
    font-size: clamp(0.78rem, 1vw, 0.92rem);
    font-weight: 700;
    letter-spacing: 0.015em;
}

.marquee-logo {
    width: 2.15rem;
    height: 2.35rem;
    flex: none;
    object-fit: contain;
}

@keyframes institution-marquee {
    to {
        transform: translateX(-50%);
    }
}

@media (prefers-reduced-motion: reduce) {
    .marquee-track {
        animation-duration: 60s;
    }

    .services-cta,
    .services-cta svg,
    .service-card,
    .service-card a svg {
        transition-duration: 0.01ms;
    }
}
</style>
