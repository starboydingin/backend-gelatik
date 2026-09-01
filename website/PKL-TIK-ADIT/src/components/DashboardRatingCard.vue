<script setup>
import { computed } from 'vue'
import { StarIcon } from '@heroicons/vue/24/solid'

const props = defineProps({
    statistics: { type: Object, default: () => ({}) },
})

const scores = [5, 4, 3, 2, 1]
const average = computed(() => Math.min(5, Math.max(0, Number(props.statistics?.rata_rata) || 0)))
const total = computed(
    () =>
        Number(props.statistics?.total_user) ||
        scores.reduce((sum, score) => sum + Number(props.statistics?.distribusi?.[score] || 0), 0),
)
const formattedAverage = computed(() =>
    average.value.toLocaleString('id-ID', { minimumFractionDigits: 1, maximumFractionDigits: 1 }),
)
const fillForStar = (star) => Math.min(100, Math.max(0, (average.value - (star - 1)) * 100))
const countFor = (score) => Number(props.statistics?.distribusi?.[score] || 0)
const percentageFor = (score) => (total.value ? (countFor(score) / total.value) * 100 : 0)
</script>

<template>
    <div class="grid gap-4 p-4 sm:p-5">
        <div class="flex min-w-0 flex-wrap items-end justify-between gap-4">
            <div>
                <div class="flex items-end gap-1.5">
                    <strong class="text-5xl leading-none text-navy sm:text-6xl">{{ formattedAverage }}</strong>
                    <span class="pb-1 text-base font-bold text-slate-500">/5</span>
                </div>
                <div class="mt-3 flex gap-1" :aria-label="`Rating rata-rata ${formattedAverage} dari 5`">
                    <span v-for="star in 5" :key="star" class="relative block size-5 sm:size-6">
                        <StarIcon class="absolute inset-0 size-full text-slate-200" />
                        <span class="absolute inset-0 overflow-hidden" :style="{ width: `${fillForStar(star)}%` }">
                            <StarIcon class="size-5 max-w-none text-amber-400 sm:size-6" />
                        </span>
                    </span>
                </div>
            </div>
            <div class="rounded-xl bg-brand-50 px-3 py-2 text-right">
                <strong class="block text-xl text-brand-800">{{ total }}</strong>
                <span class="text-xs font-semibold text-brand-700">penilaian pengguna</span>
            </div>
        </div>

        <dl class="space-y-3">
            <div v-for="score in scores" :key="score" class="grid grid-cols-[58px_minmax(0,1fr)_32px] items-center gap-3 text-xs sm:text-sm">
                <dt class="whitespace-nowrap font-semibold text-slate-600">{{ score }} bintang</dt>
                <dd class="h-2.5 min-w-0 overflow-hidden rounded-full bg-slate-100">
                    <span
                        class="block h-full rounded-full bg-amber-400"
                        :style="{ width: `${percentageFor(score)}%` }"
                    />
                </dd>
                <dd class="text-right font-bold text-navy">{{ countFor(score) }}</dd>
            </div>
        </dl>
    </div>
</template>
