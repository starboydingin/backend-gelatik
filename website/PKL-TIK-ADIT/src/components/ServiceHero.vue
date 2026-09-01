<script setup>
defineProps({
    eyebrow: String,
    title: String,
    description: String,
    stats: { type: Array, default: () => [] },
})
</script>

<template>
    <section class="service-hero">
        <div class="relative z-10 max-w-3xl">
            <p v-if="eyebrow" class="eyebrow">{{ eyebrow }}</p>
            <h2 class="mt-1.5 text-xl font-bold leading-tight text-navy sm:text-2xl">
                {{ title }}
            </h2>
            <p
                v-if="description"
                class="mt-2 max-w-2xl text-sm leading-5 text-slate-600"
            >
                {{ description }}
            </p>
            <div v-if="$slots.default" class="mt-4"><slot /></div>
        </div>
        <div v-if="stats.length" class="relative z-10 grid min-w-0 grid-cols-2 gap-3 md:min-w-64">
            <div
                v-for="stat in stats"
                :key="stat.label"
                class="rounded-lg border border-amber-200 bg-amber-50 p-3 text-slate-950"
            >
                <strong class="block text-xl font-bold text-slate-950">{{ stat.value }}</strong>
                <span class="mt-1 block text-xs font-semibold uppercase text-slate-700">{{
                    stat.label
                }}</span>
            </div>
        </div>
    </section>
</template>
