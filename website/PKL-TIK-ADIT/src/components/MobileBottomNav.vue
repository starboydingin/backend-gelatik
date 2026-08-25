<script setup>
defineProps({ items: { type: Array, default: () => [] }, activePath: String })
</script>

<template>
    <nav
        class="fixed inset-x-0 bottom-0 z-30 border-t border-[var(--color-border)] bg-[var(--color-surface)] pb-[env(safe-area-inset-bottom)] shadow-[0_-4px_18px_rgb(15_23_42_/_0.08)] md:hidden"
        aria-label="Navigasi cepat"
    >
        <div class="mx-auto grid h-[72px] max-w-[560px] grid-flow-col auto-cols-fr">
            <RouterLink
                v-for="item in items"
                :key="item.to"
                :to="item.to"
                class="relative flex min-w-0 flex-col items-center justify-center gap-1 px-1 text-[10px] font-semibold"
                :class="
                    activePath === item.to
                        ? 'text-[var(--color-brand-primary)]'
                        : 'text-[var(--color-text-muted)]'
                "
            >
                <span
                    v-if="activePath === item.to"
                    class="absolute inset-x-5 top-0 h-1 rounded-b bg-[var(--color-brand-secondary)]"
                />
                <component :is="item.icon" class="size-5" aria-hidden="true" />
                <span class="max-w-full truncate">{{ item.label }}</span>
            </RouterLink>
        </div>
    </nav>
</template>
