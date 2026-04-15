# parrot — hook installer for Claude Code on Windows
# Usage: powershell -ExecutionPolicy Bypass -File hooks/install.ps1
# Or:    claude plugin install parrot@parrot

param([switch]$Force)

$ErrorActionPreference = "Stop"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: 'node' is required. Install from https://nodejs.org"
    exit 1
}

$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { "$env:USERPROFILE\.claude" }
$HooksDir = "$ClaudeDir\hooks"
$Settings = "$ClaudeDir\settings.json"
$RepoUrl = "https://raw.githubusercontent.com/animeshpatni94/parrot/main/hooks"

$HookFiles = @("package.json", "parrot-config.js", "parrot-activate.js", "parrot-mode-tracker.js")

$ScriptDir = $PSScriptRoot

Write-Host "=== parrot hook installer ===" -ForegroundColor Cyan
Write-Host ""

# Create hooks dir
New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null

# Copy hook files
foreach ($hook in $HookFiles) {
    $localPath = Join-Path $ScriptDir $hook
    if (Test-Path $localPath) {
        Copy-Item $localPath "$HooksDir\$hook" -Force
        Write-Host "  Copied $hook (local)"
    } else {
        Invoke-WebRequest -Uri "$RepoUrl/$hook" -OutFile "$HooksDir\$hook"
        Write-Host "  Downloaded $hook"
    }
}

# Copy SKILL.md
$SkillDest = "$ClaudeDir\skills\parrot"
New-Item -ItemType Directory -Force -Path $SkillDest | Out-Null
$SkillSrc = Join-Path (Split-Path $ScriptDir) "skills\parrot\SKILL.md"
if (Test-Path $SkillSrc) {
    Copy-Item $SkillSrc "$SkillDest\SKILL.md" -Force
    Write-Host "  Copied SKILL.md (local)"
} else {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/animeshpatni94/parrot/main/skills/parrot/SKILL.md" `
        -OutFile "$SkillDest\SKILL.md"
    Write-Host "  Downloaded SKILL.md"
}

# Merge hooks into settings.json
Write-Host ""
Write-Host "Registering hooks in $Settings ..."

$nodeScript = @"
const fs = require('fs');
const settingsPath = process.argv[1];
const hooksDir = process.argv[2].replace(/\\/g, '/');

let settings = {};
if (fs.existsSync(settingsPath)) {
  settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
}
if (!settings.hooks) settings.hooks = {};

function addHook(event, command, statusMessage) {
  if (!Array.isArray(settings.hooks[event])) settings.hooks[event] = [];
  const exists = settings.hooks[event].some(e =>
    e.hooks && e.hooks.some(h => h.command && h.command.includes('parrot'))
  );
  if (!exists) {
    settings.hooks[event].push({
      hooks: [{ type: 'command', command, timeout: 5, statusMessage }]
    });
  }
}

addHook('SessionStart', 'node "' + hooksDir + '/parrot-activate.js"', 'Loading parrot mode...');
addHook('UserPromptSubmit', 'node "' + hooksDir + '/parrot-mode-tracker.js"', 'Tracking parrot mode...');

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
"@

node -e $nodeScript $Settings $HooksDir

Write-Host ""
Write-Host "Done. Parrot is now active for every Claude Code session." -ForegroundColor Green
Write-Host "  /parrot lite  - kill restated questions + recap paragraphs"
Write-Host "  /parrot full  - kill all self-repetition (default)"
Write-Host "  /parrot off   - disable"
