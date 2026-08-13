<script setup>
defineProps({ message: String, type: { type: String, default: 'error' } })
</script>
<template>
    <div
        v-if="message"
        class="mb-4 rounded-xl border px-4 py-3 text-sm"
        :class="
            type === 'success'
                ? 'border-emerald-200 bg-emerald-50 text-emerald-800'
                : 'border-rose-200 bg-rose-50 text-rose-800'
        "
    >
        {{ message }}
    </div>
</template>
