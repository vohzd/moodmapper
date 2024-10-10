// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  ssr: false, // Disable Server Side Rendering for static site generation
  target: "static", // Specify that we're building a static site
  compatibilityDate: "2024-04-03",
  devtools: {
    enabled: true,
    timeline: {
      enabled: true,
    },
  },
  devServer: {
    https: {
      key: "./certs/memorymark-dev.key",
      cert: "./certs/memorymark-dev.crt",
    },
  },
  imports: {
    autoImport: true,
  },
  app: {
    baseURL: "/moodmapper/",
  },
  runtimeConfig: {
    public: {
      apiBase: "",
    },
  },
});
