# COLD READ — Google Stitch prompt pack

Everything needed to design the full game UI in Google Stitch: the design
system, every screen, every state, with real copy. Paste the prompts in order.

---

## How to use this (read once)

**Order matters.** Paste **Prompt 0** (the design system) first. Then
**Prompt 1** (component sheet) so the system is locked before any screen
exists. Then the screen batches, 2 → 13, one at a time. Each batch is
self-contained and starts with a one-line style anchor, so Stitch stays on
system even when it loses earlier context.

**Landscape is the part Stitch will fight.** Its mobile mode usually makes
portrait phone frames. If that happens:
- Use the web/desktop canvas and ask for **844×390** artboards (a landscape
  phone, the tightest real size). Then check key screens at **1280×720**.
- Keep the word "landscape" in every prompt. The batches already do.
- Regenerate any screen that comes back portrait. Don't try to fix it by hand.

**Only one portrait frame exists:** the "turn your phone" screen in Batch 2.

**Keep the copy.** Every batch gives real game copy. If Stitch swaps in lorem
ipsum or generic app words ("Dashboard", "Profile settings"), regenerate.

**No app chrome.** This is a fullscreen game. No OS status bar, no browser
bar, no bottom tab bar, no hamburger menu. If Stitch adds them, say
"remove system and app chrome, this is a fullscreen game".

**Export for the build.** Export to Figma (or HTML) when a batch is right.
The Godot build rebuilds these as a Godot Theme plus Control scenes. Stitch
output is the visual target, not shipped code. Section "Handoff to
Antigravity" at the end covers that step.

**If a prompt gets cut off**, split it at a screen boundary and send the
second half as "continue the same batch".

---

## Prompt 0 — Design system (paste first)

```
Design the complete user interface for COLD READ, a mobile action-detective game.

ORIENTATION: LANDSCAPE ONLY. Every screen is a landscape phone artboard, 844×390, and must also scale to 1280×720. Fullscreen game: no OS status bar, no browser bar, no tab bar, no hamburger menu.

THE GAME: You are Rook, the newest detective in INTERCEPT, a fast-response police unit in Lagoon City — a fictional West African coastal megacity of open-air markets, tower blocks, docks, a lagoon and long bridges (Lagos-inspired, invented, respectful). The world is chunky brick-voxel 3D built from our own smooth bricks. The loop: smash a crime scene apart to find evidence → read the evidence in seconds → predict the escape route → chase the suspect down. Timed story choices change who stands with you and how the city looks, never difficulty. Secretly, the villain is studying how you play, and in the final act she quotes your habits back at you.

VISUAL DIRECTION: "Tactical case file meets toy city at dusk." Dark, cinematic, confident, warm. Flat color fills and crisp 1px hairlines. No glassmorphism, no heavy blur, no neon cyberpunk, no paper textures, no drop-shadow soup. Signature shape: every button and panel is a BRICK — a rectangle with 3px corner radius and one small square notch (6px) cut out of its top-right corner. Never draw studs on bricks.

COLOR TOKENS (use exactly, name them like this):
bg #0A1013 · surface #121C22 · surface-raised #19262D · line #2B3C45 · line-strong #3A4E59
text #E4EDF0 · text-muted #7C939E · text-dim #576B75
intercept-orange #FF6A2B — primary actions, the player's unit and tools
evidence-teal #45D6C6 — evidence, clues, information
danger-red #EF4D63 — timers, decisions, planted evidence, failure
success-green #93D651
reward-gold #F2C14E — stars, coins, rewards (also the yellow of city minibuses)
Color rules: at most one orange primary button per screen. Teal only for evidence and information. Red only for time pressure and danger. Never use color alone to carry meaning — pair it with an icon or a word.

TYPE:
Barlow Condensed (Bold / SemiBold) — headings, HUD, buttons. Buttons and HUD labels in UPPERCASE with wide letter-spacing.
Barlow (Regular / Medium) — dialogue and body text.
JetBrains Mono — small labels, counters, timers, eyebrow lines above headings. UPPERCASE, wide letter-spacing.
Sizes at 844×390: display 44–56, H1 28, H2 20, dialogue 17–19, body 14–15, smallest label 10–11.

LANDSCAPE LAYOUT RULES:
- The center ~60% of the screen is the game world. During action, never cover it.
- HUD hugs the edges in thin strips.
- Main thumb zones are the bottom-left and bottom-right corners. Top-center shows information only.
- Safe area: 44px inset on left and right (camera notch), 20px at the bottom.
- Touch targets at least 48px. Action buttons during gameplay 64–88px.
- Panels over gameplay slide in from the right over a left-to-right dark gradient scrim, so the world stays visible on the left.

TWO VISUAL VOICES:
1) INTERCEPT — the player's side. Gritty, condensed type, orange, chunky bricks.
2) SIGHTLINE — the city's prediction software, secretly made by the villain. Thin rounded type, sterile white and teal, soft "most likely" glows, perfectly clean. It should look helpful and a little too clean. Use it only for prediction overlays (likely routes, "most likely" tags, predicted positions).

CHARACTERS: portraits are square blocky voxel heads (rounded-corner cubes, never cylinders), in a 1px square frame on surface-raised. Speaker name in orange Barlow Condensed caps, role below in JetBrains Mono caps. No photos. There is no voice acting: dialogue is text + portrait.

ICONS: 2px stroke line icons on a 24px grid, square caps. Recurring motif: a small red paper kite — the signature the kidnapping gang leaves at every scene.

NEVER: the word LEGO, studded bricks, minifigure-shaped people, real police badges or logos, blood, weapons aimed at people (the player aims at tires, locks and remotes), loot boxes, fake countdown timers, hidden close buttons. The INTERCEPT badge is our own: a hexagonal shield with a crosshair inside.

Confirm the system, then wait for the next prompt.
```

