import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'

document.title = import.meta.env.VITE_APP_NAME || 'Gelatik'

// Apply the saved theme before Vue mounts so the switch is a hard visual cut,
// not a soft white-to-black flash during initial render.
document.documentElement.dataset.theme =
    localStorage.getItem('gelatik_theme') === 'dark' ? 'dark' : 'light'

createApp(App).use(createPinia()).use(router).mount('#app')
