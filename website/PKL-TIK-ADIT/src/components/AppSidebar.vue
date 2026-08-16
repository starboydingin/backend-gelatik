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
        class="brutal-sidebar fixed inset-y-0 left-0 z-40 flex w-[286px] flex-col border-r-[2px] border-[var(--line)] text-[var(--ink)] transition-transform lg:sticky lg:top-0 lg:h-screen"
        :class="open ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'"
    >
        <div class="app-sidebar-brand flex h-[76px] items-center border-b-[3px] border-[var(--line)] px-5">
            <GelatikLogo compact />
            <span
                v-if="adminArea"
                class="ml-auto border-2 border-[var(--line)] bg-[var(--gold)] px-2 py-1 text-[10px] font-black uppercase tracking-wider text-black"
                >Admin</span
            >
        </div>
        <nav
            class="no-scrollbar min-h-0 flex-1 overflow-y-auto px-4 py-5"
            aria-label="Navigasi utama"
        >
            <section v-for="group in groups" :key="group" class="mb-6">
                <p
                    class="mb-2 border-b-2 border-[var(--line)] px-1 pb-1 text-[10px] font-black uppercase tracking-[.16em] text-[var(--ink)]"
                >
                    {{ group }}
                </p>
                <RouterLink
                    v-for="item in items.filter((entry) => entry.group === group)"
                    :key="item.to"
                    :to="item.to"
                    class="mb-2 flex items-center gap-3 border-2 border-transparent px-3 py-2.5 text-sm font-extrabold uppercase tracking-[-.02em]"
                    :class="
                        activePath === item.to
                            ? 'border-[var(--line)] bg-[var(--teal)] text-black shadow-[3px_3px_0_var(--line)]'
                            : 'text-[var(--ink)] hover:border-[var(--line)] hover:bg-[var(--gold)] hover:text-black'
                    "
                    @click="$emit('close')"
                >
                    <span
                        class="grid size-8 shrink-0 place-items-center border-2 border-transparent"
                        :class="
                            activePath === item.to ? 'border-[var(--line)] bg-[var(--paper)] text-[var(--ink)]' : 'text-[var(--ink)]'
                        "
                        ><component :is="item.icon" class="size-5" /></span
                    ><span class="truncate">{{ item.label }}</span>
                </RouterLink>
            </section>
        </nav>
        <div class="border-t-[3px] border-[var(--line)] p-4">
            <button
                class="btn-danger flex w-full items-center justify-center gap-2 px-3 text-xs"
                @click="$emit('logout')"
            >
                <ArrowRightStartOnRectangleIcon class="size-5" />Keluar
            </button>
        </div>
    </aside>
</template>
