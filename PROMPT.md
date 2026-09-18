# Kickoff prompt for Fable

Paste the block below as your first message to Fable in a fresh Claude
Code session, from inside a clone of this repo. It gives Fable everything
it needs to hit the ground running without you having to re-explain the
project.

---

I'm Alex. I'm handing you a game project called **COLD READ** — a
brick-voxel detective/crime game for mobile. There's a playable
HTML5-canvas greybox of Cases 1–3 in this repo (`index.html`). It's
throwaway; the loop works, the graphics are placeholder.

Your job: **build Act 1 (Cases 1–3) as a real mobile game we can ship
to a phone.** Acts 2 and 3 come later.

Read these first, in this order, before doing anything else:

1. `CLAUDE.md` — brief for you. Where things stand, what must survive
   the port, working conventions.
2. `ROADMAP.md` — the full design doc: pitch, hooks, core loop, world,
   cast, choice system, all 10 cases across 3 acts, monetization,
   sound, art, legal, build plan. Long but every section matters.
3. `README.md` — greybox architecture and how it runs.

Three constraints to build against from day one:

- **Landscape orientation.** The greybox is portrait. That was a
  shortcut for prototyping. Every layout you build is landscape from
  now on.
- **Richer controls than the greybox.** Tap alone is not enough for a
  real mobile game. I want gestures — drag, hold-vs-tap, swipe
  direction as a meaningful choice, two-thumb layouts where they
  earn their place. Consider tilt for pursuits or aiming — pitch it
  to me, don't ship it without asking.
- **The Mirror system has to keep recording.** `S.mirror` in the
  greybox tracks player habits across the whole game. Act 3's payoff
  depends on it. Every new mechanic you add must feed it.

Your first tool use should NOT be a code edit. It should be asking me
one question: **what engine do we build in?** Read `CLAUDE.md` §"The
first decision" for the options and your default recommendation.
Recommend, ask, wait for my answer. Then plan.

Once we've agreed the engine, ship the smallest playable slice on a
real phone (Case 1: intro + cold_open + foot_chase, landscape) before
touching Case 2. I will play it and tell you what's wrong. Iterate on
what I actually say, not on what you think I meant.

I value directness, working output over analysis, and honest pushback
over reassurance. If I'm about to make a mistake, say so.
