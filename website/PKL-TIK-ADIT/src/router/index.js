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
        path: '/app',
        component: () => import('../layouts/AppLayout.vue'),
        meta: { auth: true },
        children: [
            { path: '', redirect: '/app/dashboard' },
            { path: 'dashboard', component: () => import('../views/user/UserDashboard.vue') },
            { path: 'kalender', component: () => import('../views/user/CalendarView.vue') },
            { path: 'pengumuman', component: () => import('../views/user/AnnouncementsView.vue') },
            { path: 'peminjaman', component: () => import('../views/shared/PeminjamanView.vue') },
            { path: 'konsultasi', component: () => import('../views/shared/KonsultasiView.vue') },
            { path: 'email-resmi', component: () => import('../views/shared/EmailView.vue') },
            { path: 'notifikasi', component: () => import('../views/user/NotificationsView.vue') },
            { path: 'faq', component: () => import('../views/user/FaqView.vue') },
            { path: 'router', component: () => import('../views/user/RouterView.vue') },
            { path: 'rating', component: () => import('../views/user/RatingView.vue') },
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
            { path: 'konsultasi', component: () => import('../views/shared/KonsultasiView.vue') },
            { path: 'email-resmi', component: () => import('../views/shared/EmailView.vue') },
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
                component: () => import('../views/admin/LoanReportView.vue'),
            },
            { path: 'pengumuman', component: () => import('../views/admin/AnnouncementsView.vue') },
            {
                path: 'referensi-layanan',
                component: () => import('../views/admin/ServiceCatalogView.vue'),
            },
        ],
    },
    { path: '/:pathMatch(.*)*', redirect: '/' },
]

const router = createRouter({
    history: createWebHistory(),
    routes,
    scrollBehavior: () => ({ top: 0 }),
})
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
})
export default router
