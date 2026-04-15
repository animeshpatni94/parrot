# parrot

**LLM already said it. Why say again?**

![Token savings](https://img.shields.io/badge/token%20savings-30--40%25-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

LLMs waste 30-40% of output tokens restating your question, echoing instructions before executing them, and tacking on summaries that repeat the intro. Parrot kills that.

## Before / After

**You ask:** "Why is my API returning 500 errors?"

<table>
<tr><th>Vanilla (167 tokens)</th><th>Parrot (68 tokens) — 59% reduction</th></tr>
<tr>
<td>

You're asking about why your API is returning 500 errors. Let me help you debug this issue.

The 500 error you're seeing is most likely caused by an unhandled exception in your route handler. Looking at your code, the `getUser` function doesn't handle the case where the database query returns null.

When the database returns null and you try to access `user.name`, it throws a TypeError because you can't access properties on null.

To fix this, you should add a null check:
```js
const user = await getUser(id);
if (!user) return res.status(404).json({ error: 'Not found' });
```

In summary, the 500 error is caused by a missing null check on the database result. Adding the guard clause above will fix the issue.

</td>
<td>

`getUser` doesn't handle null from the database. When the query returns nothing, `user.name` throws a TypeError — which surfaces as a 500.

Add a guard:
```js
const user = await getUser(id);
if (!user) return res.status(404).json({ error: 'Not found' });
```

</td>
</tr>
</table>

Same information. Half the tokens.

## Install

| Agent | Command | Auto-activates | Config file |
|-------|---------|---------------|-------------|
| **Claude Code** | `claude plugin install parrot@parrot` | Yes | `.claude-plugin/` |
| **Codex** | Clone repo | Yes | `AGENTS.md`, `.codex/` |
| **Gemini CLI** | `gemini extensions install animeshpatni94/parrot` | Yes | `GEMINI.md` |
| **Cursor** | `npx skills add animeshpatni94/parrot -a cursor` | No | `.cursor/rules/parrot.md` |
| **Windsurf** | `npx skills add animeshpatni94/parrot -a windsurf` | No | `.windsurf/rules/parrot.md` |
| **Cline** | Clone repo | Yes | `.clinerules/parrot.md` |
| **Roo Code** | Clone repo | Yes | `.roo/rules/parrot.md` |
| **Copilot** | Clone repo | Yes | `.github/copilot-instructions.md` |
| **Continue.dev** | Clone repo | Yes | `.continuerules` |
| **Zed AI** | Clone repo | Yes | `.rules` |
| **Amazon Q** | Clone repo | Yes | `.amazonq/rules/parrot.md` |
| **Augment** | Clone repo | Yes | `.augment-guidelines` |
| **Aider** | Clone repo | Yes | `.aider.conf.yml` → `rules/parrot.md` |

<details>
<summary><b>Claude Code — setup guide</b></summary>

**Option A: Plugin (recommended)**
```bash
claude plugin install parrot@parrot
```
Auto-activates every session via `SessionStart` hook. Supports `/parrot lite`, `/parrot full`, `/parrot off`.

**Option B: Standalone hooks (no plugin)**
```bash
# macOS / Linux
bash <(curl -s https://raw.githubusercontent.com/animeshpatni94/parrot/main/hooks/install.sh)

# Windows (PowerShell)
irm https://raw.githubusercontent.com/animeshpatni94/parrot/main/hooks/install.ps1 | iex
```
Copies hook scripts to `~/.claude/hooks/` and registers them in `~/.claude/settings.json`.

**Option C: Project-level only**

Clone this repo into your project. Claude Code reads `CLAUDE.md` at the project root, which references `skills/parrot/SKILL.md`. Active for that project only.

</details>

<details>
<summary><b>GitHub Copilot — setup guide</b></summary>

**Option A: Repo-level (auto-activates for everyone on the project)**

Add `.github/copilot-instructions.md` to your repo (already included if you clone parrot). Copilot Chat reads this file automatically — no config needed.

To add parrot to an existing repo:
```bash
mkdir -p .github
curl -fsSL https://raw.githubusercontent.com/animeshpatni94/parrot/main/.github/copilot-instructions.md \
  -o .github/copilot-instructions.md
```

**Option B: User-level (active across all repos)**

In VS Code: `Settings` → search `copilot instructions` → `GitHub > Copilot > Chat: Code Generation Instructions` → `Add Item` → paste:

```
Never say the same thing twice. One idea, one expression. No echoes.
NEVER restate the user's question. NEVER echo instructions before executing.
NEVER summarize what you just said. NEVER add a conclusion that repeats the intro.
NEVER use: "as you mentioned", "to summarize", "in summary", "to recap".
One idea, one expression. Said it? Move on.
```

**Option C: settings.json (VS Code)**

Add to your VS Code `settings.json`:
```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "text": "Never say the same thing twice. NEVER restate the user's question. NEVER echo instructions before executing. NEVER summarize what you just said. NEVER add a conclusion that repeats the intro. One idea, one expression."
    }
  ]
}
```

</details>

<details>
<summary><b>Cursor / Windsurf — always-on snippet</b></summary>

`npx skills add` installs the skill but doesn't auto-activate. Paste this into your agent's rules file:

```
Never say the same thing twice. One idea, one expression. No echoes.
1. NEVER restate or paraphrase the user's question.
2. NEVER echo instructions before executing them.
3. NEVER summarize what you just said at the end.
4. NEVER add a conclusion that repeats the intro.
5. NEVER use: "as you mentioned", "to summarize", "in summary", "to recap".
6. NEVER repeat an explanation in different wording.
7. One idea, one expression. Said it? Move on.
```

</details>

<details>
<summary><b>Any other tool — manual setup</b></summary>

Copy the contents of [`rules/parrot.md`](rules/parrot.md) into your tool's custom instructions or system prompt. Works with any LLM interface that accepts custom instructions.

</details>

## Usage

Parrot activates automatically on session start (Claude Code plugin / Gemini extension).

| Command | Effect |
|---------|--------|
| `/parrot lite` | Kill restated questions + recap paragraphs |
| `/parrot full` | Kill all self-repetition (default) |
| `/parrot off` | Disable |

## What it cuts

| Repetition pattern | Example |
|-------------------|---------|
| Restating the question | "You're asking about why your API..." |
| Echoing instructions | "You want me to review this PR. Let me..." |
| Recap paragraphs | "In summary, the issue is caused by..." |
| Conclusion = intro | Intro says X, conclusion restates X |
| Rephrased explanations | Same idea, different words, same paragraph |
| Filler acknowledgments | "Great question!", "I'd be happy to help" |

## Stacking with caveman

Different waste, different tool.

| | Caveman | Parrot |
|---|---------|--------|
| **Targets** | Verbose language | Repeated ideas |
| **Cuts** | Filler words, articles, hedging | Restated questions, summaries, echoed content |
| **Savings** | ~65% token reduction | ~35% token reduction |
| **Together** | ~80% fewer tokens | |

Install both:
```bash
claude plugin install caveman@caveman
claude plugin install parrot@parrot
```

Caveman compresses *how* you say it. Parrot ensures you only say it *once*.

## Evals

Three-arm evaluation against 10 real-world prompts:

| Arm | Description |
|-----|-------------|
| Baseline | No system prompt |
| Control | "Do not repeat yourself." |
| Parrot | Full SKILL.md |

Run locally:
```bash
uv run python evals/llm_run.py          # requires claude CLI
uv run --with tiktoken python evals/measure.py   # token counts + repetition ratio
```

Metrics: token count, repetition ratio (unique semantic units / total sentences), information preservation.

## Feature matrix

| Feature | Claude Code | Codex | Gemini | Cursor | Windsurf | Cline | Roo Code | Copilot | Continue | Zed | Amazon Q | Augment | Aider |
|---------|------------|-------|--------|--------|----------|-------|----------|---------|----------|-----|---------|---------|-------|
| Auto-activation | Plugin | Repo | Ext | No | No | Repo | Repo | Repo | Repo | Repo | Repo | Repo | Repo |
| `/parrot` commands | Yes | Yes | Yes | No | No | No | No | No | No | No | No | No | No |
| Mode switching | Yes | Yes | Yes | No | No | No | No | No | No | No | No | No | No |

## License

MIT
