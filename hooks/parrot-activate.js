/**
 * parrot-activate.js — SessionStart hook.
 *
 * Reads SKILL.md and prints it so Claude Code injects the rules into the
 * system prompt at the start of every session.
 */
const fs = require("fs");
const { findSkillMd } = require("./parrot-config");

const skillPath = findSkillMd();

if (skillPath) {
  const content = fs.readFileSync(skillPath, "utf-8");
  process.stdout.write(content);
} else {
  process.stderr.write(
    "parrot: SKILL.md not found. Reinstall with: claude plugin install parrot@parrot\n"
  );
}
