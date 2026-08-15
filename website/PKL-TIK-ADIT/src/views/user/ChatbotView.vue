<script setup>
import { onActivated, onBeforeUnmount, onDeactivated, onMounted, ref } from 'vue'
import { PaperAirplaneIcon, SparklesIcon, TrashIcon } from '@heroicons/vue/24/outline'
import { api, payload, errorMessage } from '../../lib/api'
import { useAuthStore } from '../../stores/auth'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
const auth = useAuthStore()
const starterResetAfter = 5 * 60 * 1000
const visitKey = `gelatik_chat_left_at:${auth.user?.id || 'current-session'}`
const sessionId = ref(localStorage.getItem('gelatik_chat_session') || '')
const messages = ref([]),
    input = ref(''),
    error = ref(''),
    sending = ref(false),
    initialized = ref(false)
const quickQuestionDrag = {
    pointerId: null,
    startX: 0,
    startScrollLeft: 0,
    moved: false,
    suppressClickUntil: 0,
}
const quickQuestions = [
    'Bagaimana cara mengajukan peminjaman aset TIK?',
    'WiFi terhubung tetapi tidak ada internet. Apa yang harus dilakukan?',
    'Bagaimana cara reset kata sandi email resmi?',
    'Bagaimana cara mengajukan sertifikat elektronik TTE?',
    'Bagaimana cara mengajukan usulan email dinas?',
]
function appendStarterIfDue() {
    const lastLeftAt = Number(sessionStorage.getItem(visitKey) || 0)
    if (lastLeftAt && Date.now() - lastLeftAt < starterResetAfter) return
    sessionStorage.removeItem(visitKey)
    messages.value.push({
        id: `starter-${Date.now()}`,
        role: 'assistant',
        localStarter: true,
        message:
            'Halo, saya Asisten Konsultasi TIK Gelatik. Ada yang bisa saya bantu hari ini? Pilih salah satu pertanyaan cepat di bawah atau tulis pertanyaan Anda sendiri.',
    })
}
function handleVisibilityChange() {
    if (document.hidden) {
        sessionStorage.setItem(visitKey, String(Date.now()))
        return
    }
    appendStarterIfDue()
}
function chatText(item) {
    return String(item.message || item.content || item.text || '')
        .replace(/\*\*(.*?)\*\*/gs, '$1')
        .replace(/^\s*\*\s+/gm, '- ')
}
function scrollQuickQuestions(event) {
    const strip = event.currentTarget
    const horizontalDelta = event.deltaX || event.deltaY
    if (strip.scrollWidth <= strip.clientWidth || horizontalDelta === 0) return

    // A mouse wheel usually emits deltaY; Shift+wheel and trackpads emit deltaX.
    strip.scrollLeft += horizontalDelta
    event.preventDefault()
}
function beginQuickQuestionDrag(event) {
    if (event.pointerType !== 'mouse') return

    const strip = event.currentTarget
    quickQuestionDrag.pointerId = event.pointerId
    quickQuestionDrag.startX = event.clientX
    quickQuestionDrag.startScrollLeft = strip.scrollLeft
    quickQuestionDrag.moved = false
    strip.setPointerCapture(event.pointerId)
}
function moveQuickQuestionDrag(event) {
    if (event.pointerId !== quickQuestionDrag.pointerId) return

    const distance = event.clientX - quickQuestionDrag.startX
    if (Math.abs(distance) > 3) quickQuestionDrag.moved = true
    if (!quickQuestionDrag.moved) return

    event.currentTarget.scrollLeft = quickQuestionDrag.startScrollLeft - distance
    if (event.cancelable) event.preventDefault()
}
function endQuickQuestionDrag(event) {
    if (event.pointerId !== quickQuestionDrag.pointerId) return

    if (quickQuestionDrag.moved) quickQuestionDrag.suppressClickUntil = Date.now() + 160
    quickQuestionDrag.pointerId = null
}
function scrollQuickQuestionsBy(event, direction) {
    event.currentTarget.scrollBy({ left: direction * 220, behavior: 'smooth' })
}
function sendQuickQuestion(question) {
    if (Date.now() < quickQuestionDrag.suppressClickUntil) return
    send(question)
}
async function history() {
    if (!sessionId.value) return
    try {
        const remoteMessages =
            payload(
                await api.get('/chatbot/history', { params: { session_id: sessionId.value } })
            ) || []
        const retainedMessages = messages.value.filter(
            (localMessage) =>
                localMessage.localStarter ||
                !remoteMessages.some(
                    (remoteMessage) =>
                        remoteMessage.role === localMessage.role &&
                        chatText(remoteMessage) === chatText(localMessage)
                )
        )
        messages.value = [...remoteMessages, ...retainedMessages]
    } catch {
        // A locally stored session can outlive a deleted server conversation.
        sessionId.value = ''
        localStorage.removeItem('gelatik_chat_session')
    }
}
async function send(text = input.value) {
    if (!String(text).trim() || sending.value) return
    const prompt = String(text).trim()
    input.value = ''
    error.value = ''
    messages.value.push({ role: 'user', message: prompt, localMessage: true })
    sending.value = true
    try {
        const result = payload(
            await api.post('/chatbot/message', {
                message: prompt,
                session_id: sessionId.value || null,
            })
        )
        if (result.session_id) {
            sessionId.value = result.session_id
            localStorage.setItem('gelatik_chat_session', result.session_id)
        }
        messages.value.push({
            role: 'assistant',
            message: result.reply || result.message || result.answer || 'Respons diterima.',
            localMessage: true,
        })
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        sending.value = false
    }
}
async function clear() {
    if (!sessionId.value) {
        messages.value = []
        appendStarterIfDue()
        return
    }
    try {
        await api.delete('/chatbot/history', { params: { session_id: sessionId.value } })
        messages.value = []
        sessionId.value = ''
        localStorage.removeItem('gelatik_chat_session')
        sessionStorage.removeItem(visitKey)
        appendStarterIfDue()
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function initialize() {
    // The welcome is entirely local so opening this page never waits for the database.
    appendStarterIfDue()
    document.addEventListener('visibilitychange', handleVisibilityChange)
    if (!initialized.value) {
        initialized.value = true
        // History is supplemental. Load it without blocking the first visible chatbot bubble.
        void history()
    }
}
onMounted(initialize)
onActivated(() => {
    if (initialized.value) initialize()
})
onDeactivated(() => {
    document.removeEventListener('visibilitychange', handleVisibilityChange)
    sessionStorage.setItem(visitKey, String(Date.now()))
})
onBeforeUnmount(() => {
    document.removeEventListener('visibilitychange', handleVisibilityChange)
    sessionStorage.setItem(visitKey, String(Date.now()))
})
</script>
<template>
    <div class="page-stack">
        <PageHeader
            title="Chatbot Gelatik"
            description="Asisten layanan menggunakan backend Gelatik; tidak ada provider key atau AI yang berjalan di browser."
            ><button class="btn-secondary" @click="clear">
                <TrashIcon class="size-4" />Hapus percakapan
            </button></PageHeader
        ><AlertMessage :message="error" />
        <section
            class="mx-auto max-w-4xl overflow-hidden border-[4px] border-[var(--line)] bg-[var(--paper)] shadow-[8px_8px_0_var(--line)]"
        >
            <header class="flex items-center gap-3 border-b-[4px] border-[var(--line)] bg-[var(--navy)] p-5 text-white">
                <span class="grid size-11 place-items-center border-[3px] border-black bg-[var(--gold)] text-black"
                    ><SparklesIcon class="size-6"
                /></span>
                <div>
                    <h2 class="font-brand text-xl font-black uppercase tracking-[-.06em]">Asisten Gelatik</h2>
                    <p class="text-xs font-bold text-white">Siap membantu informasi layanan TIK</p>
                </div>
            </header>
            <div class="min-h-[420px] space-y-4 p-4 sm:p-6">
                <div
                    v-for="(item, index) in messages"
                    :key="index"
                    class="flex"
                    :class="
                        item.role === 'user' || item.sender === 'user'
                            ? 'justify-end'
                            : 'justify-start'
                    "
                >
                    <p
                        class="max-w-[88%] whitespace-pre-wrap border-[3px] border-[var(--line)] px-4 py-3 text-sm font-semibold leading-6 shadow-[4px_4px_0_var(--line)] sm:max-w-[75%]"
                        :class="
                            item.role === 'user' || item.sender === 'user'
                                ? 'bg-[var(--teal)] text-black'
                                : 'bg-[var(--paper)] text-[var(--ink)]'
                        "
                    >
                        {{ chatText(item) }}
                    </p>
                </div>
                <p v-if="sending" class="text-sm text-slate-400">
                    Gelatik sedang menyiapkan jawaban...
                </p>
            </div>
            <div class="border-t-[4px] border-[var(--line)] p-4 sm:p-5">
                <div
                    class="quick-question-strip"
                    role="region"
                    aria-label="Pertanyaan cepat chatbot"
                    tabindex="0"
                    @wheel="scrollQuickQuestions"
                    @pointerdown="beginQuickQuestionDrag"
                    @pointermove="moveQuickQuestionDrag"
                    @pointerup="endQuickQuestionDrag"
                    @pointercancel="endQuickQuestionDrag"
                    @keydown.left.prevent="scrollQuickQuestionsBy($event, -1)"
                    @keydown.right.prevent="scrollQuickQuestionsBy($event, 1)"
                >
                    <button
                        v-for="question in quickQuestions"
                        :key="question"
                        class="quick-question"
                        :disabled="sending"
                        @click="sendQuickQuestion(question)"
                    >
                        {{ question }}
                    </button>
                </div>
                <form class="flex gap-2" @submit.prevent="send()">
                    <input
                        v-model="input"
                        class="input"
                        placeholder="Tulis pertanyaan Anda..."
                        aria-label="Pertanyaan chatbot"
                    /><button
                        class="btn-primary shrink-0 px-4 sm:px-5"
                        :disabled="sending || !input.trim()"
                    >
                        <PaperAirplaneIcon class="size-5" /><span class="hidden sm:inline"
                            >Kirim</span
                        >
                    </button>
                </form>
            </div>
        </section>
    </div>
</template>

<style scoped>
.quick-question-strip {
    display: flex;
    width: 100%;
    gap: 0.5rem;
    margin-bottom: 1rem;
    overflow-x: scroll;
    overscroll-behavior-x: contain;
    padding: 0.125rem 0.125rem 0.375rem;
    scroll-behavior: smooth;
    scroll-snap-type: x proximity;
    scrollbar-width: none;
    -webkit-overflow-scrolling: touch;
    touch-action: pan-x;
    cursor: grab;
    user-select: none;
}

.quick-question-strip::-webkit-scrollbar {
    display: none;
}

.quick-question {
    max-width: min(84vw, 38rem);
    flex: 0 0 auto;
    scroll-snap-align: start;
    border: 3px solid var(--line);
    background: var(--gold);
    padding: 0.5rem 0.75rem;
    color: #000;
    font-size: 0.75rem;
    font-weight: 900;
    line-height: 1.35;
    text-align: left;
    white-space: normal;
    box-shadow: 3px 3px 0 var(--line);
    transition: transform 160ms ease-out, box-shadow 160ms ease-out;
    user-select: none;
}

.quick-question-strip:active {
    cursor: grabbing;
}

.quick-question:hover:not(:disabled),
.quick-question:focus-visible:not(:disabled) {
    transform: translate(3px, 3px);
    box-shadow: none;
}

@media (min-width: 640px) {
    .quick-question {
        max-width: 32rem;
    }
}

@media (prefers-reduced-motion: reduce) {
    .quick-question-strip {
        scroll-behavior: auto;
    }

    .quick-question {
        transition: none;
    }
}
</style>
