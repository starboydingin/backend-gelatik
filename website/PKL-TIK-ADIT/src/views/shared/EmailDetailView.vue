<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, errorMessage, payload } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'
import StatusBadge from '../../components/StatusBadge.vue'

const route = useRoute()
const router = useRouter()
const admin = computed(() => route.path.startsWith('/admin'))
const record = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const form = ref({ email_resmi: '', catatan: '' })
async function load() {
    loading.value = true
    try {
        record.value = payload(await api.get(`/pengajuan-email/${route.params.id}`, { cache: false }))
        form.value.email_resmi = record.value.email_resmi || ''
        form.value.catatan = record.value.catatan || ''
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
async function action(type) {
    saving.value = true
    error.value = ''
    try {
        const body = { catatan: form.value.catatan }
        if (type === 'buat-email-resmi') body.email_resmi = form.value.email_resmi
        await api.post(`/pengajuan-email/${record.value.id}/${type}`, body)
        success.value = 'Data usulan berhasil diperbarui.'
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
        <button class="btn-secondary w-fit" @click="router.back()">← Kembali</button>
        <AlertMessage :message="error" /><AlertMessage :message="success" type="success" />
        <LoadingState v-if="loading" />
        <template v-else-if="record">
            <section class="card">
                <div class="flex flex-wrap items-start justify-between gap-4"><div><p class="eyebrow">Detail usulan email #{{ record.id }}</p><h1 class="mt-2 text-2xl font-bold">{{ record.nama || record.nama_pegawai || 'Pegawai ASN' }}</h1></div><StatusBadge :status="record.status" /></div>
                <dl class="mt-6 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
                    <div><dt class="label">NIP</dt><dd>{{ record.nip || '-' }}</dd></div><div><dt class="label">Unit kerja</dt><dd>{{ record.unit_kerja || '-' }}</dd></div><div><dt class="label">Jabatan</dt><dd>{{ record.jabatan || '-' }}</dd></div>
                    <div><dt class="label">Email pribadi</dt><dd class="break-all">{{ record.email_pribadi || '-' }}</dd></div><div><dt class="label">Email resmi</dt><dd class="break-all">{{ record.email_resmi || '-' }}</dd></div><div><dt class="label">Tanggal diajukan</dt><dd>{{ formatDateTime(record.created_at) }}</dd></div>
                    <div><dt class="label">Tanggal verifikasi</dt><dd>{{ formatDateTime(record.tanggal_verifikasi) }}</dd></div><div><dt class="label">Diverifikasi oleh</dt><dd>{{ record.diverifikasi_oleh || '-' }}</dd></div><div class="sm:col-span-2 lg:col-span-3"><dt class="label">Catatan petugas</dt><dd class="whitespace-pre-wrap">{{ record.catatan || '-' }}</dd></div>
                </dl>
            </section>
            <section v-if="admin && String(record.status).toLowerCase() === 'diajukan'" class="card">
                <p class="eyebrow">Keputusan petugas</p><h2 class="mt-1 text-xl font-bold">Proses usulan</h2>
                <div class="mt-5 grid gap-4 md:grid-cols-2"><label><span class="label">Email resmi</span><input v-model="form.email_resmi" type="email" class="input" placeholder="nama@lampungprov.go.id" /></label><label><span class="label">Catatan</span><textarea v-model="form.catatan" class="input min-h-24" /></label></div>
                <div class="mt-5 flex flex-wrap gap-3"><button class="btn-secondary" :disabled="saving" @click="action('verifikasi')">Verifikasi dokumen</button><button class="btn-primary" :disabled="saving || !form.email_resmi" @click="action('buat-email-resmi')">Terbitkan email resmi</button><button class="btn-danger" :disabled="saving" @click="action('tolak-email')">Tolak usulan</button></div>
            </section>
        </template>
    </div>
</template>
