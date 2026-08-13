<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, errorMessage, payload, rows } from '../lib/api'
import { useAuthStore } from '../stores/auth'
import AlertMessage from '../components/AlertMessage.vue'
import AuthLayout from '../components/AuthLayout.vue'
import AppInput from '../components/AppInput.vue'
import AppButton from '../components/AppButton.vue'
const router = useRouter(),
    auth = useAuthStore(),
    opds = ref([]),
    error = ref(''),
    loading = ref(false),
    form = ref({
        name: '',
        email: '',
        nip: '',
        no_hp: '',
        nama_opd: '',
        password: '',
        password_confirmation: '',
    })
onMounted(async () => {
    try {
        opds.value = rows(payload(await api.get('/opd')))
    } catch {}
})
async function submit() {
    loading.value = true
    error.value = ''
    try {
        auth.save(payload(await api.post('/register', form.value)))
        await auth.loadUser()
        router.push('/app/dashboard')
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
</script>
<template>
    <AuthLayout
        wide
        title="Buat akun layanan"
        subtitle="Lengkapi data kedinasan Anda untuk mulai menggunakan Gelatik."
        ><form @submit.prevent="submit">
            <AlertMessage :message="error" />
            <div class="grid gap-4 md:grid-cols-2">
                <AppInput id="name" v-model="form.name" label="Nama lengkap" required /><AppInput
                    id="nip"
                    v-model="form.nip"
                    label="NIP (18 digit)"
                    inputmode="numeric"
                    pattern="[0-9]{18}"
                    required
                /><AppInput
                    id="email"
                    v-model="form.email"
                    label="Email"
                    type="email"
                    required
                /><AppInput id="phone" v-model="form.no_hp" label="Nomor HP" required /><label
                    class="md:col-span-2"
                    ><span class="label">Perangkat daerah / OPD</span
                    ><select v-model="form.nama_opd" class="input" required>
                        <option value="" disabled>Pilih OPD</option>
                        <option
                            v-for="opd in opds"
                            :key="opd.id || opd.nama_opd"
                            :value="opd.nama_opd || opd"
                        >
                            {{ opd.nama_opd || opd }}
                        </option>
                    </select></label
                ><AppInput
                    id="new-password"
                    v-model="form.password"
                    label="Kata sandi"
                    type="password"
                    minlength="6"
                    required
                /><AppInput
                    id="confirmation"
                    v-model="form.password_confirmation"
                    label="Ulangi kata sandi"
                    type="password"
                    required
                />
            </div>
            <AppButton type="submit" class="mt-6 w-full" :loading="loading">{{
                loading ? 'Mendaftarkan…' : 'Daftar dan masuk'
            }}</AppButton>
            <p class="mt-5 text-center text-sm text-slate-500">
                Sudah memiliki akun?
                <RouterLink to="/login" class="font-semibold text-brand-600">Masuk</RouterLink>
            </p>
        </form></AuthLayout
    >
</template>
