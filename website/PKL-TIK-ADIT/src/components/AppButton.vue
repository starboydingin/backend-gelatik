<script setup>
defineProps({
    variant: { type: String, default: 'primary' },
    loading: Boolean,
    type: { type: String, default: 'button' },
})
</script>

<template>
    <button
        :type="type"
        :disabled="loading || $attrs.disabled"
        :class="
            variant === 'secondary'
                ? 'btn-secondary'
                : variant === 'danger'
                  ? 'btn-danger'
                  : 'btn-primary'
        "
    >
        <span
            v-if="loading"
            class="size-4 animate-spin rounded-full border-2 border-current border-r-transparent"
            aria-hidden="true"
        />
        <slot>{{ loading ? 'Memproses…' : '' }}</slot>
    </button>
</template>
