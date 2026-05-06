/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        graphite: {
          950: '#0a0a0a',
          900: '#111111',
          800: '#1a1a1a',
          750: '#1e1e1e',
          700: '#242424',
          600: '#2e2e2e',
          500: '#3a3a3a',
          400: '#4a4a4a',
          300: '#666666',
          200: '#888888',
          100: '#aaaaaa',
        },
        ivory: '#e8e3d8',
        'ivory-dim': '#b8b4ac',
        accent: {
          red: '#c0392b',
          'red-bright': '#e74c3c',
          blue: '#2980b9',
          'blue-bright': '#3498db',
          green: '#27ae60',
        },
      },
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', '-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'sans-serif'],
        mono: ['ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'Consolas', 'monospace'],
      },
      fontSize: {
        '2xs': ['0.625rem', { lineHeight: '0.875rem' }],
      },
    },
  },
  plugins: [],
}
