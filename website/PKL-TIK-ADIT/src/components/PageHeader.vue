<script setup>
defineProps({
    title: String,
    description: String,
    eyebrow: { type: String, default: 'Portal Gelatik' },
})
</script>
<template>
    <header
        class="mb-5 flex flex-col gap-4 border-b border-stroke pb-5 sm:flex-row sm:items-end sm:justify-between"
    >
        <div class="min-w-0">
            <p class="eyebrow">{{ eyebrow }}</p>
            <h2 class="mt-1 text-2xl font-bold text-navy">{{ title }}</h2>
            <p v-if="description" class="mt-1 max-w-3xl text-sm leading-6 text-slate-500">
                {{ description }}
            </p>
        </div>
        <div class="shrink-0"><slot /></div>
    </header>
</template>
