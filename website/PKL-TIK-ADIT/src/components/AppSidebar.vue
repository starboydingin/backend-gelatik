<script setup>
import { computed } from 'vue'
import GelatikLogo from './GelatikLogo.vue'
import { ArrowRightStartOnRectangleIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
    items: { type: Array, default: () => [] },
    activePath: String,
    adminArea: Boolean,
    areaLabel: { type: String, default: 'Admin' },
    open: Boolean,
})
defineEmits(['close', 'logout'])
const groups = computed(() => [...new Set(props.items.map((item) => item.group))])
</script>

<template>
    <aside
        class="app-sidebar fixed inset-y-0 left-0 z-40 flex w-[286px] flex-col text-white transition-transform md:sticky md:top-0 md:h-screen"
        :class="open ? 'translate-x-0' : '-translate-x-full md:translate-x-0'"
    >
        <div class="app-sidebar-brand flex h-[76px] items-center border-b px-5">
            <GelatikLogo compact inverse />
            <span
                v-if="adminArea"
                class="ml-auto rounded-full bg-amber-400 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-slate-950"
                >{{ areaLabel }}</span
            >
        </div>
        <nav
            class="no-scrollbar min-h-0 flex-1 overflow-y-auto px-4 py-5"
            aria-label="Navigasi utama"
        >
            <section v-for="group in groups" :key="group" class="mb-6">
                <p
                    class="mb-2 px-2 pb-1 text-[10px] font-bold uppercase tracking-[.16em] text-blue-200"
                >
                    {{ group }}
                </p>
                <RouterLink
                    v-for="item in items.filter((entry) => entry.group === group)"
                    :key="item.to"
                    :to="item.to"
                    class="mb-1 flex items-center gap-3 rounded-lg border border-transparent px-3 py-2.5 text-sm font-semibold"
                    :class="
                        activePath === item.to
                            ? 'border-white/15 bg-white text-blue-950 shadow-sm'
                            : 'text-blue-50 hover:bg-white/10 hover:text-white'
                    "
                    @click="$emit('close')"
                >
                    <span
                        class="grid size-8 shrink-0 place-items-center rounded-md"
                        :class="
                            activePath === item.to ? 'bg-blue-50 text-blue-800' : 'text-blue-200'
                        "
                        ><component :is="item.icon" class="size-5" /></span
                    ><span class="truncate">{{ item.label }}</span>
                </RouterLink>
            </section>
        </nav>
        <div class="border-t border-white/15 p-4">
            <button
                class="flex min-h-11 w-full items-center justify-center gap-2 rounded-lg border border-white/20 bg-white/10 px-3 text-sm font-semibold text-white hover:bg-white/15"
                @click="$emit('logout')"
            >
                <ArrowRightStartOnRectangleIcon class="size-5" />Keluar
            </button>
        </div>
    </aside>
</template>
