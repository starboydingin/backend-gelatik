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
function localDate(offsetDays = 0) {
    const date = new Date()
    date.setDate(date.getDate() + offsetDays)
    return [date.getFullYear(), String(date.getMonth() + 1).padStart(2, '0'), String(date.getDate()).padStart(2, '0')].join('-')
}
const today = localDate()
const tomorrow = localDate(1)
const minimumStartTime = computed(() => {
    if (form.value.tanggal_mulai !== today) return undefined
    const now = new Date(Date.now() + 60_000)
    return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
})
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
async function loadAssets() {
    assets.value = rows(payload(await api.get('/items')))
}
function assetName(itemId) {
    const asset = assets.value.find((entry) => String(entry.id) === String(itemId))
    return asset?.nama || asset?.nama_item || asset?.name || `Aset #${itemId}`
}
function normalizeLoanItems(entries = []) {
    return entries.map((entry) => ({
        item_id: entry.item_id || entry.master_item_id || entry.master_item?.id,
        quantity: entry.quantity || entry.jumlah || 1,
        master_item: entry.master_item,
    }))
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
        items: [],
        dokumen_pendukung: null,
    }
    showForm.value = true
    try {
        await loadAssets()
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
    try {
        const record = payload(await api.get(`/pinjam/${item.id}`))
        editingId.value = record.id
        form.value = {
            ...form.value,
            ...Object.fromEntries(
                Object.keys(form.value)
                    .filter((key) => key !== 'items' && key !== 'dokumen_pendukung')
                    .map((key) => [key, record[key] ?? form.value[key]])
            ),
            dokumen_pendukung: null,
            items: normalizeLoanItems(record.pinjam_items),
        }
        showForm.value = true
        await loadAssets()
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function showDetail(id) {
    try {
        detail.value = payload(await api.get(`/pinjam/${id}`))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function addAsset() {
    if (!draft.value.item_id) return
    const nextItem = { ...draft.value }
    try {
        if (editingId.value) {
            const updated = payload(await api.post(`/pinjam/${editingId.value}`, { items: [nextItem] }))
            form.value.items = normalizeLoanItems(updated.pinjam_items)
            await load()
        } else {
            const existing = form.value.items.find(
                (entry) => String(entry.item_id) === String(nextItem.item_id)
            )
            if (existing) existing.quantity += Number(nextItem.quantity)
            else form.value.items.push(nextItem)
        }
        draft.value = { item_id: '', quantity: 1 }
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function removeAsset(index) {
    const entry = form.value.items[index]
    if (!entry) return
    try {
        if (editingId.value) {
            const updated = payload(
                await api.delete(`/pinjam/${editingId.value}/item/${entry.item_id}`)
            )
            form.value.items = normalizeLoanItems(updated.pinjam_items)
            await load()
        } else {
            form.value.items.splice(index, 1)
        }
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function submit() {
    error.value = ''
    try {
        if (editingId.value) {
            const updateData = { ...form.value }
            delete updateData.dokumen_pendukung
            delete updateData.items
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
                        :min="today"
                        :max="tomorrow"
                        class="input"
                        required /></label
                ><label
                    ><span class="label">Jam mulai</span
                    ><input v-model="form.jam_mulai" type="time" class="input" :min="minimumStartTime" /></label
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
                ><label v-if="!editingId" class="md:col-span-2"
                    ><span class="label">Keterangan</span
                    ><textarea v-model="form.keterangan" class="input min-h-24"></textarea></label
                ><label class="md:col-span-2"
                    ><span class="label">Unggah dokumen pendukung (opsional, maksimal 1 MB)</span
                    ><input
                        type="file"
                        class="input"
                        accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                        @change="setDocument"
                /></label
                ><p v-if="editingId" class="md:col-span-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-3 text-sm">
                    Dokumen pendukung tidak dapat diubah setelah pengajuan dikirim.
                </p>
            </div>
            <section class="mt-6 border-t border-[var(--color-border)] pt-5">
                <div class="flex flex-wrap items-end justify-between gap-3">
                    <div>
                        <p class="eyebrow">Daftar aset</p>
                        <h3 class="mt-1 font-brand text-lg font-extrabold">Aset dalam pengajuan</h3>
                    </div>
                    <p class="text-sm font-medium text-slate-600">
                        {{ editingId ? 'Perubahan aset langsung disimpan.' : 'Tambahkan minimal satu aset.' }}
                    </p>
                </div>
                <div v-if="form.items.length" class="mt-4 divide-y divide-[var(--color-border)] overflow-hidden rounded-lg border border-[var(--color-border)]">
                    <div v-for="(asset, i) in form.items" :key="`${asset.item_id}-${i}`" class="flex flex-wrap items-center justify-between gap-3 p-3">
                        <div>
                            <strong>{{ asset.master_item?.nama || assetName(asset.item_id) }}</strong>
                            <p class="mt-1 text-sm text-slate-600">Jumlah: {{ asset.quantity }}</p>
                        </div>
                        <button type="button" class="btn-danger min-h-9 px-3" @click="removeAsset(i)">
                            Hapus aset
                        </button>
                    </div>
                </div>
                <p v-else class="mt-4 rounded-lg border border-dashed border-[var(--color-border-strong)] p-3 text-sm font-medium">
                    Belum ada aset yang dipilih.
                </p>
            </section>
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
                            <div v-if="admin" class="flex">
                                <RouterLink
                                    class="btn-secondary min-h-9 px-3"
                                    :to="`/admin/peminjaman/${item.id}/kelola`"
                                >
                                    Kelola
                                </RouterLink>
                            </div>
                            <div v-else class="flex flex-wrap gap-2">
                                <button
                                    class="btn-secondary min-h-9 px-3"
                                    @click="showDetail(item.id)"
                                >
                                    Detail
                                </button>
                                <button
                                    v-if="!admin && String(item.status).toLowerCase() === 'menunggu'"
                                    class="btn-secondary min-h-9 px-3"
                                    @click="edit(item)"
                                >
                                    Edit
                                </button>
                                <button class="btn-danger min-h-9 px-3" @click="remove(item.id)">
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
                <div class="sm:col-span-2 lg:col-span-4">
                    <dt class="label">Aset yang diajukan</dt>
                    <dd class="mt-2 divide-y divide-[var(--color-border)] overflow-hidden rounded-lg border border-[var(--color-border)]">
                        <div
                            v-for="entry in detail.pinjam_items || []"
                            :key="entry.id || entry.item_id"
                            class="flex items-center justify-between gap-3 p-3"
                        >
                            <span>{{ entry.master_item?.nama || entry.master_item?.nama_item || `Aset #${entry.item_id}` }}</span>
                            <strong>Jumlah {{ entry.quantity || entry.jumlah || 1 }}</strong>
                        </div>
                        <p v-if="!(detail.pinjam_items || []).length" class="p-3">Data aset belum tersedia.</p>
                    </dd>
                </div>
            </dl>
        </section>
    </div>
</template>
