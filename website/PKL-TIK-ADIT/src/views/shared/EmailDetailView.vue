<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, errorMessage, payload } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'
import StatusBadge from '../../components/StatusBadge.vue'
import { useAuthStore } from '../../stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const isBkd = computed(() => auth.isBkd)
const isAdmin = computed(() => auth.isAdmin)
const record = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const form = ref({ email_resmi: '', catatan: '' })
async function load() {
    loading.value = true
    try {
        record.value = payload(
            await api.get(`/pengajuan-email/${route.params.id}`, { cache: false })
        )
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
                <div class="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <p class="eyebrow">Detail usulan email #{{ record.id }}</p>
                        <h1 class="mt-2 text-2xl font-bold">
                            {{ record.nama || record.nama_pegawai || 'Pegawai ASN' }}
                        </h1>
                    </div>
                    <div class="flex flex-wrap gap-2">
                        <StatusBadge :status="record.status" /><StatusBadge
                            v-if="record.verification_state === 'verified'"
                            status="Terverifikasi BKD"
                        />
                    </div>
                </div>
                <dl class="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                    <div>
                        <dt class="label">NIP</dt>
                        <dd>{{ record.nip || '-' }}</dd>
                    </div>
                    <div>
                        <dt class="label">Unit kerja</dt>
                        <dd>{{ record.unit_kerja || '-' }}</dd>
                    </div>
                    <div>
                        <dt class="label">Jabatan</dt>
                        <dd>{{ record.jabatan || '-' }}</dd>
                    </div>
                    <div>
                        <dt class="label">Email pribadi</dt>
                        <dd class="break-all">{{ record.email_pribadi || '-' }}</dd>
                    </div>
                    <div>
                        <dt class="label">Email resmi</dt>
                        <dd class="break-all">{{ record.email_resmi || '-' }}</dd>
                    </div>
                    <div>
                        <dt class="label">Tanggal diajukan</dt>
                        <dd>{{ formatDateTime(record.created_at) }}</dd>
                    </div>
                    <div>
                        <dt class="label">Tanggal verifikasi</dt>
                        <dd>{{ formatDateTime(record.tanggal_verifikasi) }}</dd>
                    </div>
                    <div>
                        <dt class="label">Diverifikasi oleh</dt>
                        <dd>{{ record.diverifikasi_oleh || '-' }}</dd>
                    </div>
                    <div class="sm:col-span-2 lg:col-span-3">
                        <dt class="label">Catatan petugas</dt>
                        <dd class="whitespace-pre-wrap">{{ record.catatan || '-' }}</dd>
                    </div>
                </dl>
            </section>
            <section
                v-if="(isAdmin || isBkd) && String(record.status).toLowerCase() === 'diajukan'"
                class="card"
            >
                <p class="eyebrow">Keputusan petugas</p>
                <h2 class="mt-1 text-xl font-bold">Proses usulan</h2>
                <div class="mt-4 grid gap-3 md:grid-cols-2">
                    <label v-if="isAdmin"
                        ><span class="label">Email resmi</span
                        ><input
                            v-model="form.email_resmi"
                            type="email"
                            class="input"
                            placeholder="nama@lampungprov.go.id" /></label
                    ><label
                        ><span class="label"
                            >Catatan {{ isBkd ? 'verifikasi/penolakan' : 'penerbitan' }}</span
                        ><textarea v-model="form.catatan" class="input min-h-24" />
                    </label>
                </div>
                <p
                    v-if="isAdmin && !record.can_be_published"
                    class="mt-4 rounded-lg bg-amber-50 p-3 text-sm text-amber-800"
                >
                    Menunggu verifikasi dokumen oleh BKD sebelum email resmi dapat diterbitkan.
                </p>
                <div class="mt-5 flex flex-wrap gap-3">
                    <button
                        v-if="isBkd && record.can_be_verified"
                        class="btn-secondary"
                        :disabled="saving"
                        @click="action('verifikasi')"
                    >
                        Verifikasi dokumen</button
                    ><button
                        v-if="isAdmin"
                        class="btn-primary"
                        :disabled="saving || !form.email_resmi || !record.can_be_published"
                        @click="action('buat-email-resmi')"
                    >
                        Terbitkan email resmi</button
                    ><button
                        v-if="isBkd"
                        class="btn-danger"
                        :disabled="saving"
                        @click="action('tolak-email')"
                    >
                        Tolak usulan
                    </button>
                </div>
            </section>
        </template>
    </div>
</template>
