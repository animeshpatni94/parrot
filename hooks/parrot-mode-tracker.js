/**
 * parrot-mode-tracker.js — UserPromptSubmit hook.
 *
 * Watches for /parrot commands to switch intensity or disable.
 * Emits a one-line system message so Claude Code adjusts behavior.
 */
const input = process.env.USER_PROMPT || "";
const trimmed = input.trim().toLowerCase();

const COMMANDS = {
  "/parrot lite": "PARROT MODE: lite — kill restated questions and recap paragraphs only.",
  "/parrot full": "PARROT MODE: full — kill all forms of self-repetition. Every sentence must carry new information.",
  "/parrot off": "PARROT MODE: off — normal output, repetition allowed.",
  "parrot off": "PARROT MODE: off — normal output, repetition allowed.",
  "stop parrot": "PARROT MODE: off — normal output, repetition allowed.",
};

for (const [cmd, msg] of Object.entries(COMMANDS)) {
  if (trimmed === cmd || trimmed.startsWith(cmd + " ")) {
    process.stdout.write(msg);
    break;
  }
}
