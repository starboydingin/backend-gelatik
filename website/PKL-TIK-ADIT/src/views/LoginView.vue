<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { errorMessage } from '../lib/api'
import AlertMessage from '../components/AlertMessage.vue'
import AuthLayout from '../components/GovernmentAuthLayout.vue'
import AppInput from '../components/AppInput.vue'
import AppButton from '../components/AppButton.vue'
const auth = useAuthStore(),
    router = useRouter(),
    route = useRoute(),
    form = ref({ identifier: '', password: '' }),
    error = ref(''),
    loading = ref(false)
async function submit() {
    loading.value = true
    error.value = ''
    try {
        await auth.login(form.value)
        await auth.loadUser()
        router.push(route.query.redirect || (auth.isAdmin ? '/admin/dashboard' : '/app/dashboard'))
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
</script>
<template>
    <AuthLayout title="Masuk ke akun" subtitle="Gunakan email, NIP, atau username yang terdaftar."
        ><form @submit.prevent="submit">
            <AlertMessage :message="error" />
            <div class="space-y-3.5">
                <AppInput
                    id="identifier"
                    v-model="form.identifier"
                    label="Email, NIP, atau username"
                    autocomplete="username"
                    required
                /><AppInput
                    id="password"
                    v-model="form.password"
                    label="Kata sandi"
                    type="password"
                    autocomplete="current-password"
                    required
                />
            </div>
            <div class="my-4 flex justify-end">
                <RouterLink to="/forgot-password" class="text-sm font-semibold text-brand-600"
                    >Lupa kata sandi?</RouterLink
                >
            </div>
            <AppButton type="submit" class="w-full" :loading="loading">{{
                loading ? 'Memproses…' : 'Masuk'
            }}</AppButton>
            <div class="my-4 flex items-center gap-3 text-xs text-slate-400">
                <span class="h-px flex-1 bg-slate-200" /><span>atau</span
                ><span class="h-px flex-1 bg-slate-200" />
            </div>
            <RouterLink to="/register" class="btn-secondary w-full">Daftar akun baru</RouterLink>
        </form></AuthLayout
    >
</template>
