<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
const list = ref([]),
    error = ref(''),
    message = ref(''),
    show = ref(false),
    editingId = ref(null),
    form = ref({ judul: '', konten: '', expired_at: '' })
async function load() {
    try {
        list.value = rows(payload(await api.get('/admin/pengumuman')))
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function submit() {
    try {
        if (editingId.value) await api.put(`/admin/pengumuman/${editingId.value}`, form.value)
        else await api.post('/admin/pengumuman', form.value)
        message.value = editingId.value
            ? 'Pengumuman berhasil diperbarui.'
            : 'Pengumuman berhasil diterbitkan.'
        editingId.value = null
        form.value = { judul: '', konten: '', expired_at: '' }
        show.value = false
        load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
function edit(item) {
    editingId.value = item.id
    form.value = {
        judul: item.judul,
        konten: item.konten,
        expired_at: item.expired_at ? String(item.expired_at).slice(0, 10) : '',
    }
    show.value = true
}
function cancelEdit() {
    editingId.value = null
    show.value = false
}
async function remove(id) {
    if (!confirm('Hapus pengumuman ini?')) return
    try {
        await api.delete(`/admin/pengumuman/${id}`)
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
onMounted(load)
</script>
<template>
    <PageHeader title="Pengumuman" description="Terbitkan informasi layanan untuk pengguna portal."
        ><button class="btn-primary" @click="show = !show">Buat pengumuman</button></PageHeader
    ><AlertMessage :message="error" /><AlertMessage :message="message" type="success" />
    <form v-if="show" class="card mb-5" @submit.prevent="submit">
        <label
            ><span class="label">Judul</span
            ><input v-model="form.judul" class="input" required /></label
        ><label class="mt-4 block"
            ><span class="label">Konten</span
            ><textarea v-model="form.konten" class="input min-h-28" required></textarea></label
        ><label class="mt-4 block max-w-xs"
            ><span class="label">Berakhir pada (opsional)</span
            ><input v-model="form.expired_at" type="date" class="input"
        /></label>
        <div class="mt-5 flex gap-2">
            <button class="btn-primary">{{ editingId ? 'Simpan perubahan' : 'Terbitkan' }}</button
            ><button v-if="editingId" type="button" class="btn-secondary" @click="cancelEdit">
                Batal
            </button>
        </div>
    </form>
    <div class="card divide-y divide-slate-100">
        <EmptyState v-if="!list.length" />
        <article v-for="item in list" :key="item.id" class="py-4">
            <h2 class="font-bold text-slate-950">{{ item.judul }}</h2>
            <p class="mt-2 whitespace-pre-wrap text-sm leading-7 text-slate-600">
                {{ item.konten }}
            </p>
            <p class="mt-2 text-xs text-slate-400">{{ formatDateTime(item.created_at) }}</p>
            <div class="mt-3 flex gap-2">
                <button class="btn-secondary min-h-9 px-3" @click="edit(item)">Ubah</button
                ><button class="btn-danger min-h-9 px-3" @click="remove(item.id)">Hapus</button>
            </div>
        </article>
    </div>
</template>
