extends Node
## Boot. Wires the SceneRunner to the SceneView presenter and shows the
## title. One-tap start: pick a case, you're in it.
##
## Run headless with `--selftest` (see run_headless.sh) to drive the whole of
## Act 1 through the runner with no UI and assert the data + state + Mirror
## code paths are clean. That is the skeleton's smoke test.

var view: Node
var runner: Node

func _ready() -> void:
	GameState.load_game()
	runner = preload("res://runner/scene_runner.gd").new()
	add_child(runner)

	if "--selftest" in OS.get_cmdline_user_args():
		_selftest()
		return

	view = preload("res://ui/scene_view.gd").new()
	add_child(view)
	runner.setup(view)
	runner.case_finished.connect(func(_i): _to_title())
	runner.returned_to_title.connect(_to_title)
	_to_title()

	if "--shot" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.6).timeout
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://title.png")
		get_tree().quit()

func _to_title() -> void:
	view.show_title(runner.cases, Callable(runner, "start_case"), Callable(self, "_reset"))

func _reset() -> void:
	GameState.reset_progress()
	_to_title()

# ---------------------------------------------------------------- selftest

func _selftest() -> void:
	var ok := true
	var cases := CaseLoader.load_cases()
	print("[selftest] cases loaded: ", cases.size())
	if cases.size() != 3:
		push_error("[selftest] expected 3 cases"); ok = false
	for c in cases:
		var n := (c.get("scenes", []) as Array).size()
		print("[selftest]  - %s : %d scenes" % [c.get("name", "?"), n])
		if n == 0:
			push_error("[selftest] case has no scenes"); ok = false

	# drive Case 1 through the runner with an auto-presenter
	var auto := AutoPresenter.new()
	runner.setup(auto)
	var finished := [false]
	runner.case_finished.connect(func(_i): finished[0] = true)
	runner.start_case(0)
	if not finished[0]:
		push_error("[selftest] case 1 did not finish"); ok = false
	print("[selftest] case 1 scenes played: ", auto.count)
	print("[selftest] flags after case 1: ", GameState.flags)
	print("[selftest] trust after case 1: ", GameState.trust)

	# Mirror round-trip
	Mirror.record_block("bridge"); Mirror.record_search(true); Mirror.record_swipe("right")
	var snap := Mirror.to_dict()
	Mirror.reset()
	Mirror.from_dict(snap)
	if Mirror.roadblocks["bridge"] != 1:
		push_error("[selftest] mirror round-trip failed"); ok = false
	print("[selftest] mirror profile: ", Mirror.profile())

	# Save round-trip
	GameState.save()
	var before := GameState.flags.duplicate(true)
	GameState.flags = {}
	GameState.load_game()
	if GameState.flags.size() != before.size():
		push_error("[selftest] save round-trip lost flags"); ok = false

	print("[selftest] RESULT: ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)

## Minimal presenter used only by the selftest: replies to every scene with a
## canned result so the runner runs the full case with no UI or timers.
class AutoPresenter extends RefCounted:
	var count := 0
	func present(cfg: Dictionary, on_done: Callable) -> void:
		count += 1
		var t := String(cfg.get("type", ""))
		var result := {}
		match t:
			"breach": result = {"evidence": cfg.get("evidence", [])}
			"read": result = {"grade": "solid"}
			"intercept": result = {"cut": true}
			"pursuit", "foot_chase": result = {"stars": 3}
			"standoff": result = {"clean": true}
			"choice":
				# exercise the choice grammar: take the left branch
				var branch: Dictionary = cfg.get("left", {})
				for k in branch.get("set", {}).keys():
					if String(k).begins_with("trust_"):
						GameState.adjust_trust(String(k).substr(6), int(branch["set"][k]))
					else:
						GameState.set_flag(String(k), branch["set"][k])
				result = {"choice": "left"}
		on_done.call(result)
