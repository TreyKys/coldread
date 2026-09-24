extends CanvasLayer
## SceneView — the presenter for the skeleton.
##
## This is a TEXT SPINE. It plays the narrative scene types for real (intro,
## cold_open, choice, debrief, title) so the case flow, the choice grammar,
## Trust, flags, saving, and the Mirror are all live and testable end to end.
##
## The gameplay scene types (breach, read, intercept, pursuit, foot_chase,
## standoff) are shown as PLACEHOLDER cards that return a sane result so the
## spine keeps flowing. Those are the ones Antigravity builds into real
## brick-voxel 3D scenes — see BUILD_PLAN.md § Scene templates. Each keeps the
## same contract: present(cfg, on_done) → on_done(result: Dictionary).

const COL_BG := Color("0A1013")
const COL_PANEL := Color("121C22")
const COL_LINE := Color("2B3C45")
const COL_INK := Color("E4EDF0")
const COL_MUTED := Color("7C939E")
const COL_ACCENT := Color("FF6A2B")
const COL_EVI := Color("45D6C6")
const COL_WARN := Color("EF4D63")
const COL_GOLD := Color("F2C14E")

var _faces := {}
var _bg: ColorRect
var _scroll: ScrollContainer
var _box: VBoxContainer
var _on_done: Callable

# choice countdown
var _choice_active := false
var _choice_time := 0.0
var _choice_cfg := {}
var _choice_bar: ProgressBar

func _ready() -> void:
	layer = 10
	var f = CaseLoader._read_json("res://data/faces.json")
	if f != null:
		_faces = f
	_bg = ColorRect.new()
	_bg.color = COL_BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	var center := MarginContainer.new()
	center.add_theme_constant_override("margin_left", 40)
	center.add_theme_constant_override("margin_right", 40)
	center.add_theme_constant_override("margin_top", 26)
	center.add_theme_constant_override("margin_bottom", 26)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(center)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(_box)

func _process(delta: float) -> void:
	if not _choice_active:
		return
	_choice_time -= delta
	if _choice_bar:
		_choice_bar.value = clampf(_choice_time / float(_choice_cfg.get("timer_s", 6)), 0.0, 1.0) * 100.0
	if _choice_time <= 0.0:
		_commit_choice("hesitate")

# ---------------------------------------------------------------- helpers

func _clear() -> void:
	for c in _box.get_children():
		c.queue_free()

func _label(text: String, size: int, col: Color, uppercase := false) -> Label:
	var l := Label.new()
	l.text = text.to_upper() if uppercase else text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _button(text: String, cb: Callable, ghost := false) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.add_theme_font_size_override("font_size", 16)
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_color_override("font_color", COL_INK if ghost else COL_BG)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0) if ghost else COL_ACCENT
	sb.set_border_width_all(1 if ghost else 0)
	sb.border_color = COL_LINE
	sb.set_corner_radius_all(3)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(cb)
	return b

