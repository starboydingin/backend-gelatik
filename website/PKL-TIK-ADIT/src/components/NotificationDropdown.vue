<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { BellIcon } from '@heroicons/vue/24/outline'
import { api, errorMessage, payload, rows } from '../lib/api'

defineProps({ adminArea: Boolean })

const open = ref(false)
const items = ref([])
const error = ref('')
const unread = computed(() => items.value.filter((item) => !item.read && !item.read_at).length)

async function load() {
    try {
        items.value = rows(payload(await api.get('/notifications'))).slice(0, 5)
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function markRead(item) {
    if (!item.read && !item.read_at) await api.post(`/notifications/${item.id}/read`)
    item.read = true
}
function realtimeRefresh() {
    load()
}
onMounted(() => {
    load()
    window.addEventListener('gelatik:notification', realtimeRefresh)
})
onUnmounted(() => window.removeEventListener('gelatik:notification', realtimeRefresh))
</script>

<template>
    <div class="relative">
        <button
            class="relative grid size-11 place-items-center rounded-xl border border-stroke bg-white text-navy hover:bg-slate-50"
            aria-label="Buka notifikasi"
            :aria-expanded="open"
            @click="open = !open"
        >
            <BellIcon class="size-5" />
            <span
                v-if="unread"
                class="absolute -right-1 -top-1 grid size-5 place-items-center rounded-full bg-danger text-[10px] font-bold text-white"
                >{{ unread > 9 ? '9+' : unread }}</span
            >
        </button>
        <div
            v-if="open"
            class="absolute right-0 top-14 z-50 w-[min(22rem,calc(100vw-2rem))] overflow-hidden rounded-2xl border border-stroke bg-white shadow-xl"
        >
            <div class="flex items-center justify-between border-b border-stroke px-4 py-3">
                <strong class="text-sm text-navy">Notifikasi terbaru</strong
                ><RouterLink
                    :to="adminArea ? '/admin/notifikasi' : '/app/notifikasi'"
                    class="text-xs font-semibold text-brand-700"
                    @click="open = false"
                    >Lihat semua</RouterLink
                >
            </div>
            <p v-if="error" class="p-4 text-sm text-danger">{{ error }}</p>
            <p v-else-if="!items.length" class="p-6 text-center text-sm text-slate-500">
                Belum ada notifikasi.
            </p>
            <button
                v-for="item in items"
                v-else
                :key="item.id"
                class="flex w-full gap-3 border-b border-slate-100 px-4 py-3 text-left last:border-0 hover:bg-slate-50"
                @click="markRead(item)"
            >
                <span
                    class="mt-1 size-2 shrink-0 rounded-full"
                    :class="item.read || item.read_at ? 'bg-slate-200' : 'bg-action'"
                />
                <span class="min-w-0"
                    ><strong class="block truncate text-sm text-navy">{{
                        item.judul || 'Informasi layanan'
                    }}</strong
                    ><span class="mt-1 line-clamp-2 text-xs leading-5 text-slate-500">{{
                        item.message
                    }}</span></span
                >
            </button>
        </div>
    </div>
</template>
