using UnityEngine;
using UnityEngine.UI;
// using TMPro; // Assuming TMPro is available, but falling back to legacy UI text if not to avoid compile errors if package is missing
using System.Collections;

namespace ColdRead.UI
{
    public class HUDManager : MonoBehaviour
    {
        public static HUDManager Instance { get; private set; }

        [Header("Health")]
        public Slider healthBar;
        public Image damageOverlay; // Red flash when hurt
        
        [Header("Ammo")]
        public UnityEngine.UI.Text ammoText; 
        
        private Health playerHealth;

        void Awake()
        {
            if (Instance == null) Instance = this;
            else Destroy(gameObject);
        }

        void Start()
        {
            // Find player and subscribe to health changes
            GameObject player = GameObject.FindGameObjectWithTag("Player");
            if (player != null)
            {
                playerHealth = player.GetComponent<Health>();
                if (playerHealth != null)
                {
                    playerHealth.OnHealthChanged += UpdateHealthBar;
                    playerHealth.OnDamageTaken += FlashDamageOverlay;
                    
                    if (healthBar)
                    {
                        healthBar.maxValue = playerHealth.maxHealth;
                        healthBar.value = playerHealth.currentHealth;
                    }
                }
            }
        }

        public void UpdateHealthBar(float current, float max)
        {
            if (healthBar) healthBar.value = current;
        }

        public void FlashDamageOverlay()
        {
            if (damageOverlay != null)
            {
                StopAllCoroutines();
                StartCoroutine(DamageFlashCoroutine());
            }
        }

        private IEnumerator DamageFlashCoroutine()
        {
            Color c = damageOverlay.color;
            c.a = 0.5f; // Semi-transparent red
            damageOverlay.color = c;
            
            float fadeSpeed = 2f;
            while (damageOverlay.color.a > 0)
            {
                c.a -= Time.deltaTime * fadeSpeed;
                damageOverlay.color = c;
                yield return null;
            }
        }

        public void UpdateAmmo(int current, int max)
        {
            if (ammoText)
            {
                ammoText.text = $"{current} / {max}";
            }
        }

        void OnDestroy()
        {
            if (playerHealth != null)
            {
                playerHealth.OnHealthChanged -= UpdateHealthBar;
                playerHealth.OnDamageTaken -= FlashDamageOverlay;
            }
        }
    }
}
