const dateOnlyPattern = /^(\d{4})-(\d{2})-(\d{2})$/
const JAKARTA_TIME_ZONE = 'Asia/Jakarta'

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
              timeZone: JAKARTA_TIME_ZONE,
          }).format(date)
        : '-'
}

export function formatDateTime(value) {
    const date = toDate(value)
    if (!date) return '-'
    const time = new Intl.DateTimeFormat('id-ID', {
        hour: '2-digit',
        minute: '2-digit',
        hourCycle: 'h23',
        timeZone: JAKARTA_TIME_ZONE,
    })
        .format(date)
        .replace(':', '.')
    return `${formatDate(date)}, ${time} WIB`
}

export function formatLoanSchedule(date, time) {
    const formatted = formatDate(date)
    return time ? `${formatted}, ${String(time).slice(0, 5).replace(':', '.')} WIB` : formatted
}
