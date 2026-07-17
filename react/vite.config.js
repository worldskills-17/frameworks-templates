import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// https://vite.dev/config/
export default defineConfig({
  base: '/', // absolute — apps deploy at domain root; './' white-pages on nested routes
  plugins: [react(), tailwindcss()],
});
