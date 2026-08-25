<template>
    <div class="min-h-screen bg-canvas md:flex">
        <slot name="sidebar" />
        <div class="min-w-0 flex-1">
            <slot name="header" />
            <slot />
        </div>
        <slot name="mobile-navigation" />
    </div>
</template>
