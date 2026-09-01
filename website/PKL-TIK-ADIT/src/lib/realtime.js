import { io } from 'socket.io-client'
import { invalidateRealtimeResource } from './api'

const enabled = import.meta.env.VITE_ENABLE_REALTIME === 'true'
const realtimeUrl = import.meta.env.VITE_REALTIME_URL
let socket = null
const syncTimers = new Map()
const seenEventIds = new Set()
const seenEventOrder = []
let hasConnected = false
const notificationEvents = [
    'notification',
    'pengumuman.created',
    'konsultasi.created',
    'konsultasi.responded',
    'konsultasi.status_changed',
    'pinjam.created',
    'pinjam.status_changed',
    'usulan_email.created',
    'usulan_email.verified',
    'usulan_email.status_changed',
    'kritik_saran.created',
    'data.sync',
    'insights.sync',
    'chatbot.conversation.created',
    'chatbot.conversation.updated',
    'chatbot.conversation.deleted',
    'chatbot.message.created',
]

function dispatchDataSync(payload) {
    const resource = invalidateRealtimeResource(payload)
    if (!resource || resource === 'session') return
    const existingTimer = syncTimers.get(resource)
    if (existingTimer) window.clearTimeout(existingTimer)
    syncTimers.set(
        resource,
        window.setTimeout(() => {
            window.dispatchEvent(new CustomEvent('gelatik:data-sync', { detail: payload }))
            syncTimers.delete(resource)
        }, 120)
    )
}

function notify(payload) {
    const eventId = String(payload?.event_id || '').trim()
    if (eventId && seenEventIds.has(eventId)) return
    if (eventId) {
        seenEventIds.add(eventId)
        seenEventOrder.push(eventId)
        if (seenEventOrder.length > 300) seenEventIds.delete(seenEventOrder.shift())
    }
    dispatchDataSync(payload)
    window.dispatchEvent(new CustomEvent('gelatik:notification', { detail: payload }))
    if (String(payload?.type || '').startsWith('chatbot.')) {
        window.dispatchEvent(new CustomEvent('gelatik:chatbot', { detail: payload }))
    }
}

function resyncAfterConnect() {
    // Socket.IO reconnects do not replay missed events. Re-fetch the current
    // user's authorized data after a reconnect. The first connection must not
    // remount a page whose initial request is still running.
    if (hasConnected) window.dispatchEvent(new CustomEvent('gelatik:reconnected'))
    hasConnected = true
}

function reportConnectionError(error) {
    console.warn('Koneksi realtime belum tersedia:', error?.message || 'unknown error')
}

/**
 * All VITE_* values are bundled into browser code. Store only public URLs and
 * feature flags here—never backend credentials, API keys, or long-lived tokens.
 */
export function connectRealtime(token) {
    if (!enabled || !realtimeUrl || socket) return socket

    socket = io(realtimeUrl, {
        // Socket service adds the HTTP Bearer scheme when verifying this token
        // against Laravel. Sending the raw access token avoids "Bearer Bearer".
        auth: token ? { token } : undefined,
        transports: ['websocket', 'polling'],
    })

    notificationEvents.forEach((eventName) => socket.on(eventName, notify))
    socket.on('connect', resyncAfterConnect)
    socket.on('connect_error', reportConnectionError)

    return socket
}

export function disconnectRealtime() {
    notificationEvents.forEach((eventName) => socket?.off(eventName, notify))
    socket?.off('connect', resyncAfterConnect)
    socket?.off('connect_error', reportConnectionError)
    socket?.disconnect()
    socket = null
    hasConnected = false
    for (const timer of syncTimers.values()) window.clearTimeout(timer)
    syncTimers.clear()
    seenEventIds.clear()
    seenEventOrder.length = 0
}

export const realtimeEnabled = enabled
