using UnityEngine;

namespace ColdRead
{
    /// <summary>
    /// Zero-setup third-person orbit camera. Put on the Main Camera and set 'target' to the player.
    /// Reads look delta from GameInput (mouse / right-stick / touch drag). It also wall-avoids with a
    /// linecast. For production polish, swap to Cinemachine (see README_SETUP) and delete this.
    /// VehicleEnterExit retargets 'target' to the car when you drive.
    /// </summary>
    public class ThirdPersonCamera : MonoBehaviour
    {
        public Transform target;
        public Vector3 pivotOffset = new Vector3(0f, 1.6f, 0f);
        public float distance = 4.5f;
        public float minPitch = -15f, maxPitch = 60f;
        public float sensitivity = 1.4f;

        float _yaw, _pitch = 15f;

        void Start()
        {
            if (target) _yaw = target.eulerAngles.y;
        }

        void LateUpdate()
        {
            if (!target || GameInput.Instance == null) return;

            Vector2 look = GameInput.Instance.ConsumeLook() * sensitivity;
            _yaw += look.x;
            _pitch = Mathf.Clamp(_pitch - look.y, minPitch, maxPitch);

            Quaternion rot = Quaternion.Euler(_pitch, _yaw, 0f);
            Vector3 pivot = target.position + pivotOffset;
            Vector3 desired = pivot - rot * Vector3.forward * distance;

            if (Physics.Linecast(pivot, desired, out RaycastHit hit, ~0, QueryTriggerInteraction.Ignore))
                desired = hit.point + hit.normal * 0.2f;

            transform.position = desired;
            transform.rotation = rot;
        }
    }
}
