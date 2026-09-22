# COLD READ

A brick-voxel detective / crime game for mobile. Working title.

> **Now moving to Godot 4.** The HTML5 canvas build was the greybox — it
> proved the loop. The production game is being built in **Godot 4** (landscape,
> mobile). Start here:
> - [`ANTIGRAVITY_PROMPT.md`](./ANTIGRAVITY_PROMPT.md) — paste-ready mission for the Antigravity agent.
> - [`BUILD_PLAN.md`](./BUILD_PLAN.md) — the full phased build plan and architecture.
> - [`godot/`](./godot/) — the Godot project (boots today; narrative spine live, gameplay scenes stubbed).
> - [`greybox/index.html`](./greybox/index.html) — the frozen HTML5 prototype, kept as the feel reference.

The greybox shipped Cases 1–3 as a single-file HTML5 canvas prototype, no
build step, no assets.

- **Live greybox:** https://claude.ai/artifact/MpmWpoXrt3XiFfESddLUdG
- **Full design doc & storyboard:** see [`ROADMAP.md`](./ROADMAP.md)

The greybox exists to prove the core loop is fun before we spend on art.
It is intentionally ugly. Final art target is Arcane-style brick-voxel
(see ROADMAP § Art).

---

## Repo layout

```
index.html    The entire game. One file. No dependencies. No build step.
ROADMAP.md    Design doc, storyboard for all 10 cases, monetization, build plan.
README.md     This file.
```

That is deliberately the whole tree. Adding a build step, a framework, or a
package.json BEFORE we've locked scene variety and shipped the art pass is
the wrong order — it slows iteration on the thing that still matters most,
which is whether the moment-to-moment loop feels good.

## Run it

```sh
# any static server; the game is one file
python3 -m http.server 8000
# then open http://localhost:8000/
```

Or just double-click `index.html`. It runs off the filesystem too.

**Orientation note (correction to the greybox):** Final game is **landscape**,
not portrait. The greybox was built and tested at 390×844 (portrait phone)
to get the loop working fast. Real production build ships landscape (844×390
or wider). Layouts inside `TEMPLATES.*` will need re-tuning — chase road
proportions, breach isometric room, portrait-row placement in dialogue
panels, HUD row, evidence bag position. Nothing structural changes; the
math (`proj`, `iso`, `W/H`) is already resolution-independent.

## Publish an update to the live artifact

The greybox is published as a Claude artifact at the URL above. To push a
new version:

- **From Claude Code with the Artifact tool:** republish `index.html` with
  `url: https://claude.ai/artifact/MpmWpoXrt3XiFfESddLUdG` — same file path
  updates in place, same URL.
- No CI, no deploy script. Publishing IS the deploy.

## Architecture (30 seconds)

Everything is in one `<script>` IIFE at the bottom of `index.html`.

- **`TEMPLATES.<name>`** — one function per scene type (`intro`,
  `cold_open`, `foot_chase`, `pursuit`, `breach`, `read`, `intercept`,
  `standoff`, `choice`, `debrief`). Each returns an object with
  `enter/update/draw/onTap/onSwipe/onHold/resize/exit` lifecycle methods.
- **`CASES[]`** — pure data. Each case is `{id, name, rank, district, blurb,
  scenes:[{type, ...cfg}]}`. Adding Case 4 means adding an object to this
  array, not writing engine code.
- **`Scene.play(cfg, onDone)`** — runs one scene template with its config,
  fires `onDone(result)` when the scene finishes, `nextScene()` folds
  results into state `S` and starts the next.
- **`S`** — persistent state (`caseIdx, sceneIdx, unlocked, flags, trust,
  mirror, stars, evidence, reviveUsed`), localStorage-backed via
  `save()`/`load()` under key `'coldread.gb'`.
- **`S.mirror`** — tracks player habits (`roadblocks[]`, `smashed`, `precise`,
  `hesitations`, `swipeBias`) for the Act 3 "the villain has been studying
  you" payoff described in ROADMAP § The mirror.
