<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, errorMessage, rows } from '../../lib/api'
import { useAuthStore } from '../../stores/auth'
import LoadingState from '../../components/LoadingState.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import StatusBadge from '../../components/StatusBadge.vue'
import ScheduleCalendar from '../../components/ScheduleCalendar.vue'
import DashboardLineChart from '../../components/DashboardLineChart.vue'
import DashboardPieCharts from '../../components/DashboardPieCharts.vue'
import {
    UsersIcon,
    ChatBubbleLeftRightIcon,
    BriefcaseIcon,
    EnvelopeIcon,
    BellIcon,
    UserGroupIcon,
} from '@heroicons/vue/24/outline'

const auth = useAuthStore()
const data = ref({ summary: {}, recent: {} }),
    events = ref([]),
    calendarLoading = ref(false),
    loading = ref(true),
    error = ref('')
const cards = [
    {
        label: 'Total pengguna',
        key: 'users_total',
        to: '/admin/pengguna',
        icon: UsersIcon,
        tone: 'bg-slate-100 text-slate-600',
    },
    {
        label: 'Pengguna aktif',
        key: 'users_active',
        to: '/admin/pengguna',
        icon: UserGroupIcon,
        tone: 'bg-emerald-50 text-emerald-600',
    },
    {
        label: 'Konsultasi terbuka',
        key: 'konsultasi_open',
        to: '/admin/konsultasi',
        icon: ChatBubbleLeftRightIcon,
        tone: 'bg-sky-50 text-sky-600',
    },
    {
        label: 'Peminjaman terbuka',
        key: 'peminjaman_open',
        to: '/admin/peminjaman',
        icon: BriefcaseIcon,
        tone: 'bg-violet-50 text-violet-600',
    },
    {
        label: 'Usulan email',
        key: 'usulan_email_pending',
        to: '/admin/email-resmi',
        icon: EnvelopeIcon,
        tone: 'bg-orange-50 text-orange-600',
    },
    {
        label: 'Notifikasi belum dibaca',
        key: 'notifications_unread',
        to: '/admin/notifikasi',
        icon: BellIcon,
        tone: 'bg-rose-50 text-rose-600',
    },
]
const groups = [
    { label: 'Pengguna terbaru', key: 'users', to: '/admin/pengguna' },
    { label: 'Konsultasi terbaru', key: 'konsultasi', to: '/admin/konsultasi' },
    { label: 'Peminjaman terbaru', key: 'peminjaman', to: '/admin/peminjaman' },
    { label: 'Usulan email terbaru', key: 'usulan_email', to: '/admin/email-resmi' },
]
function formatDate(value) {
    if (!value) return 'Tanggal belum tersedia'
    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return 'Tanggal belum tersedia'
    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
    }).format(date)
}
function itemTitle(item, type) {
    if (type === 'users') return item.name || item.username || `Pengguna #${item.id}`
    if (type === 'konsultasi') return item.judul || item.topik?.topik || `Konsultasi #${item.id}`
    if (type === 'peminjaman') return item.keterangan || `Peminjaman #${item.id}`
    return item.pegawai_bkd?.Nama || item.email_resmi || item.email_pribadi || `Usulan #${item.id}`
}
function itemMeta(item, type) {
    if (type === 'users') return item.nama_opd || item.email || item.username
    if (type === 'konsultasi') return item.user?.name || item.topik?.topik
    if (type === 'peminjaman') return item.user?.name || `${item.items?.length || 0} aset`
    return item.user?.name || item.pegawai_bkd?.NIP_Baru || item.email_pribadi
}
async function loadCalendar(range) {
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
        data.value = payload(await api.get('/admin/dashboard'))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
})
</script>