---

## Prompt 1 — Component sheet

```
COLD READ — landscape 844×390 artboards, fullscreen game UI. Use the COLD READ design system (tokens, brick buttons with top-right notch, Barlow Condensed / Barlow / JetBrains Mono).

Create a component sheet across 2–3 artboards. Show every state side by side and label each one in JetBrains Mono.

BUTTONS (brick shape, top-right notch):
- Primary: orange fill, dark text. States: default, pressed (1px lower, darker), disabled (30% opacity), loading.
- Ghost: transparent, 1px line-strong border, light text.
- Info: teal fill. Danger: red fill.
- Locked: surface fill, padlock icon, "LOCKED" label, reason under it ("Need 6 ★").
- Gameplay action buttons, 64–88px: RAM (orange, fist-into-brick icon), NITRO (gold, circular charge ring around it, "HOLD" label), TRACE (teal pulse icon, charge ring), EYE (teal drone icon), HOLD (teal hand icon). Each shows states: ready, charging (ring partly filled), used (dim), pressed.

METERS AND BARS:
- Timer bar: orange; turns red with a pulse under 8 seconds. Show full, half, low.
- Chase gap meter: a horizontal track with a runner icon on the left closing on a suspect icon on the right, distance label "GAP 12m".
- Suspect HP pips: 3–4 brick pips, filled and broken.
- Choice countdown: a red bar draining left to right.
- Rank progress bar with rank names at both ends.

CHIPS AND BADGES: coins chip (gold), gems chip (teal gem), rank badge (hexagon shield + "ROOKIE"), star rows 0/1/2/3 (gold 5-point stars, empty ones in line color), district tag chips ("MARKET MILE · DUSK").

PANELS: surface panel, raised panel, right-side slide-in panel with gradient scrim, centered modal, full-bleed title card.

DIALOGUE BOXES: (a) speaker portrait left + name + role + text, (b) speaker portrait right, (c) narration with no portrait and an orange eyebrow line, (d) cinematic subtitle strip at the bottom of the screen with a small portrait.

EVIDENCE CARD: tag in mono ("DIGITAL", "TRACE", "DOCUMENT"), name in Barlow. States: default, selected (orange border), being dragged (rotated 3°, lifted shadow), used (dim), planted (red tag "PLANTED" + small warning icon).

SENTENCE SLOT (for fill-in-the-blank deduction): empty (dashed underline "?????"), armed (orange underline + tint), hovered by a dragged card (teal glow), filled (teal text), graded correct (green check), graded wrong (red cross + correct answer).

CHOICE CARD: large brick card for left or right option, arrow toward its screen edge, label "SWIPE LEFT" / "SWIPE RIGHT" in mono.

GESTURE HINTS: big translucent white arrows with a hand icon for swipe left, swipe right, swipe up, swipe down, hold, drag, two-finger drag. Short label under each ("SWIPE UP · VAULT").

TOASTS: autosave ("SAVED · CHECKPOINT"), ability ready ("TRACE READY"), story echo ("Dash will remember that."), reward ("+120 COINS").

ICON SET (2px line): pause, settings, back, close, star, coin, gem, padlock, evidence bag, magnifier, fist, drone, pulse, hand, roadblock barrier, map pin, bridge, siren, ad (play-in-square), share, red paper kite, INTERCEPT hex badge.
```

