<script setup>
defineProps({ items: { type: Array, default: () => [] }, activePath: String })
</script>

<template>
    <nav
        class="brutal-mobile-nav fixed inset-x-0 bottom-0 z-30 border-t-[3px] border-[var(--line)] pb-[env(safe-area-inset-bottom)] lg:hidden"
        aria-label="Navigasi cepat"
    >
        <div class="mx-auto grid h-[72px] max-w-[560px] grid-flow-col auto-cols-fr">
            <RouterLink
                v-for="item in items"
                :key="item.to"
                :to="item.to"
                class="flex min-w-0 flex-col items-center justify-center gap-1 border-x border-transparent px-1 text-[10px] font-black uppercase"
                :class="activePath === item.to ? 'bg-[var(--emerald)] text-black' : 'text-[var(--ink)]'"
            >
                <component :is="item.icon" class="size-5" aria-hidden="true" />
                <span class="max-w-full truncate">{{ item.label }}</span>
            </RouterLink>
        </div>
    </nav>
</template>
