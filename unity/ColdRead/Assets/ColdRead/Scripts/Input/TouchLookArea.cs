using UnityEngine;
using UnityEngine.EventSystems;

namespace ColdRead
{
    /// <summary>
    /// Transparent full-screen (or right-half) UI panel. Dragging it rotates the camera.
    /// Put on a stretched, fully transparent UI Image placed BEHIND the joystick/buttons.
    /// </summary>
    public class TouchLookArea : MonoBehaviour, IDragHandler
    {
        [SerializeField] float sensitivity = 0.12f;

        public void OnDrag(PointerEventData e)
        {
            GameInput.Instance?.AddMobileLook(e.delta * sensitivity);
        }
    }
}
