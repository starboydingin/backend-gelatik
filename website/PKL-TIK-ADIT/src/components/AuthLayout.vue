<script setup>
import GelatikLogo from './GelatikLogo.vue'
defineProps({ title: String, subtitle: String, wide: Boolean })
</script>

<template>
    <div class="min-h-screen bg-canvas">
        <header class="flex h-20 items-center bg-navy px-5 md:px-10">
            <RouterLink to="/"><GelatikLogo compact /></RouterLink>
            <nav class="ml-auto hidden items-center gap-8 text-sm font-semibold text-white md:flex">
                <RouterLink to="/">Beranda</RouterLink
                ><RouterLink to="/#layanan">Layanan</RouterLink
                ><RouterLink to="/app/faq">FAQ</RouterLink>
            </nav>
        </header>
        <main class="grid min-h-[calc(100vh-8.5rem)] place-items-center px-5 py-10">
            <section
                class="relative w-full overflow-hidden rounded-xl border border-stroke bg-white"
                :class="wide ? 'max-w-3xl' : 'max-w-xl'"
            >
                <div class="h-1 bg-brand-700" />
                <div class="p-6 sm:p-10">
                    <div class="text-center">
                        <p class="eyebrow">Gerbang Layanan TIK</p>
                        <h1 v-if="title" class="mt-3 font-brand text-3xl font-bold text-navy">
                            {{ title }}
                        </h1>
                        <p v-if="subtitle" class="mt-2 text-sm leading-6 text-slate-500">
                            {{ subtitle }}
                        </p>
                    </div>
                    <div class="mt-8"><slot /></div>
                </div>
            </section>
        </main>
        <footer class="pb-5 text-center text-xs text-slate-500">
            © {{ new Date().getFullYear() }} Dinas Komunikasi, Informatika dan Statistik Provinsi
            Lampung
        </footer>
    </div>
</template>
