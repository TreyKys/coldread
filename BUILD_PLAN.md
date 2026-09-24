# COLD READ — Build plan (Godot 4, Act 1)

The plan for turning the HTML5 greybox into a shippable landscape mobile game,
built in Godot 4 and driven from Antigravity. This is the spec the agent
follows. `ROADMAP.md` says what the game *is*; this says how it gets built and
in what order.

---

## 0. Where this picks up

The engine question is answered: **Godot 4** (validated headless on
4.7.2-stable — it renders brick-voxel 3D and runs GDScript clean in this
environment). The repo now has three parts:

| Path | What it is | Status |
| --- | --- | --- |
| `greybox/index.html` | The original HTML5 prototype of Cases 1–3 | Frozen reference. Don't edit; port the *feel*. |
| `godot/` | The production project | Boots. Narrative spine live, gameplay scenes stubbed. |
| `ROADMAP.md` / `README.md` / `PROMPT.md` | Design + handoff docs | Source of truth for design. |

The Godot skeleton is a **working narrative spine**: it loads Cases 1–3 from
data, plays the intro, cold opens, choices and debriefs for real, tracks Trust
/ flags / the Mirror, and saves after every scene. The six gameplay scene types
are placeholder cards that return a sane result so the whole case plays end to
end today. Building those six into real 3D scenes is the work.

Run it: `cd godot && ./run_headless.sh` (smoke test), or open `godot/` in the
Godot editor and press play.

---

## 1. Architecture — the greybox port map

The greybox's one insight worth keeping is its shape: **scene TYPES are code,
cases are DATA.** That's ported literally.

| Greybox (JS, one file) | Godot (this repo) | Notes |
| --- | --- | --- |
| `TEMPLATES.<type>()` lifecycle objects | one scene per type under `godot/scenes/<type>/` | The only code that changes when you add *gameplay*. |
| `CASES[]` array of objects | `godot/data/cases/*.json` + `manifest.json` | Cases 4–10 are new files, zero engine edits. |
| `EV{}`, `FACES{}` | `godot/data/evidence.json`, `data/faces.json` | Referenced by id from cases. |
| `Scene.play(cfg, onDone)` | `runner/scene_runner.gd` → `present(cfg, on_done)` | Same contract, same fold-result logic. |
| `S` (localStorage) | `autoload/game_state.gd` (`user://coldread.save`) | Cloud sync wraps this later. |
| `S.mirror` | `autoload/mirror.gd` | Its own autoload now. Record API is explicit. |
| `proj`/`iso`/`roadBox` canvas draws | Godot 3D nodes + `SurfaceTool` voxel meshes | Throwaway. Rebuild in real 3D. |
| `portraitSVG()` | `data/faces.json` → procedural mesh or `SubViewport` face | Keep zero-asset. |

### Directory layout (target)

```
godot/
  project.godot            landscape, GL-compat, autoloads   [done]
  autoload/                GameState, Mirror, AudioDirector  [done]
  runner/                  SceneRunner, CaseLoader           [done]
  ui/                      SceneView (spine) + HUD, panels   [spine done]
  data/                    cases/, evidence.json, faces.json [Act 1 done]
  scenes/                  one folder per scene TYPE          <-- the work
    foot_chase/  breach/  read/  intercept/  pursuit/  standoff/
  world/                   shared brick-voxel kit, districts, cameras
  input/                   gesture recognizer (drag/hold/swipe/tilt)
  audio/                   FMOD or bus-based director backend
  tests/                   headless test scenes
```

The agent creates `scenes/`, `world/`, `input/`, `audio/` as it builds. The
`ui/scene_view.gd` spine already shows exactly where each gameplay scene plugs
in and what result it must return.

---

## 2. The data contract (how a case is added)

A case is a JSON file: `{ id, name, rank, district, mins, blurb, scenes: [...] }`.
Each scene is `{ type, ...config }`. Evidence is referenced by id and resolved
by the loader into full objects before a scene ever sees it. To add **Case 4**:

