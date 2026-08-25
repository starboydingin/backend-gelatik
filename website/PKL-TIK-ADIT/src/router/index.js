import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
    { path: '/', component: () => import('../views/LandingView.vue') },
    { path: '/login', component: () => import('../views/LoginView.vue'), meta: { guest: true } },
    {
        path: '/register',
        component: () => import('../views/RegisterView.vue'),
        meta: { guest: true },
    },
    {
        path: '/forgot-password',
        component: () => import('../views/ForgotPasswordView.vue'),
        meta: { guest: true },
    },
    {
        path: '/reset-password',
        component: () => import('../views/ResetPasswordView.vue'),
        meta: { guest: true },
    },
    {
        path: '/verify-reset-otp',
        component: () => import('../views/OtpVerificationView.vue'),
        meta: { guest: true },
    },
    {
        path: '/app',
        component: () => import('../layouts/AppLayout.vue'),
        meta: { auth: true, userPortal: true },
        children: [
            { path: '', redirect: '/app/dashboard' },
            { path: 'dashboard', component: () => import('../views/user/UserDashboard.vue') },
            { path: 'kalender', component: () => import('../views/user/CalendarView.vue') },
            { path: 'pengumuman', component: () => import('../views/user/AnnouncementsView.vue') },
            { path: 'peminjaman', component: () => import('../views/shared/PeminjamanView.vue') },
            {
                path: 'peminjaman/:id',
                component: () => import('../views/shared/PeminjamanDetailView.vue'),
            },
            { path: 'konsultasi', component: () => import('../views/shared/KonsultasiView.vue') },
            {
                path: 'konsultasi/:id',
                component: () => import('../views/shared/KonsultasiDetailView.vue'),
            },
            { path: 'email-resmi', component: () => import('../views/shared/EmailView.vue') },
            {
                path: 'email-resmi/:id',
                component: () => import('../views/shared/EmailDetailView.vue'),
            },
            { path: 'notifikasi', component: () => import('../views/user/NotificationsView.vue') },
            { path: 'faq', component: () => import('../views/user/FaqView.vue') },
            { path: 'router', component: () => import('../views/user/RouterView.vue') },
            {
                path: 'rating',
                component: () => import('../views/user/RatingView.vue'),
                meta: { feedbackFlow: true },
            },
            { path: 'whatsapp', component: () => import('../views/user/WhatsappView.vue') },
            { path: 'chatbot', component: () => import('../views/user/ChatbotView.vue') },
            { path: 'profil', component: () => import('../views/user/ProfileView.vue') },
            { path: 'umpan-balik', component: () => import('../views/user/FeedbackView.vue') },
        ],
    },
    {
        path: '/admin',
        component: () => import('../layouts/AppLayout.vue'),
        meta: { auth: true, admin: true },
        children: [
            { path: '', redirect: '/admin/dashboard' },
            { path: 'dashboard', component: () => import('../views/admin/AdminDashboard.vue') },
            { path: 'peminjaman', component: () => import('../views/shared/PeminjamanView.vue') },
            {
                path: 'peminjaman/:id/kelola',
                component: () => import('../views/admin/LoanManagementView.vue'),
            },
            { path: 'konsultasi', component: () => import('../views/shared/KonsultasiView.vue') },
            {
                path: 'konsultasi/:id',
                component: () => import('../views/shared/KonsultasiDetailView.vue'),
            },
            { path: 'email-resmi', component: () => import('../views/shared/EmailView.vue') },
            {
                path: 'email-resmi/:id',
                component: () => import('../views/shared/EmailDetailView.vue'),
            },
            { path: 'pengguna', component: () => import('../views/admin/UsersView.vue') },
            { path: 'peran', component: () => import('../views/admin/RolesView.vue') },
            {
                path: 'notifikasi',
                component: () => import('../views/admin/AdminNotificationsView.vue'),
            },
            {
                path: 'kritik-saran',
                component: () => import('../views/admin/AdminFeedbackView.vue'),
            },
            { path: 'pengaturan', component: () => import('../views/admin/SettingsView.vue') },
            { path: 'pegawai', component: () => import('../views/admin/EmployeesView.vue') },
            {
                path: 'laporan-peminjaman',
                component: () => import('../views/admin/ServiceReportsView.vue'),
                meta: { reportType: 'peminjaman' },
            },
            {
                path: 'laporan-konsultasi',
                component: () => import('../views/admin/ServiceReportsView.vue'),
                meta: { reportType: 'konsultasi' },
            },
            {
                path: 'laporan-email',
                component: () => import('../views/admin/ServiceReportsView.vue'),
                meta: { reportType: 'usulan-email' },
            },
            { path: 'pengumuman', component: () => import('../views/admin/AnnouncementsView.vue') },
            {
                path: 'referensi-layanan',
                component: () => import('../views/admin/ServiceCatalogView.vue'),
            },
        ],
    },
    { path: '/:pathMatch(.*)*', component: () => import('../views/NotFoundView.vue') },
]

const router = createRouter({
    history: createWebHistory(),
    routes,
    scrollBehavior: () => ({ top: 0 }),
})

// Route components are lazy loaded. When a browser still holds an old HTML
// shell after a new Vite build, its old chunk name no longer exists and a
// navigation can appear to stay on the dashboard. Recover once per URL,
// without hiding genuine routing errors in a reload loop.
const staleRouteRecoveryKey = 'gelatik_stale_route_recovery'
router.onError((error, to) => {
    const message = String(error?.message || error || '')
    const isStaleChunk =
        /failed to fetch dynamically imported module|importing a module script failed|loading chunk/i.test(
            message
        )
    if (!isStaleChunk) {
        console.error('Navigasi halaman gagal dimuat.', error)
        return
    }

    const recoveryTarget = to?.fullPath || window.location.pathname
    if (sessionStorage.getItem(staleRouteRecoveryKey) === recoveryTarget) {
        console.error('Berkas halaman terbaru masih belum dapat dimuat.', error)
        return
    }
    sessionStorage.setItem(staleRouteRecoveryKey, recoveryTarget)
    window.location.assign(recoveryTarget)
})
router.afterEach(() => sessionStorage.removeItem(staleRouteRecoveryKey))

router.beforeEach(async (to) => {
    const auth = useAuthStore()
    if (to.meta.auth && !auth.authenticated)
        return `/login?redirect=${encodeURIComponent(to.fullPath)}`
    if (to.meta.auth && !auth.sessionChecked) {
        try {
            await auth.loadUser()
        } catch {
            return `/login?redirect=${encodeURIComponent(to.fullPath)}`
        }
    }
    if (to.meta.guest && auth.authenticated)
        return auth.isAdmin ? '/admin/dashboard' : '/app/dashboard'
    if (to.meta.admin) {
        if (!auth.isAdmin) return '/app/dashboard'
    }
    if (to.meta.userPortal && auth.isAdmin) return '/admin/dashboard'
    if (to.meta.feedbackFlow && !/^\d+$/.test(String(to.query.feedback_id || '')))
        return '/app/umpan-balik'
})
export default router
