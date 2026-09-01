<script setup>
import { computed, onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'

const catalogs = [
    { key: 'items', label: 'Aset TIK' },
    { key: 'topik', label: 'Topik konsultasi' },
    { key: 'faq', label: 'FAQ' },
    { key: 'sliders', label: 'Slider' },
    { key: 'routers', label: 'Router OPD' },
]
const selected = ref('items')
const data = ref({ items: [], topik: [], faq: [], sliders: [], routers: [] })
const form = ref({})
const editingId = ref(null)
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const notice = ref('')
const currentRows = computed(() => data.value[selected.value] || [])
const currentLabel = computed(() => catalogs.find((item) => item.key === selected.value)?.label)
const loadedCatalogs = new Set()

function blankForm() {
    if (selected.value === 'items')
        return { nama: '', deskripsi: '', stok: 0, kondisi: 'Baik', foto: '' }
    if (selected.value === 'topik') return { topik: '', status: true }
    if (selected.value === 'faq') return { topik_id: '', judul: '', detail: '', status: true }
    if (selected.value === 'routers') {
        return {
            nama_opd: '',
            identity_router: '',
            interface: '',
            lokasi: '',
            bandwidth_download_mbps: '',
            bandwidth_upload_mbps: '',
            status: true,
        }
    }
    return { judul: '', image: '', status: true }
}
function resetForm() {
    editingId.value = null
    form.value = blankForm()
}
async function selectCatalog(key) {
    selected.value = key
    notice.value = ''
    resetForm()
    await loadCatalog(key)
}
async function loadCatalog(key = selected.value, force = false) {
    if (loadedCatalogs.has(key) && !force) return
    loading.value = true
    error.value = ''
    try {
        data.value[key] = rows(payload(await api.get(`/admin/${key}`)))
        loadedCatalogs.add(key)

        // FAQ needs a topic list for its form, but it does not need the other
        // master-data endpoints. Load that single dependency only when needed.
        if (key === 'faq' && !loadedCatalogs.has('topik')) {
            data.value.topik = rows(payload(await api.get('/admin/topik')))
            loadedCatalogs.add('topik')
        }
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
function edit(item) {
    editingId.value = item.id
    form.value = { ...item, status: String(item.status) !== '0' }
}
function requestBody() {
    const body = { ...form.value, status: form.value.status ? 1 : 0 }
    if (selected.value === 'items') {
        delete body.status
        body.stok = Number(body.stok)
    }
    if (selected.value === 'faq') body.topik_id = Number(body.topik_id)
    if (selected.value === 'routers') {
        body.bandwidth_download_mbps = body.bandwidth_download_mbps === '' ? null : Number(body.bandwidth_download_mbps)
        body.bandwidth_upload_mbps = body.bandwidth_upload_mbps === '' ? null : Number(body.bandwidth_upload_mbps)
    }
    return body
}
async function save() {
    saving.value = true
    error.value = ''
    notice.value = ''
    try {
        const endpoint = `/admin/${selected.value}`
        if (editingId.value) await api.put(`${endpoint}/${editingId.value}`, requestBody())
        else await api.post(endpoint, requestBody())
        notice.value = `${currentLabel.value} berhasil disimpan.`
        await loadCatalog(selected.value, true)
        resetForm()
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        saving.value = false
    }
}
function displayName(item) {
    return item.nama || item.topik || item.judul || item.identity_router || `Data #${item.id}`
}
async function remove(item) {
    if (!confirm(`Hapus ${displayName(item)}?`)) return
    try {
        await api.delete(`/admin/${selected.value}/${item.id}`)
        await loadCatalog(selected.value, true)
        if (editingId.value === item.id) resetForm()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
onMounted(async () => {
    resetForm()
    await loadCatalog()
})
</script>
<template>
    <PageHeader
        title="Referensi layanan"
        description="Kelola data master yang digunakan portal web dan aplikasi mobile."
    />
    <AlertMessage :message="error" />
    <p
        v-if="notice"
        class="mb-4 border-l-4 border-emerald-500 bg-emerald-50 px-4 py-3 text-sm text-emerald-800"
    >
        {{ notice }}
    </p>
    <LoadingState v-if="loading" />
    <template v-else>
        <div class="mb-5 flex flex-wrap gap-2 border-b border-stroke pb-3">
            <button
                v-for="catalog in catalogs"
                :key="catalog.key"
                type="button"
                class="btn-secondary"
                :class="
                    selected === catalog.key ? '!border-brand-600 !bg-brand-50 !text-brand-800' : ''
                "
                @click="selectCatalog(catalog.key)"
            >
                {{ catalog.label }}
            </button>
        </div>
        <div class="grid gap-4 xl:grid-cols-[minmax(0,1fr)_360px]">
            <section class="section-panel overflow-hidden">
                <div class="border-b border-stroke px-5 py-4">
                    <h2 class="font-bold text-navy">{{ currentLabel }}</h2>
                    <p class="mt-1 text-sm text-slate-500">
                        {{ currentRows.length }} data tersedia
                    </p>
                </div>
                <div class="divide-y divide-stroke">
                    <p
                        v-if="!currentRows.length"
                        class="px-4 py-7 text-center text-sm text-slate-500"
                    >
                        Belum ada data.
                    </p>
                    <article
                        v-for="item in currentRows"
                        :key="item.id"
                        class="flex flex-col gap-3 px-5 py-4 sm:flex-row sm:items-start sm:justify-between"
                    >
                        <div class="min-w-0">
                            <h3 class="font-semibold text-slate-900">{{ displayName(item) }}</h3>
                            <p
                                v-if="item.deskripsi || item.detail"
                                class="mt-1 line-clamp-2 text-sm leading-6 text-slate-500"
                            >
                                {{ item.deskripsi || item.detail }}
                            </p>
                            <p v-if="selected === 'items'" class="mt-1 text-xs text-slate-500">
                                Stok {{ item.stok }} · {{ item.kondisi }}
                            </p>
                            <p v-if="selected === 'routers'" class="mt-1 text-xs text-slate-500">
                                {{ item.nama_opd }} · {{ item.interface || 'Tanpa interface' }} ·
                                {{ item.lokasi || 'Tanpa lokasi' }}
                            </p>
                            <p v-if="selected === 'routers'" class="mt-1 text-xs text-slate-500">
                                Bandwidth: {{ item.bandwidth_download_mbps ?? 'belum tersedia' }}
                                Mbps unduh · {{ item.bandwidth_upload_mbps ?? 'belum tersedia' }}
                                Mbps unggah
                            </p>
                        </div>
                        <div class="flex shrink-0 gap-2">
                            <button class="btn-secondary" type="button" @click="edit(item)">
                                Ubah</button
                            ><button class="btn-danger" type="button" @click="remove(item)">
                                Hapus
                            </button>
                        </div>
                    </article>
                </div>
            </section>
            <form class="section-panel h-fit p-5" @submit.prevent="save">
                <h2 class="font-bold text-navy">
                    {{ editingId ? `Ubah ${currentLabel}` : `Tambah ${currentLabel}` }}
                </h2>
                <div class="mt-5 space-y-4">
                    <template v-if="selected === 'items'">
                        <label
                            ><span class="label">Nama aset</span
                            ><input v-model="form.nama" class="input" required
                        /></label>
                        <label
                            ><span class="label">Deskripsi</span
                            ><textarea v-model="form.deskripsi" class="input min-h-24" required />
                        </label>
                        <div class="grid grid-cols-2 gap-3">
                            <label
                                ><span class="label">Stok</span
                                ><input
                                    v-model.number="form.stok"
                                    type="number"
                                    min="0"
                                    class="input"
                                    required /></label
                            ><label
                                ><span class="label">Kondisi</span
                                ><select v-model="form.kondisi" class="input">
                                    <option>Baik</option>
                                    <option>Rusak Sebagian</option>
                                    <option>Rusak Parah</option>
                                    <option>Tidak Berfungsi</option>
                                </select></label
                            >
                        </div>
                        <label
                            ><span class="label">URL foto (opsional)</span
                            ><input v-model="form.foto" class="input"
                        /></label>
                    </template>
                    <template v-else-if="selected === 'topik'"
                        ><label
                            ><span class="label">Nama topik</span
                            ><input v-model="form.topik" class="input" required /></label
                    ></template>
                    <template v-else-if="selected === 'faq'">
                        <label
                            ><span class="label">Topik</span
                            ><select v-model="form.topik_id" class="input" required>
                                <option value="">Pilih topik</option>
                                <option
                                    v-for="topic in data.topik"
                                    :key="topic.id"
                                    :value="topic.id"
                                >
                                    {{ topic.topik }}
                                </option>
                            </select></label
                        >
                        <label
                            ><span class="label">Pertanyaan</span
                            ><input v-model="form.judul" class="input" required
                        /></label>
                        <label
                            ><span class="label">Jawaban</span
                            ><textarea v-model="form.detail" class="input min-h-36" required />
                        </label>
                    </template>
                    <template v-else-if="selected === 'routers'">
                        <label
                            ><span class="label">Nama OPD</span
                            ><input v-model="form.nama_opd" class="input" required
                        /></label>
                        <label
                            ><span class="label">Identitas router</span
                            ><input v-model="form.identity_router" class="input" required
                        /></label>
                        <label
                            ><span class="label">Interface</span
                            ><input v-model="form.interface" class="input"
                        /></label>
                        <label
                            ><span class="label">Lokasi</span
                            ><input v-model="form.lokasi" class="input"
                        /></label>
                        <div class="grid gap-3 sm:grid-cols-2">
                            <label
                                ><span class="label">Bandwidth unduh (Mbps)</span
                                ><input
                                    v-model.number="form.bandwidth_download_mbps"
                                    type="number"
                                    min="0"
                                    step="0.01"
                                    class="input"
                            /></label>
                            <label
                                ><span class="label">Bandwidth unggah (Mbps)</span
                                ><input
                                    v-model.number="form.bandwidth_upload_mbps"
                                    type="number"
                                    min="0"
                                    step="0.01"
                                    class="input"
                            /></label>
                        </div>
                    </template>
                    <template v-else
                        ><label
                            ><span class="label">Judul</span
                            ><input v-model="form.judul" class="input" required /></label
                        ><label
                            ><span class="label">URL gambar</span
                            ><input v-model="form.image" class="input" required /></label
                    ></template>
                    <label
                        v-if="selected !== 'items'"
                        class="flex items-center gap-3 text-sm font-medium text-slate-700"
                        ><input v-model="form.status" type="checkbox" class="h-4 w-4" />
                        Aktif</label
                    >
                </div>
                <div class="mt-5 flex gap-2">
                    <button class="btn-primary" :disabled="saving">
                        {{ saving ? 'Menyimpan…' : 'Simpan' }}</button
                    ><button
                        v-if="editingId"
                        class="btn-secondary"
                        type="button"
                        @click="resetForm"
                    >
                        Batal
                    </button>
                </div>
            </form>
        </div>
    </template>
</template>
