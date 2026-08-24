import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './base.css'
import './design-system.css'

document.title = import.meta.env.VITE_APP_NAME || 'Gelatik'

createApp(App).use(createPinia()).use(router).mount('#app')
