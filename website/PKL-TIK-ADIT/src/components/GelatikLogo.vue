<script setup>
import gelatikWordmark from '../assets/images/gelatik-wordmark.png'

defineProps({
    compact: Boolean,
    inverse: Boolean,
})
</script>

<template>
    <span
        class="gelatik-brand inline-flex min-w-0 items-center"
        :class="compact ? 'gap-2.5' : 'gap-3'"
        aria-label="Gelatik"
    >
        <span
            class="gelatik-brand__mark grid shrink-0 place-items-center bg-white"
            :class="compact ? 'size-11' : 'size-14'"
        >
            <img
                :src="gelatikWordmark"
                alt=""
                aria-hidden="true"
                class="size-[82%] object-contain"
            />
        </span>
        <span
            class="gelatik-brand__name"
            :class="[
                compact ? 'text-lg' : 'text-xl',
                inverse ? 'text-white' : 'text-[var(--color-brand-primary-strong)]',
            ]"
        >
            GELATIK
        </span>
    </span>
</template>

<style scoped>
.gelatik-brand__mark {
    border: 1px solid rgb(203 213 225 / 0.85);
    border-radius: 0.625rem;
}

.gelatik-brand__name {
    font-family: Montserrat, Inter, Urbanist, ui-sans-serif, system-ui, sans-serif;
    font-weight: 800;
    letter-spacing: 0.075em;
    line-height: 1;
    white-space: nowrap;
}
</style>
