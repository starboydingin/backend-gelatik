<script setup>
import { computed, onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
const list = ref([]),
    selected = ref([]),
    error = ref(''),
    all = computed({
        get: () => list.value.length && selected.value.length === list.value.length,
        set: (v) => (selected.value = v ? list.value.map((x) => x.id) : []),
    })
async function load() {
    try {
        list.value = rows(payload(await api.get('/admin/kritik-saran')))
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function remove() {
    if (selected.value.length && confirm(`Hapus ${selected.value.length} masukan?`)) {
        await api.post('/admin/kritik-saran/bulk-delete', { ids: selected.value })
        selected.value = []
        load()
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="Kritik & saran"
        description="Tinjau masukan pengguna untuk peningkatan layanan."
        ><button class="btn-danger" :disabled="!selected.length" @click="remove">
            Hapus terpilih
        </button></PageHeader
    ><AlertMessage :message="error" />
    <div class="table-wrap">
        <EmptyState v-if="!list.length" />
        <table v-else class="data-table">
            <thead>
                <tr>
                    <th><input v-model="all" type="checkbox" /></th>
                    <th>Pengguna</th>
                    <th>Kritik</th>
                    <th>Saran</th>
                    <th>Tanggal</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="item in list" :key="item.id">
                    <td><input v-model="selected" type="checkbox" :value="item.id" /></td>
                    <td>{{ item.user?.name || 'Anonim' }}</td>
                    <td>{{ item.kritik }}</td>
                    <td>{{ item.saran }}</td>
                    <td>{{ item.created_at }}</td>
                </tr>
            </tbody>
        </table>
    </div>
</template>
