<script setup>
import GelatikLogo from './GelatikLogo.vue'
defineProps({ title: String, subtitle: String, wide: Boolean })
</script>

<template>
    <div
        class="min-h-screen bg-[radial-gradient(circle_at_left,_rgba(20,184,166,.14),_transparent_30%),radial-gradient(circle_at_right,_rgba(14,165,233,.12),_transparent_28%)] bg-canvas"
    >
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
                class="relative w-full overflow-hidden rounded-2xl border border-stroke bg-white shadow-xl shadow-blue-950/10"
                :class="wide ? 'max-w-3xl' : 'max-w-xl'"
            >
                <div class="h-2 bg-gradient-to-r from-action via-cyan-500 to-blue-600" />
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
