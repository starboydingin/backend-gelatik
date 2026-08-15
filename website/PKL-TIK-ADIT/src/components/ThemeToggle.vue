<script setup>
import { computed, onMounted, ref } from 'vue'
import { MoonIcon, SunIcon } from '@heroicons/vue/24/outline'

const theme = ref('light')
const isDark = computed(() => theme.value === 'dark')

function apply(nextTheme) {
    theme.value = nextTheme
    document.documentElement.dataset.theme = nextTheme
    localStorage.setItem('gelatik_theme', nextTheme)
}

function toggle() {
    apply(isDark.value ? 'light' : 'dark')
}

onMounted(() => {
    apply(localStorage.getItem('gelatik_theme') === 'dark' ? 'dark' : 'light')
})
</script>

<template>
    <!-- Root data-theme makes the palette snap; it never fades between modes. -->
    <button
        class="brutal-icon-button"
        type="button"
        :aria-label="isDark ? 'Gunakan tema terang' : 'Gunakan tema gelap'"
        :title="isDark ? 'Tema terang' : 'Tema gelap'"
        @click="toggle"
    >
        <SunIcon v-if="isDark" class="size-5" />
        <MoonIcon v-else class="size-5" />
    </button>
</template>
