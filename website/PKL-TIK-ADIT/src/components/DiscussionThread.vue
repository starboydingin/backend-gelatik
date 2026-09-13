<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { api, errorMessage, payload } from '../lib/api'
import { formatDateTime } from '../lib/date'
import AlertMessage from './AlertMessage.vue'
import LoadingState from './LoadingState.vue'
import {
    ChatBubbleLeftRightIcon,
    PaperAirplaneIcon,
    ShieldCheckIcon,
    UserCircleIcon,
    LockClosedIcon,
} from '@heroicons/vue/24/outline'

const props = defineProps({
    serviceType: {
        type: String,
        required: true, // 'konsultasi', 'pinjam', 'email-resmi'
    },
    recordId: {
        type: [Number, String],
        required: true,
    },
    status: {
        type: String,
        default: '',
    },
})

const comments = ref([])
const loading = ref(true)
const submitting = ref(false)
const error = ref('')
const newComment = ref('')

const endpointType = computed(() => {
    const s = props.serviceType.toLowerCase()
    if (s.includes('pinjam')) return 'pinjam'
    if (s.includes('email')) return 'pengajuan-email'
    if (s.includes('konsul')) return 'konsul'
    return s
})

// Diskusi HANYA aktif saat status DIPROSES / PROSES atau DITOLAK
const isDiscussionAllowed = computed(() => {
    const s = String(props.status || '').toLowerCase().trim()
    return ['proses', 'diproses', 'ditolak'].includes(s)
})

const statusNote = computed(() => {
    if (isDiscussionAllowed.value) return ''
    const s = String(props.status || '').toLowerCase().trim()
    if (['selesai', 'disetujui'].includes(s)) {
        return 'Pengajuan telah selesai. Diskusi telah ditutup.'
    }
    return 'Diskusi dua arah hanya dapat dilakukan saat status pengajuan Diproses atau Ditolak.'
})

async function loadComments() {
    if (!props.recordId) return
    loading.value = true
    error.value = ''
    try {
        const res = await api.get(`/${endpointType.value}/${props.recordId}/comments`, {
            cache: false,
        })
        comments.value = payload(res) || []
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}

async function sendComment() {
    const text = newComment.value.trim()
    if (!text) return
    if (!isDiscussionAllowed.value) {
        error.value = 'Diskusi hanya dapat dilakukan saat status pengajuan Diproses atau Ditolak.'
        return
    }

    submitting.value = true
    error.value = ''
    try {
        await api.post(`/${endpointType.value}/${props.recordId}/comments`, {
            pesan: text,
        })
        newComment.value = ''
        await loadComments()
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        submitting.value = false
    }
}

watch(
    () => [props.recordId, props.status],
    () => {
        loadComments()
    }
)

onMounted(loadComments)
</script>

<template>
    <section class="card mt-6">
        <div class="flex items-center justify-between border-b border-[var(--color-border)] pb-4">
            <div class="flex items-center gap-2.5">
                <div class="grid size-9 place-items-center rounded-lg bg-blue-50 text-blue-800">
                    <ChatBubbleLeftRightIcon class="size-5 stroke-2" />
                </div>
                <div>
                    <h2 class="font-brand text-lg font-bold leading-tight">Diskusi & Tanggapan</h2>
                    <p class="text-xs text-[var(--color-text-secondary)]">
                        Komunikasi dua arah antara pemohon dan petugas layanan
                    </p>
                </div>
            </div>
            <span
                class="rounded-full px-2.5 py-0.5 text-xs font-semibold"
                :class="
                    isDiscussionAllowed
                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                        : 'bg-slate-100 text-slate-600 border border-slate-200'
                "
            >
                {{ isDiscussionAllowed ? 'Diskusi Terbuka' : 'Diskusi Ditutup' }}
            </span>
        </div>

        <AlertMessage :message="error" class="mt-4" />

        <!-- Status Restriction Notice Banner -->
        <div
            v-if="!isDiscussionAllowed"
            class="mt-4 flex items-center gap-2.5 rounded-lg border border-amber-200 bg-amber-50/80 px-4 py-3 text-xs text-amber-800"
        >
            <LockClosedIcon class="size-4 shrink-0" />
            <span>{{ statusNote }}</span>
        </div>

        <!-- Comments List Thread -->
        <div class="mt-5 space-y-3.5">
            <LoadingState v-if="loading" />

            <div
                v-else-if="!comments.length"
                class="rounded-xl border border-dashed border-[var(--color-border)] bg-[var(--color-surface-muted)] py-8 text-center text-sm text-[var(--color-text-secondary)]"
            >
                Belum ada tanggapan atau pesan dalam diskusi ini.
            </div>

            <div
                v-for="comment in comments"
                :key="comment.id"
                class="flex flex-col gap-1.5 rounded-xl border p-4 transition"
                :class="
                    comment.is_admin
                        ? 'border-blue-200 bg-blue-50/40'
                        : 'border-[var(--color-border)] bg-[var(--color-surface)]'
                "
            >
                <div class="flex flex-wrap items-center justify-between gap-2 border-b border-black/5 pb-2">
                    <div class="flex items-center gap-2">
                        <component
                            :is="comment.is_admin ? ShieldCheckIcon : UserCircleIcon"
                            class="size-4.5"
                            :class="comment.is_admin ? 'text-blue-700' : 'text-slate-600'"
                        />
                        <span class="text-sm font-bold text-[var(--color-text-primary)]">
                            {{ comment.author_name || (comment.is_admin ? 'Petugas TIK' : 'Pemohon') }}
                        </span>
                        <span
                            class="rounded-md px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wider"
                            :class="
                                comment.is_admin
                                    ? 'bg-blue-100 text-blue-900'
                                    : 'bg-slate-100 text-slate-800'
                            "
                        >
                            {{ comment.author_role || (comment.is_admin ? 'Admin' : 'Pemohon') }}
                        </span>
                    </div>
                    <time class="text-xs text-[var(--color-text-muted)]">
                        {{ formatDateTime(comment.created_at) }}
                    </time>
                </div>

                <p class="whitespace-pre-wrap pt-1 text-sm leading-6 text-[var(--color-text-primary)]">
                    {{ comment.pesan }}
                </p>
            </div>
        </div>

        <!-- New Comment Input (Only when status allows) -->
        <form v-if="isDiscussionAllowed" class="mt-5 border-t border-[var(--color-border)] pt-4" @submit.prevent="sendComment">
            <label class="block">
                <span class="label">Tulis komentar atau tanggapan</span>
                <textarea
                    v-model="newComment"
                    rows="3"
                    class="input mt-1.5 w-full resize-y"
                    placeholder="Tulis pesan atau tanggapan Anda di sini..."
                    required
                    :disabled="submitting"
                />
            </label>
            <div class="mt-3 flex items-center justify-between">
                <p class="text-xs text-[var(--color-text-secondary)]">
                    Pesan akan tersimpan dalam riwayat pengajuan ini.
                </p>
                <button
                    type="submit"
                    class="btn-primary gap-2 text-sm"
                    :disabled="submitting || !newComment.trim()"
                >
                    <PaperAirplaneIcon class="size-4" />
                    <span>{{ submitting ? 'Mengirim...' : 'Kirim Komentar' }}</span>
                </button>
            </div>
        </form>
    </section>
</template>
