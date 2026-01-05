const playwright = require('playwright');

(async () => {
  const browser = await playwright.chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('Navigating to dashboard...');
  await page.goto('https://app.tovplay.org/logs/', { waitUntil: 'networkidle' });

  // Wait for the page to load
  await page.waitForTimeout(5000);

  // Take screenshot of the full page
  console.log('Taking screenshot...');
  await page.screenshot({ path: 'F:/tovplay/dashboard_screenshot.png', fullPage: true });

  // Check connection status
  const statusElement = await page.locator('#statusBadge').textContent().catch(() => 'Not found');
  console.log('Status:', statusElement);

  // Check if there are any log entries
  const logCount = await page.locator('.log-entry').count();
  console.log('Number of log entries:', logCount);

  // Get the first few log entries
  if (logCount > 0) {
    for (let i = 0; i < Math.min(5, logCount); i++) {
      const logText = await page.locator('.log-entry').nth(i).textContent();
      console.log(`Log ${i + 1}:`, logText.substring(0, 200));
    }
  } else {
    console.log('No logs found on dashboard');

    // Check for any error messages
    const bodyText = await page.locator('body').textContent();
    if (bodyText.includes('No logs') || bodyText.includes('Loading')) {
      console.log('Dashboard shows: No logs or still loading');
    }
  }

  // Check time filter buttons
  const timeButtons = await page.locator('.time-btn').count();
  console.log('Number of time filter buttons:', timeButtons);

  // Check team members card
  const teamMembersText = await page.locator('#teamMembersCard').textContent().catch(() => 'Not found');
  console.log('Team members card:', teamMembersText);

  // Wait for user to see
  console.log('\nKeeping browser open for inspection...');
  await page.waitForTimeout(30000);

  await browser.close();
})();
