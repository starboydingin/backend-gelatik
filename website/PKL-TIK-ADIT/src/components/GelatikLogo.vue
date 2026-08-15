<script setup>
// This asset mirrors logo-nobackground&teksgelatik.png from gelatik-mobile.
import wordmark from '../assets/images/gelatik-wordmark.png'

defineProps({ compact: Boolean })
</script>

<template>
    <div class="inline-flex min-w-0 items-center gap-2 text-[var(--ink)]">
        <!-- Asset stays a hard-edged square, never a soft floating logo. -->
        <img :src="wordmark" alt="Logo Gelatik" class="h-10 w-10 shrink-0 border-2 border-[var(--line)] object-cover" />
        <span
            class="font-brand text-lg font-black uppercase leading-none tracking-[-.08em] sm:text-xl"
            >GELATIK</span
        >
    </div>
</template>
