<script setup>
defineProps({ label: String, error: String, hint: String })
const model = defineModel()
</script>

<template>
    <label class="block">
        <span v-if="label" class="label">{{ label }}</span>
        <input
            v-bind="$attrs"
            v-model="model"
            class="input"
            :aria-invalid="Boolean(error)"
            :aria-describedby="error || hint ? `${$attrs.id}-help` : undefined"
        />
        <span
            v-if="error || hint"
            :id="`${$attrs.id}-help`"
            class="mt-1.5 block text-xs"
            :class="error ? 'text-danger' : 'text-slate-500'"
            >{{ error || hint }}</span
        >
    </label>
</template>
