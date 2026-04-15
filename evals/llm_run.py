"""
Run each prompt through Claude Code in three arms and snapshot the outputs:

  1. baseline      — no extra system prompt
  2. no-repeat     — system prompt: "Do not repeat yourself."
  3. parrot        — system prompt: "Do not repeat yourself.\n\n{SKILL.md}"

The honest delta is (3) vs (2): how much does the parrot SKILL add on top
of a plain "don't repeat" instruction? Comparing (3) vs (1) conflates the
skill with the generic instruction.

Requires:
  - `claude` CLI on PATH (Claude Code), authenticated

Run: uv run python evals/llm_run.py

Environment:
  PARROT_EVAL_MODEL   optional --model flag value passed through to claude
"""

from __future__ import annotations

import datetime as dt
import json
import os
import subprocess
from pathlib import Path

EVALS = Path(__file__).parent
SKILLS = EVALS.parent / "skills"
PROMPTS = EVALS / "prompts" / "en.txt"
SNAPSHOT = EVALS / "snapshots" / "results.json"

CONTROL_PREFIX = "Do not repeat yourself."


def run_claude(prompt: str, system: str | None = None) -> str:
    cmd = ["claude", "-p"]
    if system:
        cmd += ["--system-prompt", system]
    if model := os.environ.get("PARROT_EVAL_MODEL"):
        cmd += ["--model", model]
    cmd.append(prompt)
    out = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return out.stdout.strip()


def claude_version() -> str:
    try:
        out = subprocess.run(
            ["claude", "--version"], capture_output=True, text=True, check=True
        )
        return out.stdout.strip()
    except Exception:
        return "unknown"


def main() -> None:
    prompts = [p.strip() for p in PROMPTS.read_text().splitlines() if p.strip()]
    skills = sorted(p.name for p in SKILLS.iterdir() if (p / "SKILL.md").exists())

    print(f"=== {len(prompts)} prompts x ({len(skills)} skills + 2 control arms) ===")
    print(flush=True)

    snapshot: dict = {
        "metadata": {
            "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            "claude_cli_version": claude_version(),
            "model": os.environ.get("PARROT_EVAL_MODEL", "default"),
            "n_prompts": len(prompts),
            "control_prefix": CONTROL_PREFIX,
        },
        "prompts": prompts,
        "arms": {},
    }

    # Arm 1: baseline
    print("arm 1: baseline (no system prompt)", flush=True)
    snapshot["arms"]["__baseline__"] = [run_claude(p) for p in prompts]

    # Arm 2: control
    print('arm 2: no-repeat control ("Do not repeat yourself.")', flush=True)
    snapshot["arms"]["__no_repeat__"] = [
        run_claude(p, system=CONTROL_PREFIX) for p in prompts
    ]

    # Arm 3: skill(s)
    for skill in skills:
        skill_md = (SKILLS / skill / "SKILL.md").read_text()
        system = f"{CONTROL_PREFIX}\n\n{skill_md}"
        print(f"arm 3: {skill}", flush=True)
        snapshot["arms"][skill] = [run_claude(p, system=system) for p in prompts]

    SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
    SNAPSHOT.write_text(json.dumps(snapshot, ensure_ascii=False, indent=2))
    print(f"\nWrote {SNAPSHOT}")


if __name__ == "__main__":
    main()
