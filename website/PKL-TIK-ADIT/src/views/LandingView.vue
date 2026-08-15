<script setup>
import BrandMark from '../components/BrandMark.vue'
import ThemeToggle from '../components/ThemeToggle.vue'
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
        accent: 'bg-[var(--navy)] text-white',
    },
    {
        title: 'Konsultasi TIK',
        text: 'Sampaikan kebutuhan jaringan, aplikasi, hosting, domain, atau tanda tangan elektronik.',
        icon: ChatBubbleLeftRightIcon,
        accent: 'bg-[var(--teal)] text-black',
    },
    {
        title: 'Email resmi ASN',
        text: 'Ajukan dan pantau pembuatan alamat email kedinasan secara transparan.',
        icon: EnvelopeIcon,
        accent: 'bg-[var(--gold)] text-black',
    },
]
</script>
<template>
    <div class="min-h-screen overflow-hidden bg-[var(--paper)] text-[var(--ink)]">
        <nav class="relative z-10 mx-auto flex max-w-7xl items-center justify-between border-b-[2px] border-[var(--line)] px-5 py-4">
            <BrandMark />
            <div class="flex gap-2">
                <ThemeToggle /><RouterLink to="/login" class="btn-secondary">Masuk</RouterLink
                ><RouterLink to="/register" class="btn-primary hidden sm:inline-flex"
                    >Buat akun</RouterLink
                >
            </div>
        </nav>
        <main>
            <section
                class="relative mx-auto grid max-w-7xl items-center gap-10 px-5 pb-20 pt-10 lg:grid-cols-2 lg:py-24"
            >
                <img
                    :src="siger"
                    alt=""
                    class="brutal-siger pointer-events-none absolute right-0 top-8 z-0 hidden h-52 w-52 object-cover lg:block xl:-right-6 xl:h-64 xl:w-64"
                />
                <div class="relative">
                    <span class="badge bg-[var(--gold)] text-black"
                        >Portal layanan digital terpadu</span
                    >
                    <h1
                        class="relative mt-6 max-w-3xl font-brand text-5xl font-black uppercase leading-[.9] tracking-[-.1em] md:text-7xl"
                    >
                        Layanan TIK Lampung, <span class="bg-[var(--teal)] px-2 text-black">langsung.</span>
                    </h1>
                    <p class="mt-7 max-w-xl border-l-[8px] border-[var(--navy)] pl-4 text-lg font-semibold leading-8">
                        Ajukan kebutuhan, pantau progres, dan terhubung dengan tim Diskominfotik
                        dalam satu portal yang aman dan mudah digunakan.
                    </p>
                    <div class="mt-8 flex flex-wrap gap-3">
                        <RouterLink to="/login" class="btn-primary">Mulai menggunakan</RouterLink
                        ><a href="#layanan" class="btn-secondary">Lihat layanan</a>
                    </div>
                    <div
                        class="mt-10 flex flex-wrap gap-x-8 gap-y-3 border-y-[3px] border-[var(--line)] py-4 text-sm font-black uppercase"
                    >
                        <span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Status transparan</span>
                        ><span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Notifikasi terpadu</span>
                        ><span class="inline-flex items-center gap-2"><CheckIcon class="size-4 stroke-[3]" />Dukungan responsif</span>
                    </div>
                </div>
                <div
                    class="relative z-10 w-full border-[4px] border-[var(--line)] border-l-[14px] border-l-[var(--teal)] bg-[var(--paper)] p-7 shadow-[9px_9px_0_var(--line)] md:p-9"
                >
                    <p class="eyebrow">Alur layanan</p>
                    <h2 class="mt-2 font-brand text-3xl font-black uppercase leading-none tracking-[-.07em]">
                        Satu akun untuk seluruh proses
                    </h2>
                    <ol class="mt-7 divide-y-[3px] divide-[var(--line)]">
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
                                class="grid size-10 shrink-0 place-items-center border-2 border-[var(--line)] bg-[var(--gold)] text-sm font-black text-black"
                                >{{ index + 1 }}</span
                            >
                            <div>
                                <h3 class="font-black uppercase">{{ step[0] }}</h3>
                                <p class="mt-1 text-sm font-semibold leading-6">{{ step[1] }}</p>
                            </div>
                        </li>
                    </ol>
                </div>
            </section>
            <section id="layanan" class="border-y-[2px] border-[var(--line)] bg-[var(--paper)] py-20">
                <div class="mx-auto max-w-7xl px-5">
                    <p class="text-sm font-black uppercase tracking-widest text-[var(--teal)]">
                        Layanan utama
                    </p>
                    <h2 class="mt-2 max-w-2xl font-brand text-4xl font-black uppercase leading-[.9] tracking-[-.08em]">
                        Semua kebutuhan TIK dalam satu pintu
                    </h2>
                    <div class="mt-10 grid gap-6 md:grid-cols-3">
                        <article v-for="(service, index) in services" :key="service.title" class="card group">
                            <div class="mb-5 grid h-28 w-28 place-items-center border-[3px] border-[var(--line)]" :class="service.accent">
                                <component :is="service.icon" class="size-12 stroke-[2.5]" />
                            </div>
                            <p class="eyebrow">Layanan 0{{ index + 1 }}</p>
                            <h3 class="mt-2 font-brand text-2xl font-black uppercase leading-none tracking-[-.06em]">{{ service.title }}</h3>
                            <p class="mt-3 font-semibold leading-7">{{ service.text }}</p>
                            <RouterLink to="/login" class="mt-6 inline-flex items-center gap-2 pb-1 text-sm font-black uppercase text-[var(--navy)] hover:translate-x-1">
                                Buka layanan <ArrowRightIcon class="size-4 stroke-[3]" />
                            </RouterLink>
                        </article>
                    </div>
                </div>
            </section>
        </main>
        <footer class="border-t-[2px] border-[var(--line)] bg-[var(--paper)]">
            <div
                class="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-5 py-8 text-sm font-black uppercase"
            >
                <p>&copy; {{ new Date().getFullYear() }} Diskominfotik Provinsi Lampung</p>
                <p>Gelatik &mdash; Gerbang Layanan TIK</p>
            </div>
        </footer>
    </div>
</template>
