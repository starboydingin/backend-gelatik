<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '../../stores/auth'
import { api, payload, rows, errorMessage } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import StatusSummary from '../../components/StatusSummary.vue'
import StatusBadge from '../../components/StatusBadge.vue'
const route = useRoute(),
    auth = useAuthStore(),
    admin = computed(() => route.path.startsWith('/admin')),
    items = ref([]),
    assets = ref([]),
    loading = ref(true),
    error = ref(''),
    success = ref(''),
    search = ref(''),
    statusFilter = ref('all'),
    showForm = ref(false),
    editingId = ref(null),
    detail = ref(null),
    form = ref({
        nama_pic: '',
        jabatan_pic: '',
        instansi_pic: '',
        kontak_pic: '',
        jenis_identitas: 'NIP',
        nomor_identitas: '',
        alamat_peminjam: '',
        jenis_durasi: 'harian',
        tanggal_mulai: '',
        jam_mulai: '',
        durasi_peminjaman: 1,
        keterangan: '',
        dokumen_pendukung: null,
        items: [],
    }),
    draft = ref({ item_id: '', quantity: 1 })
const statusItems = computed(() => [
    {
        label: 'Menunggu',
        value: items.value.filter((item) => /menunggu/i.test(item.status)).length,
        tone: 'waiting',
    },
    {
        label: 'Diproses',
        value: items.value.filter((item) => /proses/i.test(item.status)).length,
        tone: 'process',
    },
    {
        label: 'Ditolak',
        value: items.value.filter((item) => /tolak/i.test(item.status)).length,
        tone: 'rejected',
    },
    {
        label: 'Selesai',
        value: items.value.filter((item) => /selesai|disetujui/i.test(item.status)).length,
        tone: 'done',
    },
])
const displayedItems = computed(() =>
    items.value.filter((item) => {
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
async function load() {
    loading.value = true
    try {
        items.value = rows(payload(await api.get('/pinjam')))
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
async function openForm() {
    editingId.value = null
    form.value = {
        ...form.value,
        nama_pic: auth.user?.name || '',
        jabatan_pic: '',
        instansi_pic: auth.user?.nama_opd || '',
        kontak_pic: auth.user?.no_hp || '',
        nomor_identitas: form.value.jenis_identitas === 'NIP' ? auth.user?.nip || '' : '',
    }
    showForm.value = true
    try {
        assets.value = rows(payload(await api.get('/items')))
    } catch {}
}
function identityChanged() {
    form.value.nomor_identitas = form.value.jenis_identitas === 'NIP' ? auth.user?.nip || '' : ''
}
function setDocument(event) {
    const file = event.target.files?.[0] || null
    if (file && file.size > 1024 * 1024) {
        event.target.value = ''
        form.value.dokumen_pendukung = null
        error.value = 'Ukuran dokumen maksimal 1 MB.'
        return
    }
    form.value.dokumen_pendukung = file
}
async function edit(item) {
    editingId.value = item.id
    form.value = {
        ...form.value,
        ...Object.fromEntries(
            Object.keys(form.value)
                .filter((key) => key !== 'items' && key !== 'dokumen_pendukung')
                .map((key) => [key, item[key] ?? form.value[key]])
        ),
        dokumen_pendukung: null,
        items: (item.pinjam_items || []).map((entry) => ({
            item_id: entry.item_id || entry.master_item_id,
            quantity: entry.quantity || entry.jumlah || 1,
        })),
    }
    showForm.value = true
    try {
        assets.value = rows(payload(await api.get('/items')))
    } catch {}
}
async function showDetail(id) {
    try {
        detail.value = payload(await api.get(`/pinjam/${id}`))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
function addAsset() {
    if (!draft.value.item_id) return
    form.value.items.push({ ...draft.value })
    draft.value = { item_id: '', quantity: 1 }
}
async function submit() {
    error.value = ''
    try {
        if (editingId.value) {
            const updateData = { ...form.value }
            delete updateData.dokumen_pendukung
            await api.put(`/pinjam/${editingId.value}`, updateData)
            success.value = 'Pengajuan berhasil diperbarui.'
            editingId.value = null
            showForm.value = false
            await load()
            return
        }
        const body = new FormData()
        Object.entries(form.value).forEach(([key, value]) => {
            if (key === 'items') body.append(key, JSON.stringify(value))
            else if (key === 'dokumen_pendukung' && value) body.append(key, value)
            else if (value !== null) body.append(key, value)
        })
        form.value.items.forEach((item, index) => {
            body.append(`items[${index}][item_id]`, item.item_id)
            body.append(`items[${index}][quantity]`, item.quantity)
        })
        body.delete('items')
        await api.post('/pinjam', body)
        success.value = 'Pengajuan berhasil dikirim.'
        showForm.value = false
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function status(id, value) {
    try {
        await api.post(`/pinjam/${id}/status`, { status: value })
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function remove(id) {
    if (!confirm('Hapus pengajuan ini?')) return
    try {
        await api.delete(`/pinjam/${id}`)
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
            eyebrow="Peminjaman aset TIK"
            title="Perangkat kegiatan lebih mudah diajukan"
            description="Pilih jadwal, cek perangkat yang tersedia, unggah dokumen pendukung, lalu pantau proses persetujuannya."
            ><button v-if="!admin" class="btn-primary" @click="openForm">
                Ajukan peminjaman
            </button></ServiceHero
        >
        <StatusSummary :items="statusItems" />
        <AlertMessage :message="error" /><AlertMessage :message="success" type="success" />
        <form v-if="showForm" class="card mb-6" @submit.prevent="submit">
            <div class="flex justify-between">
                <h2 class="text-lg font-bold">
                    {{ editingId ? 'Perbarui pengajuan' : 'Pengajuan baru' }}
                </h2>
                <button type="button" class="text-slate-400" @click="showForm = false">✕</button>
            </div>
            <div class="mt-5 grid gap-4 md:grid-cols-2">
                <label
                    ><span class="label">Nama PIC</span
                    ><input
                        v-model="form.nama_pic"
                        class="input bg-slate-50"
                        readonly
                        required /></label
                ><label
                    ><span class="label">Instansi PIC</span
                    ><input
                        v-model="form.instansi_pic"
                        class="input bg-slate-50"
                        readonly
                        required /></label
                ><label
                    ><span class="label">Kontak PIC</span
                    ><input
                        v-model="form.kontak_pic"
                        class="input bg-slate-50"
                        readonly
                        required /></label
                ><label
                    ><span class="label">Jenis identitas</span
                    ><select v-model="form.jenis_identitas" class="input" @change="identityChanged">
                        <option>KTP</option>
                        <option>SIM</option>
                        <option>Passport</option>
                        <option>NIP</option>
                    </select></label
                ><label
                    ><span class="label">Nomor identitas</span
                    ><input
                        v-model="form.nomor_identitas"
                        class="input"
                        :class="form.jenis_identitas === 'NIP' ? 'bg-slate-50' : ''"
                        :readonly="form.jenis_identitas === 'NIP'"
                        required /></label
                ><label
                    ><span class="label">Alamat peminjam</span
                    ><input v-model="form.alamat_peminjam" class="input" required /></label
                ><label
                    ><span class="label">Tanggal mulai</span
                    ><input
                        v-model="form.tanggal_mulai"
                        type="date"
                        class="input"
                        required /></label
                ><label
                    ><span class="label">Jam mulai</span
                    ><input v-model="form.jam_mulai" type="time" class="input" /></label
                ><label
                    ><span class="label">Durasi</span>
                    <div class="flex gap-2">
                        <input
                            v-model.number="form.durasi_peminjaman"
                            type="number"
                            min="1"
                            class="input"
                            required
                        /><select v-model="form.jenis_durasi" class="input">
                            <option value="harian">Hari</option>
                            <option value="jam">Jam</option>
                            <option value="menit">Menit</option>
                        </select>
                    </div></label
                ><label class="md:col-span-2"
                    ><span class="label">Keterangan</span
                    ><textarea v-model="form.keterangan" class="input min-h-24"></textarea></label
                ><label class="md:col-span-2"
                    ><span class="label">Unggah dokumen pendukung (opsional, maksimal 1 MB)</span
                    ><input
                        type="file"
                        class="input"
                        accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                        @change="setDocument"
                /></label>
            </div>
            <div class="mt-4 flex flex-wrap items-end gap-3">
                <label class="min-w-60 flex-1"
                    ><span class="label">Aset</span
                    ><select v-model="draft.item_id" class="input">
                        <option value="">Pilih aset</option>
                        <option v-for="asset in assets" :key="asset.id" :value="asset.id">
                            {{ asset.nama || asset.nama_item || asset.name }} (stok
                            {{ asset.stok ?? '-' }})
                        </option>
                    </select></label
                ><label class="w-28"
                    ><span class="label">Jumlah</span
                    ><input
                        v-model.number="draft.quantity"
                        type="number"
                        min="1"
                        class="input" /></label
                ><button type="button" class="btn-secondary" @click="addAsset">Tambah</button>
            </div>
            <div class="mt-3 flex flex-wrap gap-2">
                <span
                    v-for="(asset, i) in form.items"
                    :key="i"
                    class="badge bg-brand-50 text-brand-700"
                    >ID {{ asset.item_id }} × {{ asset.quantity }}
                    <button type="button" class="ml-2" @click="form.items.splice(i, 1)">
                        ×
                    </button></span
                >
            </div>
            <button class="btn-primary mt-5" :disabled="!form.items.length">
                {{ editingId ? 'Simpan perubahan' : 'Kirim pengajuan' }}
            </button>
        </form>
        <div class="card grid gap-3 p-4 md:grid-cols-[1fr_220px]">
            <input
                v-model="search"
                class="input"
                placeholder="Cari PIC, instansi, atau keperluan…"
            /><select v-model="statusFilter" class="input">
                <option value="all">Semua status</option>
                <option value="menunggu">Menunggu</option>
                <option value="proses">Diproses</option>
                <option value="selesai">Selesai</option>
                <option value="tolak">Ditolak</option>
            </select>
        </div>
        <LoadingState v-if="loading" />
        <div v-else class="table-wrap">
            <EmptyState v-if="!items.length" />
            <table v-else class="data-table">
                <thead>
                    <tr>
                        <th>Pengajuan</th>
                        <th>Pemohon</th>
                        <th>Jadwal</th>
                        <th>Status</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="item in displayedItems" :key="item.id">
                        <td>
                            <strong
                                >#{{ item.id }} · {{ item.keterangan || 'Peminjaman aset' }}</strong
                            >
                            <p class="mt-1 text-xs text-slate-500">
                                {{ item.pinjam_items?.length || 0 }} item
                            </p>
                        </td>
                        <td>{{ item.user?.name || item.nama_pic || '-' }}</td>
                        <td>
                            {{ item.tanggal_mulai || '-' }}<br /><span
                                class="text-xs text-slate-400"
                                >{{ item.jam_mulai || '' }}</span
                            >
                        </td>
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
                                <select
                                    v-if="admin"
                                    class="input min-h-9 w-32 py-1"
                                    :value="item.status"
                                    @change="status(item.id, $event.target.value)"
                                >
                                    <option>Menunggu</option>
                                    <option>Proses</option>
                                    <option>Selesai</option>
                                    <option>Ditolak</option></select
                                ><button class="btn-danger min-h-9 px-3" @click="remove(item.id)">
                                    Hapus
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
                    <p class="eyebrow">Detail peminjaman</p>
                    <h2 class="mt-1 text-xl font-bold text-navy">Pengajuan #{{ detail.id }}</h2>
                </div>
                <button class="btn-secondary min-h-9 px-3" @click="detail = null">Tutup</button>
            </div>
            <dl class="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <div>
                    <dt class="label">Pemohon</dt>
                    <dd>{{ detail.user?.name || detail.nama_pic }}</dd>
                </div>
                <div>
                    <dt class="label">Instansi</dt>
                    <dd>{{ detail.instansi_pic || '-' }}</dd>
                </div>
                <div>
                    <dt class="label">Jadwal</dt>
                    <dd>{{ detail.tanggal_mulai || '-' }} {{ detail.jam_mulai || '' }}</dd>
                </div>
                <div>
                    <dt class="label">Status</dt>
                    <dd><StatusBadge :status="detail.status" /></dd>
                </div>
                <div class="sm:col-span-2 lg:col-span-4">
                    <dt class="label">Keperluan</dt>
                    <dd class="whitespace-pre-wrap">{{ detail.keterangan || '-' }}</dd>
                </div>
            </dl>
        </section>
    </div>
</template>
