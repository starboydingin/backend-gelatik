<script setup>
defineProps({
    title: String,
    description: String,
    eyebrow: { type: String, default: 'Portal Gelatik' },
})
</script>
<template>
    <div
        class="page-heading mb-6 flex flex-col gap-4 pb-4 pl-4 sm:flex-row sm:items-end sm:justify-between"
    >
        <div class="min-w-0">
            <p class="eyebrow">{{ eyebrow }}</p>
            <h2 class="mt-1 font-brand text-2xl font-black uppercase leading-none tracking-[-.06em] sm:text-3xl">{{ title }}</h2>
            <p v-if="description" class="mt-1 max-w-3xl text-sm font-semibold leading-6 text-[var(--ink)]">
                {{ description }}
            </p>
        </div>
        <div class="shrink-0"><slot /></div>
    </div>
</template>

<style scoped>
/* A compact title divider: never a large framed panel. */
.page-heading {
    border: 0 !important;
    border-bottom: 2px solid var(--line) !important;
    border-left: 6px solid var(--teal) !important;
    border-radius: 0 !important;
    box-shadow: none !important;
    background: transparent !important;
}
</style>
