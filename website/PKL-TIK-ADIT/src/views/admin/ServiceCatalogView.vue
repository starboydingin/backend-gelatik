<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import LoadingState from '../../components/LoadingState.vue'
const groups = ref([]),
    error = ref(''),
    loading = ref(true)
onMounted(async () => {
    try {
        const [items, topics, faqs, sliders] = await Promise.all([
            api.get('/items'),
            api.get('/topik'),
            api.get('/faq'),
            api.get('/slider'),
        ])
        groups.value = [
            ['Aset TIK', rows(payload(items)), (x) => x.nama_item || x.name],
            ['Topik konsultasi', rows(payload(topics)), (x) => x.nama_topik || x.name],
            ['FAQ', rows(payload(faqs)), (x) => x.judul],
            ['Slider aktif', rows(payload(sliders)), (x) => x.judul],
        ]
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
})
</script>
<template>
    <PageHeader
        title="Referensi layanan"
        description="Daftar aset, topik, FAQ, dan slider aktif yang disediakan API Gelatik."
    /><AlertMessage :message="error" /><LoadingState v-if="loading" />
    <div v-else class="grid gap-5 md:grid-cols-2">
        <section v-for="group in groups" :key="group[0]" class="card">
            <h2 class="font-bold text-slate-950">{{ group[0] }}</h2>
            <ul class="mt-3 divide-y divide-slate-100">
                <li
                    v-for="item in group[1].slice(0, 8)"
                    :key="item.id"
                    class="py-2 text-sm text-slate-600"
                >
                    {{ group[2](item) || `Data #${item.id}` }}
                </li>
                <li v-if="!group[1].length" class="py-5 text-sm text-slate-400">Belum ada data.</li>
            </ul>
        </section>
    </div>
</template>
