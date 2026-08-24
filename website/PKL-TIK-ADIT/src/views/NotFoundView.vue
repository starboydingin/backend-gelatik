<script setup>
import GelatikLogo from '../components/GelatikLogo.vue'
import siger from '../assets/images/siger.png'
</script>

<template>
    <main class="grid min-h-screen place-items-center bg-[var(--color-bg-primary)] p-5">
        <section class="relative w-full max-w-2xl overflow-hidden rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)] p-8 text-center shadow-[var(--shadow-surface)] md:p-12">
            <img :src="siger" alt="" aria-hidden="true" class="absolute -right-12 -top-12 size-48 object-contain opacity-15" />
            <GelatikLogo class="justify-center" />
            <p class="eyebrow mt-10">Kesalahan 404</p>
            <h1 class="mt-3 text-3xl font-bold md:text-4xl">Halaman tidak ditemukan</h1>
            <p class="mx-auto mt-3 max-w-lg leading-7 text-[var(--color-text-secondary)]">
                Alamat yang Anda buka tidak tersedia atau telah dipindahkan.
            </p>
            <RouterLink to="/" class="btn-primary mt-7">Kembali ke beranda</RouterLink>
        </section>
    </main>
</template>
