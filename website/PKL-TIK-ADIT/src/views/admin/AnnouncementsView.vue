<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
const list = ref([]),
    error = ref(''),
    message = ref(''),
    show = ref(false),
    form = ref({ judul: '', konten: '', expired_at: '' })
async function load() {
    try {
        list.value = rows(payload(await api.get('/pengumuman')))
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function submit() {
    try {
        await api.post('/pengumuman', form.value)
        message.value = 'Pengumuman berhasil diterbitkan.'
        form.value = { judul: '', konten: '', expired_at: '' }
        show.value = false
        load()
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
            ><input v-model="form.expired_at" type="date" class="input" /></label
        ><button class="btn-primary mt-5">Terbitkan</button>
    </form>
    <div class="card divide-y divide-slate-100">
        <EmptyState v-if="!list.length" />
        <article v-for="item in list" :key="item.id" class="py-4">
            <h2 class="font-bold text-slate-950">{{ item.judul }}</h2>
            <p class="mt-2 whitespace-pre-wrap text-sm leading-7 text-slate-600">
                {{ item.konten }}
            </p>
            <p class="mt-2 text-xs text-slate-400">{{ item.created_at }}</p>
        </article>
    </div>
</template>
