<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, errorMessage, payload } from '../lib/api'
import AlertMessage from '../components/AlertMessage.vue'
import AuthLayout from '../components/AuthLayout.vue'

const router = useRouter()
const otp = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
    const challengeId = sessionStorage.getItem('gelatik_reset_challenge')
    if (!challengeId) {
        router.replace('/forgot-password')
        return
    }

    loading.value = true
    error.value = ''
    try {
        const result = payload(
            await api.post('/forgot-password/verify', {
                challenge_id: challengeId,
                otp: otp.value,
            }),
        )
        sessionStorage.removeItem('gelatik_reset_challenge')
        sessionStorage.setItem('gelatik_reset_token', result.reset_token)
        router.push('/reset-password')
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
</script>

<template>
    <AuthLayout
        title="Verifikasi WhatsApp"
        subtitle="Masukkan kode 6 digit yang dikirim ke nomor WhatsApp terdaftar. Kode berlaku selama 10 menit."
    >
        <form @submit.prevent="submit">
            <AlertMessage :message="error" />
            <label class="label" for="otp">Kode verifikasi</label>
            <input
                id="otp"
                v-model="otp"
                class="input text-center text-xl tracking-[0.35em]"
                inputmode="numeric"
                autocomplete="one-time-code"
                maxlength="6"
                pattern="[0-9]{6}"
                required
            />
            <button class="btn-primary mt-5 w-full" :disabled="loading">
                {{ loading ? 'Memverifikasi…' : 'Verifikasi kode' }}
            </button>
            <RouterLink
                to="/forgot-password"
                class="mt-5 block text-center text-sm font-semibold text-brand-700"
            >
                Kirim ulang kode
            </RouterLink>
        </form>
    </AuthLayout>
</template>
