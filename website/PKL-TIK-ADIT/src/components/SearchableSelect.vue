<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { ChevronDownIcon, MagnifyingGlassIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
    modelValue: { type: [String, Number], default: '' },
    options: { type: Array, default: () => [] },
    label: { type: String, required: true },
    placeholder: { type: String, default: 'Pilih pilihan' },
    searchPlaceholder: { type: String, default: 'Cari…' },
    disabled: Boolean,
})
const emit = defineEmits(['update:modelValue'])
const open = ref(false)
const query = ref('')
const root = ref(null)

const normalizedOptions = computed(() =>
    props.options.map((item) =>
        typeof item === 'object'
            ? { value: item.value ?? item.id, label: item.label ?? item.name ?? item.nama ?? String(item.value ?? item.id) }
            : { value: item, label: String(item) },
    ),
)
const selected = computed(() =>
    normalizedOptions.value.find((item) => String(item.value) === String(props.modelValue)),
)
const filtered = computed(() => {
    const needle = query.value.trim().toLocaleLowerCase('id-ID')
    return needle
        ? normalizedOptions.value.filter((item) => item.label.toLocaleLowerCase('id-ID').includes(needle))
        : normalizedOptions.value
})
function choose(option) {
    emit('update:modelValue', option.value)
    open.value = false
    query.value = ''
}
function closeOutside(event) {
    if (!root.value?.contains(event.target)) open.value = false
}
watch(open, (active) => {
    if (active) document.addEventListener('mousedown', closeOutside)
    else document.removeEventListener('mousedown', closeOutside)
})
onBeforeUnmount(() => document.removeEventListener('mousedown', closeOutside))
</script>

<template>
    <div ref="root" class="relative">
        <span class="label">{{ label }}</span>
        <button
            type="button"
            class="input flex w-full items-center justify-between gap-3 text-left"
            :disabled="disabled"
            :aria-expanded="open"
            @click="open = !open"
        >
            <span class="min-w-0 truncate" :class="selected ? '' : 'text-slate-400'">{{ selected?.label || placeholder }}</span>
            <ChevronDownIcon class="size-5 shrink-0" />
        </button>
        <div v-if="open" class="absolute z-30 mt-1.5 w-full overflow-hidden rounded-lg border border-[var(--color-border-strong)] bg-white shadow-lg">
            <div class="border-b border-[var(--color-border)] p-2">
                <label class="sr-only" :for="`${label}-search`">{{ searchPlaceholder }}</label>
                <div class="relative">
                    <MagnifyingGlassIcon class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-slate-500" />
                    <input
                        :id="`${label}-search`"
                        v-model="query"
                        type="search"
                        class="input w-full py-2 pl-9"
                        :placeholder="searchPlaceholder"
                        autofocus
                    />
                </div>
            </div>
            <ul class="max-h-56 overflow-y-auto py-1" role="listbox">
                <li v-if="!filtered.length" class="px-3 py-4 text-sm text-slate-500">Tidak ada pilihan yang cocok.</li>
                <li v-for="option in filtered" :key="String(option.value)">
                    <button
                        type="button"
                        class="flex w-full items-start px-3 py-2.5 text-left text-sm hover:bg-brand-50"
                        :class="String(option.value) === String(modelValue) ? 'bg-brand-50 font-bold text-brand-800' : ''"
                        @click="choose(option)"
                    >
                        {{ option.label }}
                    </button>
                </li>
            </ul>
        </div>
    </div>
</template>
