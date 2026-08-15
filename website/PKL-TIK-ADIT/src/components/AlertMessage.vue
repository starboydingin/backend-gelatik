<script setup>
defineProps({ message: String, type: { type: String, default: 'error' } })
</script>
<template>
    <div
        v-if="message"
        class="mb-4 border-[3px] border-[var(--line)] px-4 py-3 text-sm font-bold shadow-[4px_4px_0_var(--line)]"
        :class="
            type === 'success'
                ? 'bg-[var(--emerald)] text-black'
                : 'bg-[var(--danger)] text-black'
        "
    >
        {{ message }}
    </div>
</template>
