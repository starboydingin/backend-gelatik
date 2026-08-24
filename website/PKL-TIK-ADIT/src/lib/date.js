const dateOnlyPattern = /^(\d{4})-(\d{2})-(\d{2})$/

function toDate(value) {
    if (!value) return null
    const text = String(value).trim()
    const match = text.match(dateOnlyPattern)
    if (match) return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
    const parsed = new Date(text)
    return Number.isNaN(parsed.getTime()) ? null : parsed
}

export function formatDate(value) {
    const date = toDate(value)
    return date
        ? new Intl.DateTimeFormat('id-ID', {
              day: '2-digit',
              month: 'long',
              year: 'numeric',
          }).format(date)
        : '-'
}

export function formatDateTime(value) {
    const date = toDate(value)
    return date
        ? new Intl.DateTimeFormat('id-ID', {
              day: '2-digit',
              month: 'long',
              year: 'numeric',
              hour: '2-digit',
              minute: '2-digit',
          }).format(date)
        : '-'
}

export function formatLoanSchedule(date, time) {
    const formatted = formatDate(date)
    return time ? `${formatted}, ${String(time).slice(0, 5)} WIB` : formatted
}
