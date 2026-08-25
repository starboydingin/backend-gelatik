<script setup>
import { computed, onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import { formatDateTime } from '../../lib/date'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
const list = ref([]),
    selected = ref([]),
    error = ref(''),
    replyingId = ref(null),
    replyText = ref(''),
    savingReply = ref(false),
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
function startReply(item) {
    replyingId.value = item.id
    replyText.value = item.balasan || ''
}
async function sendReply(item) {
    if (!replyText.value.trim() || savingReply.value) return
    savingReply.value = true
    error.value = ''
    try {
        await api.post(`/admin/kritik-saran/${item.id}/reply`, { balasan: replyText.value.trim() })
        replyingId.value = null
        replyText.value = ''
        await load()
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        savingReply.value = false
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="Kritik & saran"
        description="Tinjau dan tanggapi masukan pengguna untuk peningkatan layanan."
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
                    <th>Kritik & saran</th>
                    <th>Dikirim</th>
                    <th>Tanggapan</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="item in list" :key="item.id">
                    <td><input v-model="selected" type="checkbox" :value="item.id" /></td>
                    <td>
                        <strong>{{ item.user?.name || 'Anonim' }}</strong>
                        <span class="mt-1 block text-xs text-slate-500">{{ item.user?.email || '-' }}</span>
                    </td>
                    <td class="min-w-72 whitespace-normal">
                        <p><strong>Kritik:</strong> {{ item.kritik }}</p>
                        <p class="mt-2"><strong>Saran:</strong> {{ item.saran }}</p>
                    </td>
                    <td class="whitespace-nowrap">{{ formatDateTime(item.created_at) }}</td>
                    <td class="min-w-80 whitespace-normal">
                        <template v-if="replyingId === item.id">
                            <textarea
                                v-model="replyText"
                                class="input min-h-28"
                                placeholder="Tulis tanggapan yang jelas dan membantu…"
                            />
                            <div class="mt-2 flex gap-2">
                                <button class="btn-primary min-h-9 px-3" :disabled="savingReply" @click="sendReply(item)">
                                    {{ savingReply ? 'Mengirim…' : 'Kirim balasan' }}
                                </button>
                                <button class="btn-secondary min-h-9 px-3" @click="replyingId = null">Batal</button>
                            </div>
                        </template>
                        <template v-else-if="item.balasan">
                            <p>{{ item.balasan }}</p>
                            <p class="mt-2 text-xs text-slate-500">
                                Oleh {{ item.responder?.name || 'Petugas' }} · {{ formatDateTime(item.dibalas_pada) }}
                            </p>
                            <button class="mt-3 text-sm font-semibold text-brand-700" @click="startReply(item)">Perbarui balasan</button>
                        </template>
                        <button v-else class="btn-primary min-h-9 px-3" @click="startReply(item)">Balas masukan</button>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>