---

## Prompt 2 — The first 60 seconds

> First launch has no menu. The player is inside Case 1 within seconds.

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system (tokens, brick-notch buttons, Barlow Condensed / Barlow / JetBrains Mono). Real copy below; don't replace it.

Screen 2.1 — TURN YOUR PHONE (the one PORTRAIT frame, 390×844). Shown only when the phone is held upright. Dark bg. An outlined phone icon rotating to landscape, orange stroke. "Turn your phone sideways" in Barlow Condensed. Under it in mono: "COLD READ PLAYS IN LANDSCAPE".

Screen 2.2 — BACKSTORY CHAPTER CARD. Background: dim placeholder of a brick-voxel open-air market at dusk, warm gold light. Center: thin hairlines above and below, mono eyebrow "ONE YEAR AGO", title "Market Mile · patrol beat". Narration below: "You were a patrol officer walking the fruit lanes. You knew every stall by the fruit they would not sell you." Bottom-right: CONTINUE (primary). Bottom-left: BACK (ghost). Top-right, small: "SKIP" in mono. Bottom-center counter "1 / 7".

Screen 2.3 — BACKSTORY DIALOGUE. Same backdrop. Right-side slide-in panel: Rook portrait, name "ROOK (YOU)" in teal, role "YOU". Text: "My cousin Nkem was thirteen. Her case is still open. Cold, they call it. So I put in for detective. Then INTERCEPT. Then here." Counter "3 / 7". CONTINUE bottom-right. Second variant of the same screen with Commander Ifeoma Nwosu: "Rookie. Callsign Rook. Welcome. Try not to become a cold case yourself before lunchtime."

Screen 2.4 — COLD OPEN. Cinematic: black letterbox bars top and bottom (12% each). World placeholder: a red van cutting off a bike taxi in a brick market lane at dusk. Subtitle strip over the bottom bar: small Dash portrait + "DASH" + "Rook — go! I'm on the wheel, you're on the ground. MOVE." Tiny mono hint at right: "TAP TO CONTINUE".

Screen 2.5 — FOOT CHASE HUD with tutorial. World placeholder: behind-the-shoulder view of a brick-voxel runner sprinting down a market lane, fruit stalls both sides, a masked suspect ahead. HUD: top-left pause icon only. Top-center: chase gap meter (runner icon closing on suspect icon, "GAP 14m"). Center-right: one large translucent tutorial arrow pointing up with a hand icon and label "SWIPE UP · VAULT". Bottom-center: three small lane pips, middle one lit. Nothing else on screen.

Screen 2.6 — TACKLED. Frozen frame of the tackle, slightly darkened. Right-side panel: teal eyebrow "TACKLED", title "Tackled in the fruit stalls", text "The goon goes down over a crate of oranges. His delivery cart is still standing, two stalls back." Three gold stars. Mono "0 COLLISIONS". CONTINUE bottom-right.
```

---

## Prompt 3 — Breach (smash-search)

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 3.1 — BREACH HUD. World placeholder: isometric brick-voxel interior of an abandoned market delivery cart area — crates, sacks, a locker, shelves, warm dusk light. One heavy crate shows a cracked texture with a small floating label "HIT AGAIN". One broken container shows a glowing teal item above it with label "TAP TO BAG".
HUD: top-left mono "THE ABANDONED DELIVERY CART". Top-right: timer bar with "0:21". Bottom-left: evidence bag — three diamond slots, one filled teal and glowing. Bottom-right: TRACE button (teal, charge ring full, label "TRACE") with a small "SWIPE UP" hint. Bottom-center hint strip in mono: "TAP TO SMASH · HOLD TO FOCUS · TWO FINGERS TO SWEEP". Pause top-left corner.

Screen 3.2 — TRACE ACTIVE. Same scene with a teal pulse ring spreading from the center. Containers holding real evidence tinted teal. One tinted red with tag "PLANTED". Top-right toast: "TRACE · TEAL = EVIDENCE · RED = PLANTED".

Screen 3.3 — EVIDENCE FOUND. A compact evidence card popping next to the evidence bag: tag "DIGITAL", name "Burner phone", one line "Sightline Maps open. Pinned: Skyway Exit 4." Bag slot 2 just filled. Second variant, a planted item: red tag "PLANTED", name "Boarding pass (dated tomorrow)", line "Printed with tomorrow's date. Someone wanted you to find this."

Screen 3.4 — SCENE CLEARED. Right-side panel over the darkened room: eyebrow "SCENE CLEARED", title "The abandoned delivery cart". A list tile: rows "EVIDENCE · Burner phone" (teal), "EVIDENCE · Bridge toll token" (teal), "FLAGGED · Boarding pass" (red). Muted line: "1 piece of evidence still in there. The read will be harder." Star row (2 of 3). CONTINUE.
```

