<script setup>
import { computed } from 'vue'

const props = defineProps({
    items: { type: Array, default: () => [] },
})

const series = [
    { key: 'peminjaman', label: 'Peminjaman', color: '#1e3a8a' },
    { key: 'konsultasi', label: 'Konsultasi', color: '#0f766e' },
    { key: 'usulan_email', label: 'Usulan email', color: '#f59e0b' },
]
const chartItems = computed(() => props.items.slice(-30))
const maxValue = computed(() =>
    Math.max(
        1,
        ...chartItems.value.flatMap((item) =>
            series.map((entry) => Number(item[entry.key]) || 0),
        ),
    ),
)
const plot = { left: 48, right: 704, top: 24, bottom: 218 }
const groupWidth = computed(() =>
    chartItems.value.length ? (plot.right - plot.left) / chartItems.value.length : 0,
)
const barWidth = computed(() => Math.max(2, Math.min(7, (groupWidth.value - 4) / series.length)))
const groupX = (index) => plot.left + index * groupWidth.value + groupWidth.value / 2
const barX = (itemIndex, seriesIndex) =>
    groupX(itemIndex) + (seriesIndex - (series.length - 1) / 2) * (barWidth.value + 1) - barWidth.value / 2
const y = (value) => plot.bottom - (Number(value || 0) / maxValue.value) * (plot.bottom - plot.top)
const barHeight = (value) => Math.max(0, plot.bottom - y(value))
const yTicks = computed(() =>
    [...new Set([0, 0.25, 0.5, 0.75, 1].map((ratio) => Math.round(maxValue.value * ratio)))].map(
        (value) => ({ value, y: y(value) }),
    ),
)
const xLabels = computed(() => {
    const step = Math.max(1, Math.ceil(chartItems.value.length / 6))
    return chartItems.value
        .map((item, index) => ({ item, index }))
        .filter(({ index }) => index % step === 0 || index === chartItems.value.length - 1)
})
</script>

<template>
    <div>
        <div class="mb-4 flex flex-wrap gap-x-5 gap-y-2 text-xs font-semibold">
            <span v-for="entry in series" :key="entry.key" class="inline-flex items-center gap-2">
                <span class="size-2.5 rounded-sm" :style="{ backgroundColor: entry.color }" />
                {{ entry.label }}
            </span>
        </div>
        <div class="w-full overflow-hidden" aria-label="Bar chart aktivitas layanan 30 hari">
            <svg
                viewBox="0 0 728 258"
                class="block h-auto min-h-[220px] w-full"
                role="img"
                preserveAspectRatio="xMidYMid meet"
            >
                <title>Aktivitas peminjaman, konsultasi, dan usulan email selama 30 hari</title>
                <g v-for="tick in yTicks" :key="tick.y">
                    <line
                        :x1="plot.left"
                        :x2="plot.right"
                        :y1="tick.y"
                        :y2="tick.y"
                        stroke="#dbe3ef"
                        stroke-width="1"
                    />
                    <text x="38" :y="tick.y + 4" text-anchor="end" class="chart-label">
                        {{ tick.value }}
                    </text>
                </g>
                <g v-for="label in xLabels" :key="label.index">
                    <text :x="groupX(label.index)" y="244" text-anchor="middle" class="chart-label">
                        {{ label.item.tanggal?.slice(5) }}
                    </text>
                </g>
                <template v-for="(entry, seriesIndex) in series" :key="entry.key">
                    <rect
                        v-for="(item, itemIndex) in chartItems"
                        :key="`${entry.key}-${item.tanggal}`"
                        :x="barX(itemIndex, seriesIndex)"
                        :y="y(item[entry.key])"
                        :width="barWidth"
                        :height="barHeight(item[entry.key])"
                        :fill="entry.color"
                        rx="1.5"
                    >
                        <title>{{ entry.label }} {{ item.tanggal }}: {{ item[entry.key] || 0 }}</title>
                    </rect>
                </template>
            </svg>
        </div>
    </div>
</template>

<style scoped>
.chart-label {
    fill: #64748b;
    font-family: Inter, Urbanist, ui-sans-serif, system-ui, sans-serif;
    font-size: 10px;
}
</style>
