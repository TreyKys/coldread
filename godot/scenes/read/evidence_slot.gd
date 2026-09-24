extends PanelContainer

signal card_dropped(slot_index, id)
signal slot_cleared(slot_index, id)

var _filled_id: String = ""

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("id")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _filled_id != "":
		slot_cleared.emit(get_meta("slot_index"), _filled_id)
		
	_filled_id = data["id"]
	card_dropped.emit(get_meta("slot_index"), _filled_id)
	
	if data.has("source") and is_instance_valid(data["source"]):
		data["source"].hide()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _filled_id != "":
			var old_id = _filled_id
			_filled_id = ""
			slot_cleared.emit(get_meta("slot_index"), old_id)

func set_empty_visuals() -> void:
	$Label.text = "[ DROP EVIDENCE ]"
	$Label.add_theme_color_override("font_color", Color("E4EDF0"))

func set_filled_visuals(name: String) -> void:
	$Label.text = name
	$Label.add_theme_color_override("font_color", Color("F2C14E"))