---

## Prompt 4 — The Read (deduction)

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 4.1 — THE READ. Full screen, bg with a faint grid. Top-left: teal eyebrow "THE READ", title "They planted something. Read past it." Top-right: small timer-free note in mono "NO TIMER · TAKE A BREATH".
Middle: one large sentence strip across the screen in Barlow Condensed 24: "The hostages are at [ _____ ] because of [ _____ ] and [ _____ ]." First blank filled with teal text "The container stack". Second blank glowing teal because a card is being dragged over it.
Bottom: a horizontal tray of evidence cards (tag + name): "TRACE · Container rust flakes" (lifted, rotated 3°, mid-drag), "DOCUMENT · Manifest: Container 9", "SIGNATURE · Red paper kite", "PLANTED · Boarding pass (dated tomorrow)" with a red tag and a small tell icon, "LOCATION · The airport".
Bottom-right: LOCK IT IN (primary). Above it: ghost button "INSIGHT" with ad icon and sublabel "greys out one wrong card". Bottom-left: CLEAR (ghost).

Screen 4.2 — READ GRADED, three variants:
SOLID: teal eyebrow "READ GRADED", title "Solid read" with a check icon, text "Every link holds. The chase starts on their bumper." Rows: each blank with a green check.
SHAKY: gold, title "Shaky read" with a tilde icon, text "Close, but one link is wrong. You start mid-distance." One row red with the correct answer after an arrow.
COLD: red, title "Cold read" with a cross icon, text "The evidence does not say that. You start far back, and they have an escort."
Each variant has MOVE (primary) bottom-right.
```

---

## Prompt 5 — Intercept (predict the route)

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 5.1 — INTERCEPT BRIEF. Right-side panel over a blurred map: eyebrow "INTERCEPT", title "Where do they run?", text "The convoy splits three ways out of the Stacks. Sightline is glowing one route as most likely. Trust it — for now." OPEN THE MAP (primary).

Screen 5.2 — INTERCEPT MAP. Top-down flat stylized city map: dark district blocks, the lagoon in deep teal-grey, three bridges, simple roads. Origin: a pulsing orange dot bottom-center. Three escape routes as lines fanning outward; line thickness shows likelihood. The thickest route is drawn in the SIGHTLINE style (thin white core, soft teal glow) with a small rounded Sightline tag "MOST LIKELY · 61%". Route end labels in mono: "LIFT BRIDGE", "BACK STREETS", "SKYWAY RAMP".
Bottom-left: a roadblock tray holding 2 draggable barrier tokens, label "ROADBLOCKS · 2". One token being dragged onto the Back Streets route, which highlights. Bottom-right: EYE ability button (teal drone, "CONFIRM ONE ROUTE") and COMMIT (primary). Top-left: mono "THICKER LINE = MORE LIKELY".

Screen 5.3 — RESULT, two variants.
CUT OFF: the suspect blip stopped at an orange barrier; right panel teal eyebrow "CUT OFF", title "Dock bridge", text "Your roadblock forced the detour. The pursuit starts close." PURSUE (primary).
MISSED: blip passing through an open route; eyebrow red "MISSED", title "Yard lanes", text "They took a route you left open. You start behind." PURSUE.
```

---

