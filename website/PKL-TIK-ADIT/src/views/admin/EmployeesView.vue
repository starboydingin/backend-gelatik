<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
const list = ref([]),
    search = ref(''),
    error = ref(''),
    loading = ref(false)
async function load() {
    loading.value = true
    try {
        list.value = rows(
            payload(
                await api.get('/pegawai', { params: search.value ? { search: search.value } : {} })
            )
        )
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        loading.value = false
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="Pegawai belum memiliki email"
        description="Data referensi pegawai yang dapat digunakan saat memproses usulan email resmi."
    /><AlertMessage :message="error" />
    <form class="mb-4 flex max-w-xl gap-2" @submit.prevent="load">
        <input
            v-model="search"
            class="input"
            placeholder="Cari nama, NIP, atau unit kerja…"
        /><button class="btn-secondary" :disabled="loading">Cari</button>
    </form>
    <div class="table-wrap">
        <EmptyState v-if="!list.length" />
        <table v-else class="data-table">
            <thead>
                <tr>
                    <th>Nama</th>
                    <th>NIP</th>
                    <th>Unit kerja</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="item in list" :key="item.id || item.NIP_Baru">
                    <td>{{ item.Nama || item.nama || item.name }}</td>
                    <td>{{ item.NIP_Baru || item.nip }}</td>
                    <td>{{ item.Unit_Kerja || item.unit_kerja || '-' }}</td>
                </tr>
            </tbody>
        </table>
    </div>
</template>
