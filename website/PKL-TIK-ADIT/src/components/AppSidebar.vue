<script setup>
import { computed } from 'vue'
import GelatikLogo from './GelatikLogo.vue'
import {
    ArrowRightStartOnRectangleIcon,
    ArrowPathRoundedSquareIcon,
    ChatBubbleLeftRightIcon,
} from '@heroicons/vue/24/outline'

const props = defineProps({
    items: { type: Array, default: () => [] },
    activePath: String,
    adminArea: Boolean,
    isAdmin: Boolean,
    open: Boolean,
})
defineEmits(['close', 'logout'])
const groups = computed(() => [...new Set(props.items.map((item) => item.group))])
</script>

<template>
    <aside
        class="fixed inset-y-0 left-0 z-40 flex w-[270px] flex-col bg-navy text-white transition-transform lg:sticky lg:top-0 lg:h-screen"
        :class="open ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'"
    >
        <div class="flex h-[76px] items-center border-b border-white/10 px-6">
            <GelatikLogo compact class="brightness-0 invert" />
        </div>
        <nav class="min-h-0 flex-1 overflow-y-auto px-4 py-5" aria-label="Navigasi utama">
            <section v-for="group in groups" :key="group" class="mb-6">
                <p
                    class="mb-2 px-3 text-[10px] font-bold uppercase tracking-[.18em] text-blue-200/70"
                >
                    {{ group }}
                </p>
                <RouterLink
                    v-for="item in items.filter((entry) => entry.group === group)"
                    :key="item.to"
                    :to="item.to"
                    class="mb-1 flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold"
                    :class="
                        activePath === item.to
                            ? 'bg-white text-navy shadow-sm'
                            : 'text-blue-100 hover:bg-white/10 hover:text-white'
                    "
                    @click="$emit('close')"
                >
                    <span
                        class="grid size-8 shrink-0 place-items-center rounded-lg"
                        :class="
                            activePath === item.to ? 'bg-brand-50 text-brand-600' : 'text-teal-200'
                        "
                        ><component :is="item.icon" class="size-5" /></span
                    ><span class="truncate">{{ item.label }}</span
                    ><span
                        v-if="activePath === item.to"
                        class="ml-auto size-2 rounded-full bg-action"
                    />
                </RouterLink>
            </section>
        </nav>
        <div class="m-4 rounded-2xl border border-white/10 bg-white/10 p-4">
            <div class="flex items-center gap-2 text-sm font-bold">
                <ChatBubbleLeftRightIcon class="size-5 text-teal-300" />Butuh bantuan?
            </div>
            <p class="mt-2 text-xs leading-5 text-blue-100/80">
                Tim TIK siap membantu kebutuhan dan kendala layanan Anda.
            </p>
            <RouterLink
                :to="adminArea ? '/admin/konsultasi' : '/app/konsultasi'"
                class="mt-3 inline-flex items-center gap-2 text-xs font-bold text-teal-300"
                >Buka konsultasi <span>→</span></RouterLink
            >
        </div>
        <div class="grid grid-cols-2 gap-2 border-t border-white/10 p-4">
            <RouterLink
                v-if="isAdmin"
                :to="adminArea ? '/app/dashboard' : '/admin/dashboard'"
                class="grid min-h-11 place-items-center rounded-xl bg-white/10 text-xs font-semibold hover:bg-white/15"
                :title="`Beralih ke ${adminArea ? 'portal user' : 'admin'}`"
                ><ArrowPathRoundedSquareIcon class="size-5"
            /></RouterLink>
            <button
                class="flex min-h-11 items-center justify-center gap-2 rounded-xl bg-white/10 px-3 text-xs font-semibold hover:bg-white/15"
                :class="!isAdmin && 'col-span-2'"
                @click="$emit('logout')"
            >
                <ArrowRightStartOnRectangleIcon class="size-5" />Keluar
            </button>
        </div>
    </aside>
</template>
