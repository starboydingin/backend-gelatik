<script setup>
import { computed, ref, watch } from 'vue'
const props = defineProps({ events: { type: Array, default: () => [] }, loading: Boolean })
const emit = defineEmits(['range-change'])
const cursor = ref(new Date())
const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
const title = computed(() =>
    new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' }).format(cursor.value)
)
const cells = computed(() => {
    const y = cursor.value.getFullYear(),
        m = cursor.value.getMonth(),
        first = new Date(y, m, 1),
        start = new Date(y, m, 1 - ((first.getDay() + 6) % 7))
    return Array.from({ length: 42 }, (_, i) => {
        const date = new Date(start)
        date.setDate(start.getDate() + i)
        const key = date.toISOString().slice(0, 10)
        return {
            key,
            date,
            current: date.getMonth() === m,
            today: key === new Date().toISOString().slice(0, 10),
            events: props.events.filter((e) => String(e.start).slice(0, 10) === key),
        }
    })
})
function range() {
    const y = cursor.value.getFullYear(),
        m = cursor.value.getMonth()
    emit('range-change', {
        start: new Date(y, m, 1).toISOString().slice(0, 10),
        end: new Date(y, m + 1, 0).toISOString().slice(0, 10),
    })
}
function move(n) {
    cursor.value = new Date(cursor.value.getFullYear(), cursor.value.getMonth() + n, 1)
}
watch(cursor, range, { immediate: true })
</script>
<template>
    <section class="card">
        <div class="mb-4 flex items-center justify-between">
            <div>
                <p class="text-xs font-bold uppercase tracking-widest text-brand-600">
                    Agenda layanan
                </p>
                <h2 class="mt-1 font-bold capitalize text-slate-950">{{ title }}</h2>
            </div>
            <div class="flex gap-2">
                <button class="btn-secondary min-h-9 px-3" @click="move(-1)">‹</button
                ><button class="btn-secondary min-h-9 px-3" @click="move(1)">›</button>
            </div>
        </div>
        <div
            class="grid grid-cols-7 border-b border-slate-100 pb-2 text-center text-xs font-semibold text-slate-400"
        >
            <span v-for="day in days" :key="day">{{ day }}</span>
        </div>
        <div class="relative mt-2 grid grid-cols-7 gap-1">
            <div
                v-for="cell in cells"
                :key="cell.key"
                class="min-h-12 rounded-xl p-1 text-center text-xs"
                :class="[
                    cell.current ? 'text-slate-700' : 'text-slate-300',
                    cell.events.length ? 'bg-emerald-50' : '',
                ]"
            >
                <span
                    class="grid size-6 place-items-center rounded-lg"
                    :class="cell.today ? 'bg-brand-600 text-white' : 'mx-auto'"
                    >{{ cell.date.getDate() }}</span
                ><span
                    v-if="cell.events.length"
                    class="mt-1 block truncate text-[9px] font-semibold text-emerald-700"
                    :title="cell.events[0].title"
                    >{{ cell.events[0].title }}</span
                >
            </div>
            <div
                v-if="loading"
                class="absolute inset-0 grid place-items-center rounded-xl bg-white/80"
            >
                <span
                    class="size-7 animate-spin rounded-full border-4 border-brand-100 border-t-brand-600"
                ></span>
            </div>
        </div>
    </section>
</template>
