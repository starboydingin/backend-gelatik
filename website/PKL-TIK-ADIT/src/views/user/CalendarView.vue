<script setup>
import { ref } from 'vue'
import { api, errorMessage, payload, rows } from '../../lib/api'
import AlertMessage from '../../components/AlertMessage.vue'
import PageHeader from '../../components/PageHeader.vue'
import ScheduleCalendar from '../../components/ScheduleCalendar.vue'
const events = ref([]),
    loading = ref(false),
    error = ref('')
async function load(range) {
    loading.value = true
    error.value = ''
    try {
        events.value = rows(payload(await api.get('/dashboard/calendar', { params: range })))
    } catch (requestError) {
        error.value = errorMessage(requestError)
    } finally {
        loading.value = false
    }
}
</script>
<template>
    <div class="page-stack">
        <PageHeader
            eyebrow="Agenda layanan"
            title="Kalender kegiatan"
            description="Lihat jadwal konsultasi, peminjaman, dan aktivitas layanan Anda."
        /><AlertMessage :message="error" /><ScheduleCalendar
            :events="events"
            :loading="loading"
            @range-change="load"
        />
    </div>
</template>
