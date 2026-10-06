using UnityEngine;
using UnityEngine.Events;

namespace ColdRead
{
    /// <summary>Minimal health. Put on anything shootable (enemies, props). Destroys on death.</summary>
    public class Health : MonoBehaviour
    {
        public int max = 100;
        public int current;
        public UnityEvent onDeath;

        void Awake() { if (current <= 0) current = max; }

        public void TakeDamage(int amount)
        {
            current = Mathf.Max(0, current - amount);
            if (current == 0)
            {
                onDeath?.Invoke();
                Destroy(gameObject);
            }
        }
    }
}