<template>
    <div class="page-stack">
        <AlertMessage :message="error" /><LoadingState v-if="loading" />
        <template v-else>
            <ServiceHero
                eyebrow="Portal admin"
                :title="`Selamat datang, ${auth.user?.name || 'Administrator'}`"
                description="Pantau ringkasan operasional dan buka modul kerja dari satu dashboard yang terintegrasi."
            ></ServiceHero>
            <section class="section-panel p-5">
                <div class="mb-4 flex items-center justify-between">
                    <div>
                        <p class="eyebrow">Ringkasan operasional</p>
                        <h2 class="mt-1 text-xl font-bold text-navy">Status layanan hari ini</h2>
                    </div>
                    <span class="badge bg-emerald-50 text-emerald-700">Data terkini</span>
                </div>
                <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                    <RouterLink
                        v-for="card in cards"
                        :key="card.key"
                        :to="card.to"
                        class="rounded-2xl border border-stroke p-4 transition hover:-translate-y-0.5 hover:border-brand-300"
                        ><div class="flex items-center justify-between">
                            <span
                                class="grid size-11 place-items-center rounded-xl"
                                :class="card.tone"
                                ><component :is="card.icon" class="size-5" /></span
                            ><span class="text-brand-600">↗</span>
                        </div>
                        <strong class="mt-4 block text-3xl text-navy">{{
                            data.summary?.[card.key] ?? 0
                        }}</strong
                        ><span class="mt-1 block text-sm font-semibold text-slate-600">{{
                            card.label
                        }}</span></RouterLink
                    >
                </div>
            </section>
            <div class="grid gap-5 xl:grid-cols-[1.3fr_.7fr]">
                <section class="section-panel">
                    <div class="section-panel-header">
                        <p class="eyebrow">30 hari terakhir</p>
                        <h2 class="mt-1 font-bold text-navy">Aktivitas layanan</h2>
                    </div>
                    <div class="p-4 sm:p-5">
                        <DashboardLineChart :items="data.dashboard?.activity_series || []" />
                    </div>
                </section>
                <section class="section-panel">
                    <div class="section-panel-header">
                        <p class="eyebrow">Kualitas layanan</p>
                        <h2 class="mt-1 font-bold text-navy">Rating pengguna</h2>
                    </div>
                    <div class="p-5">
                        <p class="text-4xl font-bold text-navy">
                            {{ data.dashboard?.rating_statistik?.rata_rata ?? 0 }}<span class="text-base text-slate-500">/5</span>
                        </p>
                        <dl class="mt-5 space-y-2 text-sm">
                            <div
                                v-for="score in [5, 4, 3, 2, 1]"
                                :key="score"
                                class="flex justify-between"
                            >
                                <dt>{{ score }} bintang</dt>
                                <dd class="font-bold">{{ data.dashboard?.rating_statistik?.distribusi?.[score] ?? 0 }}</dd>
                            </div>
                        </dl>
                    </div>
                </section>
            </div>
            <div class="grid gap-5 xl:grid-cols-[.7fr_1.3fr]">
                <section class="section-panel">
                    <div class="section-panel-header">
                        <p class="eyebrow">Permintaan terbanyak</p>
                        <h2 class="mt-1 font-bold text-navy">Topik dan aset</h2>
                    </div>
                    <div class="p-4 sm:p-5">
                        <DashboardPieCharts
                            :topics="data.dashboard?.consultation_topics || []"
                            :assets="data.dashboard?.top_5_aset || []"
                        />
                    </div>
                </section>
                <ScheduleCalendar
                    :events="events"
                    :loading="calendarLoading"
                    @range-change="loadCalendar"
                />
            </div>
            <div class="grid gap-5 md:grid-cols-2 2xl:grid-cols-4">
                <section v-for="group in groups" :key="group.key" class="section-panel">
                    <div class="section-panel-header flex items-center justify-between">
                        <h2 class="font-bold text-navy">{{ group.label }}</h2>
                        <RouterLink :to="group.to" class="text-xs font-bold text-brand-700"
                            >Lihat semua</RouterLink
                        >
                    </div>
                    <div class="divide-y divide-slate-100 px-5">
                        <article
                            v-for="item in data.recent?.[group.key] || []"
                            :key="item.id"
                            class="flex items-center gap-3 py-4"
                        >
                            <span
                                class="grid size-10 shrink-0 place-items-center rounded-xl bg-brand-50 text-xs font-bold text-brand-700"
                                >{{
                                    (item.user?.name || item.name || item.pegawai_bkd?.Nama || 'G')
                                        .slice(0, 2)
                                        .toUpperCase()
                                }}</span
                            >
                            <div class="min-w-0 flex-1">
                                <p class="truncate text-sm font-semibold text-navy">
                                    {{ itemTitle(item, group.key) }}
                                </p>
                                <p class="mt-1 truncate text-xs text-slate-500">
                                    {{ itemMeta(item, group.key) || 'Informasi akun' }} ·
                                    {{ formatDate(item.created_at) }}
                                </p>
                            </div>
                            <StatusBadge
                                :status="
                                    group.key === 'users'
                                        ? String(item.status) === '1'
                                            ? 'Aktif'
                                            : 'Nonaktif'
                                        : item.status
                                "
                            />
                        </article>
                        <p
                            v-if="!data.recent?.[group.key]?.length"
                            class="py-10 text-center text-sm text-slate-400"
                        >
                            Belum ada data.
                        </p>
                    </div>
                </section>
            </div>
            <section v-if="data.scope === 'superadmin'" class="section-panel">
                <div class="section-panel-header">
                    <p class="eyebrow">Audit global</p>
                    <h2 class="mt-1 font-bold text-navy">Aktivitas administrator terbaru</h2>
                </div>
                <div class="divide-y divide-slate-100 px-5">
                    <article
                        v-for="item in data.admin_activity || []"
                        :key="item.id"
                        class="py-3 text-sm"
                    >
                        <strong>{{ item.actor || 'Sistem' }}</strong>
                        <span class="ml-2 text-slate-500">{{ item.description }}</span>
                    </article>
                    <p v-if="!data.admin_activity?.length" class="py-8 text-center text-sm text-slate-500">Belum ada aktivitas administrator.</p>
                </div>
            </section>
        </template>
    </div>
</template>
