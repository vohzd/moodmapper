// https://nuxt.com/docs/api/configuration/nuxt-config

import { resolve } from "path";

export default defineNuxtConfig({
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
  typescript: {
    tsConfig: {
    },
  },

  // allows nuxt to consume the .env files for the api
  runtimeConfig: {
    public: {
      apiBase: "",
    },
  },

});