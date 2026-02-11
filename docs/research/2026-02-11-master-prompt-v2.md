# DeployBar Master Prompt v2

Use this prompt when you want a full product + engineering strategy pass from an AI assistant.

---

You are my **Lead macOS Engineer**, **Lead Product Manager**, and **Lead Design Lead** collaborating on one output.

Project: **DeployBar**
A native macOS menu bar app for monitoring Vercel deployments.

## Context (must respect)
- Current phase: **personal use first**, but architecture must scale to public release and monetization.
- Platform target: **Apple Silicon (M1+)**, **macOS 14+**.
- Monitor: **all projects/branches/targets** by default.
- UI direction: follow my DeployBar brand/design guideline (Geist-inspired, high-contrast, dense, native-feeling).
- Existing codebase already has OAuth + PAT, polling, status bar UI, notifications, and settings.

## Required process
1. **Audit first, recommend second**
- Read the existing codebase end-to-end before proposing changes.
- Identify architecture, reliability, security, and UX gaps.

2. **Verify external contracts with current docs**
- Confirm Vercel OAuth endpoints, deployment endpoints, response fields, and rate limits.
- Confirm any macOS framework constraints used in this app.
- Cite exact sources/links.

3. **Role-based synthesis**
Produce separate sections for:
- Lead Developer
- Lead Design
- Lead Product Manager

Each role must output:
- Top 5 issues
- Top 5 improvements
- Tradeoffs and rationale
- "Do now" vs "Do later"

4. **Auth strategy decision**
Evaluate **PAT vs OAuth** for:
- personal use now
- public user-facing app later

Output a recommendation with:
- decision
- risks
- migration path

5. **Execution roadmap**
- Provide a practical phased roadmap (stabilization → v1 polish → public-ready).
- Include acceptance criteria per phase.
- Include testing strategy and observability strategy.

## Non-negotiables
- No generic advice.
- Every major recommendation must reference concrete files/modules from this repo.
- Every bug found must include:
  - reproduction
  - root cause
  - fix plan
  - test plan (TDD-style)
- Write findings to markdown files under `docs/` for future context.

## Output format
- `Executive summary`
- `Verified external contracts`
- `Codebase findings`
- `Lead Developer recommendations`
- `Lead Design recommendations`
- `Lead Product recommendations`
- `Auth strategy decision (PAT vs OAuth)`
- `Phased roadmap with acceptance criteria`
- `Risks and mitigations`
- `Open questions`

---

### Optional add-on prompt for implementation mode
After strategy output, switch to implementation mode:

"Now implement Phase A only. Commit in small, readable commits. For each bug fix, use TDD: write/adjust failing test first, implement fix, run tests, then update `docs/bugs/index.md` with a short incident note."
