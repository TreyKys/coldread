extends CanvasLayer

## Read Scene - Evidence connection and theory crafting.
## Refactored for Godot 4 drag and drop best practices (no dynamic gdscript).

@onready var bg = $Background
@onready var vbox = $VBox
@onready var slot1 = $VBox/SentenceContainer/Slot1
@onready var slot2 = $VBox/SentenceContainer/Slot2
@onready var card_container = $VBox/CardContainer
@onready var submit_button = $SubmitButton

var _cfg: Dictionary
var _on_done: Callable
var _active: bool = false
var _evidence_catalog: Dictionary = {}

var _filled_slots: Dictionary = { 1: null, 2: null }
var _solution_1: String = ""
var _solution_2: String = ""

func _ready() -> void:
	submit_button.pressed.connect(_on_submit)
	submit_button.disabled = true
	
	var file = FileAccess.open("res://data/evidence.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and typeof(json) == TYPE_DICTIONARY and json.has("evidence"):
			for ev in json["evidence"]:
				_evidence_catalog[ev["id"]] = ev

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	
	var ev_ids = cfg.get("evidence", [])
	if ev_ids.is_empty():
		ev_ids = ["tire_marks", "blood_trail", "burner_phone", "shipping_manifest"]
		
	_solution_1 = cfg.get("solution_1", "shipping_manifest")
	_solution_2 = cfg.get("solution_2", "tire_marks")
	
	for id in ev_ids:
		_spawn_card(id)
		
	# Setup drop zones via forwarding
	slot1.set_meta("slot_index", 1)
	slot2.set_meta("slot_index", 2)
	
	slot1.set_drag_forwarding(Callable(), _can_drop_on_slot, _drop_on_slot.bind(slot1))
	slot2.set_drag_forwarding(Callable(), _can_drop_on_slot, _drop_on_slot.bind(slot2))
	
	_active = true

func _spawn_card(id: String) -> void:
	var c = PanelContainer.new()
	c.custom_minimum_size = Vector2(200, 250)
	c.set_meta("evidence_id", id)
	
	var cvbox = VBoxContainer.new()
	c.add_child(cvbox)
	
	var name_label = Label.new()
	var ev_data = _evidence_catalog.get(id, {"name": id, "description": "Unknown evidence"})
	name_label.text = ev_data.get("name", id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color("45D6C6"))
	cvbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = ev_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(180, 0)
	cvbox.add_child(desc_label)
	
	# Godot 4 set_drag_forwarding allows passing the Control source
	c.set_drag_forwarding(_get_drag_data_card.bind(c), Callable(), Callable())
	card_container.add_child(c)

# Drag forwarding for cards
func _get_drag_data_card(at_position: Vector2, source_card: Control) -> Variant:
	source_card.modulate.a = 0.5
	var preview = Label.new()
	preview.text = source_card.get_meta("evidence_id")
	source_card.set_drag_preview(preview)
	
	# Hook up a one-shot signal or check to restore alpha if drop fails
	# A simple approach for UI drops is to always restore on drag end via GUI input, but we'll keep it simple
	return {"source": source_card, "id": source_card.get_meta("evidence_id")}

# Drag forwarding for slots
func _can_drop_on_slot(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("id")

func _drop_on_slot(at_position: Vector2, data: Variant, slot: Control) -> void:
	var slot_index = slot.get_meta("slot_index")
	var card_id = data["id"]
	_filled_slots[slot_index] = card_id
	
	var name = card_id
	var ev_data = _evidence_catalog.get(card_id)
	if ev_data: name = ev_data.get("name", card_id)
		
	slot.get_node("Label").text = name
	slot.get_node("Label").add_theme_color_override("font_color", Color("F2C14E"))
	
	# Consume the original card so it can't be reused
	if data.has("source") and is_instance_valid(data["source"]):
		data["source"].queue_free()
	
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
		
	if AudioDirector.has_method("play_sfx"):
		if grade == "solid": AudioDirector.call("play_sfx", "success")
		else: AudioDirector.call("play_sfx", "failure")
		
	var tween = create_tween()
	# Fix: Tween Modulate on the ColorRect and VBox, not CanvasLayer
	tween.tween_property(bg, "modulate:a", 0.0, 0.5)
	tween.tween_property(vbox, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		if _on_done.is_valid():
			_on_done.call({"grade": grade})
		queue_free()
	)