## Prompt 6 — Pursuit (two-thumb driving)

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 6.1 — PURSUIT HUD. World placeholder: low three-quarter chase camera behind a brick-voxel police cruiser with an orange/teal siren bar, racing through market traffic at dusk; a red van ahead shedding bricks.
LEFT THUMB (bottom-left quadrant): steer zone, faint left and right chevrons, mono "SWIPE TO STEER · DRIFT".
RIGHT THUMB (bottom-right): big RAM button (88px, orange, fist icon). Above it, the NITRO button (64px, gold, circular charge ring 70% full, label "HOLD").
Top-center: suspect bar — van icon, 3 brick HP pips (one broken), "GAP 9m".
Top-left: pause icon, and next to it a small radio bark card: Dash portrait + "Hold it! Hold the button!".
Floating near center-right, small: "NEAR MISS +50" in gold.
Keep the center clear.

Screen 6.2 — RAM IMPACT. Same HUD, a brief white hit flash at the edges, "RAM · 2 TO GO" in the center-top area, one more HP pip broken.

Screen 6.3 — LEFT-HANDED LAYOUT. The same HUD mirrored: RAM and NITRO bottom-left, steer zone bottom-right. Mono tag top-right "LEFT-HANDED LAYOUT".

Screen 6.4 — THEY LOST YOU (revive). Darkened frozen chase. Center modal: red eyebrow "SQUAD DOWN", title "They lost you", text "You restart at the top of this scene either way." Buttons: "REVIVE HERE · WATCH AD" (primary, ad icon, sublabel "first revive in a case"), "REVIVE · 10 GEMS" (ghost, gem chip), "RESTART SCENE" (ghost). Visible close. No countdown.
```

---

## Prompt 7 — Standoff and the Choice

> The ROADMAP calls the choices "the heavy hitters". Give these the most care.

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 7.1 — STANDOFF. Slow motion: world placeholder of a crane gantry in heavy rain at night, desaturated, faint horizontal slow-motion streak lines. A suspect on the gantry holding a small remote. Three target reticles (thin circle + crosshair) with labels: "SPOOL", "THE REMOTE", "CRANE CABLE". Top-center: red timer "5.0s" and a heartbeat line. Bottom-left: round thumb pad "HOLD TO STEADY". Mono hint bottom-center: "TAP THE RIGHT TARGET". The player aims at objects, never at the person.

Screen 7.2 — THE CHOICE. The world freezes behind a dark scrim. Top: red mono eyebrow "DECISION". Prompt centered in Barlow Condensed 24: "Kemi Hart is live-streaming you. 12.4k watching." Small Kemi portrait next to it with a red "LIVE" dot. Under the prompt: a full-width red countdown bar, 70% remaining.
Two large brick choice cards fill the lower screen, left and right. LEFT: arrow pointing left, mono "SWIPE LEFT", label "GIVE HER AN EXCLUSIVE". RIGHT: arrow pointing right, mono "SWIPE RIGHT", label "SEIZE HER PHONE". A thin divider between them.
Footer in muted text: "Choices change who stands with you and how the city looks. Never difficulty."

Screen 7.3 — MID-SWIPE. The left card dragged 30% toward the left edge, tilted, its border glowing orange; the right card dimmed.

Screen 7.4 — YOU HESITATED. The countdown bar empty. Red eyebrow "YOU HESITATED". Title "Dash steps in and takes the phone himself." Muted: "Nobody looks good. Hesitation is its own answer, and the squad noticed."

Screen 7.5 — AFTERMATH. The chosen card enlarged on the left: "GIVE HER AN EXCLUSIVE", result "She cuts the live feed and walks with you instead." Toast: "Kemi will remember that." Right side, small: "38% OF DETECTIVES DID THE SAME" with a thin split bar 38 / 62. CONTINUE.
```

---

## Prompt 8 — End of case

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 8.1 — DEBRIEF. Two columns.
Left column: orange eyebrow "DEBRIEF · RANK 1 · ROOKIE", title "You lost the victim", three gold stars (2 filled), then a quote block with Commander Ife's portrait: "First day, and you lost her."
Right column: a tile of rows — "KEMI HART · Ally", "VICTIM · Funmi Adeyinka — still missing" (red), "SIGNATURE · Red paper kite" (teal). Under it: coins chip "+120" and a small ghost button "DOUBLE IT · WATCH AD". CONTINUE (primary) bottom-right.

Screen 8.2 — DEBRIEF WITH THE MIRROR (Act 1 finale version). Same layout, title "Act 1 · The Kites". A second tile with a muted eyebrow "THE MIRROR IS WATCHING": rows "BLOCKS BRIDGES · 3", "BLOCKS BACK STREETS · 1", "SMASHES EVERYTHING · 2 vs 1 precise", "HESITATED · 1". Style this tile a little colder — a faint Sightline teal hairline — as if something else is reading it too.

