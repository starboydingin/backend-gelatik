import vueParser from 'vue-eslint-parser'

export default [
  { ignores: ['dist/', 'node_modules/', 'public/'] },
  {
    files: ['src/**/*.{js,vue}'],
    languageOptions: {
      parser: vueParser,
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: { localStorage: 'readonly', location: 'readonly', confirm: 'readonly', prompt: 'readonly', crypto: 'readonly', setTimeout: 'readonly' },
    },
  },
]
