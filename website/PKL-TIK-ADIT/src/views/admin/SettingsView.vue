<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
const list = ref([]),
    error = ref(''),
    message = ref('')
async function load() {
    try {
        list.value = rows(payload(await api.get('/admin/settings')))
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function save() {
    try {
        list.value = rows(
            payload(
                await api.put('/admin/settings', {
                    settings: list.value.map((x) => ({
                        setting_name: x.setting_name,
                        setting_val: String(x.setting_val ?? ''),
                    })),
                })
            )
        )
        message.value = 'Pengaturan berhasil disimpan.'
    } catch (e) {
        error.value = errorMessage(e)
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="Pengaturan sistem"
        description="Konfigurasi umum yang diekspos oleh API Backend Gelatik."
    />
    <form class="card max-w-3xl" @submit.prevent="save">
        <AlertMessage :message="error" /><AlertMessage :message="message" type="success" />
        <div class="divide-y divide-slate-100">
            <label
                v-for="item in list"
                :key="item.setting_name"
                class="grid gap-2 py-4 md:grid-cols-[220px_1fr] md:items-center"
                ><span class="text-sm font-semibold text-slate-700">{{
                    item.setting_name.replaceAll('_', ' ')
                }}</span
                ><input v-model="item.setting_val" class="input"
            /></label>
        </div>
        <button class="btn-primary mt-5">Simpan pengaturan</button>
    </form>
</template>
