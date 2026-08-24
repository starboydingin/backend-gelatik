<script setup>
defineProps({ message: String, type: { type: String, default: 'error' } })
</script>
<template>
    <div
        v-if="message"
        class="mb-4 rounded-lg border px-4 py-3 text-sm font-semibold"
        :class="
            type === 'success'
                ? 'border-green-200 bg-green-50 text-green-800'
                : 'border-red-200 bg-red-50 text-red-800'
        "
    >
        {{ message }}
    </div>
</template>
