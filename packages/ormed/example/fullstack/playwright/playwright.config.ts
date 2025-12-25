import { defineConfig } from '@playwright/test';

const baseURL = process.env.BASE_URL ?? 'http://127.0.0.1:8080';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  timeout: 30_000,
  use: {
    baseURL,
    headless: true,
    viewport: { width: 1280, height: 720 },
  },
  reporter: [['list'], ['html', { open: 'never' }]],
});
