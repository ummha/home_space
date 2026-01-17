import tailwindcss from '@tailwindcss/vite'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  
  modules: [
    '@pinia/nuxt',
    '@nuxtjs/color-mode',
    '@nuxt/icon',
    '@nuxt/image',
  ],
  
  css: ['~/assets/css/main.css'],
  
  colorMode: {
    classSuffix: '',
    preference: 'light',
    fallback: 'light',
  },
  
  vite: {
    plugins: [tailwindcss()],
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
        }
      }
    }
  },
  
  image: {
    domains: ['picsum.photos', 'i.pravatar.cc'],
  },
})
