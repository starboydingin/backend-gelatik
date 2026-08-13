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
            <p v-if="eyebrow" class="eyebrow text-teal-200">{{ eyebrow }}</p>
            <h2 class="mt-3 text-2xl font-bold leading-tight text-white md:text-3xl">
                {{ title }}
            </h2>
            <p
                v-if="description"
                class="mt-3 max-w-2xl text-sm leading-6 text-blue-100 md:text-base"
            >
                {{ description }}
            </p>
            <div v-if="$slots.default" class="mt-6"><slot /></div>
        </div>
        <div v-if="stats.length" class="relative z-10 grid min-w-0 grid-cols-2 gap-3 md:min-w-64">
            <div
                v-for="stat in stats"
                :key="stat.label"
                class="rounded-2xl border border-white/15 bg-white/10 p-4 backdrop-blur-sm"
            >
                <strong class="block text-2xl text-white">{{ stat.value }}</strong>
                <span class="mt-1 block text-xs font-semibold text-blue-100">{{ stat.label }}</span>
            </div>
        </div>
    </section>
</template>
