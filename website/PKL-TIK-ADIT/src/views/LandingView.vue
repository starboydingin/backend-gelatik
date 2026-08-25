<script setup>
import BrandMark from '../components/BrandMark.vue'
import siger from '../assets/images/siger.png'
import {
    ArrowRightIcon,
    ChatBubbleLeftRightIcon,
    CheckIcon,
    EnvelopeIcon,
    WrenchScrewdriverIcon,
} from '@heroicons/vue/24/outline'
const services = [
    {
        title: 'Peminjaman aset TIK',
        text: 'Ajukan perangkat, ruang rapat virtual, dan dukungan operasional acara.',
        icon: WrenchScrewdriverIcon,
        accent: 'bg-blue-50 text-blue-800',
    },
    {
        title: 'Konsultasi TIK',
        text: 'Sampaikan kebutuhan jaringan, aplikasi, hosting, domain, atau tanda tangan elektronik.',
        icon: ChatBubbleLeftRightIcon,
        accent: 'bg-teal-50 text-teal-800',
    },
    {
        title: 'Email resmi ASN',
        text: 'Ajukan dan pantau pembuatan alamat email kedinasan secara transparan.',
        icon: EnvelopeIcon,
        accent: 'bg-amber-50 text-amber-800',
    },
]
</script>
<template>
    <div class="landing-page no-scrollbar h-dvh overflow-y-auto bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]">
        <nav class="relative z-10 w-full border-b border-[var(--color-border)] bg-[var(--color-surface)]">
            <div class="mx-auto flex w-full max-w-[1600px] items-center justify-between px-5 py-4 sm:px-7 lg:px-10">
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
                class="relative mx-auto grid max-w-7xl items-center gap-10 px-5 pb-20 pt-10 lg:grid-cols-2 lg:py-24"
            >
                <!-- The source PNG has transparent padding; enlarge its canvas and offset it above the card. -->
                <img
                    :src="siger"
                    alt=""
                    class="pointer-events-none absolute right-5 top-2 z-0 hidden h-52 w-52 object-contain opacity-90 lg:block lg:-translate-y-3"
                />
                <div class="relative">
                    <span class="badge bg-amber-100 text-amber-900"
                        >Portal layanan digital terpadu</span
                    >
                    <h1
                        class="relative mt-6 max-w-3xl font-brand text-5xl font-bold leading-[.98] tracking-tight md:text-7xl"
                    >
                        Layanan TIK Lampung, <span class="text-[var(--color-accent)]">lebih mudah.</span>
                    </h1>
                    <p class="mt-7 max-w-xl border-l-4 border-[var(--color-brand-primary)] pl-4 text-lg leading-8 text-[var(--color-text-secondary)]">
                        Ajukan kebutuhan, pantau progres, dan terhubung dengan tim Diskominfotik
                        dalam satu portal yang aman dan mudah digunakan.
                    </p>
                    <div class="mt-8 flex flex-wrap gap-3">
                        <RouterLink to="/login" class="btn-primary">Mulai menggunakan</RouterLink
                        ><a href="#layanan" class="btn-secondary">Lihat layanan</a>
                    </div>
                    <div
                        class="mt-10 flex flex-wrap gap-x-8 gap-y-3 border-y border-[var(--color-border)] py-4 text-sm font-semibold text-[var(--color-text-secondary)]"
                    >
                        <span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Status transparan</span>
                        <span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Notifikasi terpadu</span>
                        <span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Dukungan responsif</span>
                    </div>
                </div>
                <div
                    class="relative z-10 w-full rounded-2xl border border-[var(--color-border)] border-t-4 border-t-[var(--color-brand-primary)] bg-[var(--color-surface)] p-7 shadow-[var(--shadow-surface)] md:p-9 lg:translate-y-3"
                >
                    <p class="eyebrow">Alur layanan</p>
                    <h2 class="mt-2 font-brand text-3xl font-bold leading-tight tracking-tight">
                        Satu akun untuk seluruh proses
                    </h2>
                    <ol class="mt-7 divide-y divide-[var(--color-border)]">
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
                            class="flex gap-4 py-5 first:pt-0 last:pb-0"
                        >
                            <span
                                class="grid size-10 shrink-0 place-items-center rounded-lg bg-amber-100 text-sm font-bold text-amber-900"
                                >{{ index + 1 }}</span
                            >
                            <div>
                                <h3 class="font-bold">{{ step[0] }}</h3>
                                <p class="mt-1 text-sm leading-6 text-[var(--color-text-secondary)]">{{ step[1] }}</p>
                            </div>
                        </li>
                    </ol>
                </div>
            </section>
            <section id="layanan" class="border-y border-[var(--color-border)] bg-[var(--color-surface)] py-20">
                <div class="mx-auto max-w-7xl px-5">
                    <p class="eyebrow">
                        Layanan utama
                    </p>
                    <h2 class="mt-2 max-w-2xl font-brand text-4xl font-bold leading-tight tracking-tight">
                        Semua kebutuhan TIK dalam satu pintu
                    </h2>
                    <div class="mt-10 grid gap-6 md:grid-cols-3">
                        <article v-for="(service, index) in services" :key="service.title" class="card group">
                            <div class="mb-5 grid size-16 place-items-center rounded-xl" :class="service.accent">
                                <component :is="service.icon" class="size-12 stroke-[2.5]" />
                            </div>
                            <p class="eyebrow">Layanan 0{{ index + 1 }}</p>
                            <h3 class="mt-2 font-brand text-2xl font-bold leading-tight">{{ service.title }}</h3>
                            <p class="mt-3 leading-7 text-[var(--color-text-secondary)]">{{ service.text }}</p>
                            <RouterLink to="/login" class="mt-6 inline-flex items-center gap-2 pb-1 text-sm font-bold text-[var(--color-brand-primary)] hover:translate-x-1">
                                Buka layanan <ArrowRightIcon class="size-4 stroke-[3]" />
                            </RouterLink>
                        </article>
                    </div>
                </div>
            </section>
        </main>
        <footer class="border-t border-[var(--color-border)] bg-[var(--color-surface)]">
            <div
                class="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-5 py-8 text-sm font-semibold text-[var(--color-text-secondary)]"
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
}

.landing-page::-webkit-scrollbar {
    display: none;
}
</style>
