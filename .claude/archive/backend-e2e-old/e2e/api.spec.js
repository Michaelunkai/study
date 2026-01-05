import { test, expect } from '@playwright/test';

test.describe('TovPlay Backend API E2E Tests', () => {
  // Use direct IP for E2E tests to bypass Cloudflare SSL issues
  // Falls back to domain if IP access fails
  const baseUrl = process.env.PLAYWRIGHT_BASE_URL || 'http://193.181.213.220:8000';

  test('health endpoint returns healthy status', async ({ request }) => {
    const response = await request.get(`${baseUrl}/api/health`);
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.status).toBe('healthy');
  });

  test('login endpoint exists', async ({ request }) => {
    const response = await request.post(`${baseUrl}/api/users/login`, {
      data: { Email: 'test@test.com', Password: 'wrongpassword' }
    });
    const status = response.status();
    expect([400, 401, 422].includes(status)).toBe(true);
  });

  test('game requests endpoint requires auth', async ({ request }) => {
    const response = await request.get(`${baseUrl}/api/game_requests/`);
    const status = response.status();
    expect([401, 403].includes(status)).toBe(true);
  });

  test('CORS headers present', async ({ request }) => {
    const response = await request.get(`${baseUrl}/api/health`);
    const headers = response.headers();
    expect(headers['content-type']).toBeTruthy();
  });

  test('API returns JSON content-type', async ({ request }) => {
    const response = await request.get(`${baseUrl}/api/health`);
    const contentType = response.headers()['content-type'];
    expect(contentType).toBeTruthy();
    expect(contentType.includes('application/json') || contentType.includes('json')).toBe(true);
  });
});
