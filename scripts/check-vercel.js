const fs = require('fs');
const code = fs.readFileSync('temp_vercel.lua', 'utf8');
const lines = code.split('\n');
console.log('Total lines:', lines.length);
console.log('Lines 1 to 40:\n' + lines.slice(0, 40).join('\n'));
