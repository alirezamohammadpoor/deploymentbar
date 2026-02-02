# VercelBar Context

Last updated: 2026-02-02

## Product scope decisions
- Account scope: personal only (no team scopes yet).
- Targets/branches: show all targets and branches.
- Minimum macOS version: 14 (Apple Silicon / M1+).

## Bugfix protocol
- All bug fixes must use TDD: reproduce with a failing test first, then implement the fix.
- Each bug fix must be documented in an `.md` file (repro steps, failing test, fix summary, and verification).
- Keep a log of bug fixes in the same documentation file (or a linked index if multiple files are used).
