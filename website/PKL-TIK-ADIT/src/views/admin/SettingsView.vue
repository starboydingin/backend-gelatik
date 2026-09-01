<script setup>
import { computed, onMounted, ref } from 'vue'
import { BuildingOffice2Icon, ClockIcon, EnvelopeIcon, KeyIcon, PhoneIcon, UserCircleIcon } from '@heroicons/vue/24/outline'
import { api, errorMessage, payload, rows } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import { useAuthStore } from '../../stores/auth'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'

const auth = useAuthStore()
const activeTab = ref('profile')
const saving = ref(false)
const loadingActivity = ref(false)
const activityLoaded = ref(false)
const error = ref('')
const message = ref('')
const settings = ref([])
const activity = ref([])
const form = ref({ name: auth.user?.name || '', email: auth.user?.email || '', no_hp: auth.user?.no_hp || '', nama_opd: auth.user?.nama_opd || '' })
const passwordForm = ref({ current_password: '', password: '', password_confirmation: '' })
const initials = computed(() => (auth.user?.name || 'G').split(' ').map((part) => part[0]).slice(0, 2).join('').toUpperCase())
const isSuperadmin = computed(() => auth.isSuperAdmin)

function setTab(tab) {
    activeTab.value = tab
    error.value = ''
    message.value = ''
    if (tab === 'activity' && !activityLoaded.value) loadActivity()
    if (tab === 'settings' && !settings.value.length) loadSettings()
}
async function saveProfile() {
    saving.value = true
    error.value = ''
    try {
        auth.user = payload(await api.patch('/me', form.value))
        sessionStorage.setItem('gelatik_user', JSON.stringify(auth.user))
        message.value = 'Profil berhasil diperbarui.'
    } catch (requestError) { error.value = errorMessage(requestError) } finally { saving.value = false }
}
async function savePassword() {
    saving.value = true
    error.value = ''
    try {
        message.value = (await api.post('/me/change-password', passwordForm.value)).data.message
        passwordForm.value = { current_password: '', password: '', password_confirmation: '' }
    } catch (requestError) { error.value = errorMessage(requestError) } finally { saving.value = false }
}
async function loadActivity() {
    loadingActivity.value = true
    try {
        activity.value = rows(payload(await api.get('/me/activity-log', { cache: false })))
        activityLoaded.value = true
    } catch (requestError) { error.value = errorMessage(requestError) } finally { loadingActivity.value = false }
}
async function loadSettings() {
    try { settings.value = rows(payload(await api.get('/admin/settings'))) } catch (requestError) { error.value = errorMessage(requestError) }
}
async function saveSettings() {
    saving.value = true
    try {
        settings.value = rows(payload(await api.put('/admin/settings', { settings: settings.value.map((item) => ({ setting_name: item.setting_name, setting_val: String(item.setting_val ?? '') })) })))
        message.value = 'Pengaturan aplikasi berhasil disimpan.'
    } catch (requestError) { error.value = errorMessage(requestError) } finally { saving.value = false }
}
onMounted(() => { if (!auth.user) auth.loadUser() })
</script>

