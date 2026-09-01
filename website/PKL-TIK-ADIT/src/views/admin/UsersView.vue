<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import EmptyState from '../../components/EmptyState.vue'
import { useAuthStore } from '../../stores/auth'
const auth = useAuthStore()
const list = ref([]),
    search = ref(''),
    error = ref(''),
    editingBandwidth = ref(null),
    bandwidthForm = ref({ download: '', upload: '' }),
    savingBandwidth = ref(false)
function hasRole(item, name) {
    return (item.roles || []).some((role) => (role.name || role) === name)
}
async function load() {
    try {
        list.value = rows(
            payload(await api.get('/admin/users', { params: { search: search.value } }))
        )
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function active(item) {
    await api.post(
        `/admin/users/${item.id}/${String(item.status) === '1' ? 'deactivate' : 'activate'}`
    )
    load()
}
async function remove(id) {
    if (confirm('Hapus pengguna ini?')) {
        await api.delete(`/admin/users/${id}`)
        load()
    }
}
function isPrivileged(item) {
    return (item.roles || []).some((role) => ['admin', 'superadmin'].includes(role.name || role))
}
function openBandwidth(item) {
    editingBandwidth.value = item
    bandwidthForm.value = {
        download: item.bandwidth_download_mbps ?? '',
        upload: item.bandwidth_upload_mbps ?? '',
    }
}
async function saveBandwidth() {
    if (!editingBandwidth.value || savingBandwidth.value) return
    savingBandwidth.value = true
    error.value = ''
    try {
        await api.put(`/admin/users/${editingBandwidth.value.id}`, {
            bandwidth_download_mbps:
                bandwidthForm.value.download === '' ? null : Number(bandwidthForm.value.download),
            bandwidth_upload_mbps:
                bandwidthForm.value.upload === '' ? null : Number(bandwidthForm.value.upload),
        })
        editingBandwidth.value = null
        await load()
    } catch (e) {
        error.value = errorMessage(e)
    } finally {
        savingBandwidth.value = false
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="Manajemen pengguna"
        description="Kelola akun dan status akses. Akun admin dibuat secara aman melalui API oleh superadmin."
    /><AlertMessage :message="error" />
    <form class="mb-4 flex max-w-lg gap-2" @submit.prevent="load">
        <input
            v-model="search"
            class="input"
            placeholder="Cari nama, email, atau username…"
        /><button class="btn-secondary">Cari</button>
    </form>
    <div class="table-wrap">
        <EmptyState v-if="!list.length" />
        <table v-else class="data-table">
            <thead>
                <tr>
                    <th>Pengguna</th>
                    <th>Username</th>
                    <th>OPD</th>
                    <th>Bandwidth user</th>
                    <th>Status</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="item in list.filter((user) => !hasRole(user, 'superadmin'))" :key="item.id">
                    <td>
                        <strong>{{ item.name }}</strong>
                        <p class="text-xs text-slate-400">{{ item.email }}</p>
                    </td>
                    <td>{{ item.username }}</td>
                    <td>{{ item.nama_opd || '-' }}</td>
                    <td>
                        <span v-if="item.bandwidth_download_mbps != null || item.bandwidth_upload_mbps != null">
                            ↓ {{ item.bandwidth_download_mbps ?? '—' }} / ↑ {{ item.bandwidth_upload_mbps ?? '—' }} Mbps
                        </span>
                        <span v-else class="text-slate-400">Belum diatur</span>
                    </td>
                    <td>
                        <span
                            class="badge"
                            :class="
                                String(item.status) === '1'
                                    ? 'bg-emerald-50 text-emerald-700'
                                    : 'bg-slate-100 text-slate-600'
                            "
                            >{{ String(item.status) === '1' ? 'Aktif' : 'Nonaktif' }}</span
                        >
                    </td>
                    <td>
                        <div v-if="auth.isSuperAdmin || !isPrivileged(item)" class="flex gap-2">
                            <button class="btn-secondary min-h-9 px-3" @click="openBandwidth(item)">
                                Bandwidth
                            </button>
                            <button class="btn-secondary min-h-9 px-3" @click="active(item)">
                                {{
                                    String(item.status) === '1' ? 'Nonaktifkan' : 'Aktifkan'
                                }}</button
                            ><button class="btn-danger min-h-9 px-3" @click="remove(item.id)">
                                Hapus
                            </button>
                        </div>
                        <span v-else class="text-xs text-slate-400">Dilindungi</span>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <div
        v-if="editingBandwidth"
        class="fixed inset-0 z-50 grid place-items-center bg-slate-950/40 p-4"
        @click.self="editingBandwidth = null"
    >
        <form class="card w-full max-w-md space-y-4 p-6" @submit.prevent="saveBandwidth">
            <div>
                <p class="eyebrow">Bandwidth per user</p>
                <h2 class="mt-1 text-xl font-bold">{{ editingBandwidth.name }}</h2>
                <p class="mt-1 text-sm text-slate-500">
                    Kosongkan nilai jika akun belum memiliki alokasi khusus.
                </p>
            </div>
            <label class="block">
                <span class="label">Download (Mbps)</span>
                <input v-model.number="bandwidthForm.download" class="input" type="number" min="0" max="1000000" />
            </label>
            <label class="block">
                <span class="label">Upload (Mbps)</span>
                <input v-model.number="bandwidthForm.upload" class="input" type="number" min="0" max="1000000" />
            </label>
            <div class="flex justify-end gap-2">
                <button type="button" class="btn-secondary" @click="editingBandwidth = null">Batal</button>
                <button class="btn-primary" :disabled="savingBandwidth">
                    {{ savingBandwidth ? 'Menyimpan…' : 'Simpan bandwidth' }}
                </button>
            </div>
        </form>
    </div>
</template>
