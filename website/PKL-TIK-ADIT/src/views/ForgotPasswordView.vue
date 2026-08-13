<script setup>
import { ref } from 'vue'
import { api, errorMessage } from '../lib/api'
import AlertMessage from '../components/AlertMessage.vue'
import AuthLayout from '../components/AuthLayout.vue'
const email = ref(''),
    message = ref(''),
    error = ref('')
async function submit() {
    error.value = ''
    message.value = ''
    try {
        message.value = (await api.post('/forgot-password', { email: email.value })).data.message
    } catch (e) {
        error.value = errorMessage(e)
    }
}
</script>
<template>
    <AuthLayout
        title="Pulihkan kata sandi"
        subtitle="Kami akan mengirim tautan pemulihan bila email terdaftar."
    >
        <form @submit.prevent="submit">
            <AlertMessage :message="error" /><AlertMessage
                :message="message"
                type="success"
            /><label class="label">Email</label
            ><input v-model="email" type="email" class="input" required /><button
                class="btn-primary mt-5 w-full"
            >
                Kirim tautan</button
            ><RouterLink
                to="/login"
                class="mt-5 block text-center text-sm font-semibold text-brand-600"
                >Kembali ke login</RouterLink
            >
        </form>
    </AuthLayout>
</template>
