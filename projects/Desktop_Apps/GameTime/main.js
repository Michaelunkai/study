const { app, BrowserWindow, screen } = require('electron');
const path = require('path');

let win;
app.whenReady().then(() => {
  const displays = screen.getAllDisplays();
  // Prefer second monitor if available, otherwise use primary
  const targetDisplay = displays.length > 1 ? displays[1] : displays[0];
  const { x, y, width, height } = targetDisplay.bounds;

  win = new BrowserWindow({
    x,
    y,
    width,
    height,
    webPreferences: { nodeIntegration: true, contextIsolation: false },
    title: 'GameTime',
    backgroundColor: '#0d0d18',
    show: false,
    frame: true,
  });

  win.loadFile(path.join(__dirname, 'index.html'));

  win.once('ready-to-show', () => {
    win.show();
    win.setFullScreen(true);
  });
});
app.on('window-all-closed', () => app.quit());