Screen 8.3 — CLIFFHANGER. Near-black. A caught gang member behind interview-room glass, reflection of Rook faint in it. Red mono eyebrow "CLIFFHANGER". Line in Barlow 19: "You did not lose her. You were shown where to look." Then, on its own, the title card "COLD READ" in large Barlow Condensed with the red paper kite icon.

Screen 8.4 — PROMOTION. Center: large INTERCEPT hex badge. Eyebrow "PROMOTED". Title "CONSTABLE". Rank progress bar from ROOKIE to CONSTABLE, full. Unlock row: Patch portrait + "PATCH JOINS · TRACE". Reward row: "NEW OUTFIT · Night Patrol jacket". CONTINUE.

Screen 8.5 — ACT TITLE CARD. Full-bleed, dark, one thin orange hairline. "ACT II" in mono, "TOLLGATE" in huge Barlow Condensed. Subline: "The client pays in maps."
```

---

## Prompt 9 — Case Board (the hub) and pause

> The hub appears only after Case 1 ends. It is never the first screen.

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 9.1 — CASE BOARD (home hub). Dark case wall.
Top-left: Rook portrait, rank badge "CONSTABLE", rank progress bar to "DETECTIVE".
Top-right: coins chip "1,240", gems chip "35", settings icon.
Center: a horizontal row of case files drawn as dark brick folders, joined by thin red thread between small red paper kite pins, like a conspiracy wall.
- "01 · SNATCH" — done, ★★★, stamp "CLOSED".
- "02 · RED LIGHT" — current, glowing orange edge, "CONTINUE · CHECKPOINT: READ".
- "03 · THE WORKSHOP" — locked, padlock, "UNLOCKS AFTER CASE 2".
- A 4th folder mostly out of frame, "ACT II · COMING SOON".
Bottom-left: a tile "STREET CALLS" with a chip "HOT CALL · RAIN" and "3 NEW".
Bottom-right icon cluster: SQUAD, EVIDENCE LOCKER, SHOP.
Primary button: "CONTINUE CASE 2" bottom-right above the icons.

Screen 9.2 — CASE BRIEFING (a case file opened). Left 45%: district image placeholder — brick-voxel tower blocks at night, laundry lines, sodium-orange light — with a district chip "THE STACKS · NIGHT". Right: eyebrow "CASE 02", title "Red Light", logline "Every light on Dayo Sanni's street turned green at once. Then he vanished." Meta row: "~6 MIN", "RANK REWARD · CONSTABLE". A row of scene icons in order: cold open, breach, read, foot chase, intercept, pursuit, choice, debrief — completed ones teal, current one orange. Buttons: "RESUME · READ" (primary), "RESTART CASE" (ghost).

Screen 9.3 — PAUSE. Frozen gameplay on the left under the gradient scrim. Right panel: title "PAUSED", buttons stacked: RESUME (primary), RESTART SCENE, SETTINGS, QUIT TO CASE BOARD. Muted line: "Progress saves after every scene."
```

---

## Prompt 10 — Squad, evidence, Rook

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 10.1 — SQUAD. Header: Commander Ifeoma Nwosu portrait small, "INTERCEPT · SQUAD". A row of member cards, each with portrait, name, role and ability chip:
- DASH (Kojo Mensah) · Partner, driver · NITRO — "Trusts you"
- PATCH (Dr. Amara Okafor) · Forensics · TRACE — "Watching you"
- JUNO (Juno Bello) · Hacker · EYE — "New"
- Two locked silhouettes: "JOINS IN ACT II".
Relationship is shown in words, never numbers (Trust is hidden).
Tapping a card shows a right panel with the ability explained: "TRACE — a pulse that reveals hidden evidence and marks planted items. One charge per scene."

Screen 10.2 — EVIDENCE LOCKER. Tabs by case "CASE 01 / 02 / 03". A grid of collected evidence cards with small voxel item thumbnails. Some slots empty with dashed outlines "NOT FOUND". One special tile: "DEEP FILE · ADA VOSS" with a gem price chip and lock — extra lore scene, cosmetic only.

