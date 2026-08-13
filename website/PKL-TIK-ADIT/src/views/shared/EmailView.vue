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
    editingId = ref(null),
    detail = ref(null),
    form = ref({ id_peg: '', email_pribadi: '', nip: '' })
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
    { label: 'Diajukan', value: list.value.length },
    {
        label: 'Disetujui',
        value: list.value.filter((item) => /setuju|selesai|dibuat/i.test(item.status)).length,
    },
    { label: 'Ditolak', value: list.value.filter((item) => /tolak/i.test(item.status)).length },
])
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
    editingId.value = null
    showForm.value = true
    try {
        employees.value = rows(payload(await api.get('/pegawai')))
    } catch {}
}
async function edit(item) {
    editingId.value = item.id
    form.value = {
        id_peg: item.id_peg || item.id_peg_bkd || '',
        email_pribadi: item.email_pribadi || '',
        nip: item.nip || '',
    }
    showForm.value = true
    try {
        employees.value = rows(payload(await api.get('/pegawai')))
    } catch {}
}
async function showDetail(id) {
    try {
        detail.value = payload(await api.get(`/pengajuan-email/${id}`))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function submit() {
    try {
        if (editingId.value) await api.put(`/pengajuan-email/${editingId.value}`, form.value)
        else await api.post('/pengajuan-email', form.value)
        editingId.value = null
        showForm.value = false
        await load()
    } catch (e) {
        error.value = errorMessage(e)
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
            description="Pilih data pegawai, lengkapi email pribadi, lalu pantau proses pengajuan sampai alamat resmi tersedia."
            :stats="stats"
            ><button v-if="!admin" class="btn-primary" @click="open">
                Ajukan email resmi
            </button></ServiceHero
        >
        <AlertMessage :message="error" />
        <form v-if="showForm" class="card mb-6" @submit.prevent="submit">
            <h2 class="text-lg font-bold">{{ editingId ? 'Perbarui usulan' : 'Usulan baru' }}</h2>
            <div class="mt-4 grid gap-4 md:grid-cols-3">
                <label
                    ><span class="label">Pegawai</span
                    ><select v-model="form.id_peg" class="input">
                        <option value="">Pilih data pegawai</option>
                        <option
                            v-for="employee in employees"
                            :key="employee.id_peg || employee.id"
                            :value="employee.id_peg || employee.id"
                        >
                            {{ employee.nama || employee.name }} — {{ employee.nip }}
                        </option>
                    </select></label
                ><label
                    ><span class="label">NIP</span><input v-model="form.nip" class="input" /></label
                ><label
                    ><span class="label">Email pribadi</span
                    ><input v-model="form.email_pribadi" type="email" class="input" required
                /></label>
            </div>
            <button class="btn-primary mt-5">
                {{ editingId ? 'Simpan perubahan' : 'Kirim usulan' }}
            </button>
        </form>
        <div class="card grid gap-3 p-4 md:grid-cols-[1fr_220px]">
            <input
                v-model="search"
                class="input"
                placeholder="Cari nama, NIP, atau email…"
            /><select v-model="statusFilter" class="input">
                <option value="all">Semua status</option>
                <option value="menunggu">Menunggu</option>
                <option value="verifikasi">Verifikasi</option>
                <option value="selesai">Selesai</option>
                <option value="tolak">Ditolak</option>
            </select>
        </div>
        <LoadingState v-if="loading" />
        <div v-else class="table-wrap">
            <EmptyState v-if="!list.length" />
            <table v-else class="data-table">
                <thead>
                    <tr>
                        <th>Pegawai</th>
                        <th>Email pribadi</th>
                        <th>Email resmi</th>
                        <th>Status</th>
                        <th>Tindakan</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="item in displayedList" :key="item.id">
                        <td>
                            <strong>{{
                                item.nama || item.nama_pegawai || item.nip || `Usulan #${item.id}`
                            }}</strong>
                            <p class="text-xs text-slate-400">{{ item.nip }}</p>
                        </td>
                        <td>{{ item.email_pribadi }}</td>
                        <td>{{ item.email_resmi || '—' }}</td>
                        <td>
                            <StatusBadge :status="item.status" />
                        </td>
                        <td>
                            <div class="flex flex-wrap gap-2">
                                <button
                                    class="btn-secondary min-h-9 px-3"
                                    @click="showDetail(item.id)"
                                >
                                    Detail
                                </button>
                                <button
                                    v-if="!admin"
                                    class="btn-secondary min-h-9 px-3"
                                    @click="edit(item)"
                                >
                                    Edit
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
            </dl>
        </section>
    </div>
</template>
