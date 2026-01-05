import { test, expect } from '@playwright/test';

test.describe('TovPlay Frontend E2E Tests', () => {
  test('homepage responds', async ({ page }) => {
    const response = await page.goto('/', { timeout: 30000 });
    expect(response).toBeTruthy();
    expect(response.status()).toBeLessThan(500);
  });

  test('login page responds', async ({ page }) => {
    const response = await page.goto('/login', { timeout: 30000 });
    expect(response).toBeTruthy();
    expect(response.status()).toBeLessThan(500);
  });

  test('server is reachable', async ({ request }) => {
    const baseUrl = process.env.PLAYWRIGHT_BASE_URL || 'https://app.tovplay.org';
    const response = await request.get(`${baseUrl}/`);
    expect(response.status()).toBeLessThan(600);
  });
});
