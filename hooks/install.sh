#!/bin/bash
# parrot — one-command hook installer for Claude Code
# Installs: SessionStart hook (auto-load rules) + UserPromptSubmit hook (mode tracking)
# Usage: bash hooks/install.sh
#   or:  bash <(curl -s https://raw.githubusercontent.com/animeshpatni94/parrot/main/hooks/install.sh)
#   or:  bash hooks/install.sh --force   (re-install over existing hooks)
set -e

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
  esac
done

case "$OSTYPE" in
  msys*|cygwin*|mingw*)
    echo "WARNING: Running on Windows ($OSTYPE)."
    echo "         Use hooks/install.ps1 instead, or install via:"
    echo "         claude plugin install parrot@parrot"
    echo ""
    ;;
esac

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: 'node' is required to install the parrot hooks."
  echo "       Install Node.js from https://nodejs.org and re-run."
  exit 1
fi

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
REPO_URL="https://raw.githubusercontent.com/animeshpatni94/parrot/main/hooks"

HOOK_FILES=("package.json" "parrot-config.js" "parrot-activate.js" "parrot-mode-tracker.js")

# Resolve source — works from repo clone or curl pipe
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
fi

# Also copy SKILL.md so the hook can find it
SKILL_SRC=""
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../skills/parrot/SKILL.md" ]; then
  SKILL_SRC="$(cd "$SCRIPT_DIR/.." && pwd)/skills/parrot/SKILL.md"
fi

echo "=== parrot hook installer ==="
echo ""

# Create hooks dir
mkdir -p "$HOOKS_DIR"

# Copy hook files
for hook in "${HOOK_FILES[@]}"; do
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$hook" ]; then
    cp "$SCRIPT_DIR/$hook" "$HOOKS_DIR/$hook"
    echo "  Copied $hook (local)"
  else
    curl -fsSL "$REPO_URL/$hook" -o "$HOOKS_DIR/$hook"
    echo "  Downloaded $hook"
  fi
done

# Copy SKILL.md
SKILL_DEST="$CLAUDE_DIR/skills/parrot"
mkdir -p "$SKILL_DEST"
if [ -n "$SKILL_SRC" ]; then
  cp "$SKILL_SRC" "$SKILL_DEST/SKILL.md"
  echo "  Copied SKILL.md (local)"
else
  curl -fsSL "https://raw.githubusercontent.com/animeshpatni94/parrot/main/skills/parrot/SKILL.md" \
    -o "$SKILL_DEST/SKILL.md"
  echo "  Downloaded SKILL.md"
fi

# Merge hooks into settings.json
echo ""
echo "Registering hooks in $SETTINGS ..."

node -e "
const fs = require('fs');
const settingsPath = '$SETTINGS';

let settings = {};
if (fs.existsSync(settingsPath)) {
  settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
}

if (!settings.hooks) settings.hooks = {};

function addHook(event, command, statusMessage) {
  if (!Array.isArray(settings.hooks[event])) {
    settings.hooks[event] = [];
  }
  const exists = settings.hooks[event].some(e =>
    e.hooks && e.hooks.some(h => h.command && h.command.includes('parrot'))
  );
  if (!exists) {
    settings.hooks[event].push({
      hooks: [{ type: 'command', command, timeout: 5, statusMessage }]
    });
  }
}

const hooksDir = '$HOOKS_DIR'.replace(/\\\\/g, '/');
addHook(
  'SessionStart',
  'node \"' + hooksDir + '/parrot-activate.js\"',
  'Loading parrot mode...'
);
addHook(
  'UserPromptSubmit',
  'node \"' + hooksDir + '/parrot-mode-tracker.js\"',
  'Tracking parrot mode...'
);

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
"

echo ""
echo "Done. Parrot is now active for every Claude Code session."
echo "  /parrot lite  — kill restated questions + recap paragraphs"
echo "  /parrot full  — kill all self-repetition (default)"
echo "  /parrot off   — disable"
