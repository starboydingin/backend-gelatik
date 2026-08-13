<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, errorMessage } from '../lib/api'
import AlertMessage from '../components/AlertMessage.vue'
import AuthLayout from '../components/AuthLayout.vue'
const route = useRoute(),
    router = useRouter(),
    error = ref(''),
    message = ref(''),
    loading = ref(false)
const form = ref({
    token: route.query.token || '',
    email: route.query.email || '',
    password: '',
    password_confirmation: '',
})
async function submit() {
    loading.value = true
    error.value = ''
    try {
        message.value = (await api.post('/reset-password', form.value)).data.message
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
        subtitle="Gunakan tautan yang dikirimkan ke email Anda."
    >
        <form @submit.prevent="submit">
            <AlertMessage :message="error" /><AlertMessage
                :message="message"
                type="success"
            /><label class="label">Email</label
            ><input v-model="form.email" type="email" class="input mb-4" required /><label
                class="label"
                >Token reset</label
            ><input v-model="form.token" class="input mb-4" required /><label class="label"
                >Kata sandi baru</label
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
            /><button class="btn-primary mt-5 w-full" :disabled="loading">
                {{ loading ? 'Menyimpan…' : 'Simpan kata sandi' }}
            </button>
        </form>
    </AuthLayout>
</template>
