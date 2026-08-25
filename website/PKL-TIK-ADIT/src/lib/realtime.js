import { io } from 'socket.io-client'
import { invalidateRealtimeResource } from './api'

const enabled = import.meta.env.VITE_ENABLE_REALTIME === 'true'
const realtimeUrl = import.meta.env.VITE_REALTIME_URL
let socket = null
let syncTimer = null
const notificationEvents = [
    'notification',
    'konsultasi.created',
    'konsultasi.responded',
    'konsultasi.status_changed',
    'pinjam.created',
    'pinjam.status_changed',
    'usulan_email.created',
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
    invalidateRealtimeResource(payload)
    if (syncTimer) window.clearTimeout(syncTimer)
    syncTimer = window.setTimeout(() => {
        window.dispatchEvent(new CustomEvent('gelatik:data-sync', { detail: payload }))
        syncTimer = null
    }, 120)
}

function notify(payload) {
    dispatchDataSync(payload)
    window.dispatchEvent(new CustomEvent('gelatik:notification', { detail: payload }))
    if (String(payload?.type || '').startsWith('chatbot.')) {
        window.dispatchEvent(new CustomEvent('gelatik:chatbot', { detail: payload }))
    }
}

function resyncAfterConnect() {
    // Socket.IO reconnects do not replay missed events. Re-fetch the current
    // user's authorized data once the transport is available again.
    dispatchDataSync({ type: 'data.sync', resource: 'session' })
}

/**
 * All VITE_* values are bundled into browser code. Store only public URLs and
 * feature flags here—never backend credentials, API keys, or long-lived tokens.
 */
export function connectRealtime(token) {
    if (!enabled || !realtimeUrl || socket) return socket

    socket = io(realtimeUrl, {
        auth: token ? { token: `Bearer ${token}` } : undefined,
        transports: ['websocket', 'polling'],
    })

    notificationEvents.forEach((eventName) => socket.on(eventName, notify))
    socket.on('connect', resyncAfterConnect)

    return socket
}

export function disconnectRealtime() {
    notificationEvents.forEach((eventName) => socket?.off(eventName, notify))
    socket?.off('connect', resyncAfterConnect)
    socket?.disconnect()
    socket = null
    if (syncTimer) window.clearTimeout(syncTimer)
    syncTimer = null
}

/** Reconcile stale reads when a background browser tab becomes visible again. */
export function reconcileRealtime() {
    dispatchDataSync({ type: 'data.sync', resource: 'session' })
}

export const realtimeEnabled = enabled
