<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { BellIcon, MagnifyingGlassIcon } from '@heroicons/vue/24/outline'
import { api, payload, rows, errorMessage } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import { notificationRoute } from '../../lib/notificationRoute'
import { formatDateTime } from '../../lib/date'
const router = useRouter()
const list = ref([]),
    error = ref(''),
    loading = ref(true),
    search = ref(''),
    type = ref('all'),
    readStatus = ref('all')
const filtered = computed(() =>
    list.value.filter((item) => {
        const content = `${item.judul || ''} ${item.message || ''}`.toLowerCase()
        const itemType = String(item.type || item.jenis || '').toLowerCase()
        const isRead = Boolean(item.read || item.read_at)
        return (
            content.includes(search.value.toLowerCase()) &&
            (type.value === 'all' || itemType.includes(type.value)) &&
            (readStatus.value === 'all' || (readStatus.value === 'read') === isRead)
        )
    })
)
const stats = computed(() => [
    { label: 'Semua', value: list.value.length },
    {
        label: 'Belum dibaca',
        value: list.value.filter((item) => !item.read && !item.read_at).length,
    },
    {
        label: 'Konsultasi',
        value: list.value.filter((item) =>
            String(item.type || item.jenis)
                .toLowerCase()
                .includes('konsul')
        ).length,
    },
    {
        label: 'Peminjaman',
        value: list.value.filter((item) =>
            String(item.type || item.jenis)
                .toLowerCase()
                .includes('pinjam')
        ).length,
    },
])
async function load({ fresh = false } = {}) {
    loading.value = true
    try {
        list.value = rows(payload(await api.get('/notifications', { cache: !fresh })))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
async function read(id) {
    await api.post(`/notifications/${id}/read`)
    await load()
}
async function openDetail(item) {
    try {
        if (!item.read && !item.read_at) await api.post(`/notifications/${item.id}/read`)
        item.read = true
        await router.push(notificationRoute(item, false))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function all() {
    await api.post('/notifications/read-all')
    await load()
}
function realtimeRefresh(event) {
    if (event.detail?.type === 'notification') load({ fresh: true })
}
onMounted(() => {
    load()
    window.addEventListener('gelatik:notification', realtimeRefresh)
})
onUnmounted(() => window.removeEventListener('gelatik:notification', realtimeRefresh))
</script>
<template>
    <div class="page-stack">
        <AlertMessage :message="error" /><ServiceHero
            eyebrow="Pusat notifikasi"
            title="Pantau setiap perkembangan layanan Anda"
            description="Daftar ini hanya memuat notifikasi yang ditujukan untuk akun yang sedang digunakan, termasuk balasan admin pada konsultasi Anda."
            :stats="stats"
        />
        <section class="section-panel">
            <div class="grid gap-3 border-b border-stroke p-4 md:grid-cols-[1fr_180px_180px_auto]">
                <label class="relative"
                    ><MagnifyingGlassIcon
                        class="absolute left-3 top-1/2 size-5 -translate-y-1/2 text-slate-400" /><input
                        v-model="search"
                        class="input pl-10"
                        placeholder="Cari judul atau isi pesan…" /></label
                ><select v-model="type" class="input">
                    <option value="all">Semua jenis</option>
                    <option value="konsul">Konsultasi</option>
                    <option value="pinjam">Peminjaman</option>
                    <option value="email">Email</option>
                    <option value="kritik">Kritik & saran</option></select
                ><select v-model="readStatus" class="input">
                    <option value="all">Semua status</option>
                    <option value="unread">Belum dibaca</option>
                    <option value="read">Sudah dibaca</option></select
                ><button class="btn-secondary" @click="all">Tandai semua dibaca</button>
            </div>
            <LoadingState v-if="loading" /><EmptyState
                v-else-if="!filtered.length"
                title="Belum ada notifikasi"
                text="Pembaruan layanan akan tampil di halaman ini."
            />
            <div v-else class="divide-y divide-slate-100">
                <button
                    v-for="item in filtered"
                    :key="item.id"
                    class="flex w-full items-start gap-4 p-5 text-left hover:bg-brand-50/40"
                    @click="openDetail(item)"
                >
                    <span
                        class="grid size-11 shrink-0 place-items-center rounded-xl bg-sky-50 text-sky-600"
                        ><BellIcon class="size-5" /></span
                    ><span class="min-w-0 flex-1"
                        ><span class="flex flex-wrap items-center gap-2"
                            ><strong class="text-navy">{{
                                item.judul || 'Informasi layanan'
                            }}</strong
                            ><span
                                v-if="!item.read && !item.read_at"
                                class="badge bg-brand-50 text-brand-700"
                                >Baru</span
                            ></span
                        ><span class="mt-1 block text-sm leading-6 text-slate-600">{{
                            item.message
                        }}</span
                        ><small class="mt-2 block text-slate-400">{{
                            formatDateTime(item.created_at)
                        }}</small></span
                    ><span class="hidden text-sm font-semibold text-brand-700 sm:block"
                        >Buka detail →</span
                    >
                </button>
            </div>
        </section>
    </div>
</template>
