/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts}'],
  theme: {
    extend: {
      colors: {
        // Semantic aliases. The real light/dark switch is handled by CSS
        // variables so it snaps immediately instead of fading between colors.
        brand: { 50: '#CCFBF1', 100: '#CCFBF1', 200: '#99F6E4', 300: '#5EEAD4', 400: '#2DD4BF', 500: '#0F766E', 600: '#0F766E', 700: '#0F766E', 800: '#0F766E', 900: '#0F766E', 950: '#0F766E' },
        action: '#10B981', navy: '#000000', gold: '#F59E0B', canvas: '#FFFFFF', stroke: '#000000',
        success: '#16A34A', warning: '#F59E0B', danger: '#DC2626', info: '#0284C7',
      },
      fontFamily: { sans: ['Inter', 'ui-sans-serif', 'system-ui', 'Segoe UI', 'sans-serif'], brand: ['Montserrat', 'Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'] },
      boxShadow: { brutal: '5px 5px 0 #000000', 'brutal-sm': '3px 3px 0 #000000' },
    },
  },
  plugins: [],
}
