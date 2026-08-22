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
const x = (index) => {
    if (chartItems.value.length <= 1) return plot.left
    return plot.left + (index / (chartItems.value.length - 1)) * (plot.right - plot.left)
}
const y = (value) => plot.bottom - (Number(value || 0) / maxValue.value) * (plot.bottom - plot.top)
const points = (key) =>
    chartItems.value.map((item, index) => `${x(index)},${y(item[key])}`).join(' ')
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
                <span class="size-2.5 rounded-full" :style="{ backgroundColor: entry.color }" />
                {{ entry.label }}
            </span>
        </div>
        <div class="w-full overflow-hidden" aria-label="Line chart aktivitas layanan 30 hari">
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
                    <text
                        :x="x(label.index)"
                        y="244"
                        text-anchor="middle"
                        class="chart-label"
                    >
                        {{ label.item.tanggal?.slice(5) }}
                    </text>
                </g>
                <polyline
                    v-for="entry in series"
                    :key="entry.key"
                    :points="points(entry.key)"
                    fill="none"
                    :stroke="entry.color"
                    stroke-width="3"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    vector-effect="non-scaling-stroke"
                />
                <template v-for="entry in series" :key="`points-${entry.key}`">
                    <circle
                        v-for="(item, index) in chartItems"
                        :key="`${entry.key}-${item.tanggal}`"
                        :cx="x(index)"
                        :cy="y(item[entry.key])"
                        r="3.25"
                        :fill="entry.color"
                        stroke="white"
                        stroke-width="1.5"
                        vector-effect="non-scaling-stroke"
                    >
                        <title>{{ entry.label }} {{ item.tanggal }}: {{ item[entry.key] || 0 }}</title>
                    </circle>
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
