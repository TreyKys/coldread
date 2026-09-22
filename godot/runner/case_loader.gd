extends RefCounted
class_name CaseLoader
## Loads case data from res://data/. Cases are DATA, not code — Cases 4-10
## are added by dropping a JSON file in data/cases/ and listing it in
## data/manifest.json, with zero engine changes. This is the contract that
## must survive the whole project (README § Working conventions).

const DATA_DIR := "res://data/"
const CASES_DIR := "res://data/cases/"

static func _read_json(path: String):
	if not FileAccess.file_exists(path):
		push_error("COLD READ: missing data file " + path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed

## Returns Array of case dicts, in play order, with evidence ids resolved to
## full evidence dicts so templates never have to look them up.
static func load_cases() -> Array:
	var evidence: Dictionary = _read_json(DATA_DIR + "evidence.json")
	if evidence == null:
		evidence = {}
	var manifest = _read_json(DATA_DIR + "manifest.json")
	if manifest == null or not manifest.has("cases"):
		push_error("COLD READ: data/manifest.json missing or has no 'cases'")
		return []
	var out := []
	for file_name in manifest["cases"]:
		var c = _read_json(CASES_DIR + file_name)
		if c == null:
			continue
		_resolve_case(c, evidence)
		out.append(c)
	return out

## Replace evidence-id strings with full evidence dicts throughout a case.
static func _resolve_case(c: Dictionary, evidence: Dictionary) -> void:
	for sc in c.get("scenes", []):
		if sc.has("evidence"):
			sc["evidence"] = _resolve_list(sc["evidence"], evidence)
		if sc.has("decoys"):
			sc["decoys"] = _resolve_list(sc["decoys"], evidence)
		if sc.has("extra"):
			sc["extra"] = _resolve_list(sc["extra"], evidence)

static func _resolve_list(ids: Array, evidence: Dictionary) -> Array:
	var r := []
	for item in ids:
		if typeof(item) == TYPE_STRING:
			if evidence.has(item):
				r.append(evidence[item])
			else:
				push_warning("COLD READ: unknown evidence id '" + item + "'")
				r.append({"id": item, "name": item, "tag": "evidence"})
		else:
			r.append(item)   # already an inline evidence dict
	return r
