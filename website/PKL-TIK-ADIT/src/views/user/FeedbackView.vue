<script setup>
import { ref } from 'vue'
import { ChatBubbleBottomCenterTextIcon, CheckIcon } from '@heroicons/vue/24/outline'
import { api, errorMessage } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import PageHeader from '../../components/PageHeader.vue'
const form = ref({ kritik: '', saran: '' }),
    message = ref(''),
    error = ref(''),
    saving = ref(false)
async function submit() {
    saving.value = true
    error.value = ''
    try {
        await api.post('/kritik-saran', form.value)
        message.value = 'Terima kasih. Masukan Anda berhasil dikirim.'
        form.value = { kritik: '', saran: '' }
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
</script>
<template>
    <div class="page-stack">
        <PageHeader
            eyebrow="Suara pengguna"
            title="Kritik & Saran"
            description="Sampaikan pengalaman Anda agar layanan TIK dapat terus diperbaiki."
        />
        <AlertMessage :message="error" /><AlertMessage :message="message" type="success" />
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
    </div>
</template>
