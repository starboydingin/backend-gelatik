<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
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
onMounted(load)
</script>
<template>
    <PageHeader
        title="Notifikasi"
        description="Kirim pengumuman massal atau pesan kepada pengguna tertentu."
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
            class="flex items-start justify-between gap-4 py-4"
        >
            <div>
                <div class="flex gap-2">
                    <strong>{{ item.judul }}</strong
                    ><span class="badge bg-brand-50 text-brand-700">{{ item.type }}</span>
                </div>
                <p class="mt-1 text-sm text-slate-600">{{ item.message }}</p>
                <p class="mt-2 text-xs text-slate-400">
                    Tujuan: {{ item.user?.name || 'Semua pengguna' }}
                </p>
            </div>
            <button class="btn-danger" @click="remove(item.id)">Hapus</button>
        </div>
    </div>
</template>
