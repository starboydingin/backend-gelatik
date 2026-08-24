<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, errorMessage, payload } from '../../lib/api'
import { formatDateTime, formatLoanSchedule } from '../../lib/date'
import { openProtectedAttachment } from '../../lib/attachments'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'
import StatusBadge from '../../components/StatusBadge.vue'

const route = useRoute()
const router = useRouter()
const record = ref(null)
const loading = ref(true)
const error = ref('')
async function load() {
    try {
        record.value = payload(await api.get(`/pinjam/${route.params.id}`, { cache: false }))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
async function preview(kind = 'document') {
    try {
        await openProtectedAttachment(`/pinjam/${record.value.id}/attachment/${kind}`)
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
onMounted(load)
</script>

<template>
    <div class="page-stack">
        <button class="btn-secondary w-fit" @click="router.back()">← Kembali</button>
        <AlertMessage :message="error" />
        <LoadingState v-if="loading" />
        <template v-else-if="record">
            <section class="card">
                <div class="flex flex-wrap items-start justify-between gap-4">
                    <div><p class="eyebrow">Detail peminjaman #{{ record.id }}</p><h1 class="mt-2 text-2xl font-bold">{{ record.keterangan || 'Peminjaman aset TIK' }}</h1><p class="mt-2 text-sm text-slate-500">Diajukan {{ formatDateTime(record.created_at) }}</p></div>
                    <StatusBadge :status="record.status" />
                </div>
                <dl class="mt-6 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
                    <div><dt class="label">Pemohon</dt><dd>{{ record.user?.name || record.nama_pic || '-' }}</dd></div>
                    <div><dt class="label">Instansi</dt><dd>{{ record.instansi_pic || '-' }}</dd></div>
                    <div><dt class="label">Kontak</dt><dd>{{ record.kontak_pic || '-' }}</dd></div>
                    <div><dt class="label">Jadwal mulai</dt><dd>{{ formatLoanSchedule(record.tanggal_mulai, record.jam_mulai) }}</dd></div>
                    <div><dt class="label">Durasi</dt><dd>{{ record.durasi_peminjaman || '-' }} {{ record.jenis_durasi || '' }}</dd></div>
                    <div><dt class="label">Alamat penggunaan</dt><dd>{{ record.alamat_peminjam || '-' }}</dd></div>
                    <div class="sm:col-span-2 lg:col-span-3"><dt class="label">Catatan petugas</dt><dd class="whitespace-pre-wrap">{{ record.catatan_petugas || '-' }}</dd></div>
                </dl>
                <div class="mt-5 flex flex-wrap gap-3"><button v-if="record.url_dokumen" class="btn-secondary" @click="preview()">Lihat dokumen pendukung</button><button v-if="record.bukti_pengembalian" class="btn-secondary" @click="preview('return-proof')">Lihat bukti pengembalian</button></div>
            </section>
            <section class="card">
                <p class="eyebrow">Daftar aset</p><h2 class="mt-1 text-xl font-bold">Barang yang diajukan</h2>
                <div class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                    <article v-for="entry in record.pinjam_items || []" :key="entry.id || entry.item_id" class="rounded-xl border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-4"><strong>{{ entry.master_item?.nama || `Aset #${entry.item_id}` }}</strong><p class="mt-2 text-sm">Jumlah: {{ entry.quantity || entry.jumlah || 1 }}</p></article>
                    <p v-if="!(record.pinjam_items || []).length">Belum ada data aset.</p>
                </div>
            </section>
        </template>
    </div>
</template>
