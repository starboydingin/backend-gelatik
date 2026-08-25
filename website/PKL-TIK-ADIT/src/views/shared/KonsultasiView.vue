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
import SummaryModal from '../../components/SummaryModal.vue'
import PaginationControls from '../../components/PaginationControls.vue'
import SearchableSelect from '../../components/SearchableSelect.vue'
import { formatDateTime } from '../../lib/date'
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
    summary = ref(null),
    page = ref(1),
    pagination = ref({ current_page: 1, last_page: 1, total: 0 })
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
async function load({ fresh = false } = {}) {
    loading.value = true
    error.value = ''
    try {
        const data = payload(
            await api.get('/konsul', { params: { page: page.value }, cache: !fresh })
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
function showSummary(item) {
    summary.value = item
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
            await load({ fresh: true })
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
        await load({ fresh: true })
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function remove(id) {
    if (!confirm('Hapus konsultasi ini?')) return
    try {
        await api.delete(`/konsul/${id}`)
        await load({ fresh: true })
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
                <h2 class="text-lg font-bold">
                    {{ editingId ? 'Edit konsultasi' : 'Konsultasi baru' }}
                </h2>
                <button type="button" @click="showForm = false">✕</button>
            </div>
            <div class="mt-5 grid gap-4 md:grid-cols-2">
                <label
                    ><span class="label">Judul</span
                    ><input v-model="form.judul" class="input" required /></label
                ><SearchableSelect
                    v-model="form.topik_id"
                    label="Topik"
                    placeholder="Pilih topik"
                    search-placeholder="Cari topik konsultasi…"
                    :options="
                        topics.map((topic) => ({ value: topic.id, label: topicLabel(topic) }))
                    "
                />
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
            <section class="mt-5 border-t border-[var(--color-border)] pt-4">
                <p class="label">Daftar topik tersedia</p>
                <div class="mt-3 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                    <button
                        v-for="topic in topics"
                        :key="topic.id"
                        type="button"
                        class="btn-secondary min-h-10 justify-start px-3 text-left normal-case"
                        :class="
                            String(form.topik_id) === String(topic.id)
                                ? '!border-[var(--color-brand-primary)] !bg-[var(--color-brand-primary)] !text-white'
                                : ''
                        "
                        @click="form.topik_id = topic.id"
                    >
                        {{ topicLabel(topic) }}
                    </button>
                </div>
            </section>
            <button class="btn-primary mt-5">
                {{ editingId ? 'Simpan perubahan' : 'Kirim konsultasi' }}
            </button>
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
        <div v-else>
            <EmptyState v-if="!list.length" />
            <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                <article
                    v-for="item in displayedList"
                    :key="item.id"
                    class="card flex min-h-64 flex-col"
                >
                    <div class="flex items-start justify-between gap-3">
                        <p class="eyebrow">Konsultasi #{{ item.id }}</p>
                        <StatusBadge :status="item.status" />
                    </div>
                    <h2 class="mt-3 line-clamp-2 text-lg font-bold">
                        {{ item.judul || topicLabel(item.topik || {}) }}
                    </h2>
                    <p class="mt-3 line-clamp-3 text-sm leading-6 text-slate-600">
                        {{ item.pesan || item.deskripsi || item.pertanyaan || '-' }}
                    </p>
                    <dl class="mt-4 grid gap-3 text-sm sm:grid-cols-2">
                        <div>
                            <dt class="label">Pemohon</dt>
                            <dd>{{ item.user?.name || '-' }}</dd>
                        </div>
                        <div>
                            <dt class="label">Diajukan</dt>
                            <dd>{{ formatDateTime(item.created_at) }}</dd>
                        </div>
                    </dl>
                    <div class="mt-auto flex flex-wrap gap-2 pt-5">
                        <button class="btn-secondary min-h-9 px-3" @click="showSummary(item)">
                            Ringkasan</button
                        ><RouterLink
                            class="btn-secondary min-h-9 px-3"
                            :to="`${admin ? '/admin' : '/app'}/konsultasi/${item.id}`"
                            >Detail</RouterLink
                        ><button
                            v-if="!admin && String(item.status).toLowerCase() === 'menunggu'"
                            class="btn-secondary min-h-9 px-3"
                            @click="edit(item)"
                        >
                            Edit</button
                        ><button
                            v-if="!admin && String(item.status).toLowerCase() === 'menunggu'"
                            class="btn-danger min-h-9 px-3"
                            @click="remove(item.id)"
                        >
                            Hapus
                        </button>
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
        <SummaryModal
            :open="Boolean(summary)"
            :title="summary?.judul || `Konsultasi #${summary?.id}`"
            @close="summary = null"
            ><dl v-if="summary" class="grid gap-4 sm:grid-cols-2">
                <div>
                    <dt class="label">Status</dt>
                    <dd><StatusBadge :status="summary.status" /></dd>
                </div>
                <div>
                    <dt class="label">Topik</dt>
                    <dd>{{ topicLabel(summary.topik || {}) }}</dd>
                </div>
                <div class="sm:col-span-2">
                    <dt class="label">Keterangan</dt>
                    <dd class="line-clamp-5 whitespace-pre-wrap">
                        {{ summary.pesan || summary.deskripsi || '-' }}
                    </dd>
                </div>
                <div class="sm:col-span-2">
                    <dt class="label">Balasan</dt>
                    <dd>{{ summary.responses?.length || 0 }} tanggapan</dd>
                </div>
            </dl></SummaryModal
        >
    </div>
</template>
