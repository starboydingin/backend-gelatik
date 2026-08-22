<script setup>
import GelatikLogo from './GelatikLogo.vue'
defineProps({ title: String, subtitle: String, wide: Boolean })
</script>

<template>
    <div class="min-h-screen bg-[var(--paper)] text-[var(--ink)]">
        <header class="flex min-h-20 items-center border-b-[4px] border-[var(--line)] bg-[var(--paper)] px-5 md:px-10">
            <RouterLink to="/"><GelatikLogo compact /></RouterLink>
            <nav class="ml-auto hidden items-center gap-5 text-sm font-black uppercase md:flex">
                <RouterLink to="/">Beranda</RouterLink
                ><RouterLink to="/#layanan">Layanan</RouterLink
                ><RouterLink to="/app/faq">FAQ</RouterLink>
            </nav>
        </header>
        <main class="grid min-h-[calc(100vh-8.5rem)] place-items-center px-5 py-10">
            <section
                class="relative w-full overflow-visible border-[4px] border-[var(--line)] bg-[var(--paper)] shadow-[8px_8px_0_var(--line)]"
                :class="wide ? 'max-w-3xl' : 'max-w-xl'"
            >
                <div class="h-3 bg-[var(--teal)]" />
                <div class="p-6 sm:p-10">
                    <div class="text-center">
                        <p class="eyebrow">Gerbang Layanan TIK</p>
                        <h1 v-if="title" class="mt-3 font-brand text-3xl font-black uppercase tracking-[-.06em]">
                            {{ title }}
                        </h1>
                        <p v-if="subtitle" class="mt-2 text-sm font-semibold leading-6 text-[var(--ink)]">
                            {{ subtitle }}
                        </p>
                    </div>
                    <div class="mt-8"><slot /></div>
                </div>
            </section>
        </main>
        <footer class="border-t-[3px] border-[var(--line)] py-5 text-center text-xs font-bold text-[var(--ink)]">
            © {{ new Date().getFullYear() }} Dinas Komunikasi, Informatika dan Statistik Provinsi
            Lampung
        </footer>
    </div>
</template>
