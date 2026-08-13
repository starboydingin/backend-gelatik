<script setup>
import { computed } from 'vue'
import GelatikLogo from './GelatikLogo.vue'
import { ArrowRightStartOnRectangleIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
    items: { type: Array, default: () => [] },
    activePath: String,
    adminArea: Boolean,
    open: Boolean,
})
defineEmits(['close', 'logout'])
const groups = computed(() => [...new Set(props.items.map((item) => item.group))])
</script>

<template>
    <aside
        class="fixed inset-y-0 left-0 z-40 flex w-[270px] flex-col border-r border-stroke bg-white text-slate-700 transition-transform lg:sticky lg:top-0 lg:h-screen"
        :class="open ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'"
    >
        <div class="flex h-[76px] items-center border-b border-stroke px-6">
            <GelatikLogo compact />
            <span
                v-if="adminArea"
                class="ml-auto rounded-md bg-navy px-2 py-1 text-[10px] font-bold uppercase tracking-wider text-white"
                >Admin</span
            >
        </div>
        <nav
            class="no-scrollbar min-h-0 flex-1 overflow-y-auto px-4 py-5"
            aria-label="Navigasi utama"
        >
            <section v-for="group in groups" :key="group" class="mb-6">
                <p
                    class="mb-2 px-3 text-[10px] font-bold uppercase tracking-[.16em] text-slate-400"
                >
                    {{ group }}
                </p>
                <RouterLink
                    v-for="item in items.filter((entry) => entry.group === group)"
                    :key="item.to"
                    :to="item.to"
                    class="mb-1 flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold"
                    :class="
                        activePath === item.to
                            ? 'bg-brand-50 text-brand-800'
                            : 'text-slate-600 hover:bg-slate-50 hover:text-navy'
                    "
                    @click="$emit('close')"
                >
                    <span
                        class="grid size-8 shrink-0 place-items-center rounded-lg"
                        :class="
                            activePath === item.to ? 'bg-white text-brand-700' : 'text-slate-400'
                        "
                        ><component :is="item.icon" class="size-5" /></span
                    ><span class="truncate">{{ item.label }}</span>
                </RouterLink>
            </section>
        </nav>
        <div class="border-t border-stroke p-4">
            <button
                class="flex min-h-11 w-full items-center justify-center gap-2 rounded-lg border border-stroke px-3 text-xs font-semibold text-slate-600 hover:bg-slate-50"
                @click="$emit('logout')"
            >
                <ArrowRightStartOnRectangleIcon class="size-5" />Keluar
            </button>
        </div>
    </aside>
</template>
