import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api, payload } from '../lib/api'

export const useAuthStore = defineStore('auth', () => {
    const token = ref(localStorage.getItem('gelatik_token'))
    const user = ref(JSON.parse(localStorage.getItem('gelatik_user') || 'null'))
    const sessionChecked = ref(false)
    const authenticated = computed(() => Boolean(token.value))
    const roles = computed(() =>
        (user.value?.roles || []).map((role) => (typeof role === 'string' ? role : role.name))
    )
    const isAdmin = computed(() =>
        roles.value.some((role) => ['admin', 'superadmin'].includes(role))
    )
    const isSuperAdmin = computed(() => roles.value.includes('superadmin'))

    function save(data) {
        token.value = data.access_token
        user.value = data.user
        localStorage.setItem('gelatik_token', token.value)
        localStorage.setItem('gelatik_user', JSON.stringify(user.value))
    }

    async function login(credentials) {
        save(payload(await api.post('/login', credentials)))
    }
    async function loadUser() {
        if (!token.value) return
        user.value = payload(await api.get('/me'))
        localStorage.setItem('gelatik_user', JSON.stringify(user.value))
        sessionChecked.value = true
    }
    async function logout() {
        try {
            await api.post('/logout')
        } finally {
            token.value = null
            user.value = null
            localStorage.removeItem('gelatik_token')
            localStorage.removeItem('gelatik_user')
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
        login,
        loadUser,
        logout,
        save,
    }
})
