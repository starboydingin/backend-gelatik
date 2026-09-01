<script setup>
import { onMounted, ref } from 'vue'
import { api, cachedGet, errorMessage, invalidateApiCache, payload } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
const status = ref({}),
    number = ref(''),
    error = ref(''),
    message = ref(''),
    saving = ref(false)
async function load() {
    try {
        status.value = payload(await cachedGet('/notifikasi/wa/status', {}, 60_000))
        number.value = status.value.wa_number || ''
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function save() {
    saving.value = true
    try {
        status.value = payload(
            await api.post('/notifikasi/wa/subscribe', { nomor_wa: number.value, is_opt_in: true })
        )
        invalidateApiCache('/notifikasi/wa/status')
        message.value = 'Notifikasi WhatsApp telah diaktifkan.'
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        saving.value = false
    }
}
async function remove() {
    try {
        message.value = (await api.delete('/notifikasi/wa/subscribe')).data.message
        invalidateApiCache('/notifikasi/wa/status')
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="Notifikasi WhatsApp"
        description="Terima pembaruan status layanan melalui nomor WhatsApp Anda."
    />
    <div class="card max-w-2xl">
        <AlertMessage :message="error" /><AlertMessage :message="message" type="success" />
        <div class="mb-4 rounded-lg bg-emerald-50 p-3.5 text-sm text-emerald-800">
            <strong>{{ status.is_subscribed ? 'Aktif' : 'Belum aktif' }}</strong>
            <p class="mt-1">
                {{
                    status.is_subscribed
                        ? `Nomor ${status.wa_number} menerima notifikasi layanan.`
                        : 'Tambahkan nomor WhatsApp untuk berlangganan.'
                }}
            </p>
        </div>
        <label class="label">Nomor WhatsApp</label
        ><input
            v-model="number"
            class="input"
            inputmode="tel"
            placeholder="0812xxxx atau 62812xxxx"
        />
        <div class="mt-4 flex flex-wrap gap-2">
            <button class="btn-primary" :disabled="saving" @click="save">
                {{ saving ? 'Menyimpan…' : 'Simpan langganan' }}</button
            ><button v-if="status.is_subscribed" class="btn-danger" @click="remove">
                Berhenti berlangganan
            </button>
        </div>
    </div>
</template>
