# COLD READ — Godot 4 project

The production build. Landscape, mobile-first, brick-voxel. Validated on
**Godot 4.7.2-stable** (any 4.x stable should open it).

For the full plan see `../BUILD_PLAN.md`. For the design bible see
`../ROADMAP.md`. For the kickoff mission see `../ANTIGRAVITY_PROMPT.md`.

## Run it

Editor: open this folder in Godot 4 and press play.

Headless smoke test (no display needed):
```sh
./run_headless.sh          # imports, then drives all of Act 1 and asserts PASS
```

## What's here

This is a **working narrative spine**. The case flow, choices, Trust, flags,
the Mirror, and save/load are all live. The six gameplay scene types are
placeholder cards that return a sane result so the whole case plays end to end.

| Path | What it is |
| --- | --- |
| `autoload/game_state.gd` | Save/load, flags, Trust, stars, evidence, revives |
| `autoload/mirror.gd` | The Mirror — records player habits for the Act 3 payoff |
| `autoload/audio.gd` | Audio director stub (Intensity 0–4 + one-shot triggers) |
| `runner/scene_runner.gd` | Plays a case scene by scene, checkpoint-saves |
| `runner/case_loader.gd` | Loads cases from `data/`, resolves evidence ids |
| `ui/scene_view.gd` | The text spine + placeholders for gameplay scenes |
| `data/cases/*.json` | Cases 1–3 as pure data |
| `data/evidence.json`, `data/faces.json` | Evidence and character faces |
| `main/main.gd` | Boot; wires runner ↔ view; `--selftest` and `--shot` flags |

## The one rule

**Scene TYPES are code, cases are DATA.** Adding a case means a new JSON file in
`data/cases/` plus a line in `data/manifest.json` — never engine code. Adding a
new *kind* of scene is the only reason to touch code. See `../BUILD_PLAN.md`
§ Scene template contract.

## Next

Build the placeholder gameplay scenes into real brick-voxel 3D, one at a time,
each keeping the `present(cfg, on_done)` contract. Start with Case 1's
`foot_chase`. See `../BUILD_PLAN.md` § Phased milestones.
