import { io } from 'socket.io-client'

const enabled = import.meta.env.VITE_ENABLE_REALTIME === 'true'
const realtimeUrl = import.meta.env.VITE_REALTIME_URL
let socket = null

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

    socket.on('notification', (payload) => {
        window.dispatchEvent(new CustomEvent('gelatik:notification', { detail: payload }))
    })

    return socket
}

export function disconnectRealtime() {
    socket?.off('notification')
    socket?.disconnect()
    socket = null
}

export const realtimeEnabled = enabled