Screen 10.3 — ROOK. Left half: a large 3D preview area of the Rook figure (blocky voxel detective, chunky two-block legs, mitten hands, square head), on a turntable. Right half: tabs "OUTFIT / HEAD / BADGE FRAME / SIREN SOUND". A grid of options, some owned, some with coin or gem chips. Callsign fixed at the top: "ROOK".
```

---

## Prompt 11 — Street Calls, shop, ads

> Monetization rules from the ROADMAP are hard rules. Nothing for sale changes
> a choice or makes a case easier. No loot boxes. No fake timers.

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 11.1 — STREET CALLS. Title "STREET CALLS" and a streak chip "STREAK · 4 DAYS". Three call cards in a row: each has a crime type ("BAG SNATCH", "SHOP ROBBERY", "STOLEN CAR"), district chip, "2–4 MIN", reward chips (coins, stars). One card larger with a red chip "HOT CALL · RAIN". Right side: a tall "MOST WANTED" poster card for the weekly boss call — silhouette of a getaway bike, "ENDS IN 3D 4H".

Screen 11.2 — SHOP. Tabs "FEATURED / GEMS / LOOKS / NO ADS". Featured: a "STARTER PACK" card (gems + Rook outfit + cruiser skin, "$1.99", real deadline "72H LEFT"), gem packs in 4 tiers, a "NO ADS · $3.99" card. A plain line at the bottom in muted text: "Nothing here changes a choice or makes a case easier."

Screen 11.3 — CASE PASS. A horizontal reward rail with two tracks, "FREE" and "PREMIUM", tiers 1–30, rewards are cosmetics only (outfits, siren sounds, smash effects like "GOLD BRICKS", Mirror card frames). Current tier highlighted.

Screen 11.4 — MODALS, three:
(a) Insight hint: "Watch a short ad for an Insight? It greys out one wrong card. It never solves the read." Buttons "WATCH AD", "NO THANKS". Equal visual weight for both.
(b) Purchase confirm: item, price, "BUY", "CANCEL".
(c) No Ads offer: "Tired of ads between Street Calls?" "REMOVE ADS · $3.99", visible close top-right.
```

---

## Prompt 12 — Settings and system

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Screen 12.1 — SETTINGS. Left rail tabs: AUDIO, CONTROLS, DISPLAY, STREAMING, ACCOUNT, LANGUAGE. Content on the right.
AUDIO: sliders MUSIC, EFFECTS, RADIO BARKS.
CONTROLS (show this tab): toggles "HAPTICS", "LEFT-HANDED LAYOUT", "TILT TO STEER (EXPERIMENTAL)", slider "SWIPE SENSITIVITY".
DISPLAY: "TEXT SIZE" (S / M / L), "SUBTITLES" (on by default), "REDUCE MOTION", "COLORBLIND-SAFE COLORS".
STREAMING: "STREAMER MODE — swaps licensed music so your videos don't get claimed".
ACCOUNT: "CLOUD SAVE", "RESTORE PURCHASES", "PRIVACY".

Screen 12.2 — CONSENT (shown after Case 1, never before). Short centered panel: "Before you go on: we use ads to keep the story free, and anonymous stats to make it better." Two buttons of equal weight: "ALLOW", "ONLY WHAT'S NEEDED". Link "PRIVACY POLICY".

Screen 12.3 — DISTRICT TRANSITION (loading). Full-bleed district art placeholder: rainy container port at dawn, blue light. Chip "PORTSIDE · RAIN". Tip line in Barlow: "Planted evidence always has a tell. A date, a hand, a smell of fresh paint." Small brick-stack loader bottom-right.

Screen 12.4 — TOASTS AND BANNERS on top of gameplay: "SAVED · CHECKPOINT" (top-right, mono, small), "TRACE READY" (near the ability button), "Dash will remember that." (story echo, bottom-center), "NEW DISTRICT UNLOCKED · THE STACKS".
```

---

## Prompt 13 — The Mirror (Act 3, the screenshot moment)

> This is the hook no other game has. The villain shows the player a profile
> built from how they actually played. Design it to be screenshotted.

```
COLD READ — landscape 844×390, fullscreen game UI, COLD READ design system. Keep the copy.

Here the SIGHTLINE voice takes over the screen. It is the villain's software, and it has been reading the player the whole game. Clean, cold, white and teal, thin rounded type — beautiful and unsettling.

