extends Node3D

@onready var distance_label = $UI/DistanceLabel

var _cfg: Dictionary
var _on_done: Callable
var _active: bool = false
var _distance: float = 100.0

var _touch_start: Vector2
var _is_dragging: bool = false

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	_distance = 100.0
	_active = true

func _process(delta: float) -> void:
	if not _active: return
	
	_distance -= delta * 15.0 # Run speed
	if _distance <= 0:
		_distance = 0
		_finish_scene()
		
	distance_label.text = "%dm" % int(_distance)

func _unhandled_input(event: InputEvent) -> void:
	if not _active: return
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.is_pressed()
		var pos = event.position
		
		if pressed:
			_touch_start = pos
			_is_dragging = true
		else:
			if _is_dragging:
				var swipe_vec = pos - _touch_start
				if swipe_vec.length() > 50:
					if abs(swipe_vec.x) > abs(swipe_vec.y):
						if swipe_vec.x > 0:
							Mirror.record_swipe("right")
							if AudioDirector.has_method("play_sfx"): AudioDirector.call("play_sfx", "dodge")
						else:
							Mirror.record_swipe("left")
							if AudioDirector.has_method("play_sfx"): AudioDirector.call("play_sfx", "dodge")
					else:
						if swipe_vec.y < 0:
							Mirror.record_swipe("up")
							if AudioDirector.has_method("play_sfx"): AudioDirector.call("play_sfx", "vault")
						else:
							Mirror.record_swipe("down")
							if AudioDirector.has_method("play_sfx"): AudioDirector.call("play_sfx", "slide")
			_is_dragging = false

func _finish_scene() -> void:
	if not _active: return
	_active = false
		
	if _on_done.is_valid():
		_on_done.call({"stars": 3})
	queue_free()
