<script setup>
defineProps({ items: { type: Array, default: () => [] }, activePath: String })
</script>

<template>
    <nav
        class="fixed inset-x-0 bottom-0 z-30 border-t border-stroke bg-white/95 pb-[env(safe-area-inset-bottom)] backdrop-blur lg:hidden"
        aria-label="Navigasi cepat"
    >
        <div class="mx-auto grid h-[72px] max-w-[560px] grid-flow-col auto-cols-fr">
            <RouterLink
                v-for="item in items"
                :key="item.to"
                :to="item.to"
                class="flex min-w-0 flex-col items-center justify-center gap-1 px-1 text-[11px] font-semibold"
                :class="activePath === item.to ? 'text-brand-700' : 'text-slate-500'"
            >
                <component :is="item.icon" class="size-5" aria-hidden="true" />
                <span class="max-w-full truncate">{{ item.label }}</span>
            </RouterLink>
        </div>
    </nav>
</template>
