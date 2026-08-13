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
    show = ref(false),
    form = ref({ name: '', email: '', username: '', password: '', nama_opd: '' })
async function load() {
    try {
        list.value = rows(
            payload(await api.get('/admin/users', { params: { search: search.value } }))
        )
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function create() {
    try {
        await api.post('/admin/users', form.value)
        show.value = false
        await load()
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
onMounted(load)
</script>
<template>
    <PageHeader
        title="Manajemen pengguna"
        description="Kelola akun, status akses, dan admin Gelatik."
        ><button v-if="auth.isSuperAdmin" class="btn-primary" @click="show = !show">
            Tambah admin
        </button></PageHeader
    ><AlertMessage :message="error" />
    <form v-if="show" class="card mb-5" @submit.prevent="create">
        <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
            <input v-model="form.name" class="input" placeholder="Nama" required /><input
                v-model="form.email"
                type="email"
                class="input"
                placeholder="Email"
                required
            /><input v-model="form.username" class="input" placeholder="Username" required /><input
                v-model="form.password"
                type="password"
                class="input"
                placeholder="Password"
                required
            /><input v-model="form.nama_opd" class="input" placeholder="OPD" />
        </div>
        <button class="btn-primary mt-4">Simpan admin</button>
    </form>
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
                    <th>Status</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="item in list" :key="item.id">
                    <td>
                        <strong>{{ item.name }}</strong>
                        <p class="text-xs text-slate-400">{{ item.email }}</p>
                    </td>
                    <td>{{ item.username }}</td>
                    <td>{{ item.nama_opd || '-' }}</td>
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
                        <div class="flex gap-2">
                            <button class="btn-secondary min-h-9 px-3" @click="active(item)">
                                {{
                                    String(item.status) === '1' ? 'Nonaktifkan' : 'Aktifkan'
                                }}</button
                            ><button class="btn-danger min-h-9 px-3" @click="remove(item.id)">
                                Hapus
                            </button>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>
