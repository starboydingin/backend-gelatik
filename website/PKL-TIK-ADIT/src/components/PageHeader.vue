<script setup>
defineProps({
    title: String,
    description: String,
    eyebrow: { type: String, default: 'Portal Gelatik' },
})
</script>
<template>
    <div
        class="page-heading mb-6 flex flex-col gap-5 p-6 md:flex-row md:items-center md:justify-between md:p-7"
    >
        <div class="min-w-0 max-w-4xl">
            <p class="eyebrow">{{ eyebrow }}</p>
            <h2 class="mt-2 text-2xl font-bold leading-tight text-[var(--ink)] md:text-3xl">{{ title }}</h2>
            <p v-if="description" class="mt-3 max-w-3xl text-sm leading-6 text-[var(--ink)] md:text-base">
                {{ description }}
            </p>
        </div>
        <div v-if="$slots.default" class="shrink-0"><slot /></div>
    </div>
</template>

<style scoped>
/* Matches the calmer Dashboard service hero, without the heavier hard-brutalist frame. */
.page-heading {
    border: 2px solid var(--line) !important;
    border-left: 6px solid var(--line) !important;
    border-radius: 6px !important;
    box-shadow: 3px 3px 0 var(--line) !important;
    background: var(--paper) !important;
}
</style>
