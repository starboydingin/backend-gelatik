<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, errorMessage, rows } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import { useAuthStore } from '../../stores/auth'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'
import ScheduleCalendar from '../../components/ScheduleCalendar.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import StatusBadge from '../../components/StatusBadge.vue'
import DashboardBarChart from '../../components/DashboardBarChart.vue'
import DashboardRatingCard from '../../components/DashboardRatingCard.vue'
import DashboardPieCharts from '../../components/DashboardPieCharts.vue'
import {
    BriefcaseIcon,
    ChatBubbleLeftRightIcon,
    EnvelopeIcon,
    BellIcon,
} from '@heroicons/vue/24/outline'

const auth = useAuthStore()
const data = ref({}),
    events = ref([]),
    announcements = ref([]),
    calendarLoading = ref(false),
    loading = ref(true),
    error = ref('')
const cards = [
    {
        label: 'Peminjaman aktif',
        key: 'peminjaman_aktif',
        to: '/app/peminjaman',
        icon: BriefcaseIcon,
        tone: 'bg-violet-50 text-violet-600',
    },
    {
        label: 'Konsultasi berjalan',
        key: 'konsultasi_aktif',
        to: '/app/konsultasi',
        icon: ChatBubbleLeftRightIcon,
        tone: 'bg-sky-50 text-sky-600',
    },
    {
        label: 'Usulan email',
        key: 'usulan_email',
        to: '/app/email-resmi',
        icon: EnvelopeIcon,
        tone: 'bg-orange-50 text-orange-600',
    },
    {
        label: 'Notifikasi baru',
        key: 'notifikasi_belum_dibaca',
        to: '/app/notifikasi',
        icon: BellIcon,
        tone: 'bg-emerald-50 text-emerald-600',
    },
]
const recentGroups = [
    { label: 'Konsultasi terbaru', key: 'konsultasi', to: '/app/konsultasi' },
    { label: 'Peminjaman terbaru', key: 'peminjaman', to: '/app/peminjaman' },
    { label: 'Usulan email terbaru', key: 'usulan_email', to: '/app/email-resmi' },
]
function recentTitle(item, type) {
    if (type === 'konsultasi') return item.judul || item.topik?.topik || `Konsultasi #${item.id}`
    if (type === 'peminjaman') return item.keterangan || `Peminjaman #${item.id}`
    return item.pegawai_bkd?.Nama || item.email_resmi || item.email_pribadi || `Usulan #${item.id}`
}
function recentMeta(item, type) {
    if (type === 'konsultasi') return item.topik?.topik || 'Konsultasi TIK'
    if (type === 'peminjaman') {
        const assets = (item.items || []).map((asset) => asset.nama).filter(Boolean)
        return assets.length ? assets.join(', ') : 'Pengajuan peminjaman aset'
    }
    return item.pegawai_bkd?.NIP_Baru || item.email_pribadi || 'Pengajuan email ASN'
}
async function calendar(range) {
    calendarLoading.value = true
    try {
        events.value = rows(payload(await api.get('/dashboard/calendar', { params: range })))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        calendarLoading.value = false
    }
}
onMounted(async () => {
    try {
        const [dashboard, announcementResponse] = await Promise.all([
            api.get('/dashboard'),
            api.get('/pengumuman'),
        ])
        data.value = payload(dashboard)
        announcements.value = rows(payload(announcementResponse))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
})
</script>

<template>
    <div class="page-stack">
        <AlertMessage :message="error" />
        <LoadingState v-if="loading" />
        <template v-else>
            <ServiceHero
                eyebrow="Portal layanan terpadu"
                :title="`Selamat datang, ${auth.user?.name || 'Pengguna Gelatik'}`"
                description="Pantau pengajuan, jadwal, pengumuman, dan seluruh aktivitas layanan TIK dari satu halaman."
            >
                <div class="flex flex-wrap gap-3">
                    <RouterLink to="/app/konsultasi" class="btn-primary">Buat konsultasi</RouterLink
                    ><RouterLink
                        to="/app/peminjaman"
                        class="btn-secondary"
                        >Ajukan peminjaman</RouterLink
                    >
                </div>
            </ServiceHero>
            <section>
                <div class="mb-3 flex items-end justify-between">
                    <div>
                        <p class="eyebrow">Ringkasan layanan</p>
                        <h2 class="mt-1 text-xl font-bold text-navy">Aktivitas Anda hari ini</h2>
                    </div>
                    <span class="badge bg-brand-50 text-brand-700">Data terkini</span>
                </div>
                <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    <RouterLink
                        v-for="card in cards"
                        :key="card.key"
                        :to="card.to"
                        class="card group flex items-center gap-4 hover:-translate-y-0.5 hover:border-brand-300"
                    >
                        <span
                            class="grid size-12 shrink-0 place-items-center rounded-2xl"
                            :class="card.tone"
                            ><component :is="card.icon" class="size-6"
                        /></span>
                        <div class="min-w-0">
                            <p class="text-3xl font-bold text-navy">
                                {{ data.summary?.[card.key] ?? 0 }}
                            </p>
                            <p class="truncate text-sm font-semibold text-slate-500">
                                {{ card.label }}
                            </p>
                        </div>
                        <span class="ml-auto text-brand-600 transition group-hover:translate-x-1"
                            >→</span
                        >
                    </RouterLink>
                </div>
            </section>
            <section>
                <div class="mb-3">
                    <p class="eyebrow">Aktivitas akun</p>
                    <h2 class="mt-1 text-xl font-bold text-navy">Pengajuan terbaru Anda</h2>
                </div>
                <div class="grid gap-5 xl:grid-cols-3">
                    <section
                        v-for="group in recentGroups"
                        :key="group.key"
                        class="section-panel"
                    >
                        <div class="section-panel-header flex items-center justify-between gap-3">
                            <h3 class="font-bold text-navy">{{ group.label }}</h3>
                            <RouterLink :to="group.to" class="text-xs font-bold text-brand-700">
                                Lihat semua
                            </RouterLink>
                        </div>
                        <div class="divide-y divide-[var(--color-border)] px-5">
                            <article
                                v-for="item in data.recent?.[group.key] || []"
                                :key="item.id"
                                class="flex items-center gap-3 py-4"
                            >
                                <div class="min-w-0 flex-1">
                                    <p class="truncate text-sm font-semibold text-navy">
                                        {{ recentTitle(item, group.key) }}
                                    </p>
                                    <p class="mt-1 truncate text-xs text-slate-500">
                                        {{ recentMeta(item, group.key) }} ·
                                        {{ formatDateTime(item.created_at) }}
                                    </p>
                                </div>
                                <StatusBadge :status="item.status" />
                            </article>
                            <p
                                v-if="!data.recent?.[group.key]?.length"
                                class="py-10 text-center text-sm text-slate-400"
                            >
                                Belum ada data pada akun ini.
                            </p>
                        </div>
                    </section>
                </div>
            </section>
            <section class="section-panel">
                <div class="section-panel-header">
                    <p class="eyebrow">Permintaan terbanyak</p>
                    <h2 class="mt-1 font-bold text-navy">Topik dan aset</h2>
                </div>
                <div class="p-4 sm:p-5">
                    <DashboardPieCharts
                        :topics="data.consultation_topics || []"
                        :assets="data.asset_usage || []"
                    />
                </div>
            </section>
            <div class="grid gap-5 xl:grid-cols-[1.35fr_.65fr]">
                <section class="section-panel">
                    <div class="section-panel-header">
                        <p class="eyebrow">30 hari terakhir</p>
                        <h2 class="mt-1 font-bold text-navy">Aktivitas layanan</h2>
                    </div>
                    <div class="p-4 sm:p-5">
                        <DashboardBarChart :items="data.service_activity_series || []" />
                    </div>
                </section>
                <section class="section-panel">
                    <div class="section-panel-header">
                        <p class="eyebrow">Kualitas layanan</p>
                        <h2 class="mt-1 font-bold text-navy">Rating pengguna</h2>
                    </div>
                    <DashboardRatingCard :statistics="data.service_rating_statistics || {}" />
                </section>
            </div>
            <div class="grid gap-5 xl:grid-cols-[1.35fr_.65fr]">
                <ScheduleCalendar
                    :events="events"
                    :loading="calendarLoading"
                    @range-change="calendar"
                />
                <section class="section-panel">
                    <div class="section-panel-header">
                        <p class="eyebrow">Informasi terbaru</p>
                        <h2 class="mt-1 font-bold text-navy">Pengumuman</h2>
                    </div>
                    <div class="divide-y divide-slate-100 px-5">
                        <article
                            v-for="item in announcements.slice(0, 5)"
                            :key="item.id"
                            class="py-4"
                        >
                            <strong class="text-sm text-navy">{{ item.judul }}</strong>
                            <p class="mt-1 line-clamp-2 text-sm leading-6 text-slate-500">
                                {{ item.konten }}
                            </p>
                        </article>
                        <p
                            v-if="!announcements.length"
                            class="py-10 text-center text-sm text-slate-400"
                        >
                            Belum ada pengumuman.
                        </p>
                    </div>
                </section>
            </div>
        </template>
    </div>
</template>
