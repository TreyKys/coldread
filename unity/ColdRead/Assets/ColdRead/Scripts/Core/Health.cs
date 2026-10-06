using UnityEngine;
using UnityEngine.Events;

namespace ColdRead
{
    /// <summary>Minimal health. Put on anything shootable (enemies, props). Destroys on death.</summary>
    public class Health : MonoBehaviour
    {
        public float maxHealth = 100f;
        public float currentHealth;
        
        public delegate void HealthChangedAction(float current, float max);
        public event HealthChangedAction OnHealthChanged;
        
        public delegate void DamageAction();
        public event DamageAction OnDamageTaken;
        
        public delegate void DeathAction();
        public event DeathAction OnDeath;
        
        public UnityEvent onDeathEvent; // Keep this for inspector wiring

        void Awake() 
        { 
            if (currentHealth <= 0) currentHealth = maxHealth; 
        }

        public void TakeDamage(float amount)
        {
            if (currentHealth <= 0) return; // already dead

            currentHealth = Mathf.Max(0, currentHealth - amount);
            
            OnDamageTaken?.Invoke();
            OnHealthChanged?.Invoke(currentHealth, maxHealth);

            if (currentHealth <= 0)
            {
                OnDeath?.Invoke();
                onDeathEvent?.Invoke();
                // Destroy logic is moved to the listener (e.g. EnemyAI or PlayerController)
                // so we can play death animations instead of instant deletion!
            }
        }
    }
}
