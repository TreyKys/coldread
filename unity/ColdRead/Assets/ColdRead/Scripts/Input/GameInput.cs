using System;
using UnityEngine;
using UnityEngine.InputSystem;

namespace ColdRead
{
    /// <summary>
    /// Single source of truth for input. Reads keyboard / mouse / gamepad through the
    /// new Input System, and also accepts on-screen (touch) input via the public Set*/Mobile* API.
    /// Every gameplay script reads from GameInput.Instance instead of polling devices directly,
    /// so the same code runs on PC and mobile. Put ONE of these in the scene (on a Bootstrap object).
    /// </summary>
    public class GameInput : MonoBehaviour
    {
        public static GameInput Instance { get; private set; }

        // --- Values other systems read every frame ---
        public Vector2 Move { get; private set; }   // -1..1 on each axis (y = forward)
        public bool Fire { get; private set; }

        // --- One-shot events ---
        public event Action FirePressedDown;
        public event Action InteractPressed;
        public event Action JumpPressed;

        // --- Mobile overrides (written by the on-screen UI) ---
        Vector2 _mobileMove;
        Vector2 _mobileLook;   // accumulated drag delta, consumed by the camera
        bool _mobileFire;

        InputAction _move, _look, _fire, _interact, _jump;

        void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;

            _move = new InputAction("Move", InputActionType.Value);
            _move.AddCompositeBinding("2DVector")
                .With("Up", "<Keyboard>/w").With("Down", "<Keyboard>/s")
                .With("Left", "<Keyboard>/a").With("Right", "<Keyboard>/d");
            _move.AddCompositeBinding("2DVector")
                .With("Up", "<Keyboard>/upArrow").With("Down", "<Keyboard>/downArrow")
                .With("Left", "<Keyboard>/leftArrow").With("Right", "<Keyboard>/rightArrow");
            _move.AddBinding("<Gamepad>/leftStick");

            _look = new InputAction("Look", InputActionType.Value);
            _look.AddBinding("<Mouse>/delta").WithProcessor("scaleVector2(x=0.06,y=0.06)");
            _look.AddBinding("<Gamepad>/rightStick").WithProcessor("scaleVector2(x=2.5,y=2.5)");

            _fire = new InputAction("Fire", InputActionType.Button);
            _fire.AddBinding("<Mouse>/leftButton");
            _fire.AddBinding("<Gamepad>/rightTrigger");

            _interact = new InputAction("Interact", InputActionType.Button);
            _interact.AddBinding("<Keyboard>/e");
            _interact.AddBinding("<Gamepad>/buttonWest");

            _jump = new InputAction("Jump", InputActionType.Button);
            _jump.AddBinding("<Keyboard>/space");
            _jump.AddBinding("<Gamepad>/buttonSouth");

            _fire.started     += _ => FirePressedDown?.Invoke();
            _interact.performed += _ => InteractPressed?.Invoke();
            _jump.performed     += _ => JumpPressed?.Invoke();
        }

        void OnEnable()
        {
            _move.Enable(); _look.Enable(); _fire.Enable(); _interact.Enable(); _jump.Enable();
        }

        void OnDisable()
        {
            _move.Disable(); _look.Disable(); _fire.Disable(); _interact.Disable(); _jump.Disable();
        }

        void Update()
        {
            Vector2 kbMove = _move.ReadValue<Vector2>();
            Move = _mobileMove.sqrMagnitude > 0.0001f ? _mobileMove : kbMove;
            Fire = _mobileFire || _fire.IsPressed();
        }

        /// <summary>Camera calls this once per LateUpdate to get (and clear) look delta.</summary>
        public Vector2 ConsumeLook()
        {
            Vector2 v = _look.ReadValue<Vector2>() + _mobileLook;
            _mobileLook = Vector2.zero;
            return v;
        }

        // ---------------- Mobile UI API (called by VirtualJoystick / TouchButton / TouchLookArea) ----------------
        public void SetMobileMove(Vector2 v) => _mobileMove = Vector2.ClampMagnitude(v, 1f);
        public void AddMobileLook(Vector2 delta) => _mobileLook += delta;
        public void SetMobileFire(bool pressed)
        {
            if (pressed && !_mobileFire) FirePressedDown?.Invoke();
            _mobileFire = pressed;
        }
        public void MobileInteract() => InteractPressed?.Invoke();
        public void MobileJump() => JumpPressed?.Invoke();
    }
}
