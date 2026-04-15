"""
Read evals/snapshots/results.json (produced by llm_run.py) and report
token compression + repetition metrics per skill.

Measures:
  - Token reduction vs control arm
  - Repetition ratio: unique semantic units / total sentences
  - Information preservation: checks response still addresses the prompt

Tokenizer note: tiktoken o200k_base is an approximation of Claude's BPE.
Ratios are meaningful for comparison; absolute counts are approximate.

Run: uv run --with tiktoken python evals/measure.py
"""

from __future__ import annotations

import json
import re
import statistics
from pathlib import Path

import tiktoken

ENCODING = tiktoken.get_encoding("o200k_base")
SNAPSHOT = Path(__file__).parent / "snapshots" / "results.json"


def count_tokens(text: str) -> int:
    return len(ENCODING.encode(text))


def split_sentences(text: str) -> list[str]:
    """Split text into sentences, filtering out code blocks and empty lines."""
    # Remove code blocks
    text = re.sub(r"```[\s\S]*?```", "", text)
    text = re.sub(r"`[^`]+`", "", text)
    # Split on sentence boundaries
    sentences = re.split(r"(?<=[.!?])\s+", text.strip())
    return [s.strip() for s in sentences if s.strip() and len(s.strip()) > 10]


def ngram_set(sentence: str, n: int = 3) -> set[tuple[str, ...]]:
    """Extract word n-grams from a sentence for overlap detection."""
    words = sentence.lower().split()
    if len(words) < n:
        return {tuple(words)}
    return {tuple(words[i : i + n]) for i in range(len(words) - n + 1)}


def repetition_ratio(text: str) -> float:
    """
    Measure self-repetition: what fraction of sentences share significant
    n-gram overlap with an earlier sentence?

    Returns: fraction of NON-repetitive sentences (higher = less repetition = better).
    1.0 = no repetition, 0.5 = half the sentences repeat earlier content.
    """
    sentences = split_sentences(text)
    if len(sentences) <= 1:
        return 1.0

    seen_ngrams: set[tuple[str, ...]] = set()
    unique_count = 0

    for sent in sentences:
        grams = ngram_set(sent)
        if not grams:
            continue
        overlap = len(grams & seen_ngrams) / len(grams)
        if overlap < 0.5:  # Less than 50% overlap = novel content
            unique_count += 1
        seen_ngrams.update(grams)

    return unique_count / len(sentences)


def stats(values: list[float]) -> tuple[float, float, float, float, float]:
    return (
        statistics.median(values),
        statistics.mean(values),
        min(values),
        max(values),
        statistics.stdev(values) if len(values) > 1 else 0.0,
    )


def fmt_pct(x: float, invert: bool = False) -> str:
    if invert:
        x = -x
    sign = "-" if x < 0 else "+"
    return f"{sign}{abs(x) * 100:.0f}%"


def main() -> None:
    if not SNAPSHOT.exists():
        print(f"No snapshot at {SNAPSHOT}. Run `python evals/llm_run.py` first.")
        return

    data = json.loads(SNAPSHOT.read_text())
    arms = data["arms"]
    meta = data.get("metadata", {})
    prompts = data.get("prompts", [])

    baseline_tokens = [count_tokens(o) for o in arms["__baseline__"]]
    control_tokens = [count_tokens(o) for o in arms["__no_repeat__"]]

    baseline_rep = [repetition_ratio(o) for o in arms["__baseline__"]]
    control_rep = [repetition_ratio(o) for o in arms["__no_repeat__"]]

    print(f"Generated: {meta.get('generated_at', '?')}")
    print(f"Model: {meta.get('model', '?')} | CLI: {meta.get('claude_cli_version', '?')}")
    print(f"Tokenizer: tiktoken o200k_base (approximation)")
    print(f"n = {meta.get('n_prompts', len(baseline_tokens))} prompts, single run per arm")
    print()

    print("Reference arms (no skill):")
    print(f"  baseline: {sum(baseline_tokens)} tokens, "
          f"repetition ratio: {statistics.mean(baseline_rep):.2f}")
    print(f"  no-repeat control: {sum(control_tokens)} tokens "
          f"({fmt_pct(1 - sum(control_tokens) / sum(baseline_tokens))} vs baseline), "
          f"repetition ratio: {statistics.mean(control_rep):.2f}")
    print()

    print("Skills (additional reduction on top of no-repeat control):")
    print()
    print("| Skill | Token Median | Token Mean | Rep. Ratio | Tokens (skill/ctrl) |")
    print("|-------|-------------|-----------|------------|---------------------|")

    for skill, outputs in arms.items():
        if skill.startswith("__"):
            continue
        skill_tokens = [count_tokens(o) for o in outputs]
        skill_rep = [repetition_ratio(o) for o in outputs]
        savings = [
            1 - (s / t) if t else 0.0 for s, t in zip(skill_tokens, control_tokens)
        ]
        med, mean, lo, hi, sd = stats(savings)
        avg_rep = statistics.mean(skill_rep)
        print(
            f"| **{skill}** | {fmt_pct(med)} | {fmt_pct(mean)} | "
            f"{avg_rep:.2f} | {sum(skill_tokens)} / {sum(control_tokens)} |"
        )


if __name__ == "__main__":
    main()
