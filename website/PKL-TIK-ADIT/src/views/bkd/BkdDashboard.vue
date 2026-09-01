<script setup>
import { computed, onMounted, ref } from 'vue'
import { api, errorMessage, payload, rows } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'
import StatusBadge from '../../components/StatusBadge.vue'
import { formatDateTime } from '../../lib/date'

const records = ref([])
const loading = ref(true)
const error = ref('')
const waiting = computed(() =>
    records.value.filter((item) => item.verification_state === 'waiting')
)
const verified = computed(() =>
    records.value.filter((item) => item.verification_state === 'verified')
)
const rejected = computed(() => records.value.filter((item) => item.status === 'ditolak'))

async function load() {
    loading.value = true
    error.value = ''
    try {
        records.value = rows(
            payload(await api.get('/pengajuan-email', { params: { per_page: 10 }, cache: false }))
        )
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
onMounted(load)
</script>

<template>
    <div class="page-stack">
        <section class="section-panel p-4 sm:p-5">
            <p class="eyebrow">Portal verifikator BKD</p>
            <h1 class="mt-1.5 text-xl font-bold text-slate-950 sm:text-2xl">
                Verifikasi pengajuan email ASN
            </h1>
            <p class="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
                Periksa identitas dan dokumen pengajuan. Pengajuan yang lolos akan diteruskan kepada
                admin untuk penerbitan alamat email resmi.
            </p>
        </section>
        <AlertMessage :message="error" />
        <LoadingState v-if="loading" />
        <template v-else>
            <section class="grid gap-4 sm:grid-cols-3">
                <article class="card">
                    <p class="label">Menunggu verifikasi</p>
                    <p class="mt-1.5 text-2xl font-bold text-blue-900">{{ waiting.length }}</p>
                </article>
                <article class="card">
                    <p class="label">Diteruskan ke admin</p>
                    <p class="mt-1.5 text-2xl font-bold text-teal-700">{{ verified.length }}</p>
                </article>
                <article class="card">
                    <p class="label">Ditolak</p>
                    <p class="mt-1.5 text-2xl font-bold text-red-700">{{ rejected.length }}</p>
                </article>
            </section>
            <section class="section-panel overflow-hidden">
                <div class="section-panel-header flex items-center justify-between gap-4">
                    <div>
                        <p class="eyebrow">Antrean terbaru</p>
                        <h2 class="mt-1 text-xl font-bold">Perlu diperiksa</h2>
                    </div>
                    <RouterLink class="btn-secondary" to="/bkd/email-resmi">Lihat semua</RouterLink>
                </div>
                <div v-if="!waiting.length" class="p-4 text-sm text-slate-600">
                    Tidak ada pengajuan yang menunggu verifikasi.
                </div>
                <div v-else class="divide-y divide-slate-200">
                    <RouterLink
                        v-for="item in waiting.slice(0, 5)"
                        :key="item.id"
                        :to="`/bkd/email-resmi/${item.id}`"
                        class="grid gap-2 p-4 hover:bg-slate-50 sm:grid-cols-[1fr_auto] sm:items-center"
                    >
                        <div>
                            <p class="font-bold text-slate-950">
                                {{ item.nama_pegawai || item.nama || `Usulan #${item.id}` }}
                            </p>
                            <p class="mt-1 text-sm text-slate-600">
                                {{ item.nip || '-' }} · {{ item.unit_kerja || '-' }} ·
                                {{ formatDateTime(item.created_at) }}
                            </p>
                        </div>
                        <StatusBadge status="Menunggu verifikasi" />
                    </RouterLink>
                </div>
            </section>
        </template>
    </div>
</template>
