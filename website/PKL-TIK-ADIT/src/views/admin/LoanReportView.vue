<script setup>
import { ref } from 'vue'
import { api, payload, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
const filter = ref('bulanan'),
    date = ref(new Date().toISOString().slice(0, 7)),
    data = ref(null),
    error = ref(''),
    loading = ref(false)
async function load() {
    loading.value = true
    error.value = ''
    try {
        data.value = payload(
            await api.get('/laporan/peminjaman', {
                params: { filter: filter.value, tanggal: date.value },
            })
        )
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
</script>
<template>
    <PageHeader
        title="Laporan peminjaman"
        description="Ringkasan peminjaman berdasarkan periode yang dipilih."
    />
    <form class="card flex flex-wrap items-end gap-3" @submit.prevent="load">
        <label
            ><span class="label">Jenis periode</span
            ><select v-model="filter" class="input">
                <option value="harian">Harian</option>
                <option value="bulanan">Bulanan</option>
                <option value="tahunan">Tahunan</option>
            </select></label
        ><label
            ><span class="label">Tanggal periode</span
            ><input
                v-model="date"
                :type="filter === 'harian' ? 'date' : filter === 'bulanan' ? 'month' : 'number'"
                class="input"
                :min="filter === 'tahunan' ? '2000' : undefined" /></label
        ><button class="btn-primary" :disabled="loading">
            {{ loading ? 'Memuat…' : 'Tampilkan' }}
        </button>
    </form>
    <AlertMessage :message="error" />
    <section v-if="data" class="card mt-6">
        <h2 class="font-bold text-slate-950">Hasil laporan</h2>
        <dl class="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <div v-for="(value, key) in data" :key="key" class="rounded-xl bg-slate-50 p-4">
                <dt class="text-xs font-semibold uppercase tracking-wide text-slate-500">
                    {{ String(key).replaceAll('_', ' ') }}
                </dt>
                <dd class="mt-2 text-xl font-bold text-slate-950">
                    {{ typeof value === 'object' ? JSON.stringify(value) : value }}
                </dd>
            </div>
        </dl>
    </section>
</template>
