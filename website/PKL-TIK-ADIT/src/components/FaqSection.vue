<script setup>
import { computed, onMounted, ref } from 'vue'
import { cachedGet, payload, rows, errorMessage } from '../lib/api'
import { ChevronDownIcon, MagnifyingGlassIcon } from '@heroicons/vue/24/outline'

const topics = ref([])
const faqs = ref([])
const selectedTopic = ref('')
const search = ref('')
const error = ref('')
const openId = ref(null)
const loading = ref(true)

const allowedFaqTags = new Set(['p', 'strong', 'b', 'em', 'i', 'ul', 'ol', 'li', 'br', 'h3', 'h4'])

function sanitizeFaqDetail(value) {
    if (!value) return ''
    const source = document.createElement('div')
    const output = document.createElement('div')
    source.innerHTML = value

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

const topicLabel = (topic) => topic.topik || topic.nama_topik || topic.name || 'Tanpa topik'

const filteredFaqs = computed(() => {
    return faqs.value.filter((faq) => {
        const matchesSearch =
            !search.value.trim() ||
            `${faq.judul || ''} ${faq.detail || ''}`
                .toLowerCase()
                .includes(search.value.toLowerCase().trim())
        const matchesTopic =
            !selectedTopic.value || String(faq.topik_id) === String(selectedTopic.value)
        return matchesSearch && matchesTopic
    })
})

function toggleFaq(id) {
    openId.value = openId.value === id ? null : id
}

async function loadFaqs() {
    loading.value = true
    error.value = ''
    try {
        const [topicRes, faqRes] = await Promise.all([
            cachedGet('/topik', {}, 5 * 60_000),
            cachedGet('/faq', {}, 5 * 60_000),
        ])
        topics.value = rows(payload(topicRes))
        faqs.value = rows(payload(faqRes)).map((faq) => ({
            ...faq,
            formatted_detail: sanitizeFaqDetail(faq.detail),
        }))
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}

onMounted(loadFaqs)
</script>

<template>
    <section id="faq" class="border-t border-[var(--color-border)] bg-[var(--color-surface)] py-8 sm:py-10">
        <div class="mx-auto max-w-3xl px-4 sm:px-6">
            <div class="text-center">
                <p class="eyebrow justify-center">FAQ & Panduan</p>
                <h2 class="mt-1.5 font-brand text-xl font-bold tracking-tight sm:text-2xl">
                    Pertanyaan yang Sering Diajukan
                </h2>
                <p class="mx-auto mt-1.5 max-w-xl text-xs sm:text-sm leading-normal text-[var(--color-text-secondary)]">
                    Temukan jawaban cepat seputar peminjaman aset, konsultasi teknis, usulan email resmi, dan layanan jaringan di lingkungan Pemerintah Provinsi Lampung.
                </p>
            </div>

            <!-- Search & Filters -->
            <div class="mt-4 sm:mt-5 space-y-2.5">
                <div class="relative mx-auto max-w-md">
                    <MagnifyingGlassIcon
                        class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-slate-400"
                    />
                    <input
                        v-model="search"
                        type="text"
                        placeholder="Cari pertanyaan atau jawaban..."
                        class="input w-full py-1.5 pl-9 pr-3 text-xs sm:text-sm"
                    />
                </div>

                <div v-if="topics.length" class="flex flex-wrap items-center justify-center gap-1.5 pt-0.5">
                    <button
                        type="button"
                        class="rounded-full px-2.5 py-1 text-[11px] font-semibold transition sm:text-xs"
                        :class="
                            !selectedTopic
                                ? 'bg-[var(--color-brand-primary)] text-white shadow-xs'
                                : 'bg-[var(--color-surface-muted)] text-[var(--color-text-secondary)] hover:bg-slate-200'
                        "
                        @click="selectedTopic = ''"
                    >
                        Semua topik
                    </button>
                    <button
                        v-for="topic in topics"
                        :key="topic.id"
                        type="button"
                        class="rounded-full px-2.5 py-1 text-[11px] font-semibold transition sm:text-xs"
                        :class="
                            String(selectedTopic) === String(topic.id)
                                ? 'bg-[var(--color-brand-primary)] text-white shadow-xs'
                                : 'bg-[var(--color-surface-muted)] text-[var(--color-text-secondary)] hover:bg-slate-200'
                        "
                        @click="selectedTopic = String(topic.id)"
                    >
                        {{ topicLabel(topic) }}
                    </button>
                </div>
            </div>

            <!-- Accordion List -->
            <div class="mt-4 sm:mt-5">
                <div v-if="loading" class="space-y-2">
                    <div
                        v-for="i in 4"
                        :key="i"
                        class="h-10 animate-pulse rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)]"
                    />
                </div>

                <div
                    v-else-if="!filteredFaqs.length"
                    class="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-6 text-center"
                >
                    <p class="text-sm font-bold text-[var(--color-text-primary)]">Pertanyaan tidak ditemukan</p>
                    <p class="mt-1 text-xs text-[var(--color-text-secondary)]">
                        Silakan gunakan kata kunci lain atau pilih topik yang berbeda.
                    </p>
                </div>

                <div v-else class="space-y-2">
                    <article
                        v-for="faq in filteredFaqs"
                        :key="faq.id"
                        class="overflow-hidden rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] transition hover:border-slate-300"
                    >
                        <button
                            type="button"
                            class="flex w-full items-center justify-between gap-3 px-3.5 py-2.5 sm:px-4 sm:py-2.5 text-left font-semibold text-[var(--color-text-primary)]"
                            :aria-expanded="openId === faq.id"
                            @click="toggleFaq(faq.id)"
                        >
                            <span class="text-xs sm:text-sm font-semibold leading-snug">{{ faq.judul }}</span>
                            <ChevronDownIcon
                                class="size-4 shrink-0 text-slate-400 transition-transform duration-200"
                                :class="openId === faq.id ? 'rotate-180 text-[var(--color-brand-primary)]' : ''"
                            />
                        </button>
                        <div
                            v-show="openId === faq.id"
                            class="border-t border-[var(--color-border)] bg-slate-50/50 px-3.5 py-2.5 sm:px-4 sm:py-3"
                        >
                            <div
                                class="prose max-w-none text-xs leading-relaxed text-[var(--color-text-secondary)] sm:text-sm [&_p]:my-1 [&_ul]:my-1 [&_ol]:my-1 [&_li]:my-0.5"
                                v-html="faq.formatted_detail || faq.detail"
                            />
                        </div>
                    </article>
                </div>
            </div>
        </div>
    </section>
</template>
