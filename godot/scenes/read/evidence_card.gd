extends PanelContainer

signal card_drag_started(card)
signal card_drag_ended(card)

func _get_drag_data(at_position: Vector2) -> Variant:
	modulate.a = 0.5
	var preview = Label.new()
	preview.text = get_meta("evidence_id")
	set_drag_preview(preview)
	emit_signal("card_drag_started", self)
	return {"source": self, "id": get_meta("evidence_id")}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
		emit_signal("card_drag_ended", self)
