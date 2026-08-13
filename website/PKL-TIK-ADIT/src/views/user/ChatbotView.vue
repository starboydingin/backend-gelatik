<script setup>
import { onMounted, ref } from 'vue'
import { PaperAirplaneIcon, SparklesIcon, TrashIcon } from '@heroicons/vue/24/outline'
import { api, payload, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
const sessionId = ref(localStorage.getItem('gelatik_chat_session') || '')
const messages = ref([]),
    input = ref(''),
    error = ref(''),
    sending = ref(false)
const quickQuestions = [
    'Bagaimana cara mengajukan peminjaman perangkat?',
    'Bagaimana membuat email resmi ASN?',
    'Apa layanan konsultasi TIK yang tersedia?',
    'Bagaimana mengecek status pengajuan?',
    'Bagaimana melaporkan gangguan internet OPD?',
]
async function history() {
    if (!sessionId.value) return
    try {
        messages.value =
            payload(await api.get('/chatbot/history', { params: { session_id: sessionId.value } })) || []
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
    messages.value.push({ role: 'user', message: prompt })
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
        return
    }
    try {
        await api.delete('/chatbot/history', { params: { session_id: sessionId.value } })
        messages.value = []
        sessionId.value = ''
        localStorage.removeItem('gelatik_chat_session')
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
onMounted(history)
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
            class="mx-auto max-w-4xl overflow-hidden rounded-2xl border border-stroke bg-white shadow-soft"
        >
            <header
                class="flex items-center gap-3 bg-gradient-to-r from-navy to-cyan-700 p-5 text-white"
            >
                <span class="grid size-11 place-items-center rounded-xl bg-white/10"
                    ><SparklesIcon class="size-6"
                /></span>
                <div>
                    <h2 class="font-bold">Asisten Gelatik</h2>
                    <p class="text-xs text-blue-100">Siap membantu informasi layanan TIK</p>
                </div>
            </header>
            <div class="min-h-[420px] space-y-4 p-4 sm:p-6">
                <div
                    v-if="!messages.length"
                    class="rounded-2xl bg-slate-100 p-4 text-sm leading-6 text-slate-700"
                >
                    Halo, saya asisten Gelatik. Pilih pertanyaan cepat atau tulis kebutuhan layanan
                    TIK Anda.
                </div>
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
                        class="max-w-[88%] whitespace-pre-wrap rounded-2xl px-4 py-3 text-sm leading-6 sm:max-w-[75%]"
                        :class="
                            item.role === 'user' || item.sender === 'user'
                                ? 'rounded-br-md bg-brand-700 text-white'
                                : 'rounded-bl-md bg-slate-100 text-slate-700'
                        "
                    >
                        {{ item.message || item.content || item.text }}
                    </p>
                </div>
                <p v-if="sending" class="text-sm text-slate-400">
                    Gelatik sedang menyiapkan jawaban…
                </p>
            </div>
            <div class="border-t border-stroke p-4 sm:p-5">
                <div class="mb-4 flex gap-2 overflow-x-auto pb-1">
                    <button
                        v-for="question in quickQuestions"
                        :key="question"
                        class="shrink-0 rounded-full border border-brand-200 bg-brand-50 px-3 py-2 text-xs font-semibold text-brand-700 hover:bg-brand-100"
                        :disabled="sending"
                        @click="send(question)"
                    >
                        {{ question }}
                    </button>
                </div>
                <form class="flex gap-2" @submit.prevent="send()">
                    <input
                        v-model="input"
                        class="input"
                        placeholder="Tulis pertanyaan Anda…"
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
