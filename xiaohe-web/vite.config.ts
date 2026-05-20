import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5180,
    open: true,
    proxy: {
      "/api": {
        target: "http://localhost:8002",
        changeOrigin: true,
        // ws: forward /api/consult/voice/ws to the backend
        ws: true,
      },
    },
  },
});
