extends CanvasLayer

@onready var container = $MarginContainer
@onready var face_rect = $MarginContainer/HBox/Face
@onready var text_label = $MarginContainer/HBox/Text

var _faces := {}
var _active_tween: Tween

func _ready() -> void:
	layer = 90
	container.modulate.a = 0
	container.position.y = -100
	
	var file = FileAccess.open("res://data/faces.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and typeof(json) == TYPE_DICTIONARY:
			_faces = json

func play(text: String, face_id: String = "dash", duration: float = 3.0) -> void:
	if _active_tween:
		_active_tween.kill()
		
	text_label.text = text
	
	var tex_path = _faces.get(face_id, "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		face_rect.texture = load(tex_path)
	else:
		face_rect.texture = null
		
	_active_tween = create_tween()
	_active_tween.tween_property(container, "position:y", 20.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(container, "modulate:a", 1.0, 0.3)
	
	_active_tween.tween_interval(duration)
	
	_active_tween.tween_property(container, "position:y", -100.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_active_tween.parallel().tween_property(container, "modulate:a", 0.0, 0.3)