<template>
    <div class="page-stack">
        <PageHeader eyebrow="Akun administrator" title="Profil & Pengaturan" description="Kelola informasi akun, keamanan akses, dan riwayat aktivitas Anda." />
        <AlertMessage :message="error" />
        <AlertMessage :message="message" type="success" />
        <div class="grid gap-4 xl:grid-cols-[300px_minmax(0,1fr)]">
            <aside class="section-panel overflow-hidden">
                <div class="flex flex-col items-center px-5 py-6 text-center">
                    <span class="grid size-20 place-items-center rounded-full bg-brand-50 text-2xl font-bold text-brand-700">{{ initials }}</span>
                    <h2 class="mt-4 text-xl font-bold text-navy">{{ auth.user?.name }}</h2>
                    <p class="mt-1 text-sm text-slate-500">{{ auth.user?.username || auth.user?.nip }}</p>
                    <span class="badge mt-3 bg-brand-50 text-brand-800">{{ auth.roles.join(', ') }}</span>
                </div>
                <div class="divide-y divide-stroke border-t border-stroke text-sm">
                    <div class="flex gap-3 px-5 py-4"><EnvelopeIcon class="size-5 shrink-0 text-brand-600" /><span class="min-w-0 break-all">{{ auth.user?.email || '-' }}</span></div>
                    <div class="flex gap-3 px-5 py-4"><PhoneIcon class="size-5 shrink-0 text-brand-600" /><span>{{ auth.user?.no_hp || 'Nomor handphone belum diisi' }}</span></div>
                    <div class="flex gap-3 px-5 py-4"><BuildingOffice2Icon class="size-5 shrink-0 text-brand-600" /><span>{{ auth.user?.nama_opd || 'OPD belum diisi' }}</span></div>
                </div>
            </aside>
            <section class="section-panel">
                <nav class="no-scrollbar flex gap-1 overflow-x-auto border-b border-stroke p-2" aria-label="Pengaturan akun">
                    <button class="settings-tab" :class="{ active: activeTab === 'profile' }" @click="setTab('profile')"><UserCircleIcon class="size-5" />Informasi pengguna</button>
                    <button class="settings-tab" :class="{ active: activeTab === 'password' }" @click="setTab('password')"><KeyIcon class="size-5" />Ganti password</button>
                    <button class="settings-tab" :class="{ active: activeTab === 'activity' }" @click="setTab('activity')"><ClockIcon class="size-5" />Log aktivitas</button>
                    <button v-if="isSuperadmin" class="settings-tab" :class="{ active: activeTab === 'settings' }" @click="setTab('settings')"><BuildingOffice2Icon class="size-5" />Pengaturan aplikasi</button>
                </nav>
                <form v-if="activeTab === 'profile'" class="grid gap-4 p-4 md:grid-cols-[180px_1fr] md:p-5" @submit.prevent="saveProfile">
                    <label class="label md:pt-3">Nama lengkap</label><input v-model="form.name" class="input" required />
                    <label class="label md:pt-3">Username</label><input :value="auth.user?.username || auth.user?.nip" class="input bg-slate-50" disabled />
                    <label class="label md:pt-3">Email</label><input v-model="form.email" type="email" class="input" required />
                    <label class="label md:pt-3">Organisasi perangkat daerah</label><input v-model="form.nama_opd" class="input" />
                    <label class="label md:pt-3">Nomor handphone</label><input v-model="form.no_hp" class="input" inputmode="tel" />
                    <div class="md:col-start-2"><button class="btn-primary" :disabled="saving">{{ saving ? 'Menyimpan…' : 'Simpan informasi' }}</button></div>
                </form>
                <form v-else-if="activeTab === 'password'" class="grid gap-4 p-4 md:grid-cols-[180px_1fr] md:p-5" @submit.prevent="savePassword">
                    <label class="label md:pt-3">Password lama</label><input v-model="passwordForm.current_password" class="input" type="password" autocomplete="current-password" required />
                    <label class="label md:pt-3">Password baru</label><div><input v-model="passwordForm.password" class="input" type="password" autocomplete="new-password" minlength="8" required /><p class="mt-2 text-xs text-slate-500">Gunakan minimal 8 karakter dan jangan membagikannya kepada siapa pun.</p></div>
                    <label class="label md:pt-3">Konfirmasi password baru</label><input v-model="passwordForm.password_confirmation" class="input" type="password" autocomplete="new-password" minlength="8" required />
                    <div class="md:col-start-2"><button class="btn-primary" :disabled="saving">{{ saving ? 'Menyimpan…' : 'Simpan password' }}</button></div>
                </form>
                <div v-else-if="activeTab === 'activity'" class="p-4 md:p-5">
                    <p v-if="loadingActivity" class="text-sm text-slate-500">Memuat log aktivitas…</p>
                    <p v-else-if="!activity.length" class="rounded-lg bg-slate-50 p-5 text-sm text-slate-500">Belum ada aktivitas administrator yang tercatat pada akun ini.</p>
                    <ol v-else class="space-y-4 border-l-2 border-brand-100 pl-5"><li v-for="entry in activity" :key="entry.id" class="relative"><span class="absolute -left-[1.86rem] top-1.5 size-3 rounded-full bg-brand-600 ring-4 ring-white" /><p class="font-semibold text-navy">{{ entry.description }}</p><p class="mt-1 text-xs text-slate-500">{{ formatDateTime(entry.created_at) }}</p></li></ol>
                </div>
                <form v-else class="space-y-4 p-4 md:p-5" @submit.prevent="saveSettings">
                    <p class="text-sm text-slate-500">Konfigurasi global hanya ditampilkan kepada superadmin agar pengelolaan akun tetap terpisah dari pengaturan sistem.</p>
                    <label v-for="item in settings" :key="item.setting_name" class="grid gap-2 md:grid-cols-[220px_1fr] md:items-center"><span class="label mb-0">{{ item.setting_name.replaceAll('_', ' ') }}</span><input v-model="item.setting_val" class="input" /></label>
                    <button class="btn-primary" :disabled="saving">{{ saving ? 'Menyimpan…' : 'Simpan pengaturan aplikasi' }}</button>
                </form>
            </section>
        </div>
    </div>
</template>

<style scoped>
.settings-tab { display: inline-flex; min-height: 2.75rem; flex: 0 0 auto; align-items: center; gap: .5rem; border-radius: .5rem; padding: .6rem .8rem; color: var(--color-text-secondary); font-size: .875rem; font-weight: 600; }
.settings-tab:hover, .settings-tab.active { background: var(--color-brand-primary-soft); color: var(--color-brand-primary); }
</style>
