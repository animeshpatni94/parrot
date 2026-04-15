/**
 * parrot-config.js — shared config for parrot hooks.
 *
 * Resolves the correct SKILL.md path whether running from a plugin install
 * or a standalone hooks install.
 */
const fs = require("fs");
const path = require("path");

function findSkillMd() {
  // Plugin install: CLAUDE_PLUGIN_ROOT is set
  if (process.env.CLAUDE_PLUGIN_ROOT) {
    const pluginPath = path.join(
      process.env.CLAUDE_PLUGIN_ROOT,
      "skills",
      "parrot",
      "SKILL.md"
    );
    if (fs.existsSync(pluginPath)) return pluginPath;
  }

  // Standalone hooks install: skill lives alongside hooks dir
  const standaloneSkill = path.resolve(
    __dirname,
    "..",
    "skills",
    "parrot",
    "SKILL.md"
  );
  if (fs.existsSync(standaloneSkill)) return standaloneSkill;

  // Hooks dir sibling to skills dir (repo root)
  const repoSkill = path.resolve(__dirname, "..", "skills", "parrot", "SKILL.md");
  if (fs.existsSync(repoSkill)) return repoSkill;

  return null;
}

module.exports = { findSkillMd };
