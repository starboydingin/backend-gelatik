<script setup>
import { computed, ref, watch } from 'vue'
import GelatikLogo from './GelatikLogo.vue'
import {
    ArrowRightStartOnRectangleIcon,
    ChevronDownIcon,
    XMarkIcon,
} from '@heroicons/vue/24/outline'

const props = defineProps({
    items: { type: Array, default: () => [] },
    activePath: String,
    adminArea: Boolean,
    areaLabel: { type: String, default: 'Admin' },
    open: Boolean,
})
defineEmits(['close', 'logout'])

const dashboardItem = computed(() =>
    props.items.find((item) => item.to.endsWith('/dashboard') || item.singleLevel)
)
const otherItems = computed(() =>
    props.items.filter((item) => item !== dashboardItem.value)
)
const groups = computed(() => [...new Set(otherItems.value.map((item) => item.group))])
const activeGroup = computed(() =>
    groups.value.find((group) =>
        otherItems.value.some((item) => item.group === group && isItemActive(item))
    )
)
const openGroup = ref('')

function isItemActive(item) {
    if (!item) return false
    return props.activePath === item.to || props.activePath?.startsWith(`${item.to}/`)
}

function toggleGroup(group) {
    openGroup.value = openGroup.value === group ? '' : group
}

watch(
    [activeGroup, groups],
    ([current, available]) => {
        if (current) openGroup.value = current
        else if (!available.includes(openGroup.value)) openGroup.value = available[0] || ''
    },
    { immediate: true }
)
</script>

<template>
    <aside
        class="app-sidebar fixed inset-y-0 left-0 z-40 flex w-[272px] flex-col text-white transition-transform lg:sticky lg:top-0 lg:h-screen"
        :class="open ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'"
    >
        <div class="app-sidebar-brand flex h-[68px] items-center border-b px-4">
            <GelatikLogo compact inverse />
            <span
                v-if="adminArea"
                class="ml-auto rounded-full bg-amber-400 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-slate-950"
                >{{ areaLabel }}</span
            >
            <button
                type="button"
                class="ml-2 grid size-9 place-items-center rounded-lg text-blue-100 hover:bg-white/10 hover:text-white lg:hidden"
                aria-label="Tutup navigasi utama"
                @click="$emit('close')"
            >
                <XMarkIcon class="size-5" />
            </button>
        </div>
        <nav
            class="no-scrollbar min-h-0 flex-1 overflow-y-auto px-3 py-4"
            aria-label="Navigasi utama"
        >
            <!-- Single-level Dashboard Navigation Item -->
            <div v-if="dashboardItem" class="mb-2">
                <RouterLink
                    :to="dashboardItem.to"
                    class="flex items-center gap-2.5 rounded-lg border border-transparent px-2.5 py-2.5 text-sm font-semibold transition"
                    :class="
                        isItemActive(dashboardItem)
                            ? 'border-white/15 bg-white text-blue-950 shadow-sm'
                            : 'text-blue-50 hover:bg-white/10 hover:text-white'
                    "
                    @click="$emit('close')"
                >
                    <span
                        class="grid size-7 shrink-0 place-items-center rounded-md"
                        :class="
                            isItemActive(dashboardItem)
                                ? 'bg-blue-50 text-blue-800'
                                : 'text-blue-200'
                        "
                    >
                        <component :is="dashboardItem.icon" class="size-[18px]" />
                    </span>
                    <span class="truncate">{{ dashboardItem.label }}</span>
                </RouterLink>
            </div>

            <section v-for="group in groups" :key="group" class="mb-1.5">
                <button
                    type="button"
                    class="flex w-full items-center justify-between gap-3 rounded-lg px-3 py-2.5 text-left text-xs font-bold uppercase tracking-[.12em] transition"
                    :class="
                        activeGroup === group
                            ? 'bg-white/10 text-white'
                            : 'text-blue-200 hover:bg-white/5 hover:text-white'
                    "
                    :aria-expanded="openGroup === group"
                    :aria-controls="`navigation-group-${group.replaceAll(' ', '-')}`"
                    @click="toggleGroup(group)"
                >
                    <span>{{ group }}</span>
                    <ChevronDownIcon
                        class="size-4 shrink-0 transition-transform duration-200"
                        :class="openGroup === group ? 'rotate-180' : ''"
                    />
                </button>
                <div
                    :id="`navigation-group-${group.replaceAll(' ', '-')}`"
                    class="navigation-accordion"
                    :class="openGroup === group ? 'is-open' : ''"
                >
                    <div class="navigation-accordion-inner space-y-1 px-1 pt-1">
                        <RouterLink
                            v-for="item in items.filter((entry) => entry.group === group)"
                            :key="item.to"
                            :to="item.to"
                            class="flex items-center gap-2.5 rounded-lg border border-transparent px-2.5 py-2 text-sm font-semibold"
                            :class="
                                isItemActive(item)
                                    ? 'border-white/15 bg-white text-blue-950 shadow-sm'
                                    : 'text-blue-50 hover:bg-white/10 hover:text-white'
                            "
                            @click="$emit('close')"
                        >
                            <span
                                class="grid size-7 shrink-0 place-items-center rounded-md"
                                :class="
                                    isItemActive(item)
                                        ? 'bg-blue-50 text-blue-800'
                                        : 'text-blue-200'
                                "
                                ><component :is="item.icon" class="size-[18px]"
                            /></span>
                            <span class="truncate">{{ item.label }}</span>
                        </RouterLink>
                    </div>
                </div>
            </section>
        </nav>
        <div class="border-t border-white/15 p-3">
            <button
                class="flex min-h-10 w-full items-center justify-center gap-2 rounded-lg border border-white/20 bg-white/10 px-3 text-sm font-semibold text-white hover:bg-white/15"
                @click="$emit('logout')"
            >
                <ArrowRightStartOnRectangleIcon class="size-5" />Keluar
            </button>
        </div>
    </aside>
</template>

<style scoped>
.navigation-accordion {
    display: grid;
    grid-template-rows: 0fr;
    opacity: 0;
    transition:
        grid-template-rows 220ms ease,
        opacity 180ms ease;
}

.navigation-accordion.is-open {
    grid-template-rows: 1fr;
    opacity: 1;
}

.navigation-accordion-inner {
    min-height: 0;
    overflow: hidden;
}

@media (prefers-reduced-motion: reduce) {
    .navigation-accordion {
        transition: none;
    }
}
</style>
