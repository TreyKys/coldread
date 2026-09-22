# Super prompt — continue COLD READ in Antigravity

Open this repo as a workspace in **Antigravity**, open the **Agent Manager**,
start a new agent on the `godot/` project, and paste the block below as its
first mission. It gives the agent everything it needs to keep building without
re-explaining the project.

The agent should treat `BUILD_PLAN.md` as the source of truth for *how*, and
`ROADMAP.md` as the source of truth for *what the game is*. This prompt is the
*where to start*.

---

## Paste this to the Antigravity agent

I'm Alex (GitHub `TreyKys`, solo-building under NeuroDev Labs, based in Lagos).
You're continuing an in-progress mobile game called **COLD READ** — a
brick-voxel detective / crime game. Act 1 is three cases; Acts 2–3 come later.

The engine decision is already made: **Godot 4** (validated on 4.7.2-stable).
The project lives in `godot/`. It already boots. Do **not** switch engines, add
a second one, or rewrite what works.

**Read these before writing any code, in this order:**
1. `BUILD_PLAN.md` — the full architecture and the phase-by-phase plan. This is
   your spec. Follow the phases; don't skip ahead to art.
2. `godot/README.md` — what's already in the skeleton and how to run it.
3. `ROADMAP.md` — the design bible: pitch, cast, all 10 cases, choice system,
   the Mirror, monetization, art direction, legal lines. Read it end to end
   before making any design call.
4. `greybox/index.html` — the throwaway HTML5 prototype. It is the **reference
   implementation** for how every scene type *feels*. Port the feel, not the
   canvas code.

**What already works in `godot/` (do not rebuild it):**
- `autoload/game_state.gd` — save/load, flags, Trust, stars, evidence, revives.
- `autoload/mirror.gd` — the Mirror. Records player habits for the Act 3 payoff.
- `runner/scene_runner.gd` + `runner/case_loader.gd` — plays a case scene by
  scene, checkpoint-saves after each, folds results back into state.
- `data/` — Cases 1–3, evidence, and faces as pure JSON. Cases are **data**.
- `ui/scene_view.gd` — a working text spine. The narrative scene types
  (`intro`, `cold_open`, `choice`, `debrief`, title) play for real. The
  gameplay types (`breach`, `read`, `intercept`, `pursuit`, `foot_chase`,
  `standoff`) are placeholder cards that return a sane result so the flow runs.

**Your job: turn the placeholder gameplay scenes into real brick-voxel 3D
scenes, one at a time, each keeping the same contract:** a scene is presented
with `present(cfg, on_done)` and calls `on_done(result: Dictionary)` when it
finishes. `BUILD_PLAN.md` § Scene templates gives the exact contract and the
result each type must return.

**Three hard constraints, from day one:**
- **Landscape only.** The project is already configured for it. Every layout
  you build is landscape (1280×720 base, safe-area aware).
- **Richer input than tap.** Drag, hold-vs-tap, swipe *direction* as a
  meaningful choice, two-thumb layouts where they earn it. Tilt/gyro for
  pursuit steering is on the table — **pitch it to me before you ship it**,
  don't just add it.
- **The Mirror keeps recording.** Every gameplay scene you build must call the
  right `Mirror.record_*` method (roadblock kind, smash-vs-precise, swipe bias,
  ability used, hesitation). If a mechanic doesn't feed the Mirror, Act 3 lands
  hollow. This is non-negotiable.

**What must not get lost (already ported — keep it intact):** the five scene
types that work, the Mirror, data-driven cases, Rook's intro backstory,
portraits-over-voice (no real voice recordings — Alex signed off on text +
faces), and the choice grammar (Trust + flags + hesitate branch).

**Build order — ship the smallest playable slice first:**
Phase 1 is **Case 1's `foot_chase`** as a real behind-the-shoulder brick-voxel
runner, in landscape, playable on my phone via a web export I can open in your
browser. Get that feeling good and let me play it **before** you touch
`breach` or anything in Case 2. I'll tell you what's wrong. Iterate on what I
actually say, not on what you think I meant.

**How I want you to work in Antigravity:**
- Start by producing an **implementation-plan artifact** for Phase 1 only
  (the foot_chase), broken into tasks I can review. Don't plan all of Act 1 up
  front — plan one phase, build it, show me, then plan the next.
- Verify your own work before handing it back: run `godot/run_headless.sh`
  (the skeleton's smoke test) after every change to prove you didn't break the
  spine, and export a web build and open it in your browser to screenshot the
  actual scene. A **walkthrough artifact** with a screenshot of the running
  scene is how I want each phase delivered.
- Keep cases as data. If you catch yourself editing engine code to add a
  *case* (not a scene *type*), stop — it belongs in `data/`.
- Commit per working slice with a clear message. Don't batch a week of work
  into one commit.

I value working output over analysis and honest pushback over reassurance. If
I'm about to make a mistake, say so. Don't preamble, don't restate my messages,
and when a call is genuinely mine to make (spend, store accounts, art
direction, tilt controls), ask me one clear question — don't dump options.

Start now: read the four documents above, then give me the Phase 1
implementation plan for Case 1's foot_chase.
