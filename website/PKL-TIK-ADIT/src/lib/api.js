import axios from 'axios'

export const api = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api',
    headers: { Accept: 'application/json' },
    timeout: 15000,
})

// Per-tab cache for GET requests. It makes returning to a page immediate while
// keeping every account isolated and avoiding persistent sensitive data.
const readCache = new Map()
// Read data is safe to retain briefly: every successful mutation clears this
// cache, while a longer TTL prevents the same page from repeatedly competing
// for the local Laravel worker during normal navigation.
const defaultReadTtl = 90_000
const staleIfErrorTtl = 5 * 60_000
const cacheKey = (url, config = {}) =>
    JSON.stringify([url, config.params || {}, sessionStorage.getItem('gelatik_token') || ''])
const rawGet = api.get.bind(api)

export async function cachedGet(url, config = {}, ttl = defaultReadTtl) {
    const key = cacheKey(url, config)
    const cached = readCache.get(key)
    if (cached && Date.now() - cached.createdAt < ttl) return cached.response

    const request = rawGet(url, config)
    readCache.set(key, { createdAt: Date.now(), response: request })
    try {
        const response = await request
        readCache.set(key, { createdAt: Date.now(), response })
        return response
    } catch (error) {
        const mayUseStale =
            !error.response || error.code === 'ECONNABORTED' || error.response?.status >= 500
        const staleResponse = cached?.response
        const staleIsResolved = staleResponse && typeof staleResponse.then !== 'function'
        if (
            mayUseStale &&
            staleIsResolved &&
            Date.now() - cached.createdAt < staleIfErrorTtl
        ) {
            readCache.set(key, cached)
            return staleResponse
        }
        readCache.delete(key)
        throw error
    }
}

export function invalidateApiCache(prefix = '') {
    for (const key of readCache.keys()) {
        if (!prefix || key.includes(`\"${prefix}\"`)) readCache.delete(key)
    }
}

export function clearApiCache() {
    invalidateApiCache()
}

// Existing pages can keep using api.get(). Dynamic data uses a short TTL;
// pages that need a longer cache still call cachedGet(url, config, ttl).
api.get = (url, config = {}) => {
    const { cache = true, cacheTtl = defaultReadTtl, ...requestConfig } = config
    return cache ? cachedGet(url, requestConfig, cacheTtl) : rawGet(url, requestConfig)
}

api.interceptors.request.use((config) => {
    const token = sessionStorage.getItem('gelatik_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
    return config
})

api.interceptors.response.use(
    (response) => {
        if (!['get', 'head', 'options'].includes(response.config.method?.toLowerCase())) {
            clearApiCache()
        }
        return response
    },
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
