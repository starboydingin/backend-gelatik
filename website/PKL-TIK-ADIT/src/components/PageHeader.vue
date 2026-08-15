<script setup>
defineProps({
    title: String,
    description: String,
    eyebrow: { type: String, default: 'Portal Gelatik' },
})
</script>
<template>
    <div
        class="page-heading mb-6 flex flex-col gap-6 p-6 sm:p-8 lg:flex-row lg:items-center lg:justify-between"
    >
        <div class="min-w-0 max-w-4xl">
            <p class="eyebrow">{{ eyebrow }}</p>
            <h2 class="mt-3 font-brand text-3xl font-black leading-tight tracking-[-.05em] sm:text-4xl">{{ title }}</h2>
            <p v-if="description" class="mt-4 max-w-3xl text-base font-semibold leading-7 text-[var(--ink)]">
                {{ description }}
            </p>
        </div>
        <div v-if="$slots.default" class="shrink-0"><slot /></div>
    </div>
</template>

<style scoped>
/* Shared service hero: same frame, shadow, and action placement as Usulan Email. */
.page-heading {
    border: 4px solid var(--line) !important;
    border-radius: 6px !important;
    box-shadow: 5px 5px 0 var(--line) !important;
    background: var(--paper) !important;
}
</style>
