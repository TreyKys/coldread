using UnityEngine;

namespace ColdRead.UI
{
    public class MinimapCamera : MonoBehaviour
    {
        [Header("Settings")]
        public Transform target;
        public float height = 30f;
        
        void LateUpdate()
        {
            if (target == null)
            {
                GameObject player = GameObject.FindGameObjectWithTag("Player");
                if (player != null) target = player.transform;
            }
            
            if (target != null)
            {
                // Follow target X and Z, keep Y locked
                transform.position = new Vector3(target.position.x, height, target.position.z);
                
                // Optional: Rotate minimap camera with player rotation
                // transform.rotation = Quaternion.Euler(90f, target.eulerAngles.y, 0f);
            }
        }
    }
}
