const fs = require('fs');
const path = require('path');
const os = require('os');

console.log('=== SCAN TEST ===');
console.log('Start:', new Date().toISOString());

const GAME_DIRS = [
  'E:\\Games','F:\\Games',
  'C:\\Program Files (x86)\\Steam\\steamapps\\common',
  'C:\\Program Files\\Steam\\steamapps\\common',
  'F:\\SteamLibrary\\steamapps\\common',
  'E:\\SteamLibrary\\steamapps\\common',
  'C:\\Program Files\\Epic Games','C:\\XboxGames','F:\\GOG Games',
];

async function accessAsync(p){ return new Promise(res=>fs.access(p,fs.constants.F_OK,e=>res(!e))); }
async function readdirAsync(p){ return new Promise(res=>fs.readdir(p,{withFileTypes:true},(e,r)=>res(e?[]:r))); }

async function main() {
  for (const gd of GAME_DIRS) {
    const t0 = Date.now();
    const exists = await accessAsync(gd);
    const t1 = Date.now();
    console.log(`[${t1-t0}ms] ${gd} => exists=${exists}`);
    if (!exists) continue;
    const entries = await readdirAsync(gd);
    console.log(`  -> ${entries.filter(e=>e.isDirectory()).length} dirs`);
  }
  console.log('Done:', new Date().toISOString());
}

main().catch(console.error);
