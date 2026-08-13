import axios from 'axios'

export const api = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api',
    headers: { Accept: 'application/json' },
    timeout: 15000,
})

api.interceptors.request.use((config) => {
    const token = sessionStorage.getItem('gelatik_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
    return config
})

api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            sessionStorage.removeItem('gelatik_token')
            sessionStorage.removeItem('gelatik_user')
            if (!location.pathname.startsWith('/login')) location.assign('/login')
        }
        return Promise.reject(error)
    }
)

export const payload = (response) => response.data?.data ?? response.data
export const rows = (value) => value?.data ?? (Array.isArray(value) ? value : [])
export const errorMessage = (error) => {
    if (error.code === 'ECONNABORTED') return 'Permintaan terlalu lama. Silakan coba kembali.'
    if (!error.response)
        return 'Tidak dapat terhubung ke layanan. Periksa koneksi Anda lalu coba lagi.'
    const errors = error.response?.data?.errors
    if (errors) return Object.values(errors).flat().join(' ')
    if (error.response.status === 403)
        return 'Anda tidak memiliki izin untuk melakukan tindakan ini.'
    if (error.response.status >= 500)
        return 'Layanan sedang mengalami gangguan. Silakan coba beberapa saat lagi.'
    return error.response?.data?.message || 'Layanan belum dapat dihubungi. Silakan coba lagi.'
}
