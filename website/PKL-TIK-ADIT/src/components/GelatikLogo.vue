<script setup>
import logo from '../assets/images/gelatik-logo.png'
import wordmark from '../assets/images/gelatik-wordmark.png'

defineProps({ compact: Boolean, light: Boolean })
</script>

<template>
    <div class="inline-flex items-center gap-3" :class="light ? 'text-white' : 'text-brand-700'">
        <img v-if="compact" :src="wordmark" alt="Gelatik" class="h-9 w-auto object-contain" />
        <template v-else>
            <img :src="logo" alt="Logo Gelatik" class="h-12 w-12 shrink-0 object-contain" />
            <span class="font-brand text-lg font-semibold tracking-[.16em]">GELATIK</span>
        </template>
    </div>
</template>