func _portrait_row(face_id: String, who: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var swatch := ColorRect.new()      # placeholder for the procedural voxel face
	swatch.custom_minimum_size = Vector2(64, 64)
	var skin := COL_PANEL
	if _faces.has(face_id) and _faces[face_id].has("skin"):
		skin = Color(_faces[face_id]["skin"])
	swatch.color = skin
	row.add_child(swatch)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	col.add_child(_label(who, 12, COL_ACCENT, true))
	if _faces.has(face_id):
		col.add_child(_label(str(_faces[face_id].get("role", "")), 10, COL_MUTED, true))
	col.add_child(_label(text, 16, COL_INK))
	row.add_child(col)
	return row

func _tile(children: Array) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.set_border_width_all(1)
	sb.border_color = COL_LINE
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	for c in children:
		v.add_child(c)
	p.add_child(v)
	return p

func _kv(k: String, v: String, tone := "") -> HBoxContainer:
	var row := HBoxContainer.new()
	var lk := _label(k, 11, COL_MUTED, true)
	lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := COL_INK
	if tone == "good": col = Color("93D651")
	elif tone == "bad": col = COL_WARN
	elif tone == "cool": col = COL_EVI
	var lv := _label(v, 13, col)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(lk)
	row.add_child(lv)
	return row

# ---------------------------------------------------------------- dispatch

func present(cfg: Dictionary, on_done: Callable) -> void:
	_on_done = on_done
	_choice_active = false
	_scroll.scroll_vertical = 0
	match String(cfg.get("type", "")):
		"intro": _play_beats(cfg.get("beats", []), 0)
		"cold_open": _play_lines(cfg.get("lines", []), 0)
		"choice": _play_choice(cfg)
		"debrief": _play_debrief(cfg)
			"breach":
			var breach_scene = load("res://scenes/breach/breach.tscn").instantiate()
			get_tree().root.add_child(breach_scene)
			self.visible = false
			breach_scene.present(cfg, func(result):
				breach_scene.queue_free()
				self.visible = true
				_finish(result)
			)
				"read":
			var read_scene = load("res://scenes/read/read.tscn").instantiate()
			get_tree().root.add_child(read_scene)
			self.visible = false
			read_scene.present(cfg, func(result):
				read_scene.queue_free()
				self.visible = true
				_finish(result)
			)
		"intercept": _placeholder(cfg, "Predict the route, drag roadblocks onto the map. From Case 8 the weights lean away from your Mirror habits.", {"cut": true})
		"pursuit": _placeholder(cfg, "Lane driving. Swipe to switch lanes / drift, tap to ram, hold for the squad ability. Optional tilt-to-steer (pitch to Alex first).", {"stars": 2})
		"foot_chase": _placeholder(cfg, "Behind-the-shoulder runner. Swipe left/right to weave, up to vault, down to slide.", {"stars": 2})
		"standoff": _placeholder(cfg, "Slow-motion. Tap the right target fast. Hold to steady aim.", {"clean": true})
		_: _placeholder(cfg, "Unknown scene type.", {})

# ---------------------------------------------------------------- narrative

func _play_beats(beats: Array, idx: int) -> void:
	if idx >= beats.size():
		_finish({})
		return
	_clear()
	var b: Dictionary = beats[idx]
	if b.has("chapter"):
		var ch: Dictionary = b["chapter"]
		_box.add_child(_label(String(ch.get("k", "")), 10, COL_MUTED, true))
		_box.add_child(_label(String(ch.get("v", "")), 22, COL_INK))
	if b.has("face"):
		_box.add_child(_portrait_row(String(b["face"]), String(b.get("who", "")), String(b.get("text", ""))))
	elif b.has("narration"):
		if b.has("eyebrow"):
			_box.add_child(_label(String(b["eyebrow"]), 10, COL_ACCENT, true))
		_box.add_child(_label(String(b["narration"]), 16, COL_INK))
	elif b.has("text"):
		_box.add_child(_label(String(b["text"]), 16, COL_INK))
	_box.add_child(_label("%d / %d" % [idx + 1, beats.size()], 10, COL_MUTED))
	var last := idx == beats.size() - 1
	_box.add_child(_button("Take the badge" if last else "Continue", _play_beats.bind(beats, idx + 1)))

func _play_lines(lines: Array, idx: int) -> void:
	if idx >= lines.size():
		_finish({})
		return
	_clear()
	var l: Dictionary = lines[idx]
	if l.has("face"):
		_box.add_child(_portrait_row(String(l["face"]), String(l.get("who", "")), String(l.get("text", ""))))
	else:
		_box.add_child(_label(String(l.get("who", "Cold open")), 10, COL_ACCENT, true))
		_box.add_child(_label(String(l.get("text", "")), 17, COL_INK))
	_box.add_child(_label("%d / %d  ·  tap Continue" % [idx + 1, lines.size()], 10, COL_MUTED))
	_box.add_child(_button("Continue", _play_lines.bind(lines, idx + 1)))

func _play_choice(cfg: Dictionary) -> void:
	_clear()
	_choice_cfg = cfg
	_box.add_child(_label("Decision", 10, COL_WARN, true))
	_box.add_child(_label(String(cfg.get("prompt", "Choose")), 22, COL_INK))
	_choice_bar = ProgressBar.new()
	_choice_bar.show_percentage = false
	_choice_bar.value = 100
	_choice_bar.custom_minimum_size = Vector2(0, 5)
	var pb := StyleBoxFlat.new(); pb.bg_color = COL_WARN; pb.set_corner_radius_all(3)
	_choice_bar.add_theme_stylebox_override("fill", pb)
	_box.add_child(_choice_bar)
	var left: Dictionary = cfg.get("left", {})
	var right: Dictionary = cfg.get("right", {})
	_box.add_child(_button("◀  " + String(left.get("label", "Left")), _commit_choice.bind("left"), true))
	_box.add_child(_button(String(right.get("label", "Right")) + "  ▶", _commit_choice.bind("right"), true))
	_box.add_child(_label("Choices change who stands with you and how the city looks. Never difficulty.", 12, COL_MUTED))
	_choice_time = float(cfg.get("timer_s", 6)) + 1.2   # 1.2s grace to read
	_choice_active = true

func _commit_choice(which: String) -> void:
	if not _choice_active:
		return
	_choice_active = false
	var branch: Dictionary
	if which == "hesitate":
		branch = _choice_cfg.get("hesitate", _choice_cfg.get("right", {}))
		Mirror.record_hesitation()
	else:
		branch = _choice_cfg.get(which, {})
	for k in branch.get("set", {}).keys():
		if String(k).begins_with("trust_"):
			GameState.adjust_trust(String(k).substr(6), int(branch["set"][k]))
		else:
			GameState.set_flag(String(k), branch["set"][k])
	GameState.save()
	_clear()
	_box.add_child(_label("You hesitated" if which == "hesitate" else "Decided", 10, COL_ACCENT, true))
	_box.add_child(_label(String(branch.get("label", "")), 22, COL_INK))
	_box.add_child(_label(String(branch.get("result", "")), 16, COL_INK))
	_box.add_child(_label(String(branch.get("echo", "The squad will remember this.")), 12, COL_MUTED))
	_box.add_child(_button("Continue", _finish.bind({"choice": which})))

func _play_debrief(cfg: Dictionary) -> void:
	_clear()
	_box.add_child(_label("Debrief · " + String(cfg.get("_rank", cfg.get("rank", ""))), 10, COL_ACCENT, true))
	_box.add_child(_label(String(cfg.get("title", "Case closed")), 22, COL_INK))
	var st := int(GameState.stars.get(str(GameState.case_idx), 0))
	_box.add_child(_label("★".repeat(st) + "☆".repeat(3 - st), 20, COL_GOLD))
	_box.add_child(_label(String(cfg.get("text", "")), 15, COL_INK))
	var rows := []
	for r in cfg.get("rows", []):
		rows.append(_kv(String(r.get("k", "")), _resolve_row_value(r), String(r.get("tone", ""))))
	if rows.size() > 0:
		_box.add_child(_tile(rows))
	if bool(cfg.get("mirror", false)):
		var p := Mirror.profile()
		_box.add_child(_label("The Mirror is watching", 12, COL_MUTED, true))
		_box.add_child(_tile([
			_kv("Favourite block", String(p["favourite_block"])),
			_kv("Smash vs precise", "%d / %d" % [p["smash_vs_precise"][0], p["smash_vs_precise"][1]]),
			_kv("Hesitations", str(p["hesitations"])),
			_kv("Swipe bias", String(p["swipe_bias"])),
		]))
	if cfg.has("cliff"):
		_box.add_child(_label("Cliffhanger", 10, COL_WARN, true))
		_box.add_child(_label(String(cfg["cliff"]), 15, COL_INK))
	_box.add_child(_button(String(cfg.get("cta", "Continue")), _finish.bind({})))

## Debrief rows can be static {"k","value"} or dynamic {"k","flag","map"}.
func _resolve_row_value(r: Dictionary) -> String:
	if r.has("value"):
		return String(r["value"])
	if r.has("flag"):
		var fv = GameState.flags.get(String(r["flag"]), null)
		var m: Dictionary = r.get("map", {})
		if fv != null and m.has(String(fv)):
			return String(m[String(fv)])
		return String(m.get("_else", str(fv)))
	return ""

# ---------------------------------------------------------------- placeholder

func _placeholder(cfg: Dictionary, desc: String, result: Dictionary) -> void:
	_clear()
	var t := String(cfg.get("type", "")).to_upper().replace("_", " ")
	_box.add_child(_label("Gameplay scene · greybox reference exists", 10, COL_EVI, true))
	_box.add_child(_label(t, 26, COL_INK))
	if cfg.has("room"):
		_box.add_child(_label(String(cfg["room"]), 15, COL_MUTED))
	if cfg.has("win_text"):
		_box.add_child(_label(String(cfg["win_text"]), 14, COL_MUTED))
	_box.add_child(_tile([_label(desc, 14, COL_INK), _label("Antigravity builds this into a real brick-voxel scene. It returns: " + JSON.stringify(result), 11, COL_MUTED)]))
	_box.add_child(_button("Play through (stub)", _finish.bind(result)))

func _finish(result: Dictionary) -> void:
	_choice_active = false
	if _on_done.is_valid():
		var cb := _on_done
		_on_done = Callable()
		cb.call(result)

# ---------------------------------------------------------------- title

func show_title(cases: Array, on_pick: Callable, on_reset: Callable) -> void:
	_choice_active = false
	_clear()
	_scroll.scroll_vertical = 0
	_box.add_child(_label("Greybox → Godot · Act I", 10, COL_ACCENT, true))
	_box.add_child(_label("COLD READ", 48, COL_INK))
	_box.add_child(_label("Read the evidence. Predict the run. Wreck the getaway.", 12, COL_MUTED, true))
	for i in cases.size():
		var c: Dictionary = cases[i]
		var locked := i >= GameState.unlocked
		var st := int(GameState.stars.get(str(i), 0))
		var label := "0%d  %s" % [i + 1, String(c.get("name", "")).replace("Case %d · " % (i + 1), "")]
		var meta := String(c.get("rank", "")) + "  " + String(c.get("mins", ""))
		if st > 0:
			meta += "  " + "★".repeat(st)
		var b := _button(label + "     " + meta, on_pick.bind(i), true)
		b.disabled = locked
		if locked:
			b.modulate = Color(1, 1, 1, 0.4)
		_box.add_child(b)
	_box.add_child(_label("Keyboard: Enter advances. Touch: tap. This is the spine build — narrative scenes are live, gameplay scenes are stubs.", 11, COL_MUTED))
	_box.add_child(_button("Reset progress", on_reset, true))
