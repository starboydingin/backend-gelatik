<script setup>
import { computed, onMounted, ref } from 'vue'
import { WifiIcon, MagnifyingGlassIcon } from '@heroicons/vue/24/outline'
import { cachedGet, payload, rows, errorMessage } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import { useAuthStore } from '../../stores/auth'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import StatusBadge from '../../components/StatusBadge.vue'
const auth = useAuthStore(),
    data = ref(null),
    error = ref(''),
    loading = ref(true),
    search = ref(''),
    status = ref('all')
const allRows = computed(() => [...rows(data.value?.list_router), ...rows(data.value?.router)])
const bandwidth = computed(() => data.value?.bandwidth || { available: false, connections: [] })
const list = computed(() =>
    allRows.value.filter((item) => {
        const matchesSearch = Object.values(item)
            .join(' ')
            .toLowerCase()
            .includes(search.value.toLowerCase())
        const isActive =
            String(item.status) === '1' || String(item.status).toLowerCase() === 'aktif'
        return matchesSearch && (status.value === 'all' || (status.value === 'active') === isActive)
    })
)
const stats = computed(() => [
    { label: 'Total router', value: allRows.value.length },
    {
        label: 'Aktif',
        value: allRows.value.filter(
            (item) => String(item.status) === '1' || String(item.status).toLowerCase() === 'aktif'
        ).length,
    },
    {
        label: 'Nonaktif',
        value: allRows.value.filter(
            (item) =>
                !(String(item.status) === '1' || String(item.status).toLowerCase() === 'aktif')
        ).length,
    },
    {
        label: 'Lokasi',
        value: new Set(allRows.value.map((item) => item.lokasi || item.location).filter(Boolean))
            .size,
    },
])
async function load() {
    loading.value = true
    try {
        data.value = payload(await cachedGet('/list-router-opd', {}, 2 * 60_000))
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
        <AlertMessage :message="error" /><ServiceHero
            eyebrow="Infrastruktur jaringan"
            title="Informasi router untuk OPD Anda"
            :description="`Lihat identitas router, interface, lokasi pemasangan, dan status perangkat yang tercatat untuk ${auth.user?.nama_opd || 'unit kerja Anda'}.`"
            :stats="stats"
        />
        <section class="section-panel p-5 md:p-6">
            <div class="flex flex-col justify-between gap-5 md:flex-row md:items-center">
                <div>
                    <p class="eyebrow">Informasi bandwidth</p>
                    <h2 class="mt-1 text-xl font-bold">{{ bandwidth.opd || auth.user?.nama_opd || 'OPD Anda' }}</h2>
                    <p class="mt-2 text-sm text-[var(--color-text-secondary)]">
                        {{ bandwidth.available ? 'Kapasitas koneksi yang tercatat pada router OPD.' : 'Informasi bandwidth untuk OPD Anda belum tersedia.' }}
                    </p>
                </div>
                <div v-if="bandwidth.available" class="grid grid-cols-2 gap-3">
                    <div class="rounded-xl bg-blue-50 px-5 py-3 text-blue-900"><span class="block text-xs font-semibold">Download</span><strong class="text-xl">{{ bandwidth.connections?.[0]?.download_mbps ?? '—' }} Mbps</strong></div>
                    <div class="rounded-xl bg-amber-50 px-5 py-3 text-amber-900"><span class="block text-xs font-semibold">Upload</span><strong class="text-xl">{{ bandwidth.connections?.[0]?.upload_mbps ?? '—' }} Mbps</strong></div>
                </div>
                <div v-else class="flex flex-wrap gap-2">
                    <RouterLink to="/app/chatbot" class="btn-secondary">Cari solusi dengan AI</RouterLink>
                    <RouterLink to="/app/konsultasi" class="btn-primary">Buat konsultasi</RouterLink>
                </div>
            </div>
        </section>
        <section class="section-panel">
            <div class="grid gap-4 border-b border-stroke p-5 md:grid-cols-[1fr_220px]">
                <label class="relative"
                    ><MagnifyingGlassIcon
                        class="absolute left-3 top-1/2 size-5 -translate-y-1/2 text-slate-400" /><input
                        v-model="search"
                        class="input pl-10"
                        placeholder="Cari identity, interface, lokasi…" /></label
                ><select v-model="status" class="input">
                    <option value="all">Semua status</option>
                    <option value="active">Aktif</option>
                    <option value="inactive">Nonaktif</option>
                </select>
            </div>
            <LoadingState v-if="loading" /><EmptyState
                v-else-if="!list.length"
                title="Data router tidak tersedia"
                text="Pastikan OPD pada profil Anda telah terdaftar."
            />
            <div v-else class="router-table-scroll">
                <table class="data-table router-data-table">
                    <thead>
                        <tr>
                            <th>Identity router</th>
                            <th>Interface</th>
                            <th>Lokasi</th>
                            <th>Status</th>
                            <th>Pembaruan</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="item in list" :key="item.id">
                            <td>
                                <div class="flex items-center gap-3">
                                    <span
                                        class="grid size-10 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-600"
                                        ><WifiIcon class="size-5"
                                    /></span>
                                    <div>
                                        <strong class="text-navy">{{
                                            item.identity_router ||
                                            item.nama_router ||
                                            item.identity ||
                                            '-'
                                        }}</strong>
                                        <p class="mt-1 max-w-xs truncate text-xs text-slate-400">
                                            {{ item.nama_opd || item.opd || '-' }}
                                        </p>
                                    </div>
                                </div>
                            </td>
                            <td>{{ item.interface || '-' }}</td>
                            <td>{{ item.lokasi || item.location || '-' }}</td>
                            <td>
                                <StatusBadge
                                    :status="
                                        String(item.status) === '1'
                                            ? 'Aktif'
                                            : item.status || 'Nonaktif'
                                    "
                                />
                            </td>
                            <td>{{ formatDateTime(item.updated_at) }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </section>
    </div>
</template>

<style scoped>
.router-table-scroll {
    width: 100%;
    overflow-x: auto;
    overflow-y: hidden;
    overscroll-behavior-inline: contain;
    scrollbar-width: none;
}

.router-table-scroll::-webkit-scrollbar {
    display: none;
}

.router-data-table {
    min-width: 48rem;
}
</style>
