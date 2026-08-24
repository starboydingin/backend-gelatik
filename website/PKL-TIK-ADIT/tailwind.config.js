/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts}'],
  theme: {
    extend: {
      colors: {
        brand: { 50: '#EFF6FF', 100: '#DBEAFE', 200: '#BFDBFE', 300: '#93C5FD', 400: '#60A5FA', 500: '#3B82F6', 600: '#2563EB', 700: '#1E3A8A', 800: '#172E6E', 900: '#102451', 950: '#0A1633' },
        action: '#1E3A8A', navy: '#1E3A8A', gold: '#F59E0B', canvas: '#F8FAFC', stroke: '#E2E8F0',
        success: '#16A34A', warning: '#F59E0B', danger: '#DC2626', info: '#0284C7',
      },
      fontFamily: { sans: ['Urbanist', 'ui-sans-serif', 'system-ui', 'Segoe UI', 'sans-serif'], brand: ['Urbanist', 'ui-sans-serif', 'system-ui', 'sans-serif'] },
      boxShadow: { soft: '0 1px 2px rgb(15 23 42 / 0.06), 0 8px 24px rgb(15 23 42 / 0.06)' },
      borderRadius: { '2xl': '1rem' },
    },
  },
  plugins: [],
}
