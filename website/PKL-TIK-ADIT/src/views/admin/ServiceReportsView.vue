<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { api, errorMessage, payload, rows } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
import PageHeader from '../../components/PageHeader.vue'
import StatusBadge from '../../components/StatusBadge.vue'

const route = useRoute()
const reportType = computed(() => route.meta.reportType || 'peminjaman')
const titles = {
    peminjaman: ['Laporan Peminjaman', 'Pantau penggunaan aset dan status peminjaman berdasarkan periode.'],
    konsultasi: ['Laporan Konsultasi', 'Tinjau volume konsultasi, topik, dan status penanganannya.'],
    'usulan-email': ['Laporan Usulan Email', 'Pantau proses usulan email ASN berdasarkan status dan periode.'],
}
const records = ref([])
const pagination = ref(null)
const loading = ref(true)
const exporting = ref('')
const error = ref('')
const currentDate = new Date()
const defaultPeriod = () => ({
    month: String(currentDate.getMonth() + 1).padStart(2, '0'),
    year: String(currentDate.getFullYear()),
    status: '',
    opd: '',
})
const filters = ref(defaultPeriod())
const months = [
    ['01', 'Januari'],
    ['02', 'Februari'],
    ['03', 'Maret'],
    ['04', 'April'],
    ['05', 'Mei'],
    ['06', 'Juni'],
    ['07', 'Juli'],
    ['08', 'Agustus'],
    ['09', 'September'],
    ['10', 'Oktober'],
    ['11', 'November'],
    ['12', 'Desember'],
]
const years = Array.from({ length: 7 }, (_, index) => currentDate.getFullYear() + 1 - index)

const columns = computed(() => {
    if (reportType.value === 'konsultasi') return ['id', 'pemohon', 'nip', 'nama_opd', 'topik', 'judul', 'status', 'created_at']
    if (reportType.value === 'usulan-email') return ['id', 'pengaju', 'nip_pengaju', 'nama_opd', 'id_peg_bkd', 'email_pribadi', 'email_resmi', 'status', 'created_at']
    return ['id', 'pemohon', 'nip', 'nama_opd', 'tanggal_mulai', 'tanggal_selesai', 'status', 'keterangan', 'aset']
})
const labels = {
    id: 'ID', pemohon: 'Pemohon', pengaju: 'Pengaju', nip: 'NIP', nip_pengaju: 'NIP Pengaju',
    nama_opd: 'OPD', topik: 'Topik', judul: 'Judul', status: 'Status', created_at: 'Tanggal',
    tanggal_mulai: 'Mulai', tanggal_selesai: 'Selesai', keterangan: 'Keperluan', aset: 'Aset',
    id_peg_bkd: 'ID Pegawai BKD', email_pribadi: 'Email Pribadi', email_resmi: 'Email Resmi',
}

function params(page = 1) {
    const query = {
        status: filters.value.status,
        opd: filters.value.opd,
        page,
    }
    if (filters.value.month && filters.value.year) {
        const year = Number(filters.value.year)
        const month = Number(filters.value.month)
        const lastDay = new Date(year, month, 0).getDate()
        query.start_date = `${filters.value.year}-${filters.value.month}-01`
        query.end_date = `${filters.value.year}-${filters.value.month}-${String(lastDay).padStart(2, '0')}`
    }
    return Object.fromEntries(Object.entries(query).filter(([, value]) => value !== ''))
}
async function load(page = 1) {
    loading.value = true
    error.value = ''
    try {
        const response = payload(await api.get(`/laporan/${reportType.value}/data`, { params: params(page) }))
        records.value = rows(response)
        pagination.value = response
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
function reset() {
    filters.value = defaultPeriod()
    load()
}
async function exportReport(format) {
    exporting.value = format
    error.value = ''
    try {
        const response = await api.get(`/laporan/${reportType.value}/export`, {
            params: { ...params(), format },
            responseType: 'blob',
        })
        const url = URL.createObjectURL(response.data)
        const link = document.createElement('a')
        link.href = url
        link.download = `${reportType.value}.${format}`
        link.click()
        URL.revokeObjectURL(url)
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        exporting.value = ''
    }
}

watch(reportType, () => load())
onMounted(load)
</script>

<template>
    <div class="page-stack">
        <PageHeader :title="titles[reportType][0]" :description="titles[reportType][1]" eyebrow="Pelaporan layanan" />
        <section class="card">
            <form class="grid gap-4 md:grid-cols-2 xl:grid-cols-4" @submit.prevent="load()">
                <label>
                    <span class="label">Bulan</span>
                    <select v-model="filters.month" class="input">
                        <option v-for="month in months" :key="month[0]" :value="month[0]">
                            {{ month[1] }}
                        </option>
                    </select>
                </label>
                <label>
                    <span class="label">Tahun</span>
                    <select v-model="filters.year" class="input">
                        <option v-for="year in years" :key="year" :value="String(year)">
                            {{ year }}
                        </option>
                    </select>
                </label>
                <label><span class="label">Status</span><input v-model="filters.status" class="input" placeholder="Semua status" /></label>
                <label><span class="label">OPD</span><input v-model="filters.opd" class="input" placeholder="Semua OPD" /></label>
                <div class="flex flex-wrap gap-2 md:col-span-2 xl:col-span-4">
                    <button class="btn-primary" type="submit">Terapkan filter</button>
                    <button class="btn-secondary" type="button" @click="reset">Reset filter</button>
                    <button class="btn-secondary ml-auto" type="button" :disabled="Boolean(exporting)" @click="exportReport('csv')">{{ exporting === 'csv' ? 'Menyiapkan…' : 'Export CSV' }}</button>
                    <button class="btn-secondary" type="button" :disabled="Boolean(exporting)" @click="exportReport('xlsx')">{{ exporting === 'xlsx' ? 'Menyiapkan…' : 'Export Excel' }}</button>
                </div>
            </form>
        </section>
        <AlertMessage :message="error" />
        <LoadingState v-if="loading" />
        <EmptyState v-else-if="!records.length" title="Belum ada data laporan" description="Ubah filter atau pilih periode lain." />
        <div v-else class="table-wrap">
            <table class="data-table">
                <thead><tr><th v-for="column in columns" :key="column">{{ labels[column] }}</th></tr></thead>
                <tbody>
                    <tr v-for="record in records" :key="record.id">
                        <td v-for="column in columns" :key="column">
                            <StatusBadge v-if="column === 'status'" :status="record[column]" />
                            <span v-else>{{ record[column] || '—' }}</span>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <nav v-if="pagination?.last_page > 1" class="flex justify-end gap-2" aria-label="Paginasi laporan">
            <button class="btn-secondary" :disabled="pagination.current_page <= 1" @click="load(pagination.current_page - 1)">Sebelumnya</button>
            <button class="btn-secondary" :disabled="pagination.current_page >= pagination.last_page" @click="load(pagination.current_page + 1)">Berikutnya</button>
        </nav>
    </div>
</template>