Screen 13.1 — THE MIRROR. Left: Ada Voss portrait (pale, sleek white hair, dark collar), name "ADA VOSS · SIGHTLINE". Right, big and calm: "You block the bridges first. Seven times out of ten." Below it, a profile of the player drawn as clean data:
- ROADBLOCKS: horizontal bar chart — Bridges 70%, Back streets 20%, Highways 10%.
- SEARCH STYLE: a split bar "SMASHES EVERYTHING 64% · PRECISE 36%".
- HESITATIONS: "3 — every time a friend was involved".
- SWIPE BIAS: "RIGHT".
- FAVOURITE ABILITY: "NITRO".
Bottom-right: SHARE (ghost, share icon) and CONTINUE. The INTERCEPT orange is almost absent on this screen, on purpose.

Screen 13.2 — SHAREABLE MIRROR CARD, 1920×1080. "YOUR COLD READ PROFILE" at the top, the same stats in a bold poster layout, a Mirror card frame (cosmetic), the game logo and the red kite small in a corner. Made to be posted.

Screen 13.3 — THE HUD TURNS. The pursuit HUD from before, compromised: Sightline's teal "most likely" tags now point the wrong way, a thin line of Ada's text intrudes along the top edge ("You always ram on the second beat."), the INTERCEPT orange elements flicker slightly, one subtle horizontal scanline glitch. Keep it readable — unsettling, not noisy.

Screen 13.4 — INTERCEPT AGAINST THE MIRROR. The intercept map with a soft heatmap overlay of where the player has always placed roadblocks (hot on bridges). Juno's radio card: "She's reading you. Do something you've never done." Mono tag "SIGHTLINE PREDICTION · LEANING AWAY FROM YOUR HABITS".
```

---

## Review checklist (run it on every batch)

- **Landscape.** Every frame is 844×390 except the rotate screen. Nothing
  important sits in the 44px side safe areas.
- **World stays visible.** Gameplay HUDs keep the center clear. Panels during
  gameplay slide in from the right.
- **Thumbs.** Actions sit in the bottom corners. Nothing tappable at top-center
  except pause.
- **Color discipline.** At most one orange primary. Teal only for evidence and
  information. Red only for time and danger. Every color meaning also has an
  icon or a word.
- **Two voices.** Sightline elements look clean and cold. INTERCEPT elements
  look chunky and warm. You can tell them apart at a glance.
- **Brick shape.** Buttons and panels have the top-right notch. No studs
  anywhere.
- **Real copy.** No lorem ipsum, no generic app words.
- **Honest money.** Close buttons visible. Ad and no-ad options have equal
  weight. No fake timers. The "never changes outcomes" line is on the shop.
- **Legal.** No LEGO, no minifigure shapes, no real badges or logos. Nobody is
  aimed at.
- **Accessible.** Smallest text 10–11px and only for labels. Touch targets 48px
  or more. Solid, Shaky and Cold each carry an icon as well as a color.

---

## Handoff to Antigravity (Godot)

Once the screens are right, export them (Figma or HTML) and put the exports in
`design/stitch/` in the repo. Then give the Antigravity agent this:

```
The COLD READ UI is designed in Google Stitch; exports are in design/stitch/ and the source prompts are in STITCH_PROMPT.md. Rebuild it in Godot 4 — do not embed HTML.

1. Make one Godot Theme resource (godot/ui/theme/cold_read_theme.tres) from the design tokens in STITCH_PROMPT.md Prompt 0: colors as theme constants, the three fonts (Barlow Condensed, Barlow, JetBrains Mono — OFL, ship them in godot/ui/fonts/ with their licence files), font sizes per role.
2. Build the brick shape once: a StyleBox for buttons and panels with a 3px radius and the 6px top-right notch (a nine-patch texture or a small custom-drawn StyleBox). Reuse it everywhere.
3. Rebuild the component sheet (Prompt 1) as reusable Control scenes under godot/ui/components/.
4. Replace the placeholder text spine in godot/ui/scene_view.gd screen by screen, keeping the present(cfg, on_done) contract and all Mirror recording. Gameplay HUDs go on a CanvasLayer above the 3D world.
5. Respect landscape safe areas (DisplayServer.get_display_safe_area()), 48px minimum touch targets, and the left-handed layout toggle.
6. After each screen: run godot/run_headless.sh, export a web build, screenshot it next to the Stitch export, and list the differences.
Do it in the BUILD_PLAN.md phase order — the UI for a scene is built when that scene is built, not all at once.
```
