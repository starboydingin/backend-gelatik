<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { api, payload, rows, errorMessage } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import StatusBadge from '../../components/StatusBadge.vue'
import SummaryModal from '../../components/SummaryModal.vue'
import PaginationControls from '../../components/PaginationControls.vue'
import { formatDateTime } from '../../lib/date'
const route = useRoute(),
    staff = computed(() => route.path.startsWith('/admin') || route.path.startsWith('/bkd')),
    portalPrefix = computed(() =>
        route.path.startsWith('/bkd') ? '/bkd' : route.path.startsWith('/admin') ? '/admin' : '/app'
    ),
    list = ref([]),
    employees = ref([]),
    loading = ref(true),
    error = ref(''),
    search = ref(''),
    statusFilter = ref('all'),
    showForm = ref(false),
    summary = ref(null),
    page = ref(1),
    pagination = ref({ current_page: 1, last_page: 1, total: 0 }),
    submitting = ref(false),
    form = ref({ nip: '', email_pribadi: '' })
const selectedEmployee = computed(() =>
    employees.value.find(
        (employee) => String(employee.NIP_Baru || employee.nip) === String(form.value.nip)
    )
)
const displayedList = computed(() => list.value)
let filterTimer
const stats = computed(() => [
    { label: 'Diajukan', value: list.value.filter((item) => item.status === 'diajukan').length },
    {
        label: 'Disetujui',
        value: list.value.filter((item) => /setuju|selesai|dibuat/i.test(item.status)).length,
    },
    { label: 'Ditolak', value: list.value.filter((item) => /tolak/i.test(item.status)).length },
])
async function load({ fresh = false } = {}) {
    loading.value = true
    error.value = ''
    try {
        const data = payload(
            await api.get('/pengajuan-email', {
                params: {
                    page: page.value,
                    search: search.value || undefined,
                    status: ['diajukan', 'disetujui', 'ditolak'].includes(statusFilter.value)
                        ? statusFilter.value
                        : undefined,
                    verification:
                        statusFilter.value === 'menunggu'
                            ? 'waiting'
                            : statusFilter.value === 'terverifikasi'
                              ? 'verified'
                              : undefined,
                },
                cache: !fresh,
            })
        )
        list.value = rows(data)
        pagination.value = {
            current_page: Number(data?.current_page || 1),
            last_page: Number(data?.last_page || 1),
            total: Number(data?.total ?? list.value.length),
        }
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
async function changePage(nextPage) {
    page.value = nextPage
    await load()
}
async function open() {
    error.value = ''
    try {
        employees.value = rows(payload(await api.get('/pegawai'))).map((employee) => ({
            ...employee,
            nama: employee.Nama || employee.nama,
            nip: employee.NIP_Baru || employee.nip,
            name: employee.Nama || employee.nama,
        }))
        showForm.value = true
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
function showSummary(item) {
    summary.value = item
}
async function submit() {
    submitting.value = true
    error.value = ''
    try {
        await api.post('/pengajuan-email', form.value)
        showForm.value = false
        form.value = { nip: '', email_pribadi: '' }
        await load({ fresh: true })
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        submitting.value = false
    }
}
watch([search, statusFilter], () => {
    window.clearTimeout(filterTimer)
    filterTimer = window.setTimeout(() => {
        page.value = 1
        load({ fresh: true })
    }, 350)
})
onMounted(load)
onBeforeUnmount(() => window.clearTimeout(filterTimer))
</script>
<template>
    <div class="page-stack">
        <ServiceHero
            eyebrow="Email resmi ASN"
            title="Ajukan email dinas dengan data pegawai yang terverifikasi"
            description="Pilih data pegawai BKD, lengkapi email pribadi pegawai tersebut, lalu pantau proses pengajuannya."
            :stats="stats"
            ><button v-if="!staff" class="btn-primary" @click="open">
                Ajukan email ASN
            </button></ServiceHero
        >
        <AlertMessage :message="error" />
        <form v-if="showForm" class="section-panel" @submit.prevent="submit">
            <div class="section-panel-header">
                <p class="eyebrow">Pengajuan berdasarkan data BKD</p>
                <h2 class="mt-1 text-xl font-bold text-[var(--color-text-primary)]">
                    Ajukan email ASN
                </h2>
            </div>
            <div class="space-y-4 p-4 sm:p-5">
                <p class="text-sm leading-6 text-slate-600">
                    Ajukan email untuk pegawai yang datanya sudah disampaikan kepada BKD. Anda
                    bertindak sebagai pengaju, bukan pemilik email pribadi tersebut.
                </p>
                <label class="block">
                    <span class="label">Pegawai</span>
                    <select v-model="form.nip" class="input" required>
                        <option value="">-- Pilih pegawai dari data BKD --</option>
                        <option
                            v-for="employee in employees"
                            :key="employee.NIP_Baru || employee.nip"
                            :value="employee.NIP_Baru || employee.nip"
                        >
                            {{ employee.nama || employee.name }} — {{ employee.nip }}
                        </option>
                    </select>
                </label>
                <div
                    v-if="selectedEmployee"
                    class="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-4 text-sm"
                >
                    <strong>{{ selectedEmployee.nama }}</strong>
                    <p class="mt-1 text-slate-600">
                        NIP {{ selectedEmployee.nip }} -
                        {{ selectedEmployee.Unit_Kerja || selectedEmployee.unit_kerja || '-' }}
                    </p>
                </div>
                <label class="block">
                    <span class="label">Email pribadi pegawai</span>
                    <input v-model="form.email_pribadi" type="email" class="input" required />
                </label>
            </div>
            <div class="flex flex-wrap gap-2 px-4 pb-4 sm:px-5 sm:pb-5">
                <button class="btn-primary" :disabled="submitting">
                    {{ submitting ? 'Mengajukan...' : 'Ajukan email ASN' }}
                </button>
                <button type="button" class="btn-secondary" @click="showForm = false">Batal</button>
            </div>
        </form>
        <section class="section-panel overflow-hidden">
            <div class="section-panel-header">
                <p class="eyebrow">Monitoring pengajuan</p>
                <h2 class="mt-1 text-xl font-bold text-[var(--color-text-primary)]">
                    Riwayat usulan email ASN
                </h2>
            </div>
            <div
                class="grid gap-3 border-b border-[var(--color-border)] p-4 md:grid-cols-[220px_1fr] md:items-end"
            >
                <input
                    v-model="search"
                    class="input md:order-2 md:justify-self-end md:w-72"
                    placeholder="Cari nama, NIP, atau email…"
                /><select v-model="statusFilter" class="input md:order-1">
                    <option value="all">Filter status: semua</option>
                    <option value="menunggu">Menunggu verifikasi BKD</option>
                    <option value="terverifikasi">Terverifikasi BKD</option>
                    <option value="diajukan">Diajukan</option>
                    <option value="disetujui">Disetujui</option>
                    <option value="ditolak">Ditolak</option>
                </select>
            </div>
            <LoadingState v-if="loading" />
            <div v-else class="p-4">
                <EmptyState v-if="!list.length" />
                <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                    <article
                        v-for="item in displayedList"
                        :key="item.id"
                        class="card flex flex-col"
                    >
                        <div class="flex items-start justify-between gap-3">
                            <p class="eyebrow">Usulan #{{ item.id }}</p>
                            <StatusBadge :status="item.status" />
                            <StatusBadge
                                v-if="item.verification_state === 'verified'"
                                status="Terverifikasi BKD"
                            />
                        </div>
                        <h2 class="mt-3 line-clamp-2 text-lg font-bold">
                            {{ item.nama || item.nama_pegawai || 'Pegawai ASN' }}
                        </h2>
                        <dl class="mt-4 grid gap-3 text-sm">
                            <div>
                                <dt class="label">NIP</dt>
                                <dd>{{ item.nip || '-' }}</dd>
                            </div>
                            <div>
                                <dt class="label">Email pribadi</dt>
                                <dd class="truncate" :title="item.email_pribadi">
                                    {{ item.email_pribadi || '-' }}
                                </dd>
                            </div>
                            <div>
                                <dt class="label">Diajukan</dt>
                                <dd>{{ formatDateTime(item.created_at) }}</dd>
                            </div>
                        </dl>
                        <div class="mt-auto flex flex-wrap gap-2 pt-4">
                            <button class="btn-secondary min-h-9 px-3" @click="showSummary(item)">
                                Ringkasan</button
                            ><RouterLink
                                class="btn-secondary min-h-9 px-3"
                                :to="`${portalPrefix}/email-resmi/${item.id}`"
                                >{{ staff ? 'Kelola' : 'Detail' }}</RouterLink
                            >
                        </div>
                    </article>
                </div>
                <PaginationControls
                    :current-page="pagination.current_page"
                    :last-page="pagination.last_page"
                    :total="pagination.total"
                    @change="changePage"
                />
            </div>
        </section>
        <SummaryModal
            :open="Boolean(summary)"
            :title="summary?.nama || summary?.nama_pegawai || `Usulan #${summary?.id}`"
            @close="summary = null"
            ><dl v-if="summary" class="grid gap-4 sm:grid-cols-2">
                <div>
                    <dt class="label">Status</dt>
                    <dd><StatusBadge :status="summary.status" /></dd>
                </div>
                <div>
                    <dt class="label">NIP</dt>
                    <dd>{{ summary.nip || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Email pribadi</dt>
                    <dd class="break-all">{{ summary.email_pribadi || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Email resmi</dt>
                    <dd class="break-all">{{ summary.email_resmi || '-' }}</dd>
                </div>
            </dl></SummaryModal
        >
    </div>
</template>
