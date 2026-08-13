<script setup>
import { onMounted, ref } from 'vue'
import { api, payload, rows, errorMessage } from '../../lib/api'
import PageHeader from '../../components/PageHeader.vue'
import AlertMessage from '../../components/AlertMessage.vue'
import { useAuthStore } from '../../stores/auth'
const auth = useAuthStore()
const list = ref([]),
    permissions = ref([]),
    error = ref(''),
    form = ref({ name: '', permissions: [] })
async function load() {
    try {
        const [r, p] = await Promise.all([api.get('/admin/roles'), api.get('/admin/permissions')])
        list.value = rows(payload(r))
        permissions.value = rows(payload(p))
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function create() {
    try {
        await api.post('/admin/roles', form.value)
        form.value = { name: '', permissions: [] }
        load()
    } catch (e) {
        error.value = errorMessage(e)
    }
}
async function remove(id) {
    if (confirm('Hapus peran ini?')) {
        await api.delete(`/admin/roles/${id}`)
        load()
    }
}
onMounted(load)
</script>
<template>
    <PageHeader
        title="Peran & izin"
        description="Atur kelompok akses yang digunakan Backend Gelatik."
    /><AlertMessage :message="error" />
    <div class="grid gap-5 xl:grid-cols-[1fr_1.5fr]">
        <form v-if="auth.isSuperAdmin" class="card" @submit.prevent="create">
            <h2 class="font-bold">Buat peran</h2>
            <label class="mt-4 block"
                ><span class="label">Nama peran</span
                ><input v-model="form.name" class="input" required
            /></label>
            <p class="mb-2 mt-4 text-sm font-semibold">Izin</p>
            <div class="max-h-72 space-y-2 overflow-auto rounded-xl border border-slate-200 p-3">
                <label
                    v-for="permission in permissions"
                    :key="permission.id"
                    class="flex items-center gap-2 text-sm"
                    ><input v-model="form.permissions" type="checkbox" :value="permission.name" />{{
                        permission.name
                    }}</label
                >
            </div>
            <button class="btn-primary mt-4">Simpan peran</button>
        </form>
        <div class="space-y-3">
            <article v-for="role in list" :key="role.id" class="card">
                <div class="flex justify-between">
                    <div>
                        <h2 class="font-bold capitalize">{{ role.name }}</h2>
                        <p class="mt-2 text-sm text-slate-500">
                            {{
                                (role.permissions || []).map((p) => p.name).join(', ') ||
                                'Tanpa izin khusus'
                            }}
                        </p>
                    </div>
                    <button v-if="auth.isSuperAdmin" class="btn-danger" @click="remove(role.id)">
                        Hapus
                    </button>
                </div>
            </article>
        </div>
    </div>
</template>
