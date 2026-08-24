<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { api, errorMessage, payload } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'
import PageHeader from '../../components/PageHeader.vue'
import StatusBadge from '../../components/StatusBadge.vue'

const route = useRoute()
const loan = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const confirmation = ref({ status: '', catatan: '' })

const transitions = {
    Menunggu: ['Proses', 'Ditolak'],
    Proses: ['Selesai'],
}
const nextStatuses = computed(() => transitions[loan.value?.status] || [])
const canConfirm = computed(() => nextStatuses.value.length > 0)

function formatDate(value, withTime = false) {
    if (!value) return '-'
    const parsed = new Date(value)
    if (Number.isNaN(parsed.getTime())) return value
    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'long',
        year: 'numeric',
        ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}),
    }).format(parsed)
}
async function load() {
    loading.value = true
    error.value = ''
    try {
        loan.value = payload(await api.get(`/pinjam/${route.params.id}`))
        confirmation.value = {
            status: transitions[loan.value.status]?.[0] || '',
            catatan: loan.value.catatan_petugas || '',
        }
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
async function saveConfirmation() {
    if (!confirmation.value.status) return
    saving.value = true
    error.value = ''
    success.value = ''
    try {
        await api.post(`/pinjam/${loan.value.id}/status`, confirmation.value)
        success.value = 'Konfirmasi peminjaman berhasil disimpan.'
        await load()
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
onMounted(load)
</script>

<template>
    <div class="page-stack">
        <PageHeader
            eyebrow="Konfirmasi peminjaman"
            title="Kelola pengajuan peminjaman"
            description="Data pengajuan ditampilkan sebagai referensi. Hanya status dan catatan petugas yang dapat diubah oleh admin."
        >
            <RouterLink class="btn-secondary" to="/admin/peminjaman">Kembali</RouterLink>
        </PageHeader>

        <AlertMessage :message="error" />
        <AlertMessage :message="success" type="success" />
        <LoadingState v-if="loading" />

        <div v-else-if="loan" class="grid gap-6 xl:grid-cols-[minmax(0,1.3fr)_minmax(20rem,.7fr)]">
            <section class="section-panel">
                <header class="section-panel-header flex flex-wrap items-center justify-between gap-3">
                    <div>
                        <p class="eyebrow">Data pengajuan pengguna</p>
                        <h2 class="mt-1 text-xl font-bold text-[var(--color-text-primary)]">Pengajuan #{{ loan.id }}</h2>
                    </div>
                    <StatusBadge :status="loan.status" />
                </header>
                <div class="space-y-6 p-5 md:p-6">
                    <dl class="grid gap-5 sm:grid-cols-2">
                        <div><dt class="label">Pemohon / PIC</dt><dd>{{ loan.user?.name || loan.nama_pic || '-' }}</dd></div>
                        <div><dt class="label">Instansi / OPD</dt><dd>{{ loan.instansi_pic || '-' }}</dd></div>
                        <div><dt class="label">Kontak</dt><dd>{{ loan.kontak_pic || '-' }}</dd></div>
                        <div><dt class="label">Identitas</dt><dd>{{ loan.jenis_identitas || '-' }} · {{ loan.nomor_identitas || '-' }}</dd></div>
                        <div class="sm:col-span-2"><dt class="label">Alamat penggunaan</dt><dd>{{ loan.alamat_peminjam || '-' }}</dd></div>
                        <div><dt class="label">Tanggal mulai</dt><dd>{{ formatDate(loan.tanggal_mulai) }}</dd></div>
                        <div><dt class="label">Jam mulai</dt><dd>{{ loan.jam_mulai || '-' }}</dd></div>
                        <div><dt class="label">Durasi</dt><dd>{{ loan.durasi_peminjaman || '-' }} {{ loan.jenis_durasi || '' }}</dd></div>
                        <div><dt class="label">Tanggal selesai</dt><dd>{{ formatDate(loan.tanggal_selesai, true) }}</dd></div>
                        <div class="sm:col-span-2"><dt class="label">Keperluan</dt><dd class="whitespace-pre-wrap">{{ loan.keterangan || '-' }}</dd></div>
                        <div v-if="loan.url_dokumen" class="sm:col-span-2"><dt class="label">Dokumen pendukung</dt><dd><a class="font-semibold text-brand-700 underline" :href="loan.url_dokumen" target="_blank" rel="noopener">Buka dokumen pendukung</a></dd></div>
                    </dl>

                    <div>
                        <p class="label">Aset yang diajukan</p>
                        <div class="divide-y divide-[var(--color-border)] overflow-hidden rounded-lg border border-[var(--color-border)]">
                            <div v-for="entry in loan.pinjam_items || []" :key="entry.id || entry.item_id" class="flex items-center justify-between gap-4 p-3">
                                <span>{{ entry.master_item?.nama || entry.master_item?.nama_item || `Aset #${entry.item_id}` }}</span>
                                <strong class="shrink-0">{{ entry.quantity || entry.jumlah || 1 }} unit</strong>
                            </div>
                            <p v-if="!(loan.pinjam_items || []).length" class="p-3 text-sm">Data aset belum tersedia.</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="section-panel h-fit">
                <header class="section-panel-header">
                    <p class="eyebrow">Tindakan petugas</p>
                    <h2 class="mt-1 text-xl font-bold text-[var(--color-text-primary)]">Konfirmasi peminjaman</h2>
                </header>
                <form class="space-y-6 p-5 md:p-6" @submit.prevent="saveConfirmation">
                    <p class="pb-1 text-sm leading-6 text-slate-600">Admin tidak dapat mengubah formulir atau aset yang diajukan pengguna.</p>
                    <label class="block">
                        <span class="label !mb-2">Status berikutnya</span>
                        <select v-model="confirmation.status" class="input" :disabled="!canConfirm" required>
                            <option value="" disabled>Pilih status</option>
                            <option v-for="status in nextStatuses" :key="status" :value="status">{{ status }}</option>
                        </select>
                    </label>
                    <label class="block">
                        <span class="label !mb-2">Catatan petugas</span>
                        <textarea v-model="confirmation.catatan" class="input min-h-32" :disabled="!canConfirm" placeholder="Tulis catatan konfirmasi untuk pemohon."></textarea>
                    </label>
                    <p v-if="!canConfirm" class="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-3 text-sm">Pengajuan berstatus {{ loan.status }} dan tidak memiliki transisi lanjutan.</p>
                    <button class="btn-primary mt-1 w-full" :disabled="saving || !canConfirm">
                        {{ saving ? 'Menyimpan...' : 'Simpan konfirmasi' }}
                    </button>
                </form>
            </section>
        </div>
    </div>
</template>
