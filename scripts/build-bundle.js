const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../app/api/script-roblox/ghostdriver');
const files = ['ui.lua', 'settings.lua', 'corridor.lua', 'farm.lua', 'vehicle.lua', 'teleport.lua', 'main.lua'];

let bundle = '-- HipHub Ghost Driver — Standalone Production Bundle (BAC-5513 Safe)\n' +
  '-- Auto Generated: Closed-Loop Dual-Lane Highway Corridor + Near-Miss Streak Maximizer\n\n' +
  '_G.hiphub_key = "KEYLESS"\n_G.hiphub_role = "free"\n_G.hiphub_url = "https://hiphub.cloud"\n' +
  'if getgenv then getgenv().hiphub_key = "KEYLESS" end\n' +
  'if getgenv then getgenv().hiphub_role = "free" end\n' +
  'if getgenv then getgenv().hiphub_url = "https://hiphub.cloud" end\n\n';

for (const file of files) {
  const filePath = path.join(dir, file);
  if (fs.existsSync(filePath)) {
    bundle += '-- ==========================================\n';
    bundle += '-- MODULE: ' + file + '\n';
    bundle += '-- ==========================================\n';
    bundle += fs.readFileSync(filePath, 'utf8') + '\n\n';
  }
}

fs.writeFileSync(path.join(dir, 'bundle.lua'), bundle, 'utf8');
console.log('Successfully generated bundle.lua! Total size:', Buffer.byteLength(bundle), 'bytes');
