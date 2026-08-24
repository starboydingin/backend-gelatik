<script setup>
import GelatikLogo from './GelatikLogo.vue'
import siger from '../assets/images/siger.png'
defineProps({ title: String, subtitle: String, wide: Boolean })
</script>

<template>
    <div class="min-h-screen bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]">
        <header class="flex min-h-20 items-center border-b border-[var(--color-border)] bg-[var(--color-surface)] px-5 md:px-10">
            <RouterLink to="/"><GelatikLogo compact /></RouterLink>
            <nav class="ml-auto hidden items-center gap-5 text-sm font-semibold text-[var(--color-text-secondary)] md:flex">
                <RouterLink to="/">Beranda</RouterLink
                ><RouterLink to="/#layanan">Layanan</RouterLink
                ><RouterLink to="/app/faq">FAQ</RouterLink>
            </nav>
        </header>
        <main class="grid min-h-[calc(100vh-8.5rem)] place-items-center px-4 py-8 sm:px-6 md:py-12">
            <section
                class="grid w-full overflow-hidden rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)] shadow-[var(--shadow-surface)] lg:grid-cols-[0.8fr_1.2fr]"
                :class="wide ? 'max-w-5xl' : 'max-w-4xl'"
            >
                <aside class="relative hidden overflow-hidden bg-[#172e6e] p-9 text-white lg:flex lg:flex-col lg:justify-between">
                    <div>
                        <GelatikLogo inverse />
                        <p class="mt-8 max-w-xs text-sm leading-6 text-blue-100">
                            Gerbang layanan TIK Pemerintah Provinsi Lampung yang aman dan terpadu.
                        </p>
                    </div>
                    <img :src="siger" alt="" aria-hidden="true" class="mx-auto mt-10 h-44 w-44 object-contain" />
                    <span class="absolute inset-x-0 bottom-0 h-2 bg-amber-400" aria-hidden="true" />
                </aside>
                <div class="p-6 sm:p-9 md:p-10">
                    <div class="text-left">
                        <p class="eyebrow">Gerbang Layanan TIK</p>
                        <h1 v-if="title" class="mt-3 font-brand text-3xl font-bold tracking-tight">
                            {{ title }}
                        </h1>
                        <p v-if="subtitle" class="mt-2 text-sm leading-6 text-[var(--color-text-secondary)]">
                            {{ subtitle }}
                        </p>
                    </div>
                    <div class="mt-8"><slot /></div>
                </div>
            </section>
        </main>
        <footer class="border-t border-[var(--color-border)] py-5 text-center text-xs text-[var(--color-text-muted)]">
            © {{ new Date().getFullYear() }} Dinas Komunikasi, Informatika dan Statistik Provinsi
            Lampung
        </footer>
    </div>
</template>
