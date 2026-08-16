<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { api, payload, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
const filter = ref('bulanan'),
    date = ref(new Date().toISOString().slice(0, 7)),
    data = ref(null),
    error = ref(''),
    loading = ref(false)
let refreshTimer = null
let requestSequence = 0
const statusMeta = [
    { key: 'menunggu', label: 'Menunggu', tone: 'bg-gold' },
    { key: 'proses', label: 'Diproses', tone: 'bg-navy text-white' },
    { key: 'selesai', label: 'Selesai', tone: 'bg-emerald' },
    { key: 'ditolak', label: 'Ditolak', tone: 'bg-danger text-white' },
]
const report = computed(() => ({
    period: data.value?.periode || '',
    statuses: statusMeta.map((status) => ({
        ...status,
        total: Number(data.value?.total_per_status?.[status.key] || 0),
    })),
    assets: Array.isArray(data.value?.aset_terpopuler) ? data.value.aset_terpopuler : [],
    duration: Number(data.value?.rata_rata_durasi_hari || 0),
    breakdown: Array.isArray(data.value?.breakdown) ? data.value.breakdown : [],
}))
function displayDate(value) {
    if (!value) return '-'
    const parsed = new Date(`${String(value).slice(0, 10)}T00:00:00`)
    if (Number.isNaN(parsed.getTime())) return value
    return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(parsed)
}
async function load() {
    const requestId = ++requestSequence
    loading.value = true
    error.value = ''
    try {
        const response = payload(
            await api.get('/laporan/peminjaman', {
                params: { filter: filter.value, tanggal: date.value },
            })
        )
        if (requestId === requestSequence) data.value = response
    } catch (requestError) {
        if (requestId === requestSequence) error.value = errorMessage(requestError)
    } finally {
        if (requestId === requestSequence) loading.value = false
    }
}
function scheduleLoad() {
    window.clearTimeout(refreshTimer)
    refreshTimer = window.setTimeout(load, 180)
}
watch(filter, (nextFilter) => {
    const now = new Date()
    date.value = nextFilter === 'harian'
        ? now.toISOString().slice(0, 10)
        : nextFilter === 'bulanan'
          ? now.toISOString().slice(0, 7)
          : String(now.getFullYear())
})
watch(date, scheduleLoad)
onMounted(load)
onBeforeUnmount(() => window.clearTimeout(refreshTimer))
</script>
<template>
    <PageHeader
        title="Laporan peminjaman"
        description="Ringkasan peminjaman berdasarkan periode yang dipilih."
    />
    <section class="card flex flex-wrap items-end gap-3">
        <label
            ><span class="label">Jenis periode</span
            ><select v-model="filter" class="input">
                <option value="harian">Harian</option>
                <option value="bulanan">Bulanan</option>
                <option value="tahunan">Tahunan</option>
            </select></label
        ><label
            ><span class="label">Tanggal periode</span
            ><input
                v-model="date"
                :type="filter === 'harian' ? 'date' : filter === 'bulanan' ? 'month' : 'number'"
                class="input"
                :min="filter === 'tahunan' ? '2000' : undefined" /></label
        ><p v-if="loading" class="mb-2 text-sm text-slate-500" aria-live="polite">Memuat laporan…</p>
        <p v-else class="mb-2 text-sm text-slate-500">Laporan diperbarui otomatis.</p>
    </section>
    <AlertMessage :message="error" />
    <section v-if="data" class="report-panel card mt-6">
        <header class="flex flex-col gap-2 border-b-2 border-[var(--line)] pb-5 sm:flex-row sm:items-end sm:justify-between">
            <div>
                <p class="eyebrow">Hasil laporan</p>
                <h2 class="mt-2 text-xl font-bold text-[var(--ink)]">{{ report.period }}</h2>
            </div>
            <p class="text-sm text-slate-600">Ringkasan berdasarkan periode terpilih.</p>
        </header>

        <div class="mt-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <article v-for="status in report.statuses" :key="status.key" class="report-status-card" :class="status.tone">
                <p class="text-xs font-bold uppercase tracking-wide">{{ status.label }}</p>
                <strong class="mt-2 block text-3xl font-black">{{ status.total }}</strong>
            </article>
        </div>

        <div class="mt-6 grid gap-5 xl:grid-cols-[minmax(0,1.5fr)_minmax(16rem,.75fr)]">
            <section class="report-section">
                <div class="flex items-center justify-between gap-3">
                    <h3 class="font-bold text-[var(--ink)]">Aset terpopuler</h3>
                    <span class="text-xs text-slate-500">Berdasarkan jumlah unit dipinjam</span>
                </div>
                <ol v-if="report.assets.length" class="mt-3 divide-y-2 divide-[var(--line)] border-y-2 border-[var(--line)]">
                    <li v-for="(asset, index) in report.assets" :key="asset.nama" class="flex items-center gap-3 py-3">
                        <span class="grid size-8 shrink-0 place-items-center bg-gold text-sm font-black text-black">{{ index + 1 }}</span>
                        <span class="min-w-0 flex-1 truncate font-semibold text-[var(--ink)]">{{ asset.nama }}</span>
                        <strong class="shrink-0 text-[var(--navy)]">{{ asset.total_dipinjam }} unit</strong>
                    </li>
                </ol>
                <p v-else class="mt-3 border-2 border-dashed border-[var(--line)] p-4 text-sm text-slate-600">Belum ada data aset pada periode ini.</p>
            </section>

            <section class="report-duration bg-[var(--teal)] p-5 text-white">
                <p class="text-xs font-bold uppercase tracking-wide">Rata-rata durasi</p>
                <strong class="mt-3 block text-5xl font-black">{{ report.duration }}</strong>
                <span class="mt-1 block text-sm font-semibold">hari per peminjaman selesai</span>
            </section>
        </div>

        <section class="mt-6">
            <h3 class="font-bold text-[var(--ink)]">Rincian aktivitas</h3>
            <div class="table-wrap mt-3">
                <table class="data-table report-table">
                    <thead><tr><th>Waktu</th><th>Menunggu</th><th>Diproses</th><th>Selesai</th><th>Ditolak</th></tr></thead>
                    <tbody>
                        <tr v-for="entry in report.breakdown" :key="entry.waktu">
                            <td class="font-semibold">{{ displayDate(entry.waktu) }}</td>
                            <td>{{ entry.menunggu || 0 }}</td><td>{{ entry.proses || 0 }}</td><td>{{ entry.selesai || 0 }}</td><td>{{ entry.ditolak || 0 }}</td>
                        </tr>
                        <tr v-if="!report.breakdown.length"><td colspan="5" class="py-8 text-center text-slate-500">Belum ada aktivitas peminjaman pada periode ini.</td></tr>
                    </tbody>
                </table>
            </div>
        </section>
    </section>
</template>

<style scoped>
.report-panel { overflow: hidden; }
.report-status-card { border: 2px solid var(--line); padding: 1rem; color: #000; }
.report-section { min-width: 0; }
.report-duration { border: 2px solid var(--line); box-shadow: 3px 3px 0 var(--line); }
.report-table td { font-variant-numeric: tabular-nums; }
</style>
