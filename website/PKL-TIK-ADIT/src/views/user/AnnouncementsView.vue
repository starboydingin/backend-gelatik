<script setup>
import { onMounted, ref } from 'vue'
import { MegaphoneIcon } from '@heroicons/vue/24/outline'
import { api, errorMessage, payload, rows } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import LoadingState from '../../components/LoadingState.vue'
import PageHeader from '../../components/PageHeader.vue'
const items = ref([]),
    loading = ref(true),
    error = ref('')
onMounted(async () => {
    try {
        items.value = rows(payload(await api.get('/pengumuman')))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
})
</script>
<template>
    <div class="page-stack">
        <PageHeader
            eyebrow="Informasi terkini"
            title="Pengumuman"
            description="Informasi resmi dan pembaruan layanan TIK."
        /><AlertMessage :message="error" /><LoadingState v-if="loading" /><EmptyState
            v-else-if="!items.length"
            title="Belum ada pengumuman"
            text="Informasi terbaru akan muncul di halaman ini."
        />
        <div v-else class="grid gap-4 lg:grid-cols-2">
            <article v-for="item in items" :key="item.id" class="card flex gap-4">
                <span
                    class="grid size-12 shrink-0 place-items-center rounded-2xl bg-brand-50 text-brand-600"
                    ><MegaphoneIcon class="size-6"
                /></span>
                <div class="min-w-0">
                    <h2 class="font-bold text-navy">{{ item.judul }}</h2>
                    <p class="mt-2 whitespace-pre-wrap text-sm leading-6 text-slate-600">
                        {{ item.konten || item.deskripsi }}
                    </p>
                    <p class="mt-3 text-xs text-slate-400">{{ item.created_at }}</p>
                </div>
            </article>
        </div>
    </div>
</template>
