<script setup>
defineProps({
    currentPage: { type: Number, default: 1 },
    lastPage: { type: Number, default: 1 },
    total: { type: Number, default: 0 },
})
defineEmits(['change'])
</script>

<template>
    <nav
        v-if="lastPage > 1"
        class="mt-5 flex flex-wrap items-center justify-between gap-3 border-t border-[var(--color-border)] pt-4"
        aria-label="Navigasi halaman"
    >
        <p class="text-sm text-slate-600">Halaman {{ currentPage }} dari {{ lastPage }} · {{ total }} data</p>
        <div class="flex gap-2">
            <button
                type="button"
                class="btn-secondary min-h-10 px-3"
                :disabled="currentPage <= 1"
                @click="$emit('change', currentPage - 1)"
            >
                Sebelumnya
            </button>
            <button
                type="button"
                class="btn-secondary min-h-10 px-3"
                :disabled="currentPage >= lastPage"
                @click="$emit('change', currentPage + 1)"
            >
                Berikutnya
            </button>
        </div>
    </nav>
</template>
