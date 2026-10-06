using UnityEngine;

namespace ColdRead
{
    /// <summary>
    /// Arcade car physics (no WheelColliders — far simpler and the right feel for a mobile
    /// squad car). Rigidbody-based: throttle drives forward, steering yaws with speed, lateral
    /// grip kills sliding, downforce keeps it planted. VehicleEnterExit calls SetControlled().
    /// Setup: body mesh + BoxCollider + Rigidbody (mass ~800) + this component.
    /// NOTE: Unity 6 uses Rigidbody.linearVelocity. On Unity 2022.3 LTS, rename it to .velocity.
    /// </summary>
    [RequireComponent(typeof(Rigidbody))]
    public class ArcadeCarController : MonoBehaviour
    {
        [Header("Drive")]
        public float acceleration = 25f;
        public float maxSpeed = 22f;
        public float reverseSpeed = 8f;
        public float turnSpeed = 110f;   // deg/sec at speed
        public float grip = 6f;          // lateral friction
        public float downforce = 15f;

        Rigidbody _rb;
        bool _controlled;
        float _throttle, _steer;

        void Awake()
        {
            _rb = GetComponent<Rigidbody>();
            _rb.centerOfMass += Vector3.down * 0.6f;   // lower CoM so it doesn't tip
        }

        public void SetControlled(bool on)
        {
            _controlled = on;
            if (!on) { _throttle = 0f; _steer = 0f; }
        }

        void Update()
        {
            if (_controlled && GameInput.Instance != null)
            {
                _throttle = GameInput.Instance.Move.y;
                _steer = GameInput.Instance.Move.x;
            }
        }

        void FixedUpdate()
        {
            Vector3 vel = _rb.linearVelocity;
            float fwdSpeed = Vector3.Dot(vel, transform.forward);

            if (_controlled)
            {
                _rb.AddForce(transform.forward * (_throttle * acceleration), ForceMode.Acceleration);

                float speedFactor = Mathf.Clamp01(Mathf.Abs(fwdSpeed) / 4f);
                float dirSign = fwdSpeed >= -0.1f ? 1f : -1f; // steer flips in reverse
                float yaw = _steer * turnSpeed * speedFactor * dirSign * Time.fixedDeltaTime;
                _rb.MoveRotation(_rb.rotation * Quaternion.Euler(0f, yaw, 0f));
            }

            // lateral grip: cancel sideways velocity
            Vector3 lateral = transform.right * Vector3.Dot(vel, transform.right);
            _rb.AddForce(-lateral * grip, ForceMode.Acceleration);

            // planted + top-speed clamp
            _rb.AddForce(-transform.up * downforce, ForceMode.Acceleration);
            float cap = _throttle >= 0 ? maxSpeed : reverseSpeed;
            if (Mathf.Abs(fwdSpeed) > cap)
                _rb.AddForce(-transform.forward * (fwdSpeed - Mathf.Sign(fwdSpeed) * cap), ForceMode.Acceleration);
        }
    }
}
