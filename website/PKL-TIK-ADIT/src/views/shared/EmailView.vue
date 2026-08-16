<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { api, payload, rows, errorMessage } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import StatusBadge from '../../components/StatusBadge.vue'
const route = useRoute(),
    admin = computed(() => route.path.startsWith('/admin')),
    list = ref([]),
    employees = ref([]),
    loading = ref(true),
    error = ref(''),
    search = ref(''),
    statusFilter = ref('all'),
    showForm = ref(false),
    detail = ref(null),
    submitting = ref(false),
    form = ref({ nip: '', email_pribadi: '' })
const selectedEmployee = computed(() =>
    employees.value.find(
        (employee) => String(employee.NIP_Baru || employee.nip) === String(form.value.nip)
    )
)
const displayedList = computed(() =>
    list.value.filter((item) => {
        const matchesSearch = Object.values(item)
            .join(' ')
            .toLowerCase()
            .includes(search.value.toLowerCase())
        return (
            matchesSearch &&
            (statusFilter.value === 'all' ||
                String(item.status).toLowerCase().includes(statusFilter.value))
        )
    })
)
const stats = computed(() => [
    { label: 'Diajukan', value: list.value.filter((item) => item.status === 'diajukan').length },
    {
        label: 'Disetujui',
        value: list.value.filter((item) => /setuju|selesai|dibuat/i.test(item.status)).length,
    },
    { label: 'Ditolak', value: list.value.filter((item) => /tolak/i.test(item.status)).length },
])
function formatSubmittedAt(value) {
    if (!value) return '-'
    const parsed = new Date(value)
    if (Number.isNaN(parsed.getTime())) return value

    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    }).format(parsed)
}
async function load() {
    loading.value = true
    try {
        list.value = rows(payload(await api.get('/pengajuan-email')))
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
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
async function showDetail(id) {
    try {
        detail.value = payload(await api.get(`/pengajuan-email/${id}`))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function submit() {
    submitting.value = true
    error.value = ''
    try {
        await api.post('/pengajuan-email', form.value)
        showForm.value = false
        form.value = { nip: '', email_pribadi: '' }
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        submitting.value = false
    }
}
async function action(id, type) {
    let body = {}
    if (type === 'buat-email-resmi') {
        const value = prompt('Masukkan email resmi yang dibuat')
        if (!value) return
        body = { email_resmi: value }
    }
    if (type === 'tolak-email') body = { catatan: prompt('Alasan penolakan') || '' }
    try {
        await api.post(`/pengajuan-email/${id}/${type}`, body)
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
onMounted(load)
</script>
<template>
    <div class="page-stack">
        <ServiceHero
            eyebrow="Email resmi ASN"
            title="Ajukan email dinas dengan data pegawai yang terverifikasi"
            description="Pilih data pegawai BKD, lengkapi email pribadi pegawai tersebut, lalu pantau proses pengajuannya."
            :stats="stats"
            ><button v-if="!admin" class="btn-primary" @click="open">
                Ajukan email ASN
            </button></ServiceHero
        >
        <AlertMessage :message="error" />
        <form v-if="showForm" class="section-panel" @submit.prevent="submit">
            <div class="section-panel-header">
                <p class="eyebrow">Pengajuan berdasarkan data BKD</p>
                <h2 class="mt-1 text-xl font-bold text-[var(--ink)]">Ajukan email ASN</h2>
            </div>
            <div class="space-y-5 p-5 md:p-7">
                <p class="text-sm leading-6 text-slate-600">
                    Ajukan email untuk pegawai yang datanya sudah disampaikan kepada BKD. Anda bertindak sebagai pengaju, bukan pemilik email pribadi tersebut.
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
                <div v-if="selectedEmployee" class="border-2 border-[var(--line)] bg-[var(--paper)] p-4 text-sm">
                    <strong>{{ selectedEmployee.nama }}</strong>
                    <p class="mt-1 text-slate-600">
                        NIP {{ selectedEmployee.nip }} - {{ selectedEmployee.Unit_Kerja || selectedEmployee.unit_kerja || '-' }}
                    </p>
                </div>
                <label class="block">
                    <span class="label">Email pribadi pegawai</span>
                    <input v-model="form.email_pribadi" type="email" class="input" required />
                </label>
            </div>
            <div class="flex flex-wrap gap-3 px-5 pb-5 md:px-7 md:pb-7">
                <button class="btn-primary" :disabled="submitting">
                    {{ submitting ? 'Mengajukan...' : 'Ajukan email ASN' }}
                </button>
                <button type="button" class="btn-secondary" @click="showForm = false">Batal</button>
            </div>
        </form>
        <section class="section-panel overflow-hidden">
            <div class="section-panel-header">
                <p class="eyebrow">Monitoring pengajuan</p>
                <h2 class="mt-1 text-xl font-bold text-[var(--ink)]">Riwayat usulan email ASN</h2>
            </div>
        <div class="grid gap-3 border-b-2 border-[var(--line)] p-5 md:grid-cols-[220px_1fr] md:items-end">
            <input
                v-model="search"
                class="input md:order-2 md:justify-self-end md:w-72"
                placeholder="Cari nama, NIP, atau email…"
            /><select v-model="statusFilter" class="input md:order-1">
                <option value="all">Filter status: semua</option>
                <option value="diajukan">Diajukan</option>
                <option value="disetujui">Disetujui</option>
                <option value="ditolak">Ditolak</option>
            </select>
        </div>
        <LoadingState v-if="loading" />
        <div v-else class="table-wrap border-0 shadow-none">
            <EmptyState v-if="!list.length" />
            <table v-else class="data-table email-proposal-table">
                <colgroup>
                    <col class="w-12" />
                    <col class="w-40" />
                    <col class="w-40" />
                    <col class="w-56" />
                    <col class="w-52" />
                    <col class="w-28" />
                    <col class="w-36" />
                    <col class="w-72" />
                </colgroup>
                <thead>
                    <tr>
                        <th>No.</th>
                        <th>Nama</th>
                        <th>NIP</th>
                        <th>Email pribadi</th>
                        <th>Email resmi</th>
                        <th>Status</th>
                        <th>Tanggal diajukan</th>
                        <th>Tindakan</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(item, index) in displayedList" :key="item.id">
                        <td>{{ index + 1 }}</td>
                        <td class="font-semibold">
                            <strong>{{
                                item.nama || item.nama_pegawai || `Usulan #${item.id}`
                            }}</strong>
                        </td>
                        <td class="whitespace-nowrap">{{ item.nip || '-' }}</td>
                        <td class="truncate" :title="item.email_pribadi">{{ item.email_pribadi }}</td>
                        <td>{{ item.email_resmi || '—' }}</td>
                        <td>
                            <StatusBadge :status="item.status" />
                        </td>
                        <td class="whitespace-nowrap">{{ formatSubmittedAt(item.created_at) }}</td>
                        <td>
                            <div class="flex flex-nowrap gap-1.5">
                                <button
                                    class="btn-secondary min-h-9 px-3"
                                    @click="showDetail(item.id)"
                                >
                                    Detail
                                </button>
                                <button
                                    v-if="admin"
                                    class="btn-secondary min-h-9 px-3"
                                    @click="action(item.id, 'verifikasi')"
                                >
                                    Verifikasi</button
                                ><button
                                    v-if="admin"
                                    class="btn-primary min-h-9 px-3"
                                    @click="action(item.id, 'buat-email-resmi')"
                                >
                                    Buat email</button
                                ><button
                                    v-if="admin"
                                    class="btn-danger min-h-9 px-3"
                                    @click="action(item.id, 'tolak-email')"
                                >
                                    Tolak
                                </button>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        </section>
        <section v-if="detail" class="card">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <p class="eyebrow">Detail usulan email</p>
                    <h2 class="mt-1 text-xl font-bold text-navy">
                        {{ detail.nama || detail.nama_pegawai || `Usulan #${detail.id}` }}
                    </h2>
                </div>
                <button class="btn-secondary min-h-9 px-3" @click="detail = null">Tutup</button>
            </div>
            <dl class="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <div>
                    <dt class="label">NIP</dt>
                    <dd>{{ detail.nip || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Unit kerja</dt>
                    <dd>{{ detail.unit_kerja || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Jabatan</dt>
                    <dd>{{ detail.jabatan || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Email pribadi</dt>
                    <dd class="break-all">{{ detail.email_pribadi || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Email resmi</dt>
                    <dd class="break-all">{{ detail.email_resmi || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Status</dt>
                    <dd><StatusBadge :status="detail.status" /></dd>
                </div>
                <div>
                    <dt class="label">Tanggal pengajuan</dt>
                    <dd>{{ detail.created_at || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Tanggal verifikasi</dt>
                    <dd>{{ detail.tanggal_verifikasi || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Diverifikasi oleh</dt>
                    <dd>{{ detail.diverifikasi_oleh || '-' }}</dd>
                </div>
                <div class="sm:col-span-2 lg:col-span-4">
                    <dt class="label">Catatan petugas</dt>
                    <dd class="whitespace-pre-wrap">{{ detail.catatan || '-' }}</dd>
                </div>
            </dl>
        </section>
    </div>
</template>
