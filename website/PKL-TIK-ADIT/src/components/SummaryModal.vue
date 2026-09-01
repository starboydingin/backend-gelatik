<script setup>
import { nextTick, onBeforeUnmount, watch } from 'vue'

const props = defineProps({ open: Boolean, title: String })
const emit = defineEmits(['close'])
let previousFocus = null

function close() {
    emit('close')
}
function keydown(event) {
    if (event.key === 'Escape' && props.open) close()
}

watch(
    () => props.open,
    async (open) => {
        if (open) {
            previousFocus = document.activeElement
            document.addEventListener('keydown', keydown)
            await nextTick()
            document.querySelector('[data-summary-dialog]')?.focus()
        } else {
            document.removeEventListener('keydown', keydown)
            previousFocus?.focus?.()
        }
    }
)
onBeforeUnmount(() => document.removeEventListener('keydown', keydown))
</script>

<template>
    <Teleport to="body">
        <div
            v-if="open"
            class="fixed inset-0 z-[100] grid place-items-center bg-slate-950/50 p-4"
            role="presentation"
            @mousedown.self="close"
        >
            <section
                data-summary-dialog
                class="card max-h-[85vh] w-full max-w-2xl overflow-y-auto p-0"
                role="dialog"
                aria-modal="true"
                :aria-label="title || 'Ringkasan'"
                tabindex="-1"
            >
                <header class="flex items-start justify-between gap-4 border-b border-[var(--color-border)] p-4">
                    <div><p class="eyebrow">Ringkasan</p><h2 class="mt-1 text-xl font-bold">{{ title }}</h2></div>
                    <button class="btn-secondary min-h-9 px-3" type="button" @click="close">Tutup</button>
                </header>
                <div class="p-4"><slot /></div>
            </section>
        </div>
    </Teleport>
</template>
