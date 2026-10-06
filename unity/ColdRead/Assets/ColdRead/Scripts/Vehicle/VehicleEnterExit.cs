using UnityEngine;

namespace ColdRead
{
    /// <summary>
    /// Seamless get-in / get-out for the squad car. Put on the car (next to ArcadeCarController).
    /// Walk near it, press Interact (E / on-screen button) to drive; press again to step out.
    /// Assign 'seat' (a child transform where the driver sits) and 'exitPoint' (where you pop out).
    /// The player object must be tagged "Player" and have ThirdPersonController + CharacterController.
    /// </summary>
    [RequireComponent(typeof(ArcadeCarController))]
    public class VehicleEnterExit : MonoBehaviour
    {
        [Header("Mount points")]
        public Transform seat;
        public Transform exitPoint;
        public float enterRadius = 3.5f;

        [Header("Camera")]
        public ThirdPersonCamera tpsCamera;

        ArcadeCarController _car;
        GameObject _player;
        ThirdPersonController _playerCtrl;
        PlayerShooter _playerShooter;
        CharacterController _playerCC;
        bool _occupied;

        void Awake()
        {
            _car = GetComponent<ArcadeCarController>();
            _car.SetControlled(false);
            if (!tpsCamera && Camera.main) tpsCamera = Camera.main.GetComponent<ThirdPersonCamera>();
        }

        void Start()
        {
            if (GameInput.Instance != null) GameInput.Instance.InteractPressed += OnInteract;
            _player = GameObject.FindGameObjectWithTag("Player");
        }

        void OnDestroy()
        {
            if (GameInput.Instance != null) GameInput.Instance.InteractPressed -= OnInteract;
        }

        void OnInteract()
        {
            if (_occupied) { Exit(); return; }
            if (_player == null) _player = GameObject.FindGameObjectWithTag("Player");
            if (_player && Vector3.Distance(_player.transform.position, transform.position) <= enterRadius)
                Enter();
        }

        void Enter()
        {
            _playerCtrl    = _player.GetComponent<ThirdPersonController>();
            _playerShooter = _player.GetComponent<PlayerShooter>();
            _playerCC      = _player.GetComponent<CharacterController>();

            if (_playerCtrl)    _playerCtrl.SetControlEnabled(false);
            if (_playerShooter) _playerShooter.enabled = false;
            if (_playerCC)      _playerCC.enabled = false;   // disable before reparenting

            Transform t = _player.transform;
            t.SetParent(seat ? seat : transform);
            t.localPosition = Vector3.zero;
            t.localRotation = Quaternion.identity;

            _car.SetControlled(true);
            if (tpsCamera) tpsCamera.target = transform;     // camera follows the car
            _occupied = true;
        }

        void Exit()
        {
            _car.SetControlled(false);

            Transform t = _player.transform;
            t.SetParent(null);
            t.position = exitPoint ? exitPoint.position
                                   : transform.position - transform.right * 2f + Vector3.up * 0.2f;
            t.rotation = Quaternion.LookRotation(
                Vector3.ProjectOnPlane(transform.forward, Vector3.up).normalized, Vector3.up);

            if (_playerCC)      _playerCC.enabled = true;
            if (_playerCtrl)    _playerCtrl.SetControlEnabled(true);
            if (_playerShooter) _playerShooter.enabled = true;

            if (tpsCamera) tpsCamera.target = t;
            _occupied = false;
        }

        void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.cyan;
            Gizmos.DrawWireSphere(transform.position, enterRadius);
        }
    }
}
