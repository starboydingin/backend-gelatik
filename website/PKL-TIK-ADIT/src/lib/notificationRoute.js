/**
 * Resolves both current and legacy notification records to an existing Vue
 * route. Older rows only have `type`/`item_id`, so do not assume that the
 * newer `resource_*` accessors are present in every API response.
 */
export function notificationRoute(notification, admin = false) {
    const type = String(
        notification.resource_type || notification.type || notification.jenis || ''
    )
        .trim()
        .toLowerCase()
    const content = `${notification.judul || ''} ${notification.message || ''}`.toLowerCase()
    const rawId = notification.resource_id ?? notification.item_id
    const id = Number(rawId)
    const prefix = admin ? '/admin' : '/app'

    // A resource link is only valid for a persisted positive primary key.
    // Broadcast/informational notifications intentionally remain in the inbox.
    if (!Number.isInteger(id) || id < 1) return `${prefix}/notifikasi`

    const describes = (...terms) =>
        terms.some((term) => type.includes(term) || content.includes(term))

    if (describes('konsultasi', 'konsul')) return `${prefix}/konsultasi/${id}`
    if (describes('peminjaman', 'pinjam')) {
        return admin ? `${prefix}/peminjaman/${id}/kelola` : `${prefix}/peminjaman/${id}`
    }
    if (describes('usulan_email', 'email resmi', 'usulan email')) {
        return `${prefix}/email-resmi/${id}`
    }
    if (describes('kritik_saran', 'kritik', 'saran', 'feedback')) {
        return admin ? `${prefix}/kritik-saran` : `${prefix}/umpan-balik`
    }

    return `${prefix}/notifikasi`
}
