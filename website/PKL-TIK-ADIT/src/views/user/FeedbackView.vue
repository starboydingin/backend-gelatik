<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ChatBubbleBottomCenterTextIcon, CheckIcon } from '@heroicons/vue/24/outline'
import { api, errorMessage } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import AlertMessage from '../../components/AlertMessage.vue'
import PageHeader from '../../components/PageHeader.vue'
const form = ref({ kritik: '', saran: '' }),
    message = ref(''),
    error = ref(''),
    saving = ref(false),
    history = ref([]),
    selectedDetail = ref(null),
    route = useRoute(),
    router = useRouter()

async function loadHistory() {
    try {
        const response = await api.get('/kritik-saran/mine', { cache: false })
        history.value = response.data?.data?.data || response.data?.data || []
    } catch (_) {
        // Riwayat tidak boleh menghalangi pengguna mengirim masukan baru.
    }
}
async function loadDetail() {
    const id = Number(route.query.detail)
    if (!Number.isInteger(id) || id < 1) return
    try {
        selectedDetail.value = responseData(await api.get(`/kritik-saran/mine/${id}`, { cache: false }))
    } catch (_) {
        selectedDetail.value = null
    }
}
function responseData(response) {
    return response.data?.data || null
}
async function submit() {
    saving.value = true
    error.value = ''
    try {
        const created = await api.post('/kritik-saran', form.value)
        const feedbackId = Number(created.data?.data?.id)
        form.value = { kritik: '', saran: '' }
        if (Number.isInteger(feedbackId) && feedbackId > 0) {
            await router.push({ path: '/app/rating', query: { feedback_id: feedbackId } })
            return
        }
        message.value = 'Terima kasih. Masukan Anda berhasil dikirim.'
        await loadHistory()
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
onMounted(async () => {
    await Promise.all([loadHistory(), loadDetail()])
})
</script>
<template>
    <div class="page-stack">
        <PageHeader
            eyebrow="Suara pengguna"
            title="Kritik & Saran"
            description="Sampaikan pengalaman Anda agar layanan TIK dapat terus diperbaiki."
        />
        <AlertMessage :message="error" /><AlertMessage :message="message" type="success" />
        <section v-if="selectedDetail" class="card mx-auto max-w-5xl p-6 md:p-8">
            <p class="eyebrow">Detail masukan</p>
            <h2 class="mt-2 text-xl font-bold text-navy">Kritik & saran Anda</h2>
            <p class="mt-5 text-sm"><strong>Kritik:</strong> {{ selectedDetail.kritik }}</p>
            <p class="mt-2 text-sm"><strong>Saran:</strong> {{ selectedDetail.saran }}</p>
            <div v-if="selectedDetail.balasan" class="mt-5 rounded-xl bg-brand-50 p-4 text-sm text-slate-700">
                <strong class="text-navy">Tanggapan {{ selectedDetail.responder?.name || 'Petugas' }}</strong>
                <p class="mt-2 whitespace-pre-line">{{ selectedDetail.balasan }}</p>
            </div>
            <p v-else class="mt-5 text-sm text-slate-500">Masukan Anda sedang ditinjau petugas.</p>
        </section>
        <div class="mx-auto grid max-w-5xl gap-5 lg:grid-cols-[.75fr_1.25fr]">
            <aside
                class="flex flex-col items-start rounded-xl bg-[var(--color-brand-primary-strong)] p-6 text-white shadow-[var(--shadow-surface)] md:p-7"
            >
                <ChatBubbleBottomCenterTextIcon class="size-10 text-[var(--color-brand-secondary)]" />
                <div class="relative z-10">
                    <p class="eyebrow !text-[var(--color-brand-secondary)]">Suara pengguna</p>
                    <h2 class="mt-3 font-brand text-3xl font-bold leading-tight !text-white">
                        Ceritakan pengalaman Anda apa adanya
                    </h2>
                    <p class="mt-4 text-sm font-semibold leading-7 text-white">
                        Pisahkan kendala yang dirasakan dan usulan penyelesaiannya agar masukan
                        lebih mudah dipahami petugas.
                    </p>
                    <div class="mt-7 space-y-3">
                        <div
                            v-for="tip in [
                                'Sampaikan kritik dengan jelas',
                                'Berikan saran yang dapat dilakukan',
                            ]"
                            :key="tip"
                            class="flex items-center gap-3 rounded-lg border border-white/20 bg-white/10 p-3 text-sm font-semibold text-white"
                        >
                            <CheckIcon class="size-5 text-[var(--color-brand-secondary)]" />{{ tip }}
                        </div>
                    </div>
                </div>
            </aside>
            <form class="card p-6 md:p-8" @submit.prevent="submit">
                <p class="eyebrow">Form masukan</p>
                <h2 class="mt-2 text-2xl font-bold text-navy">Kritik dan saran layanan</h2>
                <p class="mt-2 text-sm text-slate-500">
                    Kedua bagian wajib diisi sesuai pengalaman Anda.
                </p>
                <label class="mt-7 block"
                    ><span class="label flex justify-between"
                        >Kritik
                        <span class="normal-case tracking-normal text-slate-400"
                            >{{ form.kritik.length }} karakter</span
                        ></span
                    ><textarea
                        v-model="form.kritik"
                        class="input min-h-36"
                        placeholder="Jelaskan kendala atau bagian layanan yang perlu diperbaiki…"
                        required
                    /></label
                ><label class="mt-5 block"
                    ><span class="label flex justify-between"
                        >Saran perbaikan
                        <span class="normal-case tracking-normal text-slate-400"
                            >{{ form.saran.length }} karakter</span
                        ></span
                    ><textarea
                        v-model="form.saran"
                        class="input min-h-36"
                        placeholder="Tuliskan solusi atau perubahan yang Anda harapkan…"
                        required
                    />
                </label>
                <div class="mt-6 flex flex-wrap justify-end gap-3">
                    <RouterLink to="/app/dashboard" class="btn-secondary">Batal</RouterLink
                    ><button class="btn-primary" :disabled="saving">
                        {{ saving ? 'Mengirim…' : 'Kirim kritik & saran' }}
                    </button>
                </div>
            </form>
        </div>
        <section v-if="history.length" class="card mx-auto max-w-5xl p-6 md:p-8">
            <p class="eyebrow">Riwayat masukan</p>
            <h2 class="mt-2 text-xl font-bold text-navy">Tanggapan untuk kritik & saran Anda</h2>
            <div class="mt-5 divide-y divide-stroke">
                <article v-for="item in history" :key="item.id" class="py-5 first:pt-0 last:pb-0">
                    <p class="text-xs text-slate-500">Dikirim {{ formatDateTime(item.created_at) }}</p>
                    <p class="mt-2 text-sm"><strong>Kritik:</strong> {{ item.kritik }}</p>
                    <p class="mt-1 text-sm"><strong>Saran:</strong> {{ item.saran }}</p>
                    <div v-if="item.balasan" class="mt-4 rounded-xl bg-brand-50 p-4 text-sm text-slate-700">
                        <strong class="text-navy">Balasan {{ item.responder?.name || 'Petugas' }}</strong>
                        <p class="mt-2 whitespace-pre-line">{{ item.balasan }}</p>
                        <p class="mt-2 text-xs text-slate-500">{{ formatDateTime(item.dibalas_pada) }}</p>
                    </div>
                    <p v-else class="mt-4 text-sm text-slate-500">Masukan Anda sedang ditinjau petugas.</p>
                </article>
            </div>
        </section>
    </div>
</template>
