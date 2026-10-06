# COLD READ — Unity foundation (setup)

This is the Unity port's starting skeleton: the **glue code** for a mobile third-person
open-world shooter with a drivable squad car — the exact style in the reference video.
It does **not** contain character models. That's the whole point: characters are *imported
assets*, never generated in code. You bring a rigged model; these scripts move, animate,
aim, and drive it.

> **The rule that fixes everything:** never build a human in code (no voxels, no CSG, no
> billboards, no procedural rigs). Import a **rigged humanoid** (Mixamo / Ready Player Me /
> a bought character) and these scripts do the rest.

---

## 0. What you need
- **Unity 6 LTS** (6000.x) via Unity Hub, with **Android Build Support** (+ iOS if on Mac).
  - On **Unity 2022.3 LTS** instead? One edit: in `ArcadeCarController.cs`, rename
    `_rb.linearVelocity` → `_rb.velocity`. Everything else is the same.

## 1. Open the project
1. Unity Hub → **Add → Add project from disk** → select `unity/ColdRead`.
2. Open it. Let it import. When it asks to **enable the new Input System backend / restart**, say **Yes**.
3. If Package Manager flags a version, click its suggested **fix/upgrade** (URP, Input System,
   Cinemachine, TextMeshPro are the ones that matter).

## 2. Project settings (once)
- **Edit → Project Settings → Player → Resolution/Orientation →** Default Orientation = **Landscape Left**.
- **Player → Other Settings →** confirm **Active Input Handling = Input System Package (New)** (or Both).
- Graphics should already be URP. If a scene looks pink, assign the URP asset under
  **Project Settings → Graphics**.

## 3. Bootstrap object (the input hub)
- New empty GameObject named **`Bootstrap`** → add component **`GameInput`**. That's it —
  everything finds it via `GameInput.Instance`.

## 4. Get a real character (pick ONE to start)
**Fastest (free):**
- **Mixamo.com** → pick a character (e.g. "X Bot") → add **Idle**, **Walk**, **Run**, **Jump**
  animations → download each **FBX for Unity**. Drag into `Assets/ColdRead/Characters/`.
- Select the model → **Inspector → Rig → Animation Type = Humanoid → Apply**. Do the same for each anim FBX.

**Your "PES base → many characters" plan:** use **one** base body, then make variants by
swapping **materials/textures** and attachments. (Ready Player Me `.glb` works too — download
the avatar and import it; it comes rigged. For deeper realism later, Character Creator 4.)

## 5. Animator (so it actually walks)
1. Create an **Animator Controller** `PlayerAnimator`.
2. Add a **float `Speed`** and a **bool `Grounded`**.
3. Make a **Blend Tree** on the base state, parameter `Speed`: 0 = Idle, ~2 = Walk, ~5.5 = Run.
4. (Optional) Jump state gated by `Grounded`.

## 6. Build the Player
- Empty GameObject **`Player`** → tag it **`Player`**.
  - Add **Character Controller** (set Center Y ≈ 0.9, Height ≈ 1.8).
  - Drag your rigged model **as a child**; add/assign the **Animator** (controller = `PlayerAnimator`).
  - Add **`ThirdPersonController`** (assign Animator; camera auto-finds Main Camera).
  - Add **`PlayerShooter`**.

## 7. Camera
- Select **Main Camera** → add **`ThirdPersonCamera`** → set **Target = Player**.
  (Later: replace with a Cinemachine 3rd-person rig and delete this script — the car swap still works.)

## 8. The squad car
- Car body mesh (any) → add **Box Collider**, **Rigidbody** (Mass ≈ 800), **`ArcadeCarController`**.
- Add **`VehicleEnterExit`**:
  - Child empty **`Seat`** where the driver sits → assign to `seat`.
  - Child empty **`ExitPoint`** beside the door → assign to `exitPoint`.
  - Assign **tpsCamera** = the Main Camera's `ThirdPersonCamera`.
- Ground needs a collider. Done: walk up, press **E** (or the on-screen button) to drive, press again to exit.

## 9. Mobile UI (Canvas)
Create a **Canvas** (Render Mode: Screen Space – Overlay). When it adds an EventSystem, if asked,
let it use the **Input System UI Input Module**. Then:
- **Left:** an Image (ring) with a child Image (thumb) → add **`VirtualJoystick`** (assign `handle`).
- **Right (behind everything):** a stretched, fully-transparent Image → add **`TouchLookArea`**.
- **FIRE** button (bottom-right): Image → add **`TouchButton`** (action = `FireHold`).
- **Enter/Exit** button: Image → **`TouchButton`** (action = `Interact`).
- (Optional **Jump**: `TouchButton` action = `Jump`.)
These auto-wire to `GameInput.Instance` — no OnClick setup needed.

## 10. Play
- **PC:** WASD move, mouse look, **LMB** fire, **E** enter/exit car, **Space** jump.
- **Phone:** Build & Run to device (Android/iOS) for the touch controls.

---

### Files in here
```
Scripts/Input/   GameInput, VirtualJoystick, TouchButton, TouchLookArea
Scripts/Player/  ThirdPersonController, ThirdPersonCamera, PlayerShooter
Scripts/Vehicle/ ArcadeCarController, VehicleEnterExit
Scripts/Core/    Health
```
Everything reads input through `GameInput`, so one control scheme serves PC + mobile.

**Next:** port the Cold Read design systems (cases, the Mirror, read/breach scenes) from
`ROADMAP.md` into C# — see `ANTIGRAVITY_UNITY_PROMPT.md` for how to hand that to Antigravity
without it going rogue on the art again.
