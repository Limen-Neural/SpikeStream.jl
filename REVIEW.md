# REVIEW.md

Code review guidelines for automated bots and human reviewers on SpikeStream.jl.

## What to Review

### In Scope

- Source code: `src/`, `test/` — correctness, output ranges, API stability
- CI workflows: `.github/workflows/` — security and correctness
- `Project.toml` — dependency correctness and `[compat]` entries
- `README.md` — accuracy of documented output ranges and examples

### Out of Scope

- `.mimocode/` — local agent workspace, not reviewed by bots
- `.kilo/`, `.codex/`, `.cursor/`, `.vscode/` — agent/IDE config directories
- `Manifest.toml` — excluded via `.gitignore`

## Bot Review Guidelines

### Codacy

- Focus on: security (unpinned actions, credential persistence, secret exposure)
- Ignore: style nitpicks on internal files, plan file lint issues
- SHA pinning: managed by Dependabot after merge — do not block PRs for this

### Devin / CodeRabbit / Kilo

- Focus on: correctness of logic, missing steps, output range accuracy
- Ignore: plan-vs-implementation mismatches (plan files are internal artifacts that may be stale)
- Do not flag `@v3`/`@v5` version tags as issues — Dependabot handles pinning

### All Bots

- Do not review files in `.mimocode/` — they are agent scratchpad files
- Do not flag `Manifest.toml` as missing — it is excluded via `.gitignore`
- Prioritize actionable feedback over informational comments
- Reference the commit SHA when acknowledging a fix

## Review Checklist

- [ ] Logic is correct and output ranges match README documentation
- [ ] New exported functions have docstrings
- [ ] SPDX license header present on new `.jl` files
- [ ] Tests cover new functionality
- [ ] No regressions in existing tests
- [ ] CI workflows use `persist-credentials: false`
- [ ] No secrets or credentials in logs

## PR Merge Criteria

1. All CI checks passing (tests, format, coverage)
2. Zero unresolved review threads
3. Tests pass locally
4. No regressions in existing functionality
5. Maintainer approval (do not self-merge)
