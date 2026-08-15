<script setup>
defineProps({
    title: String,
    description: String,
    eyebrow: { type: String, default: 'Portal Gelatik' },
})
</script>
<template>
    <header
        class="mb-7 flex flex-col gap-4 border-b-[4px] border-[var(--line)] pb-5 sm:flex-row sm:items-end sm:justify-between"
    >
        <div class="min-w-0">
            <p class="eyebrow">{{ eyebrow }}</p>
            <h2 class="mt-1 font-brand text-3xl font-black uppercase tracking-[-.06em]">{{ title }}</h2>
            <p v-if="description" class="mt-1 max-w-3xl text-sm font-semibold leading-6 text-[var(--ink)]">
                {{ description }}
            </p>
        </div>
        <div class="shrink-0"><slot /></div>
    </header>
</template>
