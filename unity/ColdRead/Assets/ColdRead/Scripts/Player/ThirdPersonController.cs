using UnityEngine;

namespace ColdRead
{
    /// <summary>
    /// Camera-relative third-person movement on a CharacterController. Drives an Animator
    /// (float "Speed", bool "Grounded"). Works the same on PC and mobile because it reads
    /// GameInput, not raw devices. Put on the Player root; the rigged model + Animator go underneath.
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public class ThirdPersonController : MonoBehaviour
    {
        [Header("Movement")]
        public float walkSpeed = 2.2f;
        public float runSpeed = 5.5f;
        public float rotationSharpness = 12f;
        public float gravity = -20f;
        public float jumpHeight = 1.1f;

        [Header("Refs")]
        public Transform cameraTransform;
        public Animator animator;

        CharacterController _cc;
        float _vy;
        bool _controlEnabled = true;

        void Awake()
        {
            _cc = GetComponent<CharacterController>();
            if (!cameraTransform && Camera.main) cameraTransform = Camera.main.transform;
            if (!animator) animator = GetComponentInChildren<Animator>();
        }

        void Start()
        {
            if (GameInput.Instance != null) GameInput.Instance.JumpPressed += OnJump;
        }

        void OnDestroy()
        {
            if (GameInput.Instance != null) GameInput.Instance.JumpPressed -= OnJump;
        }

        /// <summary>Called by VehicleEnterExit when the player gets in/out of a car.</summary>
        public void SetControlEnabled(bool on)
        {
            _controlEnabled = on;
            if (!on && animator) animator.SetFloat("Speed", 0f);
        }

        void OnJump()
        {
            if (_controlEnabled && _cc.isGrounded)
                _vy = Mathf.Sqrt(jumpHeight * -2f * gravity);
        }

        void Update()
        {
            if (!_controlEnabled || GameInput.Instance == null) { GravityOnly(); return; }

            Vector2 mv = GameInput.Instance.Move;

            Vector3 camF = cameraTransform
                ? Vector3.ProjectOnPlane(cameraTransform.forward, Vector3.up).normalized
                : Vector3.forward;
            Vector3 camR = cameraTransform
                ? Vector3.ProjectOnPlane(cameraTransform.right, Vector3.up).normalized
                : Vector3.right;

            Vector3 wish = camF * mv.y + camR * mv.x;
            float amount = Mathf.Clamp01(wish.magnitude);
            if (amount > 0.001f) wish /= amount; // normalize without losing 'amount'

            float speed = (amount > 0.6f ? runSpeed : walkSpeed) * amount;
            Vector3 horizontal = wish * speed;

            if (amount > 0.05f)
            {
                Quaternion target = Quaternion.LookRotation(wish, Vector3.up);
                transform.rotation = Quaternion.Slerp(
                    transform.rotation, target, 1f - Mathf.Exp(-rotationSharpness * Time.deltaTime));
            }

            if (_cc.isGrounded && _vy < 0f) _vy = -2f;
            _vy += gravity * Time.deltaTime;

            _cc.Move((horizontal + Vector3.up * _vy) * Time.deltaTime);

            if (animator)
            {
                animator.SetFloat("Speed", new Vector2(horizontal.x, horizontal.z).magnitude, 0.1f, Time.deltaTime);
                animator.SetBool("Grounded", _cc.isGrounded);
            }
        }

        void GravityOnly()
        {
            if (_cc.isGrounded && _vy < 0f) _vy = -2f;
            _vy += gravity * Time.deltaTime;
            _cc.Move(Vector3.up * _vy * Time.deltaTime);
        }
    }
}
