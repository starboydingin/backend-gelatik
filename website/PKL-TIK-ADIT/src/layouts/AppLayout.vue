<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { connectRealtime, disconnectRealtime } from '../lib/realtime'
import { invalidateRealtimeResource, realtimeResource } from '../lib/api'
import AppShell from '../components/AppShell.vue'
import AppSidebar from '../components/AppSidebar.vue'
import AppHeader from '../components/AppHeader.vue'
import MobileBottomNav from '../components/MobileBottomNav.vue'
import PageContainer from '../components/PageContainer.vue'
import {
    HomeIcon,
    CalendarDaysIcon,
    ChatBubbleLeftRightIcon,
    BriefcaseIcon,
    EnvelopeIcon,
    WifiIcon,
    ChatBubbleBottomCenterTextIcon,
    BellIcon,
    UserCircleIcon,
    QuestionMarkCircleIcon,
    StarIcon,
    DevicePhoneMobileIcon,
    SparklesIcon,
    UsersIcon,
    ShieldCheckIcon,
    IdentificationIcon,
    ChartBarIcon,
    MegaphoneIcon,
    Cog6ToothIcon,
    Squares2X2Icon,
} from '@heroicons/vue/24/outline'

const auth = useAuthStore(),
    route = useRoute(),
    router = useRouter(),
    open = ref(false),
    syncRevision = ref(0)
