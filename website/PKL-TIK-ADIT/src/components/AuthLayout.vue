<script setup>
import GelatikLogo from './GelatikLogo.vue'
defineProps({ title: String, subtitle: String, wide: Boolean })
const guideImage = '/assets/images/muli-meghanai-guides.png'
</script>

<template>
    <div class="flex min-h-screen flex-col bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]">
        <header class="flex min-h-14 items-center border-b border-[var(--color-border)] bg-[var(--color-surface)] px-4 sm:px-6 md:px-8">
            <RouterLink to="/"><GelatikLogo compact /></RouterLink>
            <nav class="ml-auto hidden items-center gap-4 text-sm font-semibold text-[var(--color-text-secondary)] md:flex">
                <RouterLink to="/">Beranda</RouterLink
                ><RouterLink to="/#layanan">Layanan</RouterLink
                ><RouterLink to="/app/faq">FAQ</RouterLink>
            </nav>
        </header>
        <main class="flex-1 px-4 py-6 sm:px-6 sm:py-8 lg:py-10">
            <section
                class="mx-auto grid w-full overflow-hidden rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] shadow-[var(--shadow-surface)] lg:grid-cols-[0.72fr_1.28fr]"
                :class="wide ? 'max-w-5xl' : 'max-w-[860px]'"
            >
                <aside class="relative hidden overflow-hidden bg-[#172e6e] p-5 text-white lg:flex lg:flex-col">
                    <p class="max-w-xs text-sm font-semibold leading-6 text-blue-50">
                        Gerbang layanan TIK Pemerintah Provinsi Lampung yang aman dan terpadu.
                    </p>
                    <div v-if="$slots.guide" class="mt-4 rounded-lg border border-white/15 bg-white/10 p-3.5">
                        <p class="text-xs font-bold uppercase tracking-[.12em] text-amber-300">Cara membuat akun</p>
                        <div class="mt-3 text-xs leading-5 text-blue-50"><slot name="guide" /></div>
                    </div>
                    <img
                        :src="guideImage"
                        alt="Muli dan Meghanai Lampung"
                        class="mx-auto mt-4 h-36 w-full max-w-[190px] object-contain"
                    />
                    <span class="absolute inset-x-0 bottom-0 h-1.5 bg-amber-400" aria-hidden="true" />
                </aside>
                <div class="p-5 sm:p-6">
                    <div class="text-left">
                        <p class="eyebrow">Gerbang Layanan TIK</p>
                        <h1 v-if="title" class="mt-2 font-brand text-2xl font-bold tracking-tight sm:text-[1.75rem]">
                            {{ title }}
                        </h1>
                        <p v-if="subtitle" class="mt-1.5 text-sm leading-5 text-[var(--color-text-secondary)]">
                            {{ subtitle }}
                        </p>
                    </div>
                    <details
                        v-if="$slots.guide"
                        class="mt-4 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-3 text-sm lg:hidden"
                    >
                        <summary class="cursor-pointer font-bold text-[var(--color-brand-primary)]">Cara membuat akun</summary>
                        <div class="mt-3 text-xs leading-5 text-[var(--color-text-secondary)]"><slot name="guide" /></div>
                    </details>
                    <div class="mt-5"><slot /></div>
                </div>
            </section>
        </main>
        <footer class="border-t border-[var(--color-border)] px-4 py-2.5 text-center text-xs text-[var(--color-text-muted)]">
            © {{ new Date().getFullYear() }} Dinas Komunikasi, Informatika dan Statistik Provinsi
            Lampung
        </footer>
    </div>
</template>
