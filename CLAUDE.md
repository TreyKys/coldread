# Brief for the next Claude (Fable, or whoever picks this up)

You've inherited a game project called **COLD READ** — a brick-voxel
detective/crime mobile game. The user (Alex, based in Lagos, GitHub
`TreyKys`) is solo-building it under NeuroDev Labs. He is direct, wants
working output over analysis, and prefers honest pushback over
reassurance. Match that. Don't preamble, don't restate his messages, and
don't dump options when one call would do.

## Where things stand

- **`index.html`** — a playable HTML5-canvas greybox of Cases 1–3.
  Single file, no build step. Runs on any static server or by opening
  the file. Live at https://claude.ai/artifact/MpmWpoXrt3XiFfESddLUdG.
- **`ROADMAP.md`** — full design doc: pitch, hooks research, core loop,
  world, cast, choice system, all 10 cases across 3 acts, monetization,
  sound, art, legal, build plan. Read this before making design calls.
- **`README.md`** — architecture, run/publish instructions, done vs. next.
  Read this before touching code.
- **`PROMPT.md`** — the kickoff prompt Alex used to hand this off; use it
  to understand what scope he actually wants next.

The greybox exists to prove the loop is fun before spending on art. It
worked — his exact words: *"the decisions were the heavy hitters. damn.
I felt the dopamine. I think we can start with this. It's definitely not
boring."*

## What Alex actually asked for next

Verbatim from the handoff:

> "the prompt for Fable to build the whole mobile game (at least Act 1
> first, the rest coming soon....) and also there should be more controls,
> not just taps. more in (the game is played on landscape not portrait
> mode)"

Three real asks in that:

1. **Build Act 1 as a real mobile game**, not just a browser prototype.
   Cases 1–3, shippable to a phone. Acts 2–3 later.
2. **Landscape orientation** — the greybox is portrait. That's wrong for
   the final product. Everything gets re-tuned for landscape.
3. **Richer input** — currently just taps + a few swipes. Add real
   gestures: drag, hold-vs-tap, two-thumb layouts, swipe direction as
   meaningful choice. Possibly tilt/gyro for pursuits or aiming. Let the
   scene type dictate the gesture, not the reverse.

## The first decision (make it with Alex, don't decide alone)

**What do you build Act 1 in?** The greybox is HTML5 canvas. That won't
scale to the brick-voxel art target, mobile store distribution, or
gyro/haptics. Real options:

- **Godot 4** — open source, first-class mobile export (Android + iOS),
  has voxel/GridMap tooling, GDScript is fast to iterate in. Best fit
  for the Arcane brick-voxel look on a solo-founder budget.
- **Unity** — huge ecosystem, best mobile toolchain, but licensing +
  monetization overhead grows with revenue. Overkill for the scope.
- **Flutter + Flame** — 2D-friendly, single codebase, but the brick-voxel
  aesthetic wants a real 3D pipeline underneath.
- **Keep HTML5 canvas + Capacitor/Cordova wrapper** — fastest to ship
  something to a phone this week, but every graphics improvement fights
  the browser. Dead end for the art vision.

Ask him. Recommend Godot 4 as the default unless he pushes back —
solo-founder, open source, voxel-native, ships to both stores, and the
data-driven scene architecture (`CASES[]` + `TEMPLATES.*`) ports cleanly
to a Node/Resource pattern in Godot.

## What must not get lost in the port

The greybox has real design work already done. When you rebuild in whatever
engine, these are the things that MUST survive:

- **The five scene types that work:** cold_open, breach, read, chase
  (foot + pursuit), choice, debrief. The greybox's `TEMPLATES.*` are
  the reference implementations.
- **The Mirror system.** `S.mirror` tracks player habits across the whole
  game — smash-vs-precise, roadblock placement patterns, hesitation
  count, swipe direction bias. This is the Act 3 payoff: the villain uses
  the player's own patterns against them. If you don't record it through
  Acts 1–2, Act 3 lands hollow. Every new mechanic must feed the mirror.
- **Data-driven cases.** `CASES[]` is pure data — one array of case
  objects, each a list of scene configs. Cases 4–10 must be addable
  without touching engine code. Port this contract carefully.
- **The intro sequence for Rook** (Case 1's `intro` scene) — patrol
  officer, cousin Nkem's cold case, why he joined INTERCEPT. That
  backstory is load-bearing for the third-act reveal.
- **Portraits over voice.** Alex explicitly signed off on: no real voice
  recordings, text lines + character portraits are enough. Do not add
  voiceover unless he asks for it.
- **The choice grammar.** Choices carry `trust` (with the four
  factions), `mirror` (habit tags), and consequences that resurface
  cases later. See ROADMAP § Choice system.

## What can be redone from scratch

- Rendering. All of it. The canvas 2D draws (`proj`, `iso`, `roadBox`,
  procedural SVG portraits) are throwaway placeholders.
- Input plumbing. Currently pointer events + a few keyboard fallbacks.
  Real mobile input is different — replace it.
- State persistence. Currently `localStorage` under `'coldread.gb'`.
  Real game needs a proper save system with cloud sync (see ROADMAP §
  Monetization for why — revives, gems).
- The Playwright test harness. Not portable. Use whatever the target
  engine provides.

## Working conventions

- **Data-driven first.** New cases must be data, not code. If you find
  yourself writing a case class, you've broken the architecture — cases
  are configs, scene types are the code.
- **Playtest before you polish.** Alex plays every build. Ship a rough
  version he can actually play in a day, then iterate on what he says.
  Don't build in a cave for a week.
- **Landscape, always.** The greybox is portrait. That was a shortcut.
  Every layout you build is landscape from now on.
- **One-tap start.** Alex opens the game and is in a case within 60
  seconds. No login, no tutorial wall, no launcher animation on the
  first play.
- **Ask one clear question when blocked.** Never dump three options with
  paragraphs each. Recommend, and only ask if it's a call only Alex can
  make (auth, spend, business direction, art direction he hasn't set).

## First steps when you open this repo

1. Read `ROADMAP.md` end to end. It's ~55KB, worth it.
2. Read `README.md` for the greybox architecture.
3. Read the last section of `PROMPT.md` for the kickoff scope.
4. Ask Alex the engine question above.
5. Once decided, build the smallest playable slice: Case 1's intro +
   cold_open + foot_chase, in landscape, on a real phone. Ship that
   before touching Case 2. He will tell you what's wrong before you're
   done — listen to that first.
