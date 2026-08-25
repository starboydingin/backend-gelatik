import axios from 'axios'

export const api = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api',
    headers: { Accept: 'application/json' },
    timeout: 15000,
})

// Per-tab cache for GET requests. It makes returning to a page immediate while
// keeping every account isolated and avoiding persistent sensitive data.
const readCache = new Map()
let cacheEpoch = 0
// Read data is safe to retain briefly: every successful mutation clears this
// cache, while a longer TTL prevents the same page from repeatedly competing
// for the local Laravel worker during normal navigation.
const defaultReadTtl = 60_000
const staleIfErrorTtl = 5 * 60_000
const cachePolicies = [
    { match: /^(\/dashboard|\/admin\/dashboard)$/, ttl: 30_000 },
    { match: /^\/notifications/, ttl: 20_000 },
    { match: /^\/chatbot/, ttl: 20_000 },
    {
        match: /^(\/faq|\/topik|\/items?|\/opd|\/pengumuman|\/slider|\/list-router-opd)/,
        ttl: 5 * 60_000,
    },
]
const resourceEndpointPrefixes = {
    peminjaman: ['/pinjam', '/dashboard', '/laporan/peminjaman'],
    konsultasi: ['/konsul', '/dashboard', '/laporan/konsultasi'],
    usulan_email: ['/pengajuan-email', '/pegawai', '/dashboard', '/laporan/usulan-email'],
    notification: ['/notifications', '/dashboard'],
    kritik_saran: ['/kritik-saran', '/notifications'],
    rating: ['/rating', '/dashboard'],
    user: ['/me', '/dashboard'],
    whatsapp_subscription: ['/notifikasi/wa', '/dashboard'],
    faq: ['/faq'],
    mastertopik: ['/topik', '/faq'],
    masteritem: ['/items', '/item', '/dashboard'],
    router: ['/list-router-opd'],
    routerlist: ['/list-router-opd'],
    pengumuman: ['/pengumuman', '/dashboard'],
    slider: ['/slider', '/dashboard'],
    settings: ['/admin/settings', '/dashboard'],
    insights: ['/dashboard'],
}
const cacheKey = (url, config = {}) =>
    JSON.stringify([url, config.params || {}, sessionStorage.getItem('gelatik_token') || ''])
const rawGet = api.get.bind(api)

export async function cachedGet(url, config = {}, ttl = defaultReadTtl) {
    const key = cacheKey(url, config)
    const cached = readCache.get(key)
    if (cached && Date.now() - cached.createdAt < ttl) return cached.response

    const requestEpoch = cacheEpoch
    const request = rawGet(url, config)
    const pendingEntry = { createdAt: Date.now(), response: request }
    readCache.set(key, pendingEntry)
    try {
        const response = await request
        // A realtime event or mutation may invalidate this request while it is
        // still in flight. Never let that older response repopulate the cache.
        if (cacheEpoch === requestEpoch && readCache.get(key) === pendingEntry) {
            readCache.set(key, { createdAt: Date.now(), response })
        }
        return response
    } catch (error) {
        const mayUseStale =
            !error.response || error.code === 'ECONNABORTED' || error.response?.status >= 500
        const staleResponse = cached?.response
        const staleIsResolved = staleResponse && typeof staleResponse.then !== 'function'
        if (
            cacheEpoch === requestEpoch &&
            readCache.get(key) === pendingEntry &&
            mayUseStale &&
            staleIsResolved &&
            Date.now() - cached.createdAt < staleIfErrorTtl
        ) {
            readCache.set(key, cached)
            return staleResponse
        }
        if (readCache.get(key) === pendingEntry) readCache.delete(key)
        throw error
    }
}

function cachedTtl(url, explicitTtl) {
    if (Number.isFinite(explicitTtl)) return explicitTtl
    return cachePolicies.find((policy) => policy.match.test(url))?.ttl || defaultReadTtl
}

export function realtimeResource(payload = {}) {
    const type = String(payload.type || '').toLowerCase()
    if (type === 'insights.sync') return 'insights'
    const fromPayload = String(payload.resource || '')
        .trim()
        .toLowerCase()
    if (fromPayload) return fromPayload.replace(/[\s-]/g, '_')
    if (type.startsWith('pinjam.')) return 'peminjaman'
    if (type.startsWith('konsultasi.')) return 'konsultasi'
    if (type.startsWith('usulan_email.')) return 'usulan_email'
    if (type === 'notification') return 'notification'
    if (type === 'insights.sync') return 'insights'
    return ''
}

export function invalidateApiCache(prefix = '') {
    cacheEpoch += 1
    for (const key of readCache.keys()) {
        if (!prefix) {
            readCache.delete(key)
            continue
        }
        try {
            const [url] = JSON.parse(key)
            if (url === prefix || url.startsWith(`${prefix}/`)) readCache.delete(key)
        } catch {
            // A malformed in-memory key must never retain potentially stale data.
            readCache.delete(key)
        }
    }
}

/** Invalidate only REST reads that can be affected by a realtime event. */
export function invalidateRealtimeResource(payload = {}) {
    const resource = realtimeResource(payload)
    if (!resource || resource === 'session') {
        invalidateApiCache()
        return resource
    }
    const prefixes = resourceEndpointPrefixes[resource]
    if (!prefixes) {
        invalidateApiCache()
        return resource
    }
    for (const prefix of prefixes) invalidateApiCache(prefix)
    return resource
}

export function clearApiCache() {
    invalidateApiCache()
}

// Existing pages can keep using api.get(). Dynamic data uses a short TTL;
// pages that need a longer cache still call cachedGet(url, config, ttl).
api.get = (url, config = {}) => {
    const { cache = true, cacheTtl, ...requestConfig } = config
    return cache
        ? cachedGet(url, requestConfig, cachedTtl(url, cacheTtl))
        : rawGet(url, requestConfig)
}

api.interceptors.request.use((config) => {
    const token = sessionStorage.getItem('gelatik_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
    if (!['get', 'head', 'options'].includes(config.method?.toLowerCase())) {
        // Clear before a mutation as well as after it succeeds. This prevents
        // an older GET that finishes during the write from being shown later.
        clearApiCache()
    }
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
