using UnityEngine;
using UnityEngine.EventSystems;

namespace ColdRead
{
    public enum TouchButtonAction { FireHold, Interact, Jump }

    /// <summary>
    /// On-screen action button. Put on a UI Image/Button. FireHold reports press+release
    /// (hold to keep firing); Interact and Jump fire once on tap.
    /// </summary>
    public class TouchButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
    {
        [SerializeField] TouchButtonAction action = TouchButtonAction.FireHold;

        public void OnPointerDown(PointerEventData e)
        {
            var gi = GameInput.Instance;
            if (gi == null) return;
            switch (action)
            {
                case TouchButtonAction.FireHold: gi.SetMobileFire(true); break;
                case TouchButtonAction.Interact: gi.MobileInteract(); break;
                case TouchButtonAction.Jump:     gi.MobileJump(); break;
            }
        }

        public void OnPointerUp(PointerEventData e)
        {
            if (action == TouchButtonAction.FireHold)
                GameInput.Instance?.SetMobileFire(false);
        }
    }
}
