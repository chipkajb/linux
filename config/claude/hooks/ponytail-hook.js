#!/usr/bin/env node
// ponytail — Claude Code hook (SessionStart + UserPromptSubmit).
// Port of pi's extensions/caveman-ponytail.ts: inject the ponytail ruleset into
// context at session start, toggle it with /ponytail.
//
// SessionStart: emit rules when ~/.claude/.ponytail-active says "on".
// UserPromptSubmit: recognise /ponytail on|off|status and flip the flag.

const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagPath = path.join(claudeDir, '.ponytail-active');
const rulesPath = path.join(__dirname, 'ponytail-rules.md');

function isOn() {
  try {
    return fs.readFileSync(flagPath, 'utf8').trim() === 'on';
  } catch {
    return false;
  }
}

function setFlag(on) {
  if (on) fs.writeFileSync(flagPath, 'on\n');
  else { try { fs.unlinkSync(flagPath); } catch {} }
}

function readPrompt() {
  return new Promise((resolve) => {
    let input = '';
    process.stdin.on('data', (c) => (input += c));
    process.stdin.on('end', () => {
      try { resolve(JSON.parse(input).prompt || ''); } catch { resolve(''); }
    });
  });
}

(async () => {
  const event = process.argv[2] || '';

  if (event === 'SessionStart') {
    if (!isOn()) return;
    let rules = '';
    try { rules = fs.readFileSync(rulesPath, 'utf8'); } catch { return; }
    process.stdout.write('PONYTAIL MODE ACTIVE\n\n' + rules + '\n');
    return;
  }

  if (event === 'UserPromptSubmit') {
    const prompt = (await readPrompt()).trim().toLowerCase();
    // Only a bare /ponytail (or /ponytail <arg>) counts as a toggle command.
    const m = prompt.match(/^\/ponytail\b\s*(\S*)/);
    if (!m) return;
    const arg = m[1] || '';
    if (['off', 'stop', 'disable', 'normal'].includes(arg)) setFlag(false);
    else setFlag(true);
    process.stdout.write('PONYTAIL MODE ' + (isOn() ? 'ON' : 'OFF') + '\n');
  }
})();
