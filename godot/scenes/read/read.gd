extends CanvasLayer

@onready var bg = $Background
@onready var vbox = $VBox
@onready var sentence_container = $VBox/SentenceContainer
@onready var card_container = $VBox/CardContainer
@onready var submit_button = $SubmitButton

var _cfg: Dictionary
var _on_done: Callable
var _active: bool = false
var _evidence_catalog: Dictionary = {}

var _slots: Array[Control] = []
var _blanks: int = 0
var _solution_answers: Array = []

func _ready() -> void:
	submit_button.pressed.connect(_on_submit)
	submit_button.disabled = true
	
	var file = FileAccess.open("res://data/evidence.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and typeof(json) == TYPE_DICTIONARY:
			_evidence_catalog = json

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	
	var sentence_text = String(cfg.get("sentence", "The suspect is heading to ___ by using ___"))
	_solution_answers = cfg.get("answers", [])
	
	var parts = sentence_text.split("___")
	_blanks = parts.size() - 1
	
	for i in range(parts.size()):
		if parts[i] != "":
			var l = Label.new()
			l.text = parts[i]
			l.add_theme_font_size_override("font_size", 32)
			sentence_container.add_child(l)
			
		if i < _blanks:
			var slot = preload("res://scenes/read/evidence_slot.tscn").instantiate()
			slot.set_meta("slot_index", i)
			
			slot.card_dropped.connect(_on_card_dropped)
			slot.slot_cleared.connect(_on_slot_cleared)
			
			sentence_container.add_child(slot)
			slot.set_empty_visuals()
			_slots.append(slot)
	
	var extra_ids = cfg.get("extra", [])
	var pool_ids = []
	for ev_dict in GameState.evidence:
		pool_ids.append(ev_dict["id"])
	for extra_id in extra_ids:
		if not extra_id in pool_ids:
			pool_ids.append(extra_id)
			
	for id in pool_ids:
		_spawn_card(id)
	
	_active = true

func _spawn_card(id: String) -> void:
	var c = preload("res://scenes/read/evidence_card.tscn").instantiate()
	c.set_meta("evidence_id", id)
	
	var ev_data = _evidence_catalog.get(id, {"name": id, "description": ""})
	c.get_node("VBox/NameLabel").text = ev_data.get("name", id)
	c.get_node("VBox/DescLabel").text = ev_data.get("description", "")
	
	card_container.add_child(c)

func _on_card_dropped(slot_index: int, card_id: String) -> void:
	var slot = _slots[slot_index]
	var name = card_id
	var ev_data = _evidence_catalog.get(card_id)
	if ev_data: name = ev_data.get("name", card_id)
	
	slot.set_filled_visuals(name)
	_check_completion()

func _on_slot_cleared(slot_index: int, card_id: String) -> void:
	var slot = _slots[slot_index]
	slot.set_empty_visuals()
	
	for c in card_container.get_children():
		if c.get_meta("evidence_id") == card_id:
			c.show()
			break
			
	_check_completion()

func _check_completion() -> void:
	var complete = true
	for slot in _slots:
		if slot._filled_id == "":
			complete = false
	submit_button.disabled = not complete

func _on_submit() -> void:
	if not _active: return
	_active = false
	
	var grade = "cold"
	var correct_count = 0
	
	for i in range(_blanks):
		var slot_ans = _slots[i]._filled_id
		var truth = _solution_answers[i] if i < _solution_answers.size() else ""
		if typeof(truth) == TYPE_ARRAY:
			if slot_ans in truth:
				correct_count += 1
		else:
			if slot_ans == truth:
				correct_count += 1
				
	if correct_count == _blanks:
		grade = "solid"
	elif correct_count > 0:
		grade = "shaky"
		
	if AudioDirector.has_method("play_sfx"):
		if grade == "solid": AudioDirector.call("play_sfx", "success")
		else: AudioDirector.call("play_sfx", "failure")
		
	var tween = create_tween()
	tween.tween_property(bg, "modulate:a", 0.0, 0.5)
	tween.tween_property(vbox, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		if _on_done.is_valid():
			_on_done.call({"grade": grade})
		queue_free()
	)
