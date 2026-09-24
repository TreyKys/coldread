extends Node
## SceneRunner — plays a case file scene by scene, with a checkpoint (save)
## after every scene. Ported from the greybox `startCase` / `nextScene`.
##
## The runner knows nothing about HOW a scene plays. It hands each scene
## config to the presenter (SceneView) and folds the result back into
## GameState. That keeps scene TYPES as the only code that changes when you
## add gameplay, and cases as pure data.

signal case_finished(case_idx: int)
signal returned_to_title()

var cases := []
var presenter                                  # anything with present(cfg, Callable)

func setup(presenter_node) -> void:
	presenter = presenter_node
	cases = CaseLoader.load_cases()

func case_count() -> int:
	return cases.size()

func start_case(idx: int) -> void:
	if idx < 0 or idx >= cases.size():
		returned_to_title.emit()
		return
	GameState.begin_case(idx)
	GameState.save()
	_next_scene()

func _next_scene() -> void:
	var c: Dictionary = cases[GameState.case_idx]
	var scenes: Array = c.get("scenes", [])
	if GameState.scene_idx >= scenes.size():
		# case complete — unlock the next one
		GameState.unlocked = maxi(GameState.unlocked, mini(cases.size(), GameState.case_idx + 2))
		GameState.save()
		case_finished.emit(GameState.case_idx)
		return

	# Build the effective config: scene data + case defaults + run-scoped hints.
	var cfg: Dictionary = (scenes[GameState.scene_idx] as Dictionary).duplicate(true)
	cfg["district"] = cfg.get("district", c.get("district", "market_mile"))
	cfg["_case_name"] = c.get("name", "")
	cfg["_rank"] = c.get("rank", "")
	cfg["_grade"] = GameState.run["grade"]     # how the last Read graded → chase start distance
	cfg["_cut"] = GameState.run["cut"]         # did the Intercept cut them off
	cfg["_last_stars"] = GameState.run.get("last_stars", 3)
	GameState.save()

	presenter.present(cfg, Callable(self, "_on_scene_done"))

func _on_scene_done(result: Dictionary) -> void:
	# Fold the scene's result into persistent state (greybox nextScene()).
	if result.has("evidence"):
		GameState.evidence = GameState.evidence + result["evidence"]
	if result.has("grade"):
		GameState.run["grade"] = result["grade"]
	if result.has("cut"):
		GameState.run["cut"] = bool(result["cut"])
	if result.has("stars"):
		GameState.record_stars(int(result["stars"]))
	GameState.scene_idx += 1
	GameState.save()
	_next_scene()
