const puppeteer = require('C:/Users/micha/AppData/Roaming/npm/node_modules/puppeteer');

(async () => {
    console.log('Starting time filter test...');
    const browser = await puppeteer.launch({
        headless: true,
        executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });

    await page.goto('https://app.tovplay.org/logs/', { waitUntil: 'networkidle2', timeout: 30000 });
    await new Promise(r => setTimeout(r, 2000));

    // Find all time filter buttons
    const buttons = await page.$$eval('button', btns => btns.map(b => ({
        text: b.innerText.trim(),
        className: b.className
    })));
    console.log('\n=== Time Filter Buttons Found ===');
    buttons.filter(b => b.text.includes('Minute') || b.text.includes('Hour') || b.text.includes('Day')).forEach(b => {
        console.log(`- ${b.text}`);
    });

    // Test clicking each time filter
    const timeFilters = ['1 Minute', '5 Minutes', '30 Minutes', '1 Hour', '24 Hours', '7 Days'];
    console.log('\n=== Testing Time Filter Clicks ===');

    for (const filter of timeFilters) {
        try {
            await page.evaluate((filterText) => {
                const buttons = document.querySelectorAll('button');
                for (const btn of buttons) {
                    if (btn.innerText.includes(filterText)) {
                        btn.click();
                        return true;
                    }
                }
                return false;
            }, filter);
            await new Promise(r => setTimeout(r, 500));
            console.log(`✓ Clicked: ${filter}`);
        } catch (e) {
            console.log(`✗ Failed: ${filter} - ${e.message}`);
        }
    }

    // Check stats after clicking different filters
    console.log('\n=== Verifying Stats Update ===');
    const stats = await page.evaluate(() => {
        const elements = document.querySelectorAll('h2, .stat-value, [class*="stat"]');
        return Array.from(elements).map(el => el.innerText).filter(t => t.includes('0') || t.includes('ERROR'));
    });
    console.log('Stats values:', stats.slice(0, 8).join(', '));

    // Test Refresh Now button
    console.log('\n=== Testing Refresh Button ===');
    const refreshClicked = await page.evaluate(() => {
        const buttons = document.querySelectorAll('button');
        for (const btn of buttons) {
            if (btn.innerText.includes('Refresh')) {
                btn.click();
                return true;
            }
        }
        return false;
    });
    console.log(refreshClicked ? '✓ Refresh button clicked' : '✗ Refresh button not found');

    // Take final screenshot after all tests
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: 'F:/tovplay/.logs/dashboard_final.png', fullPage: true });
    console.log('\nFinal screenshot saved: dashboard_final.png');

    await browser.close();
    console.log('\n=== All Time Filter Tests Complete ===');
})();
