<script setup>
import BrandMark from '../components/BrandMark.vue'
import siger from '../assets/images/siger.png'
const services = [
    [
        'Peminjaman aset TIK',
        'Ajukan perangkat, ruang rapat virtual, dan dukungan operasional acara.',
        '/assets/images/peminjaman-perangkat-transparent.png',
    ],
    [
        'Konsultasi TIK',
        'Sampaikan kebutuhan jaringan, aplikasi, hosting, domain, atau tanda tangan elektronik.',
        '/assets/images/helpdesk-support-transparent.png',
    ],
    [
        'Email resmi ASN',
        'Ajukan dan pantau pembuatan alamat email kedinasan secara transparan.',
        '/assets/images/email-dinas-transparent.png',
    ],
]
</script>
<template>
    <div class="min-h-screen overflow-hidden bg-canvas">
        <nav class="relative z-10 mx-auto flex max-w-7xl items-center justify-between px-5 py-5">
            <BrandMark />
            <div class="flex gap-2">
                <RouterLink to="/login" class="btn-secondary">Masuk</RouterLink
                ><RouterLink to="/register" class="btn-primary hidden sm:inline-flex"
                    >Buat akun</RouterLink
                >
            </div>
        </nav>
        <main>
            <section
                class="relative mx-auto grid max-w-7xl items-center gap-12 px-5 pb-20 pt-12 lg:grid-cols-2 lg:py-24"
            >
                <img
                    :src="siger"
                    alt=""
                    class="pointer-events-none absolute -left-12 top-5 -z-0 w-72 opacity-[.12]"
                />
                <div class="relative">
                    <span class="badge bg-brand-100 text-brand-700"
                        >Portal layanan digital terpadu</span
                    >
                    <h1
                        class="mt-6 font-brand text-5xl font-bold leading-[1.06] tracking-tight text-slate-950 md:text-6xl"
                    >
                        Layanan TIK Lampung, <span class="text-brand-600">lebih sederhana.</span>
                    </h1>
                    <p class="mt-6 max-w-xl text-lg leading-8 text-slate-600">
                        Ajukan kebutuhan, pantau progres, dan terhubung dengan tim Diskominfotik
                        dalam satu portal yang aman dan mudah digunakan.
                    </p>
                    <div class="mt-8 flex flex-wrap gap-3">
                        <RouterLink to="/login" class="btn-primary">Mulai menggunakan</RouterLink
                        ><a href="#layanan" class="btn-secondary">Lihat layanan</a>
                    </div>
                    <div
                        class="mt-10 flex flex-wrap gap-x-8 gap-y-3 text-sm font-semibold text-slate-600"
                    >
                        <span>✓ Status transparan</span><span>✓ Notifikasi terpadu</span
                        ><span>✓ Dukungan responsif</span>
                    </div>
                </div>
                <div class="relative mx-auto w-full max-w-xl">
                    <div class="absolute inset-10 rounded-full bg-brand-100 blur-3xl" />
                    <div
                        class="card relative overflow-hidden border-brand-700 bg-brand-700 p-8 text-white"
                    >
                        <img
                            src="/assets/images/helpdesk-support-transparent.png"
                            alt="Ilustrasi dukungan layanan TIK"
                            class="mx-auto h-72 object-contain drop-shadow-2xl"
                        />
                        <div class="grid grid-cols-3 gap-3">
                            <div
                                v-for="stat in [
                                    ['24/7', 'Akses portal'],
                                    ['1', 'Akun terpadu'],
                                    ['100%', 'Daring'],
                                ]"
                                :key="stat[1]"
                                class="rounded-xl border border-white/20 bg-white/10 p-3 text-center backdrop-blur"
                            >
                                <strong class="block text-lg">{{ stat[0] }}</strong
                                ><small class="text-brand-100">{{ stat[1] }}</small>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
            <section id="layanan" class="bg-white py-20">
                <div class="mx-auto max-w-7xl px-5">
                    <p class="text-sm font-bold uppercase tracking-widest text-brand-600">
                        Layanan utama
                    </p>
                    <h2 class="mt-2 font-brand text-3xl font-bold text-slate-950">
                        Semua kebutuhan TIK dalam satu pintu
                    </h2>
                    <div class="mt-10 grid gap-5 md:grid-cols-3">
                        <article v-for="service in services" :key="service[0]" class="card group">
                            <div class="mb-5 grid h-44 place-items-center rounded-2xl bg-brand-50">
                                <img
                                    :src="service[2]"
                                    :alt="service[0]"
                                    class="h-36 object-contain transition group-hover:-translate-y-1"
                                />
                            </div>
                            <h3 class="text-xl font-bold text-slate-950">{{ service[0] }}</h3>
                            <p class="mt-2 leading-7 text-slate-600">{{ service[1] }}</p>
                        </article>
                    </div>
                </div>
            </section>
        </main>
        <footer class="border-t border-stroke bg-white">
            <div
                class="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-5 py-8 text-sm text-slate-500"
            >
                <p>© {{ new Date().getFullYear() }} Diskominfotik Provinsi Lampung</p>
                <p>Gelatik — Gerbang Layanan TIK</p>
            </div>
        </footer>
    </div>
</template>
