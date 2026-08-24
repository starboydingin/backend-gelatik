<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, errorMessage, payload } from '../lib/api'
import AlertMessage from '../components/AlertMessage.vue'
import AuthLayout from '../components/AuthLayout.vue'
const router = useRouter(),
    identifier = ref(''),
    error = ref('')
async function submit() {
    error.value = ''
    try {
        const challenge = payload(await api.post('/forgot-password', { identifier: identifier.value }))
        sessionStorage.setItem('gelatik_reset_challenge', challenge.challenge_id)
        router.push('/verify-reset-otp')
    } catch (e) {
        error.value = errorMessage(e)
    }
}
</script>
<template>
    <AuthLayout
        title="Pulihkan kata sandi"
        subtitle="Masukkan email, NIP, atau username. Kode verifikasi akan dikirim ke nomor WhatsApp yang terdaftar."
    >
        <form @submit.prevent="submit">
            <AlertMessage :message="error" /><label class="label">Email, NIP, atau username</label
            ><input v-model="identifier" autocomplete="username" class="input" required /><button
                class="btn-primary mt-5 w-full"
            >
                Kirim kode WhatsApp</button
            ><RouterLink
                to="/login"
                class="mt-5 block text-center text-sm font-semibold text-brand-600"
                >Kembali ke login</RouterLink
            >
        </form>
    </AuthLayout>
</template>
