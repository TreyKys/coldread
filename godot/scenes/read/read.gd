extends CanvasLayer

## Read Scene - Evidence connection and theory crafting.
## Implements Godot's built-in Drag and Drop for Control nodes.

@onready var slot1 = $VBox/SentenceContainer/Slot1
@onready var slot2 = $VBox/SentenceContainer/Slot2
@onready var card_container = $VBox/CardContainer
@onready var submit_button = $SubmitButton

var _cfg: Dictionary
var _on_done: Callable
var _active: bool = false
var _evidence_catalog: Dictionary = {}

# Current slots
var _filled_slots: Dictionary = { 1: null, 2: null }

# Hardcoded true answers for the prototype/skeleton if not provided by config
var _solution_1: String = ""
var _solution_2: String = ""

func _ready() -> void:
	submit_button.pressed.connect(_on_submit)
	submit_button.disabled = true
	
	# Attempt to load evidence database
	var file = FileAccess.open("res://data/evidence.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and typeof(json) == TYPE_DICTIONARY and json.has("evidence"):
			for ev in json["evidence"]:
				_evidence_catalog[ev["id"]] = ev

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	
	var ev_ids = cfg.get("evidence", []) # What player found in breach
	if ev_ids.is_empty():
		ev_ids = ["tire_marks", "blood_trail", "burner_phone", "shipping_manifest"]
		
	_solution_1 = cfg.get("solution_1", "shipping_manifest")
	_solution_2 = cfg.get("solution_2", "tire_marks")
	
	for id in ev_ids:
		_spawn_card(id)
		
	# Setup drop zones
	_setup_slot(slot1, 1)
	_setup_slot(slot2, 2)
	
	_active = true

func _spawn_card(id: String) -> void:
	var c = PanelContainer.new()
	c.custom_minimum_size = Vector2(200, 250)
	c.set_meta("evidence_id", id)
	
	var vbox = VBoxContainer.new()
	c.add_child(vbox)
	
	var name_label = Label.new()
	var ev_data = _evidence_catalog.get(id, {"name": id, "description": "Unknown evidence"})
	name_label.text = ev_data.get("name", id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color("45D6C6"))
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = ev_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(180, 0)
	vbox.add_child(desc_label)
	
	# Enable drag
	c.set_script(_get_card_script())
	card_container.add_child(c)

func _setup_slot(slot_node: Control, slot_index: int) -> void:
	slot_node.set_meta("slot_index", slot_index)
	slot_node.set_script(_get_slot_script())
	# Hook up signal from dynamic script
	slot_node.connect("card_dropped", Callable(self, "_on_card_dropped"))

func _on_card_dropped(slot_index: int, card_id: String) -> void:
	_filled_slots[slot_index] = card_id
	
	var name = card_id
	var ev_data = _evidence_catalog.get(card_id)
	if ev_data: name = ev_data.get("name", card_id)
		
	var slot_node = slot1 if slot_index == 1 else slot2
	slot_node.get_node("Label").text = name
	slot_node.get_node("Label").add_theme_color_override("font_color", Color("F2C14E"))
	
	_check_completion()

func _check_completion() -> void:
	if _filled_slots[1] != null and _filled_slots[2] != null:
		submit_button.disabled = false
	else:
		submit_button.disabled = true

func _on_submit() -> void:
	if not _active: return
	_active = false
	
	var grade = "cold"
	var c1 = _filled_slots[1]
	var c2 = _filled_slots[2]
	
	if c1 == _solution_1 and c2 == _solution_2:
		grade = "solid"
	elif c1 == _solution_1 or c2 == _solution_2:
		grade = "shaky"
		
	# In a full game, we might send this grade to Mirror or GameState
	if AudioDirector.has_method("play_sfx"):
		if grade == "solid": AudioDirector.call("play_sfx", "success")
		else: AudioDirector.call("play_sfx", "failure")
		
	# Mirror tracking for thoroughness / time spent could go here
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		if _on_done.is_valid():
			_on_done.call({"grade": grade})
		queue_free()
	)

# ----------------------------------------------------------------------
# Dynamic scripts for Drag and Drop
# We generate them here to avoid needing separate small script files

func _get_card_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """
extends PanelContainer
func _get_drag_data(at_position: Vector2) -> Variant:
	set_modulate(Color(1, 1, 1, 0.5))
	var preview = Label.new()
	preview.text = get_meta("evidence_id")
	set_drag_preview(preview)
	return {"source": self, "id": get_meta("evidence_id")}
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		set_modulate(Color(1, 1, 1, 1.0))
	"""
	s.reload()
	return s

func _get_slot_script() -> GDScript:
	var s = GDScript.new()
	s.source_code = """
extends PanelContainer
signal card_dropped(slot_index, id)
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("id")
func _drop_data(at_position: Vector2, data: Variant) -> void:
	emit_signal("card_dropped", get_meta("slot_index"), data["id"])
	if data.has("source") and is_instance_valid(data["source"]):
		# Optionally hide the original card
		pass
	"""
	s.reload()
	return s

