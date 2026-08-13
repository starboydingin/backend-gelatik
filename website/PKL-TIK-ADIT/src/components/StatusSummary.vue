<script setup>
import { CheckCircleIcon, ClockIcon, XCircleIcon, ArrowPathIcon } from '@heroicons/vue/24/outline'
const icons = {
    waiting: ClockIcon,
    process: ArrowPathIcon,
    done: CheckCircleIcon,
    rejected: XCircleIcon,
}
const tones = {
    waiting: 'bg-amber-50 text-amber-600',
    process: 'bg-sky-50 text-sky-600',
    done: 'bg-emerald-50 text-emerald-600',
    rejected: 'bg-rose-50 text-rose-600',
}
defineProps({ items: { type: Array, default: () => [] } })
</script>

<template>
    <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <div v-for="item in items" :key="item.label" class="card flex items-center gap-4 p-4">
            <span
                class="grid size-11 shrink-0 place-items-center rounded-xl"
                :class="tones[item.tone]"
                ><component :is="icons[item.tone]" class="size-5"
            /></span>
            <div class="min-w-0">
                <strong class="text-2xl text-navy">{{ item.value }}</strong>
                <p class="text-xs font-bold uppercase tracking-[.14em] text-slate-500">
                    {{ item.label }}
                </p>
            </div>
        </div>
    </div>
</template>
