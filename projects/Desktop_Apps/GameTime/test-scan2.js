// Simulate exactly what main.js does
const fs = require('fs');
const path = require('path');
const os = require('os');

function splitName(raw) {
  let s = raw.replace(/[-_]/g, ' ');
  s = s.replace(/([a-z])([A-Z])/g, '$1 $2');
  s = s.replace(/([a-zA-Z])(\d)/g, '$1 $2');
  s = s.replace(/(\d)([a-zA-Z])/g, '$1 $2');
  return s.replace(/\s+/g, ' ').trim();
}
function norm(s) {
  return splitName(s).toLowerCase().replace(/[^a-z0-9 ]/g,' ').replace(/\s+/g,' ').trim();
}

const SKIP = ['redistributables','steamworks','__common','steam controller configs','directx','vcredist','_commonredist'];

const t0 = Date.now();
const games = [], seen = new Set();
const dirs = ['E:\\Games','F:\\Games','C:\\Program Files (x86)\\Steam\\steamapps\\common'];

for (const gd of dirs) {
  let entries;
  try { entries = fs.readdirSync(gd, { withFileTypes: true }); }
  catch(e) { console.log('SKIP (no exist):', gd); continue; }
  console.log(`FOUND: ${gd} (${entries.filter(e=>e.isDirectory()).length} dirs)`);
  for (const e of entries) {
    if (!e.isDirectory()) continue;
    const raw = e.name;
    if (seen.has(raw.toLowerCase())) continue;
    if (SKIP.some(s => raw.toLowerCase().includes(s))) continue;
    seen.add(raw.toLowerCase());
    games.push({ name: raw, displayName: splitName(raw) });
  }
}

const t1 = Date.now();
console.log(`\nTotal games: ${games.length} in ${t1-t0}ms`);
games.forEach(g => console.log(' -', g.displayName));
