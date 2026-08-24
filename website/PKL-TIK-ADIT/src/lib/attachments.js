import { api } from './api'

export async function openProtectedAttachment(endpoint) {
    const previewWindow = window.open('', '_blank')
    if (previewWindow) previewWindow.opener = null
    try {
        const response = await api.get(endpoint, { cache: false, responseType: 'blob' })
        const url = URL.createObjectURL(response.data)
        if (previewWindow) previewWindow.location.href = url
        else window.open(url, '_blank', 'noopener,noreferrer')
        window.setTimeout(() => URL.revokeObjectURL(url), 60_000)
    } catch (error) {
        previewWindow?.close()
        throw error
    }
}
