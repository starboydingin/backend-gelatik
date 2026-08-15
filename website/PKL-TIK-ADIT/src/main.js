import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'

document.title = import.meta.env.VITE_APP_NAME || 'Gelatik'

// Apply the saved theme before Vue mounts to prevent a light-theme flash.
document.documentElement.dataset.theme =
    localStorage.getItem('gelatik_theme') === 'dark' ? 'dark' : 'light'

createApp(App).use(createPinia()).use(router).mount('#app')
