import { resolve } from "node:path";
import process from "node:process";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

const { TAURI_DEV_HOST: devHost } = process.env;

const devServer = () => {
  const server = { port: 1420, strictPort: true };

  if (!devHost) {
    return server;
  }

  return { ...server, hmr: { host: devHost, port: 1421, protocol: "ws" }, host: devHost };
};

export default defineConfig({
  build: {
    target: ["chrome120", "safari17"],
  },
  clearScreen: false,
  envPrefix: ["VITE_", "TAURI_ENV_*"],
  input: {
    island: resolve(import.meta.dirname, "island.html"),
    settings: resolve(import.meta.dirname, "index.html"),
  },
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": resolve(import.meta.dirname, "src"),
    },
  },
  root: import.meta.dirname,
  server: devServer(),
});
