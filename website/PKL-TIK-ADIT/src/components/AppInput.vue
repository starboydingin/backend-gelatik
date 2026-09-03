<script setup>
import { computed, ref } from 'vue'
import { EyeIcon, EyeSlashIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
    label: String,
    error: String,
    hint: String,
    type: {
        type: String,
        default: 'text',
    },
})

const model = defineModel()
const showPassword = ref(false)

const isPassword = computed(() => props.type === 'password')
const computedType = computed(() => {
    if (isPassword.value) {
        return showPassword.value ? 'text' : 'password'
    }
    return props.type
})
</script>

<template>
    <label class="block">
        <span v-if="label" class="label">{{ label }}</span>
        <div class="relative">
            <input
                v-bind="$attrs"
                v-model="model"
                :type="computedType"
                class="input w-full"
                :class="{ '!pr-10': isPassword }"
                :aria-invalid="Boolean(error)"
                :aria-describedby="error || hint ? `${$attrs.id}-help` : undefined"
            />
            <button
                v-if="isPassword"
                type="button"
                tabindex="-1"
                class="absolute inset-y-0 right-0 flex items-center pr-3 text-slate-400 hover:text-slate-600 focus:outline-none focus:text-brand-600 transition-colors cursor-pointer"
                :aria-label="showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'"
                :title="showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'"
                @click.stop.prevent="showPassword = !showPassword"
            >
                <EyeSlashIcon v-if="showPassword" class="h-5 w-5" aria-hidden="true" />
                <EyeIcon v-else class="h-5 w-5" aria-hidden="true" />
            </button>
        </div>
        <span
            v-if="error || hint"
            :id="`${$attrs.id}-help`"
            class="mt-1.5 block text-xs"
            :class="error ? 'text-danger' : 'text-slate-500'"
            >{{ error || hint }}</span
        >
    </label>
</template>
