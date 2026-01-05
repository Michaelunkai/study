const puppeteer = require('C:/Users/micha/AppData/Roaming/npm/node_modules/puppeteer');

(async () => {
    console.log('Starting Puppeteer...');
    const browser = await puppeteer.launch({
        headless: true,
        executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });

    console.log('Navigating to dashboard...');
    await page.goto('https://app.tovplay.org/logs/', { waitUntil: 'networkidle2', timeout: 30000 });

    // Wait for page to fully load
    await new Promise(r => setTimeout(r, 3000));

    console.log('Page title:', await page.title());

    // Check for errors in console
    const consoleErrors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') {
            consoleErrors.push(msg.text());
        }
    });

    // Check page content
    const pageContent = await page.content();

    // Verify key elements
    const hasTitle = pageContent.includes('TovPlay Error Dashboard') || pageContent.includes('Error Dashboard');
    const hasTimeFilters = pageContent.includes('1 Minute') || pageContent.includes('5 Minutes');
    const hasSeverityBadges = pageContent.includes('severity-badge') || pageContent.includes('CRITICAL') || pageContent.includes('HIGH');
    const hasTeamAttribution = pageContent.includes('team-badge') || pageContent.includes('team-member');

    console.log('\n=== Dashboard Verification ===');
    console.log('Title present:', hasTitle);
    console.log('Time filters present:', hasTimeFilters);
    console.log('Severity badges present:', hasSeverityBadges);
    console.log('Team attribution present:', hasTeamAttribution);

    // Take screenshot
    const screenshotPath = 'F:/tovplay/.logs/dashboard_screenshot.png';
    await page.screenshot({ path: screenshotPath, fullPage: true });
    console.log('\nScreenshot saved to:', screenshotPath);

    // Test clicking time filter buttons
    console.log('\n=== Testing Time Filters ===');
    const timeFilterButtons = await page.$$('button, .time-filter, [onclick*="setTimeRange"]');
    console.log('Found', timeFilterButtons.length, 'potential filter buttons');

    // Check if error container exists
    const errorContainer = await page.$('.error-log, .error-container, #errors, .errors-list');
    console.log('Error display container:', errorContainer ? 'Found' : 'Not found');

    // Get stats display
    const statsText = await page.evaluate(() => {
        const statsEl = document.querySelector('.stats, .statistics, #stats');
        return statsEl ? statsEl.innerText : 'Stats element not found';
    });
    console.log('Stats display:', statsText.substring(0, 200));

    if (consoleErrors.length > 0) {
        console.log('\n=== Console Errors ===');
        consoleErrors.forEach(err => console.log('ERROR:', err));
    } else {
        console.log('\nNo JavaScript console errors detected!');
    }

    await browser.close();
    console.log('\n=== Test Complete ===');
})();
