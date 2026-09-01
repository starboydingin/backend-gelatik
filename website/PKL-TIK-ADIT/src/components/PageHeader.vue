<script setup>
defineProps({
    title: String,
    description: String,
    eyebrow: { type: String, default: 'Portal Gelatik' },
})
</script>
<template>
    <div
        class="page-heading mb-4 flex flex-col gap-3 p-4 sm:p-5 md:flex-row md:items-center md:justify-between"
    >
        <div class="min-w-0 max-w-4xl">
            <p class="eyebrow">{{ eyebrow }}</p>
            <h2 class="mt-1.5 text-xl font-bold leading-tight text-[var(--color-text-primary)] sm:text-2xl">{{ title }}</h2>
            <p v-if="description" class="mt-2 max-w-3xl text-sm leading-5 text-[var(--color-text-secondary)]">
                {{ description }}
            </p>
        </div>
        <div v-if="$slots.default" class="shrink-0"><slot /></div>
    </div>
</template>

<style scoped>
.page-heading {
    border-top: 4px solid var(--color-brand-primary) !important;
}
</style>
