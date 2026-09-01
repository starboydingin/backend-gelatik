<script setup>
import { InboxIcon } from '@heroicons/vue/24/outline'
defineProps({
    title: { type: String, default: 'Belum ada data' },
    text: { type: String, default: 'Data akan tampil di sini setelah tersedia.' },
})
</script>
<template>
    <div class="px-4 py-8 text-center sm:py-10">
        <div
            class="mx-auto mb-3 grid size-10 place-items-center rounded-lg bg-brand-50 text-brand-600"
        >
            <InboxIcon class="size-5" />
        </div>
        <h3 class="font-semibold text-navy">{{ title }}</h3>
        <p class="mx-auto mt-1 max-w-md text-sm leading-6 text-slate-500">{{ text }}</p>
        <div v-if="$slots.default" class="mt-4"><slot /></div>
    </div>
</template>
