extends CanvasLayer

var _rect: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
	layer = 100 # Always on top
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0, 0, 0, 0)
	add_child(_rect)

func fade_out(duration: float = 0.3) -> void:
	if _is_transitioning: return
	_is_transitioning = true
	var t = create_tween()
	t.tween_property(_rect, "color:a", 1.0, duration)
	await t.finished
	_is_transitioning = false

func fade_in(duration: float = 0.3) -> void:
	if _is_transitioning: return
	_is_transitioning = true
	var t = create_tween()
	t.tween_property(_rect, "color:a", 0.0, duration)
	await t.finished
	_is_transitioning = false

func play_transition(half_duration: float = 0.3, callback: Callable = Callable()) -> void:
	if _is_transitioning: return
	_is_transitioning = true
	
	var t = create_tween()
	t.tween_property(_rect, "color:a", 1.0, half_duration)
	await t.finished
	
	if callback.is_valid():
		callback.call()
		
	var t2 = create_tween()
	t2.tween_property(_rect, "color:a", 0.0, half_duration)
	await t2.finished
	
	_is_transitioning = false
