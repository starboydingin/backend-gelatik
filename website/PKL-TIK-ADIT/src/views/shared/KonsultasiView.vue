<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { api, payload, rows, errorMessage } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
import ServiceHero from '../../components/ServiceHero.vue'
import StatusSummary from '../../components/StatusSummary.vue'
import StatusBadge from '../../components/StatusBadge.vue'
const route = useRoute(),
    admin = computed(() => route.path.startsWith('/admin')),
    list = ref([]),
    topics = ref([]),
    loading = ref(true),
    error = ref(''),
    search = ref(''),
    statusFilter = ref('all'),
    showForm = ref(false),
    form = ref({ judul: '', topik_id: '', deskripsi: '', file: null }),
    editingId = ref(null),
    detail = ref(null),
    reply = ref({}),
    expanded = ref(null)
const topicLabel = (topic) => topic.topik || topic.nama_topik || topic.name || 'Tanpa topik'
const statusItems = computed(() => [
    {
        label: 'Menunggu',
        value: list.value.filter((item) => /menunggu/i.test(item.status)).length,
        tone: 'waiting',
    },
    {
        label: 'Diproses',
        value: list.value.filter((item) => /proses/i.test(item.status)).length,
        tone: 'process',
    },
    {
        label: 'Ditolak',
        value: list.value.filter((item) => /tolak/i.test(item.status)).length,
        tone: 'rejected',
    },
    {
        label: 'Selesai',
        value: list.value.filter((item) => /selesai/i.test(item.status)).length,
        tone: 'done',
    },
])
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
async function load() {
    loading.value = true
    try {
        list.value = rows(payload(await api.get('/konsul')))
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
async function loadTopics() {
    topics.value = rows(payload(await api.get('/topik')))
}
async function open() {
    editingId.value = null
    form.value = { judul: '', topik_id: '', deskripsi: '', file: null }
    showForm.value = true
    try {
        await loadTopics()
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function edit(item) {
    try {
        const record = payload(await api.get(`/konsul/${item.id}`))
        editingId.value = record.id
        form.value = {
            judul: record.judul || '',
            topik_id: record.topik_id || record.faq_id || '',
            deskripsi: record.deskripsi || record.pesan || record.pertanyaan || '',
            file: null,
        }
        await loadTopics()
        showForm.value = true
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function showDetail(id) {
    try {
        detail.value = payload(await api.get(`/konsul/${id}`))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function submit() {
    try {
        if (editingId.value) {
            await api.put(`/konsul/${editingId.value}`, {
                judul: form.value.judul,
                topik_id: form.value.topik_id,
                deskripsi: form.value.deskripsi,
            })
            editingId.value = null
            showForm.value = false
            await load()
            return
        }
        const body = new FormData()
        body.append('judul', form.value.judul)
        body.append('topik_id', form.value.topik_id)
        body.append('deskripsi', form.value.deskripsi)
        if (form.value.file) body.append('file', form.value.file)
        await api.post('/konsul', body)
        showForm.value = false
        form.value = { judul: '', topik_id: '', deskripsi: '', file: null }
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function respond(id) {
    try {
        await api.post(`/konsul/${id}/response`, { isi_respon: reply.value[id] })
        reply.value[id] = ''
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function status(id, value) {
    try {
        await api.post(`/konsul/${id}/status`, { status: value })
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function remove(id) {
    if (!confirm('Hapus konsultasi ini?')) return
    try {
        await api.delete(`/konsul/${id}`)
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
            eyebrow="Layanan konsultasi"
            title="Butuh bantuan dari tim TIK?"
            description="Sampaikan kendala atau kebutuhan teknologi, pantau statusnya, dan lanjutkan percakapan dalam satu tempat."
            ><button v-if="!admin" class="btn-primary" @click="open">
                Buat konsultasi
            </button></ServiceHero
        >
        <StatusSummary :items="statusItems" />
        <AlertMessage :message="error" />
        <form v-if="showForm" class="card mb-6" @submit.prevent="submit">
            <div class="flex justify-between">
                <h2 class="text-lg font-bold">{{ editingId ? 'Edit konsultasi' : 'Konsultasi baru' }}</h2>
                <button type="button" @click="showForm = false">✕</button>
            </div>
            <div class="mt-5 grid gap-4 md:grid-cols-2">
                <label
                    ><span class="label">Judul</span
                    ><input v-model="form.judul" class="input" required /></label
                ><label
                    ><span class="label">Topik</span
                    ><select v-model="form.topik_id" class="input" required>
                        <option value="">Pilih topik</option>
                        <option v-for="topic in topics" :key="topic.id" :value="topic.id">
                            {{ topicLabel(topic) }}
                        </option>
                    </select></label
                ><label v-if="!editingId" class="md:col-span-2"
                    ><span class="label">Penjelasan</span
                    ><textarea
                        v-model="form.deskripsi"
                        class="input min-h-28"
                        required
                    ></textarea></label
                ><label class="md:col-span-2"
                    ><span class="label">Lampiran (opsional)</span
                    ><input
                        type="file"
                        class="input"
                        accept=".jpg,.jpeg,.png,.pdf"
                        @change="form.file = $event.target.files[0]"
                /></label>
            </div>
            <section class="mt-5 border-t-2 border-[var(--line)] pt-4">
                <p class="label">Daftar topik tersedia</p>
                <div class="mt-3 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                    <button
                        v-for="topic in topics"
                        :key="topic.id"
                        type="button"
                        class="btn-secondary min-h-10 justify-start px-3 text-left normal-case"
                        :class="String(form.topik_id) === String(topic.id) ? 'bg-[var(--teal)] text-white' : ''"
                        @click="form.topik_id = topic.id"
                    >
                        {{ topicLabel(topic) }}
                    </button>
                </div>
            </section>
            <button class="btn-primary mt-5">{{ editingId ? 'Simpan perubahan' : 'Kirim konsultasi' }}</button>
        </form>
        <div class="card grid gap-3 p-4 md:grid-cols-[1fr_220px]">
            <input v-model="search" class="input" placeholder="Cari judul konsultasi…" /><select
                v-model="statusFilter"
                class="input"
            >
                <option value="all">Semua status</option>
                <option value="menunggu">Menunggu</option>
                <option value="proses">Diproses</option>
                <option value="selesai">Selesai</option>
                <option value="tolak">Ditolak</option>
            </select>
        </div>
        <LoadingState v-if="loading" />
        <div v-else class="space-y-3">
            <EmptyState v-if="!list.length" />
            <article v-for="item in displayedList" :key="item.id" class="card">
                <div class="flex w-full flex-wrap items-start justify-between gap-4 text-left">
                    <div>
                        <div class="flex flex-wrap items-center gap-2">
                            <h2 class="font-bold text-slate-950">
                                {{
                                    item.judul || topicLabel(item.topik || {}) || `Konsultasi #${item.id}`
                                }}
                            </h2>
                            <StatusBadge :status="item.status" />
                        </div>
                        <p class="mt-1 text-sm text-slate-500">
                            {{ item.user?.name }} · {{ item.created_at }}
                        </p>
                    </div>
                    <div class="flex flex-wrap gap-2">
                        <button class="btn-secondary min-h-9 px-3" @click="showDetail(item.id)">Detail</button>
                        <button
                            v-if="!admin && String(item.status).toLowerCase() === 'menunggu'"
                            class="btn-secondary min-h-9 px-3"
                            @click="edit(item)"
                        >
                            Edit
                        </button>
                        <button
                            class="btn-secondary min-h-9 px-3"
                            @click="expanded = expanded === item.id ? null : item.id"
                        >
                            {{ expanded === item.id ? 'Tutup ringkasan' : 'Ringkasan' }}
                        </button>
                    </div>
                </div>
                <div v-if="expanded === item.id" class="mt-5 border-t border-slate-100 pt-5">
                    <p class="whitespace-pre-wrap text-sm leading-7">
                        {{
                            item.deskripsi ||
                            item.keterangan ||
                            item.isi_konsultasi ||
                            item.pertanyaan
                        }}
                    </p>
                    <div class="mt-4 space-y-2">
                        <div
                            v-for="response in item.responses || []"
                            :key="response.id"
                            class="rounded-xl bg-slate-50 p-3 text-sm"
                        >
                            <strong>{{ response.user?.name || 'Petugas' }}</strong>
                            <p class="mt-1">{{ response.isi_respon || response.jawaban }}</p>
                        </div>
                    </div>
                    <div v-if="admin" class="mt-4 flex gap-2">
                        <input
                            v-model="reply[item.id]"
                            class="input"
                            placeholder="Tulis tanggapan…"
                        /><button
                            class="btn-primary"
                            :disabled="!reply[item.id]"
                            @click="respond(item.id)"
                        >
                            Kirim
                        </button>
                    </div>
                    <div class="mt-3 flex flex-wrap gap-2">
                        <select
                            v-if="admin"
                            class="input w-40"
                            :value="item.status"
                            @change="status(item.id, $event.target.value)"
                        >
                            <option>Diproses</option>
                            <option>Ditolak</option>
                            <option>Selesai</option></select
                        ><button class="btn-danger" @click="remove(item.id)">Hapus</button>
                    </div>
                </div>
            </article>
        </div>
        <section v-if="detail" class="card">
            <div class="flex flex-wrap items-start justify-between gap-4">
                <div>
                    <p class="eyebrow">Detail konsultasi</p>
                    <h2 class="mt-1 font-brand text-xl font-extrabold">{{ detail.judul || 'Konsultasi TIK' }}</h2>
                </div>
                <button class="btn-secondary min-h-9 px-3" @click="detail = null">Tutup</button>
            </div>
            <dl class="mt-5 grid gap-4 sm:grid-cols-2">
                <div><dt class="label">Topik</dt><dd>{{ topicLabel(detail.topik || {}) }}</dd></div>
                <div><dt class="label">Status</dt><dd><StatusBadge :status="detail.status" /></dd></div>
                <div class="sm:col-span-2">
                    <dt class="label">Permintaan Anda</dt>
                    <dd class="whitespace-pre-wrap">{{ detail.deskripsi || detail.pesan || detail.pertanyaan || '-' }}</dd>
                </div>
                <div class="sm:col-span-2">
                    <dt class="label">Tanggapan petugas</dt>
                    <dd class="mt-2 space-y-3">
                        <article v-for="response in detail.responses || []" :key="response.id" class="border-2 border-[var(--line)] p-3">
                            <strong>{{ response.user?.name || 'Petugas' }}</strong>
                            <p class="mt-1 whitespace-pre-wrap">{{ response.isi_respon || response.jawaban || response.pesan }}</p>
                        </article>
                        <p v-if="!(detail.responses || []).length">Belum ada tanggapan dari petugas.</p>
                    </dd>
                </div>
            </dl>
        </section>
    </div>
</template>
