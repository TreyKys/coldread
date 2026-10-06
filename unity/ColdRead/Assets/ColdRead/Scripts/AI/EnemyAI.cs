using UnityEngine;
using UnityEngine.AI;

namespace ColdRead.AI
{
    [RequireComponent(typeof(NavMeshAgent))]
    [RequireComponent(typeof(Health))]
    public class EnemyAI : MonoBehaviour
    {
        public enum AIState { Idle, Chase, Attack, Dead }
        
        [Header("Settings")]
        public float detectionRadius = 15f;
        public float attackRange = 5f;
        public float fireRate = 1f;
        public float damage = 10f;
        
        [Header("Refs")]
        public Animator animator;
        public Transform muzzleFirePoint;
        public GameObject muzzleFlashPrefab;

        private NavMeshAgent agent;
        private Health health;
        private Transform playerTarget;
        private AIState currentState = AIState.Idle;
        private float nextFireTime;

        void Awake()
        {
            agent = GetComponent<NavMeshAgent>();
            health = GetComponent<Health>();
            
            if (animator == null) animator = GetComponentInChildren<Animator>();
            
            health.OnDeath += HandleDeath;
        }

        void Start()
        {
            // Find player - assumes player is tagged "Player"
            GameObject player = GameObject.FindGameObjectWithTag("Player");
            if (player) playerTarget = player.transform;
        }

        void Update()
        {
            if (currentState == AIState.Dead || playerTarget == null) return;

            float distanceToPlayer = Vector3.Distance(transform.position, playerTarget.position);

            switch (currentState)
            {
                case AIState.Idle:
                    if (distanceToPlayer <= detectionRadius)
                        ChangeState(AIState.Chase);
                    break;

                case AIState.Chase:
                    if (distanceToPlayer <= attackRange)
                    {
                        ChangeState(AIState.Attack);
                    }
                    else if (distanceToPlayer > detectionRadius * 1.5f)
                    {
                        ChangeState(AIState.Idle);
                    }
                    else
                    {
                        agent.SetDestination(playerTarget.position);
                    }
                    break;

                case AIState.Attack:
                    if (distanceToPlayer > attackRange * 1.2f)
                    {
                        ChangeState(AIState.Chase);
                    }
                    else
                    {
                        agent.SetDestination(transform.position); // Stop moving
                        FaceTarget();
                        
                        if (Time.time >= nextFireTime)
                        {
                            Shoot();
                            nextFireTime = Time.time + (1f / fireRate);
                        }
                    }
                    break;
            }

            UpdateAnimator();
        }

        void FaceTarget()
        {
            Vector3 direction = (playerTarget.position - transform.position).normalized;
            direction.y = 0;
            if (direction != Vector3.zero)
            {
                Quaternion lookRot = Quaternion.LookRotation(direction);
                transform.rotation = Quaternion.Slerp(transform.rotation, lookRot, Time.deltaTime * 5f);
            }
        }

        void Shoot()
        {
            if (animator) animator.SetTrigger("Shoot");
            
            if (muzzleFlashPrefab && muzzleFirePoint)
            {
                Instantiate(muzzleFlashPrefab, muzzleFirePoint.position, muzzleFirePoint.rotation);
            }

            Health targetHealth = playerTarget.GetComponent<Health>();
            if (targetHealth != null)
            {
                targetHealth.TakeDamage(damage);
            }
        }

        void ChangeState(AIState newState)
        {
            currentState = newState;
        }

        void UpdateAnimator()
        {
            if (animator)
            {
                animator.SetFloat("Speed", agent.velocity.magnitude);
            }
        }

        void HandleDeath()
        {
            ChangeState(AIState.Dead);
            agent.enabled = false;
            if (animator) animator.SetTrigger("Die");
            Destroy(gameObject, 5f); // Cleanup after a few seconds
        }

        void OnDestroy()
        {
            if (health != null) health.OnDeath -= HandleDeath;
        }
    }
}
