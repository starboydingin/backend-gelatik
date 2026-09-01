<script setup>
import GelatikLogo from './GelatikLogo.vue'
import {
    DocumentCheckIcon,
    LockClosedIcon,
    ShieldCheckIcon,
    UserCircleIcon,
} from '@heroicons/vue/24/outline'

defineProps({ title: String, subtitle: String, wide: Boolean })

const guideImage = '/assets/images/muli-meghanai-guides.png'
const trustItems = [
    {
        title: 'Aman & terpercaya',
        text: 'Akses akun dilindungi untuk kebutuhan layanan pemerintahan.',
        icon: LockClosedIcon,
    },
    {
        title: 'Layanan terintegrasi',
        text: 'Ajukan dan pantau layanan TIK melalui satu portal.',
        icon: DocumentCheckIcon,
    },
    {
        title: 'Cepat & efisien',
        text: 'Status proses dan tanggapan tersedia pada akun Anda.',
        icon: ShieldCheckIcon,
    },
]
</script>

<template>
    <div class="auth-page flex min-h-screen flex-col bg-white text-[var(--color-text-primary)]">
        <main
            class="grid min-h-0 flex-1 lg:grid-cols-[minmax(0,1.08fr)_minmax(29rem,.92fr)]"
        >
            <section
                class="auth-information relative hidden min-h-[640px] overflow-hidden border-r border-[var(--color-border)] px-8 py-7 lg:flex lg:flex-col xl:px-12"
            >
                <div class="relative z-20 flex items-center justify-between gap-5">
                    <RouterLink to="/" aria-label="Kembali ke beranda Gelatik">
                        <GelatikLogo />
                    </RouterLink>
                    <p
                        class="max-w-[15rem] text-right text-xs font-semibold leading-5 text-[var(--color-text-secondary)]"
                    >
                        Portal layanan TIK Pemerintah Provinsi Lampung
                    </p>
                </div>

                <div class="relative z-10 mt-8 max-w-[22rem]">
                    <p class="eyebrow">Gerbang layanan digital</p>
                    <h2 class="mt-2 font-brand text-4xl font-bold leading-[1.05] text-blue-950">
                        Layanan TIK dalam satu akses.
                    </h2>
                    <p class="mt-4 text-sm leading-6 text-[var(--color-text-secondary)]">
                        Gunakan satu akun untuk mengajukan kebutuhan, memantau proses, dan menerima
                        tanggapan layanan secara transparan.
                    </p>
                </div>

                <div v-if="!$slots.guide" class="relative z-20 mt-7 grid max-w-[20rem] gap-3">
                    <article
                        v-for="item in trustItems"
                        :key="item.title"
                        class="flex items-start gap-3 rounded-xl border border-white/70 bg-white/90 p-3 shadow-sm backdrop-blur"
                    >
                        <span
                            class="grid size-10 shrink-0 place-items-center rounded-full bg-teal-50 text-teal-700"
                        >
                            <component :is="item.icon" class="size-5" />
                        </span>
                        <div>
                            <h3 class="text-sm font-bold text-blue-950">{{ item.title }}</h3>
                            <p class="mt-0.5 text-xs leading-5 text-slate-600">{{ item.text }}</p>
                        </div>
                    </article>
                </div>

                <img
                    :src="guideImage"
                    alt="Muli dan Meghanai Lampung menyambut pengguna layanan Gelatik"
                    class="pointer-events-none absolute bottom-0 right-2 z-10 h-[68%] max-h-[650px] w-[58%] object-contain object-bottom xl:right-8"
                />

                <section
                    v-if="$slots.guide"
                    class="relative z-20 mt-auto max-w-xl rounded-xl border border-[var(--color-border)] bg-white/95 p-4 shadow-[var(--shadow-surface)] backdrop-blur"
                    aria-labelledby="account-guide-title"
                >
                    <div class="flex items-center gap-2.5">
                        <span class="grid size-9 place-items-center rounded-lg bg-teal-50 text-teal-700">
                            <DocumentCheckIcon class="size-5" />
                        </span>
                        <h3 id="account-guide-title" class="font-bold text-teal-800">
                            Cara membuat akun
                        </h3>
                    </div>
                    <div class="mt-3 text-xs leading-5 text-[var(--color-text-secondary)]">
                        <slot name="guide" />
                    </div>
                </section>
            </section>

            <section
                class="flex min-h-0 flex-col bg-[var(--color-bg-primary)] px-4 py-5 sm:px-7 sm:py-7 lg:px-8 xl:px-12"
            >
                <div class="mx-auto flex w-full items-center justify-between gap-4 lg:justify-end">
                    <RouterLink
                        to="/"
                        class="lg:hidden"
                        aria-label="Kembali ke beranda Gelatik"
                    >
                        <GelatikLogo compact />
                    </RouterLink>
                    <div
                        class="flex max-w-[18rem] items-center gap-2 text-right text-xs font-semibold leading-4 text-[var(--color-text-secondary)]"
                    >
                        <ShieldCheckIcon class="size-6 shrink-0 text-[var(--color-brand-primary)]" />
                        <span>Portal resmi layanan TIK Pemerintah Provinsi Lampung</span>
                    </div>
                </div>

                <div class="my-auto flex w-full justify-center py-7">
                    <section
                        class="w-full rounded-2xl border border-[var(--color-border)] bg-white p-5 shadow-[var(--shadow-overlay)] sm:p-6"
                        :class="wide ? 'max-w-[660px]' : 'max-w-[520px]'"
                    >
                        <div class="text-center">
                            <span
                                class="mx-auto -mt-12 grid size-16 place-items-center rounded-full border border-[var(--color-border)] bg-white text-teal-700 shadow-md"
                            >
                                <UserCircleIcon class="size-9" />
                            </span>
                            <h1
                                v-if="title"
                                class="mt-3 font-brand text-2xl font-bold tracking-tight text-blue-950 sm:text-[1.75rem]"
                            >
                                {{ title }}
                            </h1>
                            <p
                                v-if="subtitle"
                                class="mx-auto mt-1.5 max-w-lg text-sm leading-5 text-[var(--color-text-secondary)]"
                            >
                                {{ subtitle }}
                            </p>
                        </div>

                        <details
                            v-if="$slots.guide"
                            class="mt-4 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-3 text-sm lg:hidden"
                        >
                            <summary
                                class="cursor-pointer font-bold text-[var(--color-brand-primary)]"
                            >
                                Cara membuat akun
                            </summary>
                            <div
                                class="mt-3 text-xs leading-5 text-[var(--color-text-secondary)]"
                            >
                                <slot name="guide" />
                            </div>
                        </details>

                        <div class="mt-5"><slot /></div>
                    </section>
                </div>
            </section>
        </main>

    </div>
</template>

<style scoped>
.auth-information {
    background:
        radial-gradient(circle at 84% 18%, rgb(13 148 136 / 0.12), transparent 28%),
        linear-gradient(145deg, #ffffff 0%, #f8fbff 58%, #e8f3f5 100%);
}

.auth-information::before {
    position: absolute;
    inset: 0;
    background-image: radial-gradient(rgb(30 64 175 / 0.1) 1px, transparent 1px);
    background-size: 22px 22px;
    content: '';
    mask-image: linear-gradient(to bottom right, black, transparent 68%);
    pointer-events: none;
}
</style>
