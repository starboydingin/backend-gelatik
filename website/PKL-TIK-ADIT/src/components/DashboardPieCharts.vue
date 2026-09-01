<script setup>
import { computed } from 'vue'

const props = defineProps({
    topics: { type: Array, default: () => [] },
    assets: { type: Array, default: () => [] },
})

const colors = ['#1e3a8a', '#0f766e', '#f59e0b', '#2563eb', '#10b981', '#7c3aed']

function compact(items, labelKey, valueKey) {
    const normalized = items
        .map((item) => ({ label: item[labelKey] || 'Tanpa nama', value: Number(item[valueKey]) || 0 }))
        .filter((item) => item.value > 0)
        .sort((left, right) => right.value - left.value)
    const visible = normalized.slice(0, 5)
    const remainder = normalized.slice(5).reduce((total, item) => total + item.value, 0)
    if (remainder > 0) visible.push({ label: 'Lainnya', value: remainder })
    const total = visible.reduce((sum, item) => sum + item.value, 0)
    let cursor = 0
    const segments = visible.map((item, index) => {
        const start = (cursor / total) * 100
        cursor += item.value
        const end = (cursor / total) * 100
        return `${colors[index % colors.length]} ${start}% ${end}%`
    })
    return {
        total,
        items: visible.map((item, index) => ({ ...item, color: colors[index % colors.length] })),
        background: total ? `conic-gradient(${segments.join(', ')})` : '#e2e8f0',
    }
}

const charts = computed(() => [
    {
        title: 'Topik konsultasi',
        suffix: 'permintaan',
        ...compact(props.topics, 'label', 'total'),
    },
    {
        title: 'Aset dipinjam',
        suffix: 'unit',
        ...compact(props.assets, 'nama_item', 'total_peminjaman'),
    },
])
</script>

<template>
    <div class="grid gap-4 sm:grid-cols-2">
        <section v-for="chart in charts" :key="chart.title" class="min-w-0">
            <h3 class="text-sm font-bold text-navy">{{ chart.title }}</h3>
            <div class="mt-3 flex flex-col items-center gap-3">
                <div
                    class="aspect-square w-full max-w-[180px] shrink-0 rounded-full border-4 border-white shadow-sm"
                    :style="{ background: chart.background }"
                    role="img"
                    :aria-label="`${chart.title}, total ${chart.total} ${chart.suffix}`"
                />
                <div class="w-full min-w-0 space-y-2.5">
                    <div
                        v-for="item in chart.items"
                        :key="item.label"
                        class="grid grid-cols-[auto_minmax(0,1fr)_auto] items-start gap-2 text-xs"
                    >
                        <span class="mt-1 size-2.5 rounded-full" :style="{ backgroundColor: item.color }" />
                        <span class="break-words leading-5 text-slate-600">{{ item.label }}</span>
                        <strong class="whitespace-nowrap text-navy">{{ item.value }}</strong>
                    </div>
                    <p v-if="!chart.items.length" class="text-xs text-slate-500">
                        Belum ada data.
                    </p>
                </div>
            </div>
        </section>
    </div>
</template>
