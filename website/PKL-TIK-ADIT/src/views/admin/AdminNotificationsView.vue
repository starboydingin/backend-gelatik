<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, payload, rows, errorMessage } from '../../lib/api'
import { notificationRoute } from '../../lib/notificationRoute'
import { formatDateTime } from '../../lib/date'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'

const router = useRouter()
const list = ref([]),
    error = ref(''),
    show = ref(false),
    form = ref({ user_id: 0, judul: '', message: '', type: 'informasi' })

async function load() {
    try {
        list.value = rows(payload(await api.get('/admin/notifications')))
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function create() {
    try {
        await api.post('/admin/notifications', form.value)
        show.value = false
        load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function remove(id) {
    if (confirm('Hapus notifikasi?')) {
        await api.delete(`/admin/notifications/${id}`)
        load()
    }
}
function hasDetail(item) {
    return notificationRoute(item, true) !== '/admin/notifikasi'
}
async function openDetail(item) {
    const route = notificationRoute(item, true)
    if (route && route !== '/admin/notifikasi') {
        await router.push(route)
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="Notifikasi"
        description="Kirim pengumuman massal atau pesan kepada pengguna tertentu, serta pantau aktivitas dan balasan pengajuan."
    />
    <AlertMessage :message="error" />
    <form v-if="show" class="card mb-5" @submit.prevent="create">
        <div class="grid gap-3 md:grid-cols-2">
            <label
                ><span class="label">ID pengguna (0 untuk semua)</span
                ><input v-model.number="form.user_id" type="number" min="0" class="input" /></label
            ><label
                ><span class="label">Jenis</span
                ><select v-model="form.type" class="input">
                    <option>informasi</option>
                    <option>peringatan</option>
                    <option>layanan</option>
                </select></label
            ><label
                ><span class="label">Judul</span
                ><input v-model="form.judul" class="input" required /></label
            ><label
                ><span class="label">Pesan</span
                ><input v-model="form.message" class="input" required
            /></label>
        </div>
        <button class="btn-primary mt-4">Kirim notifikasi</button>
    </form>
    <div class="card divide-y divide-slate-100">
        <EmptyState v-if="!list.length" />
        <div
            v-for="item in list"
            :key="item.id"
            class="flex items-start justify-between gap-4 py-4 transition"
            :class="hasDetail(item) ? 'cursor-pointer hover:bg-slate-50/80 -mx-4 px-4 rounded-lg' : ''"
            @click="hasDetail(item) ? openDetail(item) : null"
        >
            <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                    <strong>{{ item.judul }}</strong>
                    <span class="badge bg-brand-50 text-brand-700">{{ item.type }}</span>
                    <span
                        v-if="hasDetail(item)"
                        class="text-xs font-semibold text-brand-700 hover:underline"
                    >
                        Buka detail →
                    </span>
                </div>
                <p class="mt-1 text-sm text-slate-600">{{ item.message }}</p>
                <div class="mt-2 flex flex-wrap items-center gap-3 text-xs text-slate-400">
                    <span>Tujuan: {{ item.user?.name || 'Semua pengguna' }}</span>
                    <span v-if="item.created_at">• {{ formatDateTime(item.created_at) }}</span>
                </div>
            </div>
            <button class="btn-danger shrink-0" @click.stop="remove(item.id)">Hapus</button>
        </div>
    </div>
</template>
