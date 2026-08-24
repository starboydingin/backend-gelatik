export function notificationRoute(notification, admin = false) {
    const type = String(notification.resource_type || notification.type || '').toLowerCase()
    const id = notification.resource_id || notification.item_id
    if (!id) return admin ? '/admin/notifikasi' : '/app/notifikasi'

    if (type.includes('konsult')) return `${admin ? '/admin' : '/app'}/konsultasi/${id}`
    if (type.includes('pinjam'))
        return admin ? `/admin/peminjaman/${id}/kelola` : `/app/peminjaman/${id}`
    if (type.includes('email')) return `${admin ? '/admin' : '/app'}/email-resmi/${id}`
    return admin ? '/admin/notifikasi' : '/app/notifikasi'
}
