#!/usr/bin/env node

// statusline.js
// Status line for Claude Code, styled after the robbyrussell Oh My Zsh theme.
// Reads JSON from stdin and writes a single status line to stdout.

const chunks = [];
process.stdin.on('data', (chunk) => chunks.push(chunk));
process.stdin.on('end', () => {
  let input = {};
  try {
    input = JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch (_) {}

  // ANSI color helpers (these will render dimmed in the Claude status bar)
  const reset  = '\x1b[0m';
  const cyan   = '\x1b[36m';
  const red    = '\x1b[31m';
  const yellow = '\x1b[33m';
  const blue   = '\x1b[34m';
  const bold   = '\x1b[1m';

  // Current directory — prefer the Claude-supplied cwd, fall back to process.cwd()
  const cwd = input.cwd || input.workspace?.current_dir || process.cwd();
  const home = process.env.HOME || '';
  const displayDir = cwd.startsWith(home)
    ? '~' + cwd.slice(home.length)
    : cwd;
  // Show only the last two path segments to keep things compact
  const dirParts = displayDir.replace(/\/$/, '').split('/');
  const shortDir = dirParts.length > 2
    ? '…/' + dirParts.slice(-2).join('/')
    : displayDir;

  // Git branch via worktree info or a quick git command
  let branch = '';
  if (input.worktree?.branch) {
    branch = input.worktree.branch;
  } else {
    try {
      const { execSync } = require('child_process');
      branch = execSync(
        'git -C ' + JSON.stringify(cwd) + ' symbolic-ref --short HEAD 2>/dev/null',
        { encoding: 'utf8', timeout: 1000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } }
      ).trim();
    } catch (_) {}
  }

  // Model display name
  const model = input.model?.display_name || '';

  // Context usage
  const used = input.context_window?.used_percentage;
  const usedStr = used != null ? Math.round(used) + '% ctx' : '';

  // Vim mode
  const vimMode = input.vim?.mode || '';

  // PR number for current branch
  let prLabel = '';
  if (branch) {
    try {
      const { execSync } = require('child_process');
      const num = execSync(
        'gh pr view --json number -q .number 2>/dev/null',
        { encoding: 'utf8', timeout: 3000, cwd, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } }
      ).trim();
      if (num) prLabel = 'PR #' + num;
    } catch (_) {}
  }

  // Build the line
  // Format: <dir>  git:(<branch>)  <model>  <ctx%>  [VIM MODE]  <pr url>
  const parts = [];

  // Arrow (green = success, red = could signal issues — we just use green always here)
  parts.push(cyan + bold + shortDir + reset);

  if (branch) {
    parts.push(blue + bold + 'git:(' + reset + red + branch + reset + blue + bold + ')' + reset);
  }

  if (model) {
    parts.push(yellow + model + reset);
  }

  if (usedStr) {
    const pct = Math.round(used);
    // Turn red when context is getting tight
    const ctxColor = pct > 75 ? red : (pct > 50 ? yellow : cyan);
    parts.push(ctxColor + usedStr + reset);
  }

  if (vimMode) {
    parts.push(bold + '[' + vimMode + ']' + reset);
  }

  if (prLabel) {
    parts.push(blue + prLabel + reset);
  }

  process.stdout.write(parts.join('  ') + '\n');
});
