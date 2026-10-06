# Antigravity / Gemini prompt pack — COLD READ (Unity)

Paste the block below into Antigravity when you want it to keep building. It locks the engine,
the art pipeline, and the one rule that was making every character come out as garbage.

---

## SYSTEM / GROUND RULES (keep these pinned)

You are building **COLD READ**, a mobile third-person open-world detective/action game in
**Unity 6 LTS (URP)**, landscape, for Android + iOS (also runs on PC). Target look: a
mid-realistic mobile open-world shooter with a drivable squad car you can get in and out of.

**HARD RULES — do not break:**
1. **NEVER generate characters or humans in code.** No procedural meshes, no voxels, no CSG,
   no 2D billboards, no runtime rig-building. Characters are **imported rigged assets**
   (Mixamo / Ready Player Me / Character Creator / bought packs) in `.fbx` or `.glb`, set to
   **Humanoid** rig. If a human looks wrong, the fix is the import/retarget/Animator — never
   "write code to build the body."
2. **Reuse the existing scripts** in `Assets/ColdRead/Scripts/` (GameInput, ThirdPersonController,
   ThirdPersonCamera, PlayerShooter, ArcadeCarController, VehicleEnterExit, VirtualJoystick,
   TouchButton, TouchLookArea, Health). Extend them; don't reinvent the controller.
3. **All input goes through `GameInput`.** Don't read `UnityEngine.Input` or devices directly.
4. **Scenes/prefabs are assembled in the Unity Editor**, not hand-written as YAML. When a step
   needs the Editor, give me exact click-by-click steps instead of emitting a broken `.unity` file.
5. **Landscape. One-tap into gameplay. Data-driven cases** (see `../ROADMAP.md`). New cases must
   be data (ScriptableObjects / JSON), not new classes.
6. Keep it **mobile-performant**: URP, baked lighting where possible, LODs, modest poly counts.

## WHAT ALREADY EXISTS
- Movement/camera/shooting/vehicle glue: done (the scripts above). Needs a rigged character + an
  Animator with a `Speed` float + `Grounded` bool, and scene wiring per `README_SETUP.md`.
- Design is fully written in `../ROADMAP.md`, `../COLD_READ_MASTER_DESIGN.md`,
  `../LAGOON_CITY_MAP_DESIGN.md`, `../CHAPTER_01_DESIGN.md`. Read before making design calls.
- The five scene types that must survive the port: **cold_open, breach, read, chase (foot +
  pursuit), choice, debrief**. The **Mirror system** (tracks player habits for the Act 3 payoff)
  must be fed by every new mechanic.

## NEXT TASKS (do in order, smallest playable slice first)
1. Get the **Player** moving in a test scene with a Mixamo character + Animator blend tree.
2. Drop in the **squad car**; confirm enter/exit + driving + camera handoff.
3. Block out a small slice of **Lagoon City** (from the map doc) as the open-world test ground.
4. Build the **mobile Canvas** (joystick, look area, FIRE, interact) per README.
5. Port **Case 1 intro + cold_open + foot_chase** as data-driven scenes. Ship that before Case 2.
6. Wire the **Mirror** recorder so habits start logging from Case 1.

## STYLE OF WORK
Direct, working output over analysis. Recommend one path; don't dump options. Ship a rough
playable build fast, then iterate on feedback. Ask one clear question only when it's a call
the founder must make (spend, auth, art/business direction).
