<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { Bars3Icon } from '@heroicons/vue/24/outline'
import NotificationDropdown from './NotificationDropdown.vue'
import GelatikLogo from './GelatikLogo.vue'
import ThemeToggle from './ThemeToggle.vue'

defineProps({ user: Object, subtitle: String, adminArea: Boolean })
defineEmits(['menu'])
const route = useRoute()
const titles = {
    dashboard: ['Ringkasan aktivitas layanan', 'Dashboard'],
    konsultasi: ['Pusat bantuan dan konsultasi', 'Konsultasi TIK'],
    peminjaman: ['Layanan perangkat dan aset TIK', 'Peminjaman perangkat'],
    kalender: ['Agenda layanan Anda', 'Kalender Kegiatan'],
    'email-resmi': ['Pengajuan email resmi Pemerintah Provinsi Lampung', 'Usulan Email ASN'],
    router: ['Informasi perangkat jaringan unit kerja', 'Router OPD'],
    'umpan-balik': ['Masukan untuk peningkatan layanan TIK', 'Kritik, Saran & Rating'],
    rating: ['Nilai pengalaman menggunakan layanan TIK', 'Rating Layanan'],
    notifikasi: ['Pembaruan aktivitas layanan Anda', 'Notifikasi'],
    profil: ['Kelola informasi dan keamanan akun Anda', 'Profil & Akun'],
    faq: ['Informasi layanan', 'Pertanyaan Umum'],
    chatbot: ['Asisten layanan digital', 'Chatbot Gelatik'],
    whatsapp: ['Pengaturan kanal notifikasi', 'Notifikasi WhatsApp'],
    pengguna: ['Manajemen akses', 'Daftar Pengguna'],
    peran: ['Manajemen otorisasi', 'Peran & Izin'],
    pegawai: ['Referensi data ASN', 'Data Pegawai Email'],
    'laporan-peminjaman': ['Pelaporan operasional', 'Laporan Peminjaman'],
    pengumuman: ['Konten portal', 'Pengumuman'],
    'kritik-saran': ['Masukan pengguna', 'Kritik dan Saran'],
    pengaturan: ['Konfigurasi aplikasi', 'Pengaturan'],
    'referensi-layanan': ['Master layanan', 'Referensi Layanan'],
}
const current = computed(
    () =>
        titles[route.path.split('/').filter(Boolean).at(-1)] || [
            'Portal layanan terpadu',
            'Gelatik',
        ]
)
const initials = computed(() => (String(route.meta?.initials || '') || '').trim())
</script>

<template>
    <header
        class="brutal-header sticky top-0 z-20 flex min-h-[76px] items-center gap-4 border-b-[3px] border-[var(--line)] px-4 md:px-7"
    >
        <button
            class="brutal-icon-button shrink-0 lg:hidden"
            aria-label="Buka menu navigasi"
            @click="$emit('menu')"
        >
            <Bars3Icon class="size-6" />
        </button>
        <!-- Desktop branding lives only in the persistent left navigation. -->
        <GelatikLogo compact class="shrink-0 lg:hidden" />
        <div class="min-w-0 flex-1">
            <p class="eyebrow truncate">{{ current[0] }}</p>
            <h1 class="truncate font-brand text-xl font-black uppercase tracking-[-.04em]">{{ current[1] }}</h1>
        </div>
        <ThemeToggle />
        <NotificationDropdown :admin-area="adminArea" />
        <div class="hidden min-w-0 items-center gap-3 sm:flex">
            <span
                class="grid size-11 shrink-0 place-items-center border-[3px] border-[var(--line)] bg-[var(--gold)] font-black text-black"
                >{{
                    initials ||
                    (user?.name || 'G')
                        .split(' ')
                        .map((part) => part[0])
                        .slice(0, 2)
                        .join('')
                        .toUpperCase()
                }}</span
            >
            <div class="max-w-52 text-right">
                <p class="truncate text-sm font-semibold text-navy">{{ user?.name }}</p>
                <p class="truncate text-[11px] text-slate-500">{{ user?.nama_opd || subtitle }}</p>
            </div>
        </div>
    </header>
</template>
