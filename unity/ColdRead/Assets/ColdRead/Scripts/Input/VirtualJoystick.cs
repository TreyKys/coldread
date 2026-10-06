using UnityEngine;
using UnityEngine.EventSystems;

namespace ColdRead
{
    /// <summary>
    /// On-screen movement stick. Put this on a UI Image (the ring/background) in a Canvas,
    /// and assign 'handle' to a child Image (the thumb). Feeds GameInput.SetMobileMove.
    /// </summary>
    public class VirtualJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        [SerializeField] RectTransform background;
        [SerializeField] RectTransform handle;
        [SerializeField] float range = 90f;

        void Reset() { background = transform as RectTransform; }

        public void OnPointerDown(PointerEventData e) => OnDrag(e);

        public void OnDrag(PointerEventData e)
        {
            if (!background) background = transform as RectTransform;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(
                background, e.position, e.pressEventCamera, out Vector2 local);
            Vector2 input = Vector2.ClampMagnitude(local / range, 1f);
            if (handle) handle.anchoredPosition = input * range;
            GameInput.Instance?.SetMobileMove(input);
        }

        public void OnPointerUp(PointerEventData e)
        {
            if (handle) handle.anchoredPosition = Vector2.zero;
            GameInput.Instance?.SetMobileMove(Vector2.zero);
        }
    }
}
