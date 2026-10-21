const fs = require('fs');
const luaparse = require('luaparse');

const scriptDir = 'f:/hiphub/car/app/api/script-roblox/ghostdriver';
const files = ['ui.lua', 'settings.lua', 'corridor.lua', 'farm.lua', 'vehicle.lua', 'teleport.lua', 'main.lua'];

let luaScript = '_G.hiphub_key = "KEYLESS"\n_G.hiphub_role = "free"\n_G.hiphub_url = "https://hiphub.cloud"\n';
for (const f of files) {
  luaScript += '\n' + fs.readFileSync(scriptDir + '/' + f, 'utf8');
}

try {
  luaparse.parse(luaScript);
  console.log('Concatenated source: 100% VALID!');
} catch (e) {
  console.log('Concatenated source error:', e.message, 'line:', e.line);
}
