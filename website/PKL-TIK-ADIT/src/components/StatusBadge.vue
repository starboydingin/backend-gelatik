<script setup>
import { computed } from 'vue'
const props = defineProps({ status: { type: String, default: '' } })
const tone = computed(() => {
    const value = props.status.toLowerCase()
    if (/(disetujui|selesai|aktif|diterima|success)/.test(value)) return 'bg-green-100 text-success'
    if (/(ditolak|batal|gagal|error)/.test(value)) return 'bg-red-100 text-danger'
    if (/(maintenance|pemeliharaan)/.test(value)) return 'bg-violet-100 text-violet-700'
    if (/(proses|diproses)/.test(value)) return 'bg-sky-100 text-info'
    if (/(warning|menunggu|pending)/.test(value)) return 'bg-amber-100 text-amber-700'
    return 'bg-sky-100 text-info'
})
</script>
<template>
    <span class="badge" :class="tone"
        ><slot>{{ status || 'Menunggu' }}</slot></span
    >
</template>
