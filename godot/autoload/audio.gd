extends Node
## Audio director — stub interface.
##
## The real game drives one Intensity value (0-4) and a few one-shot
## triggers into an adaptive Afrobeats score (ROADMAP § Sound). FMOD or
## Godot's own AudioServer buses can sit behind this. For now it just logs,
## so scene templates can call it from day one without knowing the backend.

signal intensity_changed(value: int)

var intensity := 0

func set_intensity(value: int) -> void:
	value = clampi(value, 0, 4)
	if value != intensity:
		intensity = value
		intensity_changed.emit(value)

## One-shots: "evidence_find", "ram", "near_miss", "takedown", "slot_lock",
## "star", "tape_stop", "heartbeat", ...
func trigger(_id: String) -> void:
	pass

## Haptics, routed here so a settings toggle can mute both at once.
## weight: "light" (bag), "medium" (smash), "heavy" (ram/takedown).
func haptic(_weight: String) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(20 if _weight == "light" else (40 if _weight == "medium" else 80))