- **Rendering** — `proj(x,z)` for pseudo-3D road/chase scenes,
  `iso(x,y,z,ox,oy,sc)` for isometric interiors (breach). All draws are
  raw `canvas` 2D calls, no library.
- **Faces** — `FACES[id]` is a small color+shape recipe; `portraitSVG(id)`
  builds a 24×24 crisp-pixel SVG face from it at render time. Zero assets.

## What's done vs. what's next

### Done (Cases 1–3, greybox)

- Core loop: **breach → read → intercept/pursuit → choice → debrief**
- Backstory intro for Rook (Case 1 only) — 7 beats, chapter cards + portraits
- Character faces in all dialogue (procedural SVG, no photography)
- Two-tier breach mechanic: heavy containers (CRATE/LOCKER/DUFFEL/SAFE)
  crack on first hit, shatter on second, reveal an inner item that needs
  a bag tap. Light containers still one-tap. Some empty heavies as red
  herrings.
- Mirror tracking wired for smash-vs-precise, roadblock placement,
  hesitation, swipe bias
- Panel-mash guard (360ms pointer lock after any panel opens)
- Hot reload via `window.claude.hot.snapshot()`/`ready()`

### Next (per user feedback and ROADMAP)

**Immediate — scene-type variety for Cases 4–10.** Not every case should
be a chase. The design doc's scene-type table has stakeout, interrogation,
forensics-lab, courtroom, tail-in-traffic, night-market-shakedown. Build
templates for at least two of these before Case 4. Do NOT restructure
Cases 1–2, which are already tested — earn variety in new episodes.

**Immediate — art-style spike.** Before continuing content, rebuild ONE
scene in the target Arcane-style brick-voxel look so we can eyeball the
delta from placeholder → final. Suggested target: Case 1 breach (the
sunlit stall interior). Judge fidelity, then decide budget for a full
art pass.

**Medium — Act 2 episodic build (per ROADMAP § Build plan).** Cases 4–7
released as episodes every 3–4 weeks. Each episode adds one new district,
one new scene template, one new mechanic hook that pays off in Act 3.

**Long — Act 3 payoff.** The villain uses `S.mirror` against the player.
The Mirror system must be RECORDING correctly through Acts 1–2 or Act 3
lands hollow. Any new mechanic added to Cases 4–7 should also feed
`S.mirror` when the player uses it.

## Working conventions

- **One file.** Don't split into modules until we've locked scope. A
  single searchable file has been the right call so far — grep is fast,
  hot reload is instant, and nothing gets lost across imports.
- **Data-driven cases.** New cases live in `CASES[]`. New scene TYPES are
  the only reason to touch `TEMPLATES`. If you find yourself editing
  engine code to add a case, stop and ask whether it should be a template
  instead.
- **Playtest before you polish.** Playwright headless walkthroughs against
  the pinned Chromium at `/opt/pw-browsers/chromium-1194/chrome-linux/chrome`
  catch real bugs (chase gap never closing, panel mash blowing through
  decisions, breach layout too dim). Test in a 390×844 viewport.
- **Don't take real photographs of people.** Faces are procedural SVG.
  Voice lines are text with portraits — the user explicitly signed off on
  "no real recordings needed."
- **Ugly is fine.** Everything in the greybox is meant to be replaced by
  the art pass. Focus on feel, not finish.

## For the human picking this up

The user (Alex) plays and gives feedback in short, direct chunks. Ship
working updates first, discuss second. When something needs a decision
that could go either way, ask ONE clear question — don't dump options.
The last feedback verbatim was:

> "okay okay, honestly, it's all very interesting, but I hope that's not
> what the graphics would look like? they need to be more immersive. plus
> before starting the user needs to know the backstory of his character.
> but this is very nice the convos don't even need real recordings of
> people talking. it's nice the way it is (maybe we just add faces and
> that's it), though not all scenes should be chasing and we need to make
> the evidence smashing more interesting. (it's nice but could be
> better), the decisions were the heavy hitters. damn. I felt the
> dopamine. I think we can start with this. It's definitely not boring."

Backstory intro, faces, and layered smashing are done as of the last
push. Scene variety and art-style spike are the next asks.