const userItems = [
    { label: 'Dashboard', to: '/app/dashboard', icon: HomeIcon, group: 'Dashboard' },
    {
        label: 'Konsultasi TIK',
        to: '/app/konsultasi',
        icon: ChatBubbleLeftRightIcon,
        group: 'Layanan',
    },
    { label: 'Kalender', to: '/app/kalender', icon: CalendarDaysIcon, group: 'Informasi' },
    { label: 'Peminjaman', to: '/app/peminjaman', icon: BriefcaseIcon, group: 'Layanan' },
    { label: 'Usulan Email', to: '/app/email-resmi', icon: EnvelopeIcon, group: 'Layanan' },
    { label: 'Internet & Bandwidth', to: '/app/router', icon: WifiIcon, group: 'Layanan' },
    {
        label: 'Kritik & Saran',
        to: '/app/umpan-balik',
        icon: ChatBubbleBottomCenterTextIcon,
        group: 'Interaksi',
    },
    { label: 'Pengumuman', to: '/app/pengumuman', icon: MegaphoneIcon, group: 'Informasi' },
    { label: 'Notifikasi', to: '/app/notifikasi', icon: BellIcon, group: 'Interaksi' },
    { label: 'FAQ', to: '/app/faq', icon: QuestionMarkCircleIcon, group: 'Informasi' },
    { label: 'Riwayat Kritik & Saran', to: '/app/umpan-balik', icon: StarIcon, group: 'Interaksi' },
    {
        label: 'WhatsApp',
        to: '/app/whatsapp',
        icon: DevicePhoneMobileIcon,
        group: 'Akun',
    },
    { label: 'Chatbot', to: '/app/chatbot', icon: SparklesIcon, group: 'Interaksi' },
    { label: 'Profil', to: '/app/profil', icon: UserCircleIcon, group: 'Akun' },
]
const adminItems = [
    { label: 'Dasbor', to: '/admin/dashboard', icon: HomeIcon, group: 'Portal admin' },
    { label: 'Pengguna', to: '/admin/pengguna', icon: UsersIcon, group: 'Akses' },
    { label: 'Peran & Izin', to: '/admin/peran', icon: ShieldCheckIcon, group: 'Akses' },
    {
        label: 'Konsultasi',
        to: '/admin/konsultasi',
        icon: ChatBubbleLeftRightIcon,
        group: 'Layanan',
    },
    { label: 'Peminjaman', to: '/admin/peminjaman', icon: BriefcaseIcon, group: 'Layanan' },
    { label: 'Usulan Email', to: '/admin/email-resmi', icon: EnvelopeIcon, group: 'Layanan' },
    { label: 'Pegawai Email', to: '/admin/pegawai', icon: IdentificationIcon, group: 'Layanan' },
    {
        label: 'Laporan Peminjaman',
        to: '/admin/laporan-peminjaman',
        icon: ChartBarIcon,
        group: 'Pelaporan',
    },
    {
        label: 'Laporan Konsultasi',
        to: '/admin/laporan-konsultasi',
        icon: ChartBarIcon,
        group: 'Pelaporan',
    },
    {
        label: 'Laporan Usulan Email',
        to: '/admin/laporan-email',
        icon: ChartBarIcon,
        group: 'Pelaporan',
    },
    {
        label: 'Kritik & Saran',
        to: '/admin/kritik-saran',
        icon: ChatBubbleBottomCenterTextIcon,
        group: 'Konten',
    },
    { label: 'Pengumuman', to: '/admin/pengumuman', icon: MegaphoneIcon, group: 'Konten' },
    {
        label: 'Referensi Layanan',
        to: '/admin/referensi-layanan',
        icon: Squares2X2Icon,
        group: 'Konten',
    },
    { label: 'Notifikasi', to: '/admin/notifikasi', icon: BellIcon, group: 'Sistem' },
    { label: 'Profil & Pengaturan', to: '/admin/pengaturan', icon: Cog6ToothIcon, group: 'Sistem' },
]
const adminArea = computed(() => route.path.startsWith('/admin'))
const items = computed(() => {
    if (!adminArea.value) return userItems
    if (auth.roles.includes('superadmin')) return adminItems
    return adminItems.filter((item) => item.to !== '/admin/peran')
})
const mobileItems = computed(() =>
    adminArea.value
        ? [adminItems[0], adminItems[3], adminItems[1]]
        : [userItems[0], userItems[1], userItems[3], userItems.at(-1)]
)
async function logout() {
    await auth.logout()
    disconnectRealtime()
    router.push('/login')
}
function routeUsesResource(resource) {
    if (resource === 'session') return false
    const path = route.path
    if (resource === 'insights') return path.endsWith('/dashboard')
    if (resource === 'peminjaman')
        return (
            path.includes('peminjaman') ||
            path.includes('laporan-peminjaman') ||
            path.endsWith('/kalender')
        )
    if (resource === 'konsultasi')
        return (
            path.includes('konsultasi') ||
            path.includes('laporan-konsultasi') ||
            path.endsWith('/kalender')
        )
    if (resource === 'usulan_email')
        return path.includes('email-resmi') || path.includes('laporan-email')
    if (resource === 'notification') return path.endsWith('/notifikasi')
    if (resource === 'kritik_saran')
        return path.endsWith('/umpan-balik') || path.endsWith('/kritik-saran')
    if (resource === 'rating') return path.endsWith('/rating') || path.endsWith('/dashboard')
    if (resource === 'user') return path.endsWith('/profil')
    if (resource === 'whatsapp_subscription') return path.endsWith('/whatsapp')
    if (resource === 'faq' || resource === 'mastertopik')
        return path.endsWith('/faq') || path.includes('konsultasi')
    if (resource === 'masteritem')
        return path.includes('peminjaman') || path.includes('referensi-layanan')
    if (resource === 'router' || resource === 'routerlist') return path.endsWith('/router')
    if (resource === 'pengumuman' || resource === 'slider')
        return path.endsWith('/pengumuman') || path.endsWith('/dashboard')
    if (resource === 'settings') return path.endsWith('/pengaturan')
    return false
}
function activeRouteResource() {
    const path = route.path
    if (path.endsWith('/dashboard')) return 'insights'
    if (path.includes('peminjaman') || path.includes('laporan-peminjaman')) return 'peminjaman'
    if (path.includes('konsultasi') || path.includes('laporan-konsultasi')) return 'konsultasi'
    if (path.includes('email-resmi') || path.includes('laporan-email')) return 'usulan_email'
    if (path.endsWith('/notifikasi')) return 'notification'
    if (path.endsWith('/umpan-balik') || path.endsWith('/kritik-saran')) return 'kritik_saran'
    if (path.endsWith('/rating')) return 'rating'
    if (path.endsWith('/profil')) return 'user'
    if (path.endsWith('/whatsapp')) return 'whatsapp_subscription'
    if (path.endsWith('/faq')) return 'faq'
    if (path.endsWith('/router')) return 'router'
    if (path.endsWith('/pengumuman')) return 'pengumuman'
    if (path.includes('referensi-layanan')) return 'masteritem'
    if (path.endsWith('/pengaturan')) return 'settings'
    return ''
}
function reconcileAfterReconnect() {
    const resource = activeRouteResource()
    if (!resource) return
    invalidateRealtimeResource({ resource })
    syncRevision.value += 1
}
async function refreshActivePage(event) {
    const resource = realtimeResource(event?.detail || {})
    if (resource === 'user' && auth.authenticated) {
        try {
            await auth.loadUser()
        } catch {
            // The next protected request remains the authorization authority.
        }
    }
    if (!routeUsesResource(resource)) return
    // The event is debounced in realtime.js. Reconstruct only the active view
    // whose REST resource changed; unrelated pages retain their lazy cache.
    syncRevision.value += 1
}
onMounted(() => {
    connectRealtime(auth.token)
    window.addEventListener('gelatik:data-sync', refreshActivePage)
    window.addEventListener('gelatik:reconnected', reconcileAfterReconnect)
})
onBeforeUnmount(() => {
    window.removeEventListener('gelatik:data-sync', refreshActivePage)
    window.removeEventListener('gelatik:reconnected', reconcileAfterReconnect)
    disconnectRealtime()
})
</script>

<template>
    <AppShell>
        <template #sidebar
            ><div
                v-if="open"
                class="fixed inset-0 z-30 bg-slate-950/45 md:hidden"
                @click="open = false" />
            <AppSidebar
                :items="items"
                :active-path="route.path"
                :admin-area="adminArea"
                :open="open"
                @close="open = false"
                @logout="logout"
        /></template>
        <template #header
            ><AppHeader :user="auth.user" :subtitle="auth.roles.join(', ')" :admin-area="adminArea"
        /></template>
        <PageContainer>
            <RouterView v-slot="{ Component }">
                <!-- API reads remain cached per page. Do not cache route instances:
                     a retained dashboard instance can mask the next route after a
                     role change or a realtime refresh. -->
                <component :is="Component" :key="`${route.fullPath}:${syncRevision}`" />
            </RouterView>
        </PageContainer>
        <template #mobile-navigation
            ><MobileBottomNav :items="mobileItems" :active-path="route.path"
        /></template>
    </AppShell>
</template>
