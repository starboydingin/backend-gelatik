<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { connectRealtime, disconnectRealtime } from '../lib/realtime'
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
    open = ref(false)
const userItems = [
    { label: 'Dashboard', to: '/app/dashboard', icon: HomeIcon, group: 'Portal layanan' },
    {
        label: 'Konsultasi TIK',
        to: '/app/konsultasi',
        icon: ChatBubbleLeftRightIcon,
        group: 'Portal layanan',
    },
    { label: 'Kalender', to: '/app/kalender', icon: CalendarDaysIcon, group: 'Portal layanan' },
    { label: 'Peminjaman', to: '/app/peminjaman', icon: BriefcaseIcon, group: 'Portal layanan' },
    { label: 'Usulan Email', to: '/app/email-resmi', icon: EnvelopeIcon, group: 'Portal layanan' },
    { label: 'Router OPD', to: '/app/router', icon: WifiIcon, group: 'Portal layanan' },
    {
        label: 'Kritik & Saran',
        to: '/app/umpan-balik',
        icon: ChatBubbleBottomCenterTextIcon,
        group: 'Portal layanan',
    },
    { label: 'Pengumuman', to: '/app/pengumuman', icon: MegaphoneIcon, group: 'Portal layanan' },
    { label: 'Notifikasi', to: '/app/notifikasi', icon: BellIcon, group: 'Akun & bantuan' },
    { label: 'FAQ', to: '/app/faq', icon: QuestionMarkCircleIcon, group: 'Akun & bantuan' },
    { label: 'Rating', to: '/app/rating', icon: StarIcon, group: 'Akun & bantuan' },
    {
        label: 'WhatsApp',
        to: '/app/whatsapp',
        icon: DevicePhoneMobileIcon,
        group: 'Akun & bantuan',
    },
    { label: 'Chatbot', to: '/app/chatbot', icon: SparklesIcon, group: 'Akun & bantuan' },
    { label: 'Profil', to: '/app/profil', icon: UserCircleIcon, group: 'Akun & bantuan' },
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
        group: 'Layanan',
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
    { label: 'Pengaturan', to: '/admin/pengaturan', icon: Cog6ToothIcon, group: 'Sistem' },
]
const adminArea = computed(() => route.path.startsWith('/admin'))
const items = computed(() => (adminArea.value ? adminItems : userItems))
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
onMounted(() => connectRealtime(auth.token))
onBeforeUnmount(disconnectRealtime)
</script>

<template>
    <AppShell>
        <template #sidebar
            ><div
                v-if="open"
                class="fixed inset-0 z-30 bg-slate-950/45 lg:hidden"
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
            ><AppHeader
                :user="auth.user"
                :subtitle="auth.roles.join(', ')"
                :admin-area="adminArea"
                @menu="open = true"
        /></template>
        <PageContainer><RouterView /></PageContainer>
        <template #mobile-navigation
            ><MobileBottomNav :items="mobileItems" :active-path="route.path"
        /></template>
    </AppShell>
</template>
