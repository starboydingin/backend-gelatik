<script setup>
import { ExclamationTriangleIcon } from '@heroicons/vue/24/outline'
defineProps({ title: { type: String, default: 'Data belum dapat dimuat' }, message: String })
defineEmits(['retry'])
</script>
<template>
    <div class="card grid min-h-56 place-items-center text-center">
        <div>
            <ExclamationTriangleIcon class="mx-auto size-10 text-warning" />
            <h3 class="mt-3 font-bold text-navy">{{ title }}</h3>
            <p class="mt-2 max-w-md text-sm text-slate-500">{{ message }}</p>
            <button class="btn-secondary mt-5" @click="$emit('retry')">Coba lagi</button>
        </div>
    </div>
</template>