1. Write `data/cases/case_04_container9.json`.
2. Add any new evidence ids to `data/evidence.json`.
3. Add the filename to `data/manifest.json`.
4. If Case 4 needs a scene type that doesn't exist yet (e.g. `boat_pursuit`),
   *that* is the only reason to add code — a new folder under `scenes/`.

If you're writing a "Case" class, you've broken the architecture. Cases are
configs; scene types are the code.

---

## 3. Scene template contract

Every scene type is a Godot scene whose root script implements one method:

```gdscript
func present(cfg: Dictionary, on_done: Callable) -> void
# ...play the scene, then exactly once:
on_done.call(result)   # result: Dictionary, shape depends on type
```

`SceneRunner` folds `result` into `GameState` and advances. The runner passes
these run-scoped hints into every `cfg`: `_grade` (how the last Read graded →
chase start distance), `_cut` (did the Intercept cut them off), `_case_name`,
`_rank`, `district`.

| Type | Controls (landscape) | Must return | Feeds the Mirror |
| --- | --- | --- | --- |
| `intro` | tap-through beats | `{}` | — |
| `cold_open` | tap-through lines | `{}` | — |
| `breach` | two-finger drag to sweep, **hold** to focus a heavy container, tap revealed item to bag; swipe-up = TRACE | `{ evidence: [...] }` | `record_search(smashed_everything)` |
| `read` | **drag** evidence cards into sentence blanks | `{ grade: "solid"\|"shaky"\|"cold" }` | — (decoy handling is a tell, not a habit) |
| `intercept` | **drag** roadblocks onto a top-down route map | `{ cut: bool, route: id }` | `record_block(route.kind)` per placement |
| `pursuit` | swipe lane / drift, **tap** ram, **hold** ability, optional **tilt** steer | `{ stars: 1..3, hits: n }` | `record_swipe(dir)`, `record_ability(id)` |
| `foot_chase` | swipe L/R weave, **up** vault, **down** slide | `{ stars: 1..3 }` | `record_swipe(dir)` |
| `standoff` | **hold** to steady, tap the right target | `{ clean: bool }` | — |
| `choice` | **swipe** L/R (or tap); timeout = Hesitate | `{ choice: "left"\|"right"\|"hesitate" }` | `record_hesitation()` on timeout |
| `debrief` | tap continue | `{}` | reads `Mirror.profile()` from Case 3 on |

The greybox `TEMPLATES.*` in `greybox/index.html` are the reference for each
one's pacing, failure handling (checkpoint + revive offer), and juice
(hit-stop, shake, evidence stinger). Match the feel; replace the rendering.

---

## 4. The Mirror (Act 3 depends on this)

`autoload/mirror.gd` records, in one place, everything Ada Voss uses against
the player in Act 3:

- **roadblock placement** by route kind (bridge / back / highway / docks),
- **search style** (smashed everything vs. worked precisely),
- **hesitation** count (let a choice timer run out),
- **swipe direction bias**,
- **which squad abilities** the player leans on.

It persists inside the save file and survives the whole game. `Mirror.profile()`
returns the summary the debrief shows from Case 3 and Ada quotes in Act 3.

