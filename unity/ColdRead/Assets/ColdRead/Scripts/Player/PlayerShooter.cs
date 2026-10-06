using UnityEngine;

namespace ColdRead
{
    /// <summary>
    /// Hitscan shooting driven by the FIRE input (mouse / RT / on-screen button).
    /// Fires from the camera's aim so the crosshair = where you hit. Damages anything with a Health.
    /// Optional LineRenderer 'tracer' for a quick muzzle-to-impact streak.
    /// </summary>
    public class PlayerShooter : MonoBehaviour
    {
        [Header("Aim")]
        public Camera aimCamera;
        public Transform muzzle;        // optional, visual start of the tracer

        [Header("Gun")]
        public float fireRate = 8f;     // shots per second
        public float range = 120f;
        public int damage = 20;
        public LayerMask hitMask = ~0;

        [Header("FX (optional)")]
        public LineRenderer tracer;

        float _nextShot;

        void Awake() { if (!aimCamera) aimCamera = Camera.main; }

        void Update()
        {
            if (GameInput.Instance == null) return;
            if (GameInput.Instance.Fire && Time.time >= _nextShot)
            {
                _nextShot = Time.time + 1f / Mathf.Max(0.01f, fireRate);
                Shoot();
            }
        }

        void Shoot()
        {
            Transform cam = aimCamera ? aimCamera.transform : transform;
            Vector3 origin = cam.position;
            Vector3 dir = cam.forward;
            Vector3 end = origin + dir * range;

            if (Physics.Raycast(origin, dir, out RaycastHit hit, range, hitMask, QueryTriggerInteraction.Ignore))
            {
                end = hit.point;
                hit.collider.GetComponentInParent<Health>()?.TakeDamage(damage);
            }

            if (tracer)
            {
                tracer.positionCount = 2;
                tracer.SetPosition(0, muzzle ? muzzle.position : origin);
                tracer.SetPosition(1, end);
                tracer.enabled = true;
                CancelInvoke(nameof(HideTracer));
                Invoke(nameof(HideTracer), 0.03f);
            }
        }

        void HideTracer() { if (tracer) tracer.enabled = false; }
    }
}
