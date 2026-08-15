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
const allowedFaqTags = new Set(['p', 'strong', 'b', 'em', 'i', 'ul', 'ol', 'li', 'br', 'h3', 'h4'])

function sanitizeFaqDetail(value) {
    const source = document.createElement('div')
    const output = document.createElement('div')
    source.innerHTML = value || ''

    const appendNode = (node, parent) => {
        if (node.nodeType === 3) {
            parent.append(document.createTextNode(node.textContent || ''))
            return
        }
        if (node.nodeType !== 1) return

        const tag = node.tagName.toLowerCase()
        const target = allowedFaqTags.has(tag) ? document.createElement(tag) : parent
        for (const child of node.childNodes) appendNode(child, target)
        if (target !== parent) parent.append(target)
    }

    for (const node of source.childNodes) appendNode(node, output)
    return output.innerHTML
}
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
        ).map((faq) => ({ ...faq, formatted_detail: sanitizeFaqDetail(faq.detail) }))
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
    <div class="card overflow-hidden">
        <LoadingState v-if="loading" />
        <EmptyState v-else-if="!filtered.length" title="FAQ belum tersedia" />
        <article v-for="faq in filtered" :key="faq.id" class="faq-item">
            <button
                type="button"
                class="faq-trigger"
                :aria-expanded="open === faq.id"
                @click="open = open === faq.id ? null : faq.id"
            >
                <span>{{ faq.judul }}</span
                ><span>{{ open === faq.id ? '−' : '+' }}</span>
            </button>
            <Transition name="faq-answer">
                <div v-if="open === faq.id" class="faq-answer">
                    <div class="faq-answer-content" v-html="faq.formatted_detail"></div>
                </div>
            </Transition>
        </article>
    </div>
</template>

<style scoped>
.faq-item + .faq-item {
    border-top: 2px solid var(--line);
}

.faq-trigger {
    display: flex;
    width: 100%;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 1rem 1.25rem;
    color: var(--ink);
    font-weight: 700;
    text-align: left;
    transition: background-color 160ms ease-out, transform 160ms ease-out;
}

.faq-trigger:hover,
.faq-trigger:focus-visible {
    background: #f1f5f9;
}

.faq-trigger:active {
    transform: translateY(1px);
}

.faq-answer {
    max-height: 1400px;
    overflow: hidden;
}

.faq-answer-content {
    padding: 0 1.25rem 1.25rem;
    color: #334155;
    font-size: 0.9375rem;
    line-height: 1.75;
}

.faq-answer-content :deep(p) {
    margin: 0 0 0.875rem;
}

.faq-answer-content :deep(ul),
.faq-answer-content :deep(ol) {
    margin: 0 0 0.875rem 1.25rem;
}

.faq-answer-content :deep(ul) {
    list-style: disc;
}

.faq-answer-content :deep(ol) {
    list-style: decimal;
}

.faq-answer-content :deep(li + li) {
    margin-top: 0.25rem;
}

.faq-answer-enter-active,
.faq-answer-leave-active {
    transition: max-height 240ms ease-out, opacity 180ms ease-out;
}

.faq-answer-enter-from,
.faq-answer-leave-to {
    max-height: 0;
    opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
    .faq-trigger,
    .faq-answer-enter-active,
    .faq-answer-leave-active {
        transition: none;
    }
}
</style>