**The rule for Cases 4–10:** any new mechanic that involves a choice of *how*
(not just *whether*) must call a `Mirror.record_*` method. Add new counters to
`mirror.gd` when a new mechanic introduces a new habit (e.g. Case 5's HOLD
ability, Case 9's split-squad assignment). The Act 3 "the villain has been
studying you" payoff is only as good as what got recorded in Acts 1–2.

---

## 5. Landscape + input

Landscape is locked in `project.godot` (`handheld/orientation=4`, sensor
landscape). Base viewport 1280×720, `canvas_items` stretch, `expand` aspect,
safe-area insets respected in the HUD.

Build one shared **gesture recognizer** under `input/` rather than re-deriving
gestures per scene. It should classify: tap, hold (>250ms stationary),
drag (with live delta), swipe (direction + velocity), and two-finger drag. Each
scene subscribes to the gestures it needs. This is where the "richer controls"
ask lives — the greybox only had tap + crude swipe.

Two-thumb layouts where they earn it: pursuit wants steer on one side, ram/
ability on the other. Foot chase is single-thumb swipe. Breach is two-finger
sweep. **Tilt/gyro** for pursuit steering is promising but is Alex's call —
prototype it behind a flag and pitch it with a build he can feel, don't ship it
silently.

---

## 6. Rendering & art pipeline

Two rendering worlds, matching the greybox split:

- **UI scenes** (`intro`, `cold_open`, `read`, `choice`, `debrief`) — Godot
  `Control` nodes on a `CanvasLayer`. The spine already does this.
- **Gameplay scenes** (`breach`, `intercept`, `pursuit`, `foot_chase`,
  `standoff`) — real 3D: a `Node3D` world, brick-voxel meshes, per-district
  lighting, the three cameras from ROADMAP § Art (low three-quarter chase cam,
  behind-the-shoulder foot cam, top-down intercept).

**Placeholder → final, in that order.** First build every gameplay scene with a
shared **greybox brick kit** in `world/` (pooled `SurfaceTool`/`MultiMesh`
cubes, flat district colors, no textures) so the loop is playable and tunable
cheaply. Only after the loop feels right do you do the art-style spike: rebuild
**one** scene (suggest Case 1 breach, the sunlit stall interior) in the target
Arcane brick-voxel look, judge the delta, then budget a full art pass.
MagicaVoxel for models, Blender for rig/anim, Kenney CC0 kits for greybox
stand-ins.

**Destruction on cheap phones** (ROADMAP): pre-broken chunk prefabs, pooled and
reused, physics only near camera, a hard cap on active pieces per device tier,
debris fades ~3s. Target 30fps on 3GB Android. Don't ship live fracture.

**Legal lines are hard rules, not preferences:** our own smooth brick (corner
notch, no stud grid), our own figure (never the minifigure shape), no "LEGO"
anywhere, no "Master Builder", no real police insignia / bank / company logos.
See ROADMAP § Art direction and legal lines.

**Portraits over voice.** Faces stay procedural from `data/faces.json` (a small
voxel head or a `SubViewport`-rendered pixel face). No real voice recordings —
Alex signed off on text + faces. Don't add voiceover unless he asks.

---

## 7. Save, audio, monetization

- **Save** goes through `GameState` only, so a cloud-sync layer (needed for
  revives/gems per ROADMAP § Monetization) can wrap it without touching scenes.
- **Audio** goes through `AudioDirector` (stub now): one Intensity value (0–4)
  plus one-shot triggers, so scenes can call it before the FMOD/bus backend
  exists. Wire the real adaptive Afrobeats score behind it later.
- **Monetization** is stubbed until the loop is proven. When it goes in, put
  ads and IAP behind one interface so networks swap out. Rules from ROADMAP:
  rewarded ads only in story (~8/day), first revive free with an ad, **no
  paid better-choices, no paid random boxes.** Nothing for sale changes a
  choice outcome or makes a case easier.

---

## 8. Phased milestones

Ship the smallest playable slice, let Alex play, iterate. Don't build in a cave.

**Phase 1 — one real gameplay scene. `foot_chase`, Case 1.**
Behind-the-shoulder brick-voxel runner in landscape: swipe to weave, up to
vault, down to slide, guided so Case 1's can't be lost (`canFail:false`).
Records swipe bias to the Mirror. Ends in the tackle, returns `{stars}`.
*Done when:* Alex plays it on his phone (web export) and it feels good;
`run_headless.sh` still passes.

**Phase 2 — `breach` + `read`, Case 1.** Two-finger smash-search with the
heavy/light container mechanic and TRACE (greybox has the reference), then the
drag-cards Read graded Solid/Shaky/Cold. Breach records smash-vs-precise.
*Done when:* Case 1 plays intro→cold_open→foot_chase→breach→read→pursuit
(pursuit still stub)→choice→debrief, and the Read grade actually changes where
the next chase starts.

~~**Phase 3 — `pursuit` + `intercept` + `standoff`.**~~ [DONE] Lane driving with ram/
nitro (two-thumb), the drag-roadblock route map (records block kind), the
slow-mo tap-target standoff. Now **all of Case 1** is real 3D.
*Done when:* Case 1 is fully playable with no placeholder cards.

**Phase 4 — Cases 2 & 3 as data + district art.** No new scene *types* needed
(Act 1 reuses the six). Build The Stacks and Portside district looks and
lighting. Verify the Mirror numbers accumulate across all three cases and the
Case 3 debrief shows a real profile.
*Done when:* Act 1 plays start to finish, landscape, on a phone.

**Phase 5 — art-style spike + polish + closed test.** Rebuild one scene in the
final brick-voxel look, wire audio Intensity, add haptics, first-pass juice
everywhere. Then ~20 outside testers (ROADMAP § Phases).

**Later — Act 2 (Cases 4–7), Act 3 (Cases 8–10)** as episodes. Each Act 2 case
adds one district, one new scene template, one mechanic that feeds the Mirror
and pays off in Act 3.

---

## 9. Testing

- **Spine smoke test:** `godot/run_headless.sh` drives all of Act 1 through the
  runner headless and asserts data + state + Mirror + save are clean. Run it
  after every change; it's the regression net for the case flow.
- **Visual check:** export a Web build (`godot --headless --export-release "Web"`)
  and open it in Antigravity's browser to screenshot and play the actual scene.
  This is how a headless agent "sees" the game.
- **Device check:** Alex plays each phase on a real Android phone before the
  next phase starts. That feedback outranks everything here.
- Add headless test scenes under `tests/` for anything with tricky math (chase
  gap closing, intercept weighted pick, Read grading).

---

## 10. Working in Antigravity

- Point the agent at `godot/`, hand it `ANTIGRAVITY_PROMPT.md`.
- One phase at a time: produce an **implementation-plan artifact** for the
  current phase only, build it, deliver a **walkthrough artifact** with a
  screenshot of the running scene, then plan the next phase. Don't front-load a
  plan for all of Act 1.
- The agent verifies its own work across surfaces: terminal for
  `run_headless.sh`, browser for the web-export screenshot.
- Commit per working slice with a clear message. Keep cases in `data/`.

---

## 11. Definition of done — Act 1

Act 1 ships when Cases 1–3 play start to finish in landscape on a 3GB Android
phone at 30fps, all six gameplay scenes are real 3D (no placeholders), the
Mirror records across all three cases and the Case 3 debrief shows a true
profile, choices persist and resurface, and the soft-launch gates from
ROADMAP § Soft-launch gates (D1 30%+, Case 1 completion 85%+, session 5–8 min,
crash-free 99.5%+) are the targets for the closed test.

---

## 12. Open decisions for Alex (don't decide these alone)

- **Tilt/gyro** for pursuit steering — prototype behind a flag, then he decides.
- **Rendering path** — start `gl_compatibility` (widest device support). Switch
  to the Vulkan `mobile` renderer for the art pass only if target phones hold
  30fps.
- **Store account / bundle id / signing** — his call, needed before any export
  that leaves his phone.
- **Title & trademark** — "COLD READ" and "INTERCEPT" need a store + trademark
  search before marketing spend (ROADMAP § Legal).
- **Protagonist** (customizable Rook vs. fixed hero) and **main-cast voice**
  (human actors vs. AI at launch) — business/creative calls from the ROADMAP's
  open decisions, not engineering ones.
