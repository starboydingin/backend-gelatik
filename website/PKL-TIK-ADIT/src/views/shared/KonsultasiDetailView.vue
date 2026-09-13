<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, errorMessage, payload } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import { openProtectedAttachment } from '../../lib/attachments'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'
import StatusBadge from '../../components/StatusBadge.vue'
import DiscussionThread from '../../components/DiscussionThread.vue'

const route = useRoute()
const router = useRouter()
const admin = computed(() => route.path.startsWith('/admin'))
const record = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const reply = ref('')
const replyFile = ref(null)
const nextStatus = ref('')
const archived = computed(() => Boolean(record.value?.deleted_at))
const availableStatuses = computed(() => {
    if (archived.value) return []
    const current = String(record.value?.status || '').toLowerCase()
    if (current === 'menunggu') return ['Diproses', 'Ditolak', 'Selesai']
    if (current === 'diproses') return ['Selesai', 'Ditolak']
    return []
})

async function load() {
    loading.value = true
    error.value = ''
    try {
        record.value = payload(await api.get(`/konsul/${route.params.id}`, { cache: false }))
        nextStatus.value = availableStatuses.value[0] || ''
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
async function sendReply() {
    if (!reply.value.trim()) return
    saving.value = true
    try {
        const body = new FormData()
        body.append('isi_respon', reply.value.trim())
        if (replyFile.value) body.append('file', replyFile.value)
        await api.post(`/konsul/${record.value.id}/response`, body)
        reply.value = ''
        replyFile.value = null
        await load()
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
async function updateStatus() {
    if (!nextStatus.value) return
    saving.value = true
    try {
        await api.post(`/konsul/${record.value.id}/status`, { status: nextStatus.value })
        await load()
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
async function preview(endpoint) {
    try {
        await openProtectedAttachment(endpoint)
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
            <AlertMessage
                v-if="archived"
                message="Konsultasi ini telah diarsipkan. Detail tetap tersedia sebagai riwayat, tetapi tidak dapat diubah atau ditanggapi lagi."
                type="success"
            />
            <section class="card">
                <div class="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <p class="eyebrow">Detail konsultasi #{{ record.id }}</p>
                        <h1 class="mt-2 text-2xl font-bold">{{ record.judul }}</h1>
                        <p class="mt-2 text-sm text-slate-500">{{ formatDateTime(record.created_at) }}</p>
                    </div>
                    <StatusBadge :status="record.status" />
                </div>
                <dl class="mt-4 grid gap-3 sm:grid-cols-2">
                    <div><dt class="label">Pemohon</dt><dd>{{ record.user?.name || '-' }}</dd></div>
                    <div><dt class="label">Topik</dt><dd>{{ record.topik?.topik || record.topik?.judul || '-' }}</dd></div>
                    <div class="sm:col-span-2"><dt class="label">Keterangan</dt><dd class="whitespace-pre-wrap leading-7">{{ record.pesan || record.deskripsi || '-' }}</dd></div>
                </dl>
                <button v-if="record.file && !archived" class="btn-secondary mt-5" @click="preview(`/konsul/${record.id}/attachment`)">Lihat lampiran</button>
            </section>

            <!-- Admin Status Control Form -->
            <section v-if="admin && !archived" class="card">
                <form @submit.prevent="updateStatus">
                    <p class="eyebrow">Status layanan</p>
                    <div class="mt-4 flex flex-wrap items-end gap-3">
                        <label class="flex-1 min-w-[200px] block">
                            <span class="label">Status berikutnya</span>
                            <select v-model="nextStatus" class="input mt-1" :disabled="!availableStatuses.length">
                                <option v-for="status in availableStatuses" :key="status">{{ status }}</option>
                            </select>
                        </label>
                        <button v-if="availableStatuses.length" class="btn-primary" :disabled="saving">
                            Simpan status
                        </button>
                    </div>
                    <p v-if="!availableStatuses.length" class="mt-3 text-sm text-slate-500">
                        Status konsultasi ini sudah final.
                    </p>
                </form>
            </section>

            <!-- Two-way Discussion Thread -->
            <DiscussionThread
                v-if="!archived"
                service-type="konsultasi"
                :record-id="record.id"
                :status="record.status"
            />
        </template>
    </div>
</template>
