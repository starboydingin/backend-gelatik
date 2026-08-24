import { io } from 'socket.io-client'

const enabled = import.meta.env.VITE_ENABLE_REALTIME === 'true'
const realtimeUrl = import.meta.env.VITE_REALTIME_URL
let socket = null
const notificationEvents = [
    'notification',
    'konsultasi.created',
    'konsultasi.responded',
    'konsultasi.status_changed',
    'pinjam.created',
    'pinjam.status_changed',
    'usulan_email.created',
    'usulan_email.status_changed',
    'chatbot.conversation.created',
    'chatbot.conversation.updated',
    'chatbot.conversation.deleted',
    'chatbot.message.created',
]

function notify(payload) {
    window.dispatchEvent(new CustomEvent('gelatik:notification', { detail: payload }))
    if (String(payload?.type || '').startsWith('chatbot.')) {
        window.dispatchEvent(new CustomEvent('gelatik:chatbot', { detail: payload }))
    }
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

    return socket
}

export function disconnectRealtime() {
    notificationEvents.forEach((eventName) => socket?.off(eventName, notify))
    socket?.disconnect()
    socket = null
}

export const realtimeEnabled = enabled
