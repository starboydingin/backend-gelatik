<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { BellIcon } from '@heroicons/vue/24/outline'
import { useRouter } from 'vue-router'
import { api, errorMessage, invalidateApiCache, payload, rows } from '../lib/api'
import { notificationRoute } from '../lib/notificationRoute'

const props = defineProps({ adminArea: Boolean })
const router = useRouter()

const open = ref(false)
const items = ref([])
const error = ref('')
const unread = computed(() => items.value.filter((item) => !item.read && !item.read_at).length)

async function load({ fresh = false } = {}) {
    try {
        if (fresh) invalidateApiCache('/notifications')
        items.value = rows(payload(await api.get('/notifications', { cache: !fresh }))).slice(0, 5)
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
async function markRead(item) {
    if (!item.read && !item.read_at) await api.post(`/notifications/${item.id}/read`)
    item.read = true
}
function toggleOpen() {
    open.value = !open.value
}
async function openItem(item) {
    try {
        await markRead(item)
        open.value = false
        await router.push(notificationRoute(item, props.adminArea))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    }
}
function realtimeRefresh() {
    load({ fresh: true })
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
            class="icon-button relative"
            aria-label="Buka notifikasi"
            :aria-expanded="open"
            @click="toggleOpen"
        >
            <BellIcon class="size-5" />
            <span
                v-if="unread"
                class="absolute -right-1 -top-1 grid size-5 place-items-center rounded-full bg-red-600 text-[10px] font-bold text-white ring-2 ring-[var(--color-surface)]"
                >{{ unread > 9 ? '9+' : unread }}</span
            >
        </button>
        <div
            v-if="open"
            class="absolute right-0 top-14 z-50 w-[min(22rem,calc(100vw-2rem))] overflow-hidden rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] shadow-[var(--shadow-overlay)]"
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
                @click="openItem(item)"
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
