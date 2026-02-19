// Simulate exactly what index.html does in the renderer
const fs   = require('fs');
const path = require('path');
const os   = require('os');

function splitName(r){
  let s=r.replace(/[-_]/g,' ');
  s=s.replace(/([a-z])([A-Z])/g,'$1 $2');
  s=s.replace(/([a-zA-Z])(\d)/g,'$1 $2');
  s=s.replace(/(\d)([a-zA-Z])/g,'$1 $2');
  return s.replace(/\s+/g,' ').trim();
}
function norm(s){
  return splitName(s).toLowerCase().replace(/[^a-z0-9 ]/g,' ').replace(/\s+/g,' ').trim();
}

const SKIP = new Set(['redistributables','steamworks','directx','vcredist','_commonredist']);
const GAME_DIRS = ['E:\\Games','F:\\Games','C:\\Program Files (x86)\\Steam\\steamapps\\common'];

const KNOWN_SAVES = [
  { game:'witcher 3',    p: path.join(os.homedir(),'Documents','The Witcher 3','gamesaves') },
  { game:'ninja gaiden', p: path.join(os.homedir(),'AppData','Local','NINJAGAIDEN2BLACK') },
  { game:'indika',       p: path.join(os.homedir(),'AppData','Local','Indika') },
  { game:'tailsofiron',  p: path.join(os.homedir(),'AppData','Local','ThankYouVeryCool') },
];

function getSaveDate(raw){
  const n=norm(raw);
  for(const e of KNOWN_SAVES){
    if(n.includes(norm(e.game))||norm(e.game).includes(n)){
      try{
        if(fs.existsSync(e.p)){
          const files=fs.readdirSync(e.p);
          const ext=['.sav','.save','.sl2','.ess'];
          const times=files
            .filter(f=>ext.includes(path.extname(f).toLowerCase()))
            .map(f=>{try{return fs.statSync(path.join(e.p,f)).mtime.getTime();}catch(er){return 0;}})
            .filter(t=>t>0).sort((a,b)=>a-b);
          if(times.length)return new Date(times[times.length-1]);
        }
      }catch(er){}
    }
  }
  return null;
}

try {
  const games=[], seen=new Set();
  for(const gd of GAME_DIRS){
    let entries;
    try{entries=fs.readdirSync(gd,{withFileTypes:true});}catch(e){console.log('SKIP:',gd);continue;}
    console.log('SCAN:', gd, entries.filter(e=>e.isDirectory()).length, 'dirs');
    for(const e of entries){
      if(!e.isDirectory())continue;
      const raw=e.name, lo=raw.toLowerCase();
      if(seen.has(lo))continue;
      if([...SKIP].some(s=>lo.includes(s)))continue;
      seen.add(lo);
      const saveDate=getSaveDate(raw);
      games.push({ name:raw, display:splitName(raw), saveDate:saveDate?saveDate.toISOString():null });
    }
  }
  console.log('Total games:', games.length);
  games.slice(0,5).forEach(g=>console.log(' -', g.display));
  console.log('SUCCESS - no errors');
} catch(e) {
  console.error('ERROR:', e.message);
  console.error(e.stack);
}
