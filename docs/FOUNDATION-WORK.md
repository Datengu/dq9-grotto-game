# Foundation work toward v0.3

Baseline: local and GitHub `main` at `d93df33` (v0.2). Live issue bodies #1–#8 read on 8 September 2026; all open, no open PRs or issue comments. Work proceeds on `codex/foundation-transitions-motion`. No duplicate issues or generator reset.

## #2 — interior exits

Reproduced by walking straight from the weapon-shop entrance through the visible opening, without pressing E. The original actor fell to y = -121.31 in four simulated seconds. The old playthrough only approached the E interaction, so it missed this route.

The doorway now detects crossing before the edge, queues one transition outside physics mutation, returns to the correct building facing outward, and keeps deliberate interactions on E. An invisible collision backstop and last-safe-position bounds recovery prevent falling even if transition handling fails. Scene changes clear pending transitions safely.

Regression tests exercise all five buildings from straight and diagonal approaches, correct return positions/orientation, a disconnected transition listener, forced out-of-bounds recovery and normal shop interaction. The walking probe now exits with a lowest y of -0.014, consistent with the collision margin. Exported and visual validation are recorded as work progresses; implementation alone does not close an issue.
