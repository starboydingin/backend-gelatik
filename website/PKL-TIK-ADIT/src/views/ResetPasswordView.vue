<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, errorMessage } from '../lib/api'
import AlertMessage from '../components/AlertMessage.vue'
import AuthLayout from '../components/AuthLayout.vue'
const router = useRouter(),
    error = ref(''),
    message = ref(''),
    loading = ref(false)
const form = ref({
    reset_token: sessionStorage.getItem('gelatik_reset_token') || '',
    password: '',
    password_confirmation: '',
})
async function submit() {
    loading.value = true
    error.value = ''
    try {
        message.value = (await api.post('/reset-password', form.value)).data.message
        sessionStorage.removeItem('gelatik_reset_token')
        setTimeout(() => router.push('/login'), 1300)
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
</script>
<template>
    <AuthLayout
        title="Atur kata sandi baru"
        subtitle="Buat kata sandi baru setelah nomor WhatsApp Anda berhasil diverifikasi."
    >
        <form @submit.prevent="submit">
            <AlertMessage :message="error" /><AlertMessage
                :message="message"
                type="success"
            /><AlertMessage
                v-if="!form.reset_token"
                message="Sesi verifikasi tidak tersedia. Silakan minta kode baru."
            /><label class="label">Kata sandi baru</label
            ><input
                v-model="form.password"
                type="password"
                minlength="8"
                class="input mb-4"
                required
            /><label class="label">Konfirmasi kata sandi</label
            ><input
                v-model="form.password_confirmation"
                type="password"
                minlength="8"
                class="input"
                required
            /><button class="btn-primary mt-5 w-full" :disabled="loading || !form.reset_token">
                {{ loading ? 'Menyimpan…' : 'Simpan kata sandi' }}
            </button>
        </form>
    </AuthLayout>
</template>
