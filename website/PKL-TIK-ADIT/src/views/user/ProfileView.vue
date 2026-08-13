<script setup>
import { computed, ref } from 'vue'
import {
    EnvelopeIcon,
    PhoneIcon,
    BuildingOffice2Icon,
    UserCircleIcon,
} from '@heroicons/vue/24/outline'
import { api, payload, errorMessage } from '../../lib/api'
import { useAuthStore } from '../../stores/auth'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
const auth = useAuthStore(),
    saving = ref(false),
    message = ref(''),
    error = ref('')
const form = ref({
    name: auth.user?.name || '',
    email: auth.user?.email || '',
    no_hp: auth.user?.no_hp || '',
    nama_opd: auth.user?.nama_opd || '',
})
const initials = computed(() =>
    (auth.user?.name || 'G')
        .split(' ')
        .map((part) => part[0])
        .slice(0, 2)
        .join('')
        .toUpperCase()
)
async function submit() {
    saving.value = true
    error.value = ''
    try {
        auth.user = payload(await api.patch('/me', form.value))
        localStorage.setItem('gelatik_user', JSON.stringify(auth.user))
        message.value = 'Profil berhasil diperbarui.'
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
</script>
<template>
    <div class="page-stack">
        <PageHeader
            eyebrow="Data pribadi"
            title="Profil & Akun"
            description="Kelola informasi kontak dan unit kerja pada akun yang sedang digunakan."
        /><AlertMessage :message="error" /><AlertMessage :message="message" type="success" />
        <div class="grid gap-5 xl:grid-cols-[320px_1fr]">
            <aside class="space-y-5">
                <section class="service-hero flex-col items-center text-center md:flex-col">
                    <span
                        class="relative z-10 grid size-24 place-items-center rounded-3xl border-4 border-white/30 bg-white/90 text-3xl font-semibold text-brand-700"
                        >{{ initials }}</span
                    >
                    <div class="relative z-10">
                        <h2 class="text-xl font-bold text-white">{{ auth.user?.name }}</h2>
                        <p class="mt-1 text-sm text-blue-100">
                            {{ auth.user?.username || auth.user?.nip }}
                        </p>
                        <span class="badge mt-3 bg-white/10 text-white">{{
                            auth.roles.join(', ') || 'user'
                        }}</span>
                    </div>
                </section>
                <section class="card space-y-4">
                    <p class="eyebrow">Informasi akun</p>
                    <div
                        v-for="item in [
                            [EnvelopeIcon, auth.user?.email],
                            [PhoneIcon, auth.user?.no_hp || '-'],
                            [BuildingOffice2Icon, auth.user?.nama_opd || '-'],
                        ]"
                        :key="item[1]"
                        class="flex gap-3"
                    >
                        <component :is="item[0]" class="size-5 shrink-0 text-brand-600" /><span
                            class="min-w-0 break-words text-sm text-slate-600"
                            >{{ item[1] }}</span
                        >
                    </div>
                </section>
            </aside>
            <form class="section-panel" @submit.prevent="submit">
                <div class="section-panel-header flex items-center gap-3">
                    <UserCircleIcon class="size-6 text-brand-600" />
                    <div>
                        <p class="eyebrow">Informasi pengguna</p>
                        <h2 class="font-bold text-navy">Data akun utama</h2>
                    </div>
                </div>
                <div class="grid gap-5 p-5 md:grid-cols-2 md:p-7">
                    <label
                        ><span class="label">Nama lengkap</span
                        ><input v-model="form.name" class="input" required /></label
                    ><label
                        ><span class="label">Email akun</span
                        ><input v-model="form.email" type="email" class="input" required /></label
                    ><label
                        ><span class="label">Nomor handphone</span
                        ><input v-model="form.no_hp" class="input" inputmode="tel" /></label
                    ><label
                        ><span class="label">Organisasi perangkat daerah</span
                        ><input v-model="form.nama_opd" class="input"
                    /></label>
                    <div class="flex justify-end md:col-span-2">
                        <button class="btn-primary" :disabled="saving">
                            {{ saving ? 'Menyimpan…' : 'Simpan informasi' }}
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</template>
