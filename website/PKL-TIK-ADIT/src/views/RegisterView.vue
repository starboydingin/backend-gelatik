<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, errorMessage, payload, rows } from '../lib/api'
import { useAuthStore } from '../stores/auth'
import AlertMessage from '../components/AlertMessage.vue'
import AuthLayout from '../components/GovernmentAuthLayout.vue'
import AppInput from '../components/AppInput.vue'
import AppButton from '../components/AppButton.vue'
import SearchableSelect from '../components/SearchableSelect.vue'
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
    >
        <template #guide>
            <ol class="list-decimal space-y-1.5 pl-4">
                <li>Isi nama lengkap dan NIP 18 digit sesuai data kedinasan.</li>
                <li>Gunakan email resmi yang aktif serta nomor HP yang dapat dihubungi.</li>
                <li>Pilih perangkat daerah atau OPD tempat Anda bertugas.</li>
                <li>Buat kata sandi minimal 8 karakter dan ulangi dengan tepat.</li>
                <li>Periksa kembali data; setelah berhasil, sistem akan masuk ke akun secara otomatis.</li>
            </ol>
        </template>
        <form @submit.prevent="submit">
            <AlertMessage :message="error" />
            <div class="grid gap-3.5 md:grid-cols-2">
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
                    label="Email resmi dinas"
                    type="email"
                    hint="Gunakan email resmi dinas yang terdaftar."
                    required
                /><AppInput
                    id="phone"
                    v-model="form.no_hp"
                    label="Nomor HP"
                    required
                /><SearchableSelect
                    v-model="form.nama_opd"
                    class="md:col-span-2"
                    label="Perangkat daerah / OPD"
                    placeholder="Pilih OPD"
                    search-placeholder="Cari nama OPD…"
                    :options="
                        opds.map((opd) => ({
                            value: opd.nama_opd || opd,
                            label: opd.nama_opd || opd,
                        }))
                    "
                />
                <AppInput
                    id="new-password"
                    v-model="form.password"
                    label="Kata sandi"
                    type="password"
                    minlength="8"
                    hint="Gunakan minimal 8 karakter."
                    required
                /><AppInput
                    id="confirmation"
                    v-model="form.password_confirmation"
                    label="Ulangi kata sandi"
                    type="password"
                    required
                />
            </div>
            <AppButton type="submit" class="mt-5 w-full" :loading="loading">{{
                loading ? 'Mendaftarkan…' : 'Daftar dan masuk'
            }}</AppButton>
            <div class="my-4 flex items-center gap-3 text-xs text-slate-400">
                <span class="h-px flex-1 bg-slate-200" /><span>atau</span
                ><span class="h-px flex-1 bg-slate-200" />
            </div>
            <p class="text-center text-sm text-slate-500">
                Sudah memiliki akun?
                <RouterLink to="/login" class="font-semibold text-brand-600">Masuk</RouterLink>
            </p>
        </form>
    </AuthLayout>
</template>
