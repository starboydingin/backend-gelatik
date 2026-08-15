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
            <h2 class="mt-2 text-2xl font-bold leading-tight text-navy md:text-3xl">
                {{ title }}
            </h2>
            <p
                v-if="description"
                class="mt-3 max-w-2xl text-sm leading-6 text-slate-600 md:text-base"
            >
                {{ description }}
            </p>
            <div v-if="$slots.default" class="mt-6"><slot /></div>
        </div>
        <div v-if="stats.length" class="relative z-10 grid min-w-0 grid-cols-2 gap-3 md:min-w-64">
            <div
                v-for="stat in stats"
                :key="stat.label"
                class="border-[3px] border-[var(--line)] bg-[var(--gold)] p-4 text-black"
            >
                <strong class="block text-2xl font-black text-black">{{ stat.value }}</strong>
                <span class="mt-1 block text-xs font-black uppercase text-black">{{
                    stat.label
                }}</span>
            </div>
        </div>
    </section>
</template>
