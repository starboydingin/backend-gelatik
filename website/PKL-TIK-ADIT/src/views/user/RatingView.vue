<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { StarIcon } from '@heroicons/vue/24/solid'
import { api, payload, errorMessage } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import ServiceHero from '../../components/ServiceHero.vue'
const rating = ref(null),
    selected = ref(0),
    hover = ref(0),
    error = ref(''),
    message = ref(''),
    saving = ref(false),
    route = useRoute(),
    router = useRouter()
const feedbackId = computed(() => Number(route.query.feedback_id))
const value = computed(() => hover.value || selected.value)
const hasExistingRating = computed(() => {
    const score = Number(rating.value?.rating ?? rating.value?.nilai)
    return Number.isInteger(score) && score >= 1 && score <= 5
})
const labels = [
    'Belum memilih',
    'Sangat kurang',
    'Perlu perbaikan',
    'Cukup baik',
    'Baik',
    'Sangat baik',
]
onMounted(async () => {
    try {
        const savedRating = payload(await api.get('/rating', { cache: false }))
        const score = Number(savedRating?.rating ?? savedRating?.nilai)
        rating.value = Number.isInteger(score) && score >= 1 && score <= 5 ? savedRating : null
        selected.value = rating.value ? score : 0
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
})
async function submit() {
    if (!selected.value) return
    saving.value = true
    error.value = ''
    try {
        const endpoint = hasExistingRating.value ? '/rating/update' : '/rating'
        try {
            rating.value = payload(await api.post(endpoint, { rating: selected.value, feedback_id: feedbackId.value }))
        } catch (requestError) {
            const detail = String(requestError.response?.data?.message || requestError.response?.data?.errors?.rating?.[0] || '')
            if (endpoint === '/rating/update' && /belum pernah/i.test(detail)) {
                rating.value = payload(await api.post('/rating', { rating: selected.value, feedback_id: feedbackId.value }))
            } else {
                throw requestError
            }
        }
        await router.replace('/app/umpan-balik')
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        saving.value = false
    }
}
</script>
<template>
    <div class="page-stack">
        <AlertMessage :message="error" /><AlertMessage
            :message="message"
            type="success"
        /><RouterLink to="/app/umpan-balik" class="inline-flex text-sm font-semibold text-navy"
            >← Kembali ke kritik & saran</RouterLink
        >
        <section
            class="mx-auto max-w-4xl overflow-hidden rounded-[28px] border border-stroke bg-white shadow-soft"
        >
            <ServiceHero
                eyebrow="Penilaian layanan"
                title="Seberapa puas Anda dengan layanan kami?"
                description="Rating tersimpan sebagai penilaian umum layanan dan dapat diperbarui kapan saja."
            />
            <div class="p-6 text-center md:p-10">
                <div class="flex justify-center gap-1 sm:gap-3" @mouseleave="hover = 0">
                    <button
                        v-for="star in 5"
                        :key="star"
                        class="rounded-xl p-1"
                        :aria-label="`${star} bintang`"
                        @mouseenter="hover = star"
                        @focus="hover = star"
                        @click="selected = star"
                    >
                        <StarIcon
                            class="size-11 sm:size-14"
                            :class="star <= value ? 'text-amber-400' : 'text-slate-200'"
                        />
                    </button>
                </div>
                <div class="mx-auto mt-6 max-w-lg rounded-2xl border border-stroke bg-slate-50 p-5">
                    <h2 class="text-xl font-bold text-navy">{{ labels[value] }}</h2>
                    <p class="mt-2 text-sm text-slate-500">{{ selected || 0 }} dari 5 bintang</p>
                </div>
                <div class="mt-7 flex justify-center gap-3">
                    <RouterLink to="/app/umpan-balik" class="btn-secondary">Batal</RouterLink
                    ><button class="btn-primary" :disabled="!selected || saving" @click="submit">
                        {{ saving ? 'Menyimpan…' : hasExistingRating ? 'Perbarui rating' : 'Beri rating' }}
                    </button>
                </div>
            </div>
        </section>
    </div>
</template>
