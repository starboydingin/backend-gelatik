<script setup>
defineProps({
    open: Boolean,
    title: { type: String, default: 'Konfirmasi tindakan' },
    message: String,
    confirmLabel: { type: String, default: 'Lanjutkan' },
    danger: Boolean,
})
defineEmits(['confirm', 'cancel'])
</script>
<template>
    <Teleport to="body"
        ><div
            v-if="open"
            class="fixed inset-0 z-[70] grid place-items-center bg-slate-950/50 p-4"
            @click.self="$emit('cancel')"
        >
            <section
                class="card w-full max-w-md p-5"
                role="dialog"
                aria-modal="true"
                :aria-label="title"
            >
                <h2 class="text-xl font-bold text-navy">{{ title }}</h2>
                <p class="mt-2 text-sm leading-6 text-slate-600">{{ message }}</p>
                <div class="mt-5 flex justify-end gap-2">
                    <button class="btn-secondary" @click="$emit('cancel')">Batal</button
                    ><button
                        :class="danger ? 'btn-danger' : 'btn-primary'"
                        @click="$emit('confirm')"
                    >
                        {{ confirmLabel }}
                    </button>
                </div>
            </section>
        </div></Teleport
    >
</template>
