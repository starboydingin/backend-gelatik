<script setup>
import { computed, ref } from 'vue'
import {
    ClockIcon,
    EnvelopeIcon,
    KeyIcon,
    PhoneIcon,
    BuildingOffice2Icon,
    UserCircleIcon,
} from '@heroicons/vue/24/outline'
import { api, payload, rows, errorMessage } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import { useAuthStore } from '../../stores/auth'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
const auth = useAuthStore(),
    saving = ref(false),
    activeTab = ref('profile'),
    activity = ref([]),
    activityLoaded = ref(false),
    loadingActivity = ref(false),
    message = ref(''),
    error = ref('')
const form = ref({
    name: auth.user?.name || '',
    email: auth.user?.email || '',
    no_hp: auth.user?.no_hp || '',
    nama_opd: auth.user?.nama_opd || '',
})
const passwordForm = ref({ current_password: '', password: '', password_confirmation: '' })
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
        sessionStorage.setItem('gelatik_user', JSON.stringify(auth.user))
        message.value = 'Profil berhasil diperbarui.'
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
function setTab(tab) {
    activeTab.value = tab
    error.value = ''
    message.value = ''
    if (tab === 'activity' && !activityLoaded.value) loadActivity()
}
async function submitPassword() {
    saving.value = true
    error.value = ''
    message.value = ''
    try {
        message.value = (await api.post('/me/change-password', passwordForm.value)).data.message
        passwordForm.value = { current_password: '', password: '', password_confirmation: '' }
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
async function loadActivity() {
    loadingActivity.value = true
    try {
        activity.value = rows(payload(await api.get('/me/activity-log', { cache: false })))
        activityLoaded.value = true
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loadingActivity.value = false
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
        <div class="grid gap-4 xl:grid-cols-[300px_1fr]">
            <aside class="space-y-5">
                <section class="service-hero flex-col items-center text-center md:flex-col">
                    <span
                        class="grid size-24 place-items-center rounded-xl border border-brand-200 bg-brand-50 text-3xl font-semibold text-brand-700"
                        >{{ initials }}</span
                    >
                    <div>
                        <h2 class="text-xl font-bold text-navy">{{ auth.user?.name }}</h2>
                        <p class="mt-1 text-sm text-slate-500">
                            {{ auth.user?.username || auth.user?.nip }}
                        </p>
                        <span class="badge mt-3 bg-brand-50 text-brand-800">{{
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
            <section class="section-panel">
                <nav class="no-scrollbar flex gap-1 overflow-x-auto border-b border-stroke p-2" aria-label="Pengaturan akun">
                    <button class="profile-tab" :class="{ active: activeTab === 'profile' }" @click="setTab('profile')"><UserCircleIcon class="size-5" />Informasi pengguna</button>
                    <button class="profile-tab" :class="{ active: activeTab === 'password' }" @click="setTab('password')"><KeyIcon class="size-5" />Ganti password</button>
                    <button class="profile-tab" :class="{ active: activeTab === 'activity' }" @click="setTab('activity')"><ClockIcon class="size-5" />Log aktivitas</button>
                </nav>
                <form v-if="activeTab === 'profile'" @submit.prevent="submit">
                    <div class="section-panel-header flex items-center gap-3">
                        <UserCircleIcon class="size-6 text-brand-600" />
                        <div>
                            <p class="eyebrow">Informasi pengguna</p>
                            <h2 class="font-bold text-navy">Data akun utama</h2>
                        </div>
                    </div>
                    <div class="grid gap-4 p-4 md:grid-cols-2 md:p-5">
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
                <form v-else-if="activeTab === 'password'" class="grid gap-4 p-4 md:grid-cols-[180px_1fr] md:p-5" @submit.prevent="submitPassword">
                    <label class="label md:pt-3">Password lama</label><input v-model="passwordForm.current_password" class="input" type="password" autocomplete="current-password" required />
                    <label class="label md:pt-3">Password baru</label><div><input v-model="passwordForm.password" class="input" type="password" autocomplete="new-password" minlength="8" required /><p class="mt-2 text-xs text-slate-500">Gunakan minimal 8 karakter dan jangan membagikannya kepada siapa pun.</p></div>
                    <label class="label md:pt-3">Konfirmasi password baru</label><input v-model="passwordForm.password_confirmation" class="input" type="password" autocomplete="new-password" minlength="8" required />
                    <div class="md:col-start-2"><button class="btn-primary" :disabled="saving">{{ saving ? 'Menyimpan…' : 'Simpan password' }}</button></div>
                </form>
                <div v-else class="p-4 md:p-5">
                    <p v-if="loadingActivity" class="text-sm text-slate-500">Memuat log aktivitas…</p>
                    <p v-else-if="!activity.length" class="rounded-lg bg-slate-50 p-5 text-sm text-slate-500">Belum ada aktivitas yang tercatat pada akun ini.</p>
                    <ol v-else class="space-y-4 border-l-2 border-brand-100 pl-5"><li v-for="entry in activity" :key="entry.id" class="relative"><span class="absolute -left-[1.86rem] top-1.5 size-3 rounded-full bg-brand-600 ring-4 ring-white" /><p class="font-semibold text-navy">{{ entry.description }}</p><p class="mt-1 text-xs text-slate-500">{{ formatDateTime(entry.created_at) }}</p></li></ol>
                </div>
            </section>
        </div>
    </div>
</template>
<style scoped>
.profile-tab { display: inline-flex; min-height: 2.75rem; flex: 0 0 auto; align-items: center; gap: .5rem; border-radius: .5rem; padding: .6rem .8rem; color: var(--color-text-secondary); font-size: .875rem; font-weight: 600; }
.profile-tab:hover, .profile-tab.active { background: var(--color-brand-primary-soft); color: var(--color-brand-primary); }
</style>
