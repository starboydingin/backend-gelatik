import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api, clearApiCache, payload } from '../lib/api'

export const useAuthStore = defineStore('auth', () => {
    function storedUser() {
        try {
            return JSON.parse(sessionStorage.getItem('gelatik_user') || 'null')
        } catch {
            sessionStorage.removeItem('gelatik_user')
            return null
        }
    }

    // Per-tab authentication allows user and admin monitoring in separate tabs.
    const token = ref(sessionStorage.getItem('gelatik_token'))
    const user = ref(storedUser())
    const sessionChecked = ref(false)
    const authenticated = computed(() => Boolean(token.value))
    const roles = computed(() => {
        const assigned = Array.isArray(user.value?.roles) ? user.value.roles : []
        const legacy = user.value?.role ? [user.value.role] : []
        return [...assigned, ...legacy]
            .map((role) => (typeof role === 'string' ? role : role?.name))
            .map((role) =>
                String(role || '')
                    .trim()
                    .toLowerCase()
            )
            .filter(Boolean)
            .filter((role, index, all) => all.indexOf(role) === index)
    })
    const isAdmin = computed(() =>
        roles.value.some((role) => ['admin', 'superadmin'].includes(role))
    )
    const isSuperAdmin = computed(() => roles.value.includes('superadmin'))
    const isBkd = computed(() => roles.value.includes('bkd'))
    const portalHome = computed(() => {
        if (isBkd.value) return '/bkd/dashboard'
        return isAdmin.value ? '/admin/dashboard' : '/app/dashboard'
    })

    function save(data) {
        if (!data?.access_token || !data?.user) {
            throw new Error('Respons autentikasi tidak lengkap.')
        }
        clearApiCache()
        token.value = data.access_token
        user.value = data.user
        sessionStorage.setItem('gelatik_token', token.value)
        sessionStorage.setItem('gelatik_user', JSON.stringify(user.value))
    }

    async function login(credentials) {
        save(payload(await api.post('/login', credentials)))
    }
    async function loadUser() {
        if (!token.value) {
            sessionChecked.value = true
            return
        }
        user.value = payload(await api.get('/me'))
        if (!user.value || typeof user.value !== 'object') {
            throw new Error('Data sesi pengguna tidak valid.')
        }
        sessionStorage.setItem('gelatik_user', JSON.stringify(user.value))
        sessionChecked.value = true
    }
    async function logout() {
        try {
            await api.post('/logout')
        } finally {
            clearApiCache()
            token.value = null
            user.value = null
            sessionChecked.value = true
            sessionStorage.removeItem('gelatik_token')
            sessionStorage.removeItem('gelatik_user')
        }
    }
    return {
        token,
        user,
        sessionChecked,
        authenticated,
        roles,
        isAdmin,
        isSuperAdmin,
        isBkd,
        portalHome,
        login,
        loadUser,
        logout,
        save,
    }
})
