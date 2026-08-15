<script setup>
import { computed, onMounted, ref } from 'vue'
import { cachedGet, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
const topics = ref([]),
    faqs = ref([]),
    selected = ref(''),
    search = ref(''),
    error = ref(''),
    open = ref(null),
    loading = ref(true)
const topicLabel = (topic) => topic.topik || topic.nama_topik || topic.name || 'Tanpa topik'
const filtered = computed(() =>
    faqs.value.filter((x) =>
        `${x.judul || ''} ${x.detail || ''}`.toLowerCase().includes(search.value.toLowerCase())
    )
)
async function load() {
    loading.value = true
    error.value = ''
    try {
        topics.value = rows(payload(await cachedGet('/topik', {}, 5 * 60_000)))
        faqs.value = rows(
            payload(
                await cachedGet('/faq', {
                    params: selected.value ? { topik_id: selected.value } : {},
                }, 5 * 60_000)
            )
        )
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="FAQ layanan"
        description="Jawaban cepat untuk pertanyaan yang paling sering diajukan."
    /><AlertMessage :message="error" />
    <div class="mb-5 grid gap-3 md:grid-cols-[1fr_250px]">
        <input v-model="search" class="input" placeholder="Cari pertanyaan atau jawaban…" /><select
            v-model="selected"
            class="input"
            @change="load"
        >
            <option value="">Semua topik</option>
            <option v-for="topic in topics" :key="topic.id" :value="topic.id">
                {{ topicLabel(topic) }}
            </option>
        </select>
    </div>
    <section class="mb-5 border-2 border-[var(--line)] p-4">
        <p class="label">Topik FAQ tersedia</p>
        <div class="mt-3 flex flex-wrap gap-2">
            <button
                v-for="topic in topics"
                :key="topic.id"
                type="button"
                class="btn-secondary min-h-9 px-3"
                :class="selected === topic.id ? 'bg-[var(--teal)] text-white' : ''"
                @click="selected = topic.id; load()"
            >
                {{ topicLabel(topic) }}
            </button>
        </div>
    </section>
    <div class="card divide-y divide-slate-100">
        <LoadingState v-if="loading" />
        <EmptyState v-else-if="!filtered.length" title="FAQ belum tersedia" />
        <article v-for="faq in filtered" :key="faq.id">
            <button
                class="flex w-full items-center justify-between gap-4 py-4 text-left font-semibold text-slate-900"
                @click="open = open === faq.id ? null : faq.id"
            >
                <span>{{ faq.judul }}</span
                ><span>{{ open === faq.id ? '−' : '+' }}</span>
            </button>
            <p
                v-if="open === faq.id"
                class="whitespace-pre-wrap pb-5 text-sm leading-7 text-slate-600"
            >
                {{ faq.detail }}
            </p>
        </article>
    </div>
</template>
