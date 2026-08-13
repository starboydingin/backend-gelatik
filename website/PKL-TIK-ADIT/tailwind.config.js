/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts}'],
  theme: {
    extend: {
      colors: {
        // Token Gelatik Mobile: teal untuk identitas, emerald untuk aksi.
        brand: { 50: '#F0FDFA', 100: '#CCFBF1', 200: '#99F6E4', 300: '#5EEAD4', 400: '#2DD4BF', 500: '#14B8A6', 600: '#0F766E', 700: '#115E59', 800: '#134E4A', 900: '#134E4A', 950: '#042F2E' },
        action: '#10B981', navy: '#1E3A8A', gold: '#F59E0B', canvas: '#F8FAFC', stroke: '#E2E8F0',
        success: '#16A34A', warning: '#F59E0B', danger: '#DC2626', info: '#0284C7',
      },
      fontFamily: { sans: ['Inter', 'ui-sans-serif', 'system-ui', 'Segoe UI', 'sans-serif'], brand: ['Montserrat', 'Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'] },
      boxShadow: { soft: '0 12px 32px -24px rgba(15, 118, 110, .28)' },
    },
  },
  plugins: [],
}
