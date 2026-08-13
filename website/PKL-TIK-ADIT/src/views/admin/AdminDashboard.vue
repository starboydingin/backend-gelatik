<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, errorMessage } from '../../lib/api'
import { useAuthStore } from '../../stores/auth'
import LoadingState from '../../components/LoadingState.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import StatusBadge from '../../components/StatusBadge.vue'
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
    ['Konsultasi terbaru', 'konsultasi', '/admin/konsultasi'],
    ['Peminjaman terbaru', 'peminjaman', '/admin/peminjaman'],
    ['Usulan email terbaru', 'usulan_email', '/admin/email-resmi'],
]
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
            <div class="grid gap-5 xl:grid-cols-3">
                <section v-for="group in groups" :key="group[1]" class="section-panel">
                    <div class="section-panel-header flex items-center justify-between">
                        <h2 class="font-bold text-navy">{{ group[0] }}</h2>
                        <RouterLink :to="group[2]" class="text-xs font-bold text-brand-700"
                            >Lihat semua</RouterLink
                        >
                    </div>
                    <div class="divide-y divide-slate-100 px-5">
                        <article
                            v-for="item in data.recent?.[group[1]] || []"
                            :key="item.id"
                            class="flex items-center gap-3 py-4"
                        >
                            <span
                                class="grid size-10 shrink-0 place-items-center rounded-xl bg-brand-50 text-xs font-bold text-brand-700"
                                >{{
                                    (item.user?.name || item.nama || 'G').slice(0, 2).toUpperCase()
                                }}</span
                            >
                            <div class="min-w-0 flex-1">
                                <p class="truncate text-sm font-semibold text-navy">
                                    {{
                                        item.judul ||
                                        item.keperluan ||
                                        item.email_pribadi ||
                                        item.user?.name ||
                                        `Data #${item.id}`
                                    }}
                                </p>
                                <p class="mt-1 truncate text-xs text-slate-500">
                                    {{ item.user?.name || item.created_at }}
                                </p>
                            </div>
                            <StatusBadge :status="item.status" />
                        </article>
                        <p
                            v-if="!data.recent?.[group[1]]?.length"
                            class="py-10 text-center text-sm text-slate-400"
                        >
                            Belum ada data.
                        </p>
                    </div>
                </section>
            </div>
        </template>
    </div>
</template>
