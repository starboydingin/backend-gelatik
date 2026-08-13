<script setup>
import { InboxIcon } from '@heroicons/vue/24/outline'
defineProps({
    title: { type: String, default: 'Belum ada data' },
    text: { type: String, default: 'Data akan tampil di sini setelah tersedia.' },
})
</script>
<template>
    <div class="px-5 py-14 text-center">
        <div
            class="mx-auto mb-3 grid size-12 place-items-center rounded-2xl bg-brand-50 text-brand-600"
        >
            <InboxIcon class="size-6" />
        </div>
        <h3 class="font-semibold text-navy">{{ title }}</h3>
        <p class="mx-auto mt-1 max-w-md text-sm leading-6 text-slate-500">{{ text }}</p>
        <div v-if="$slots.default" class="mt-5"><slot /></div>
    </div>
</template>
