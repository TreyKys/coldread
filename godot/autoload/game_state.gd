extends Node
## Persistent player state. Ported from the greybox `S`.
##
## Everything the save file holds: progress, flags, Trust with each squad
## member, stars per case, the current evidence bag, revive count, and the
## Mirror (delegated to the Mirror autoload). Real game wants cloud sync
## later (ROADMAP § Monetization) — keep all reads/writes going through
## here so a sync layer can wrap it.

const SAVE_PATH := "user://coldread.save"
const SAVE_VERSION := 1

var case_idx := 0
var scene_idx := 0
var unlocked := 1                          # highest case index unlocked (1-based count)
var flags := {}                            # kemi, informant, keys, cole, public_trust, ...
var trust := {"dash": 1, "patch": 1, "juno": 1, "sol": 1, "wren": 1, "kemi": 0}
var stars := {}                            # case_idx (as string key) -> int 1..3
var evidence := []                         # evidence dicts bagged in the current case
var revive_used := 0

# run-scoped values folded between scenes (not persisted long-term)
var run := {"grade": "solid", "cut": false, "star_sum": 0, "star_n": 0, "last_stars": 3}

func set_flag(key: String, value) -> void:
	flags[key] = value

func adjust_trust(who: String, delta: int) -> void:
	trust[who] = clampi(int(trust.get(who, 0)) + delta, 0, 3)

func record_stars(n: int) -> void:
	run["last_stars"] = n
	run["star_sum"] += n
	run["star_n"] += 1
	stars[str(case_idx)] = maxi(1, roundi(float(run["star_sum"]) / maxf(1.0, float(run["star_n"]))))

func begin_case(idx: int) -> void:
	case_idx = idx
	scene_idx = 0
	evidence = []
	run = {"grade": "solid", "cut": false, "star_sum": 0, "star_n": 0, "last_stars": 3}

func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"case_idx": case_idx,
		"scene_idx": scene_idx,
		"unlocked": unlocked,
		"flags": flags,
		"trust": trust,
		"stars": stars,
		"revive_used": revive_used,
		"mirror": Mirror.to_dict(),
	}

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("COLD READ: could not open save file for write")
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	case_idx = int(parsed.get("case_idx", 0))
	scene_idx = int(parsed.get("scene_idx", 0))
	unlocked = int(parsed.get("unlocked", 1))
	flags = parsed.get("flags", {})
	trust = parsed.get("trust", trust)
	stars = parsed.get("stars", {})
	revive_used = int(parsed.get("revive_used", 0))
	if parsed.has("mirror"):
		Mirror.from_dict(parsed["mirror"])

func reset_progress() -> void:
	case_idx = 0
	scene_idx = 0
	unlocked = 1
	flags = {}
	trust = {"dash": 1, "patch": 1, "juno": 1, "sol": 1, "wren": 1, "kemi": 0}
	stars = {}
	evidence = []
	revive_used = 0
	run = {"grade": "solid", "cut": false, "star_sum": 0, "star_n": 0, "last_stars": 3}
	Mirror.reset()
	save()
