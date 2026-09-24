extends Node3D

## Breach 2.0 - Smash & Grab Diorama
## Time is based on previous scene's stars.
## Smash recognizable props to find evidence.

@onready var camera: Camera3D = $Camera3D
@onready var prop_container: Node3D = $PropContainer
@onready var debris_container: Node3D = $DebrisContainer
@onready var timer_label: Label = $UI/TopBar/TimerLabel
@onready var progress_label: Label = $UI/TopBar/ProgressLabel
@onready var trace_label: Label = $UI/TraceLabel
@onready var vignette: ColorRect = $UI/VignetteOverlay
@onready var ambient_light: DirectionalLight3D = $DirectionalLight3D

# -- State --
var _cfg: Dictionary
var _on_done: Callable
var _time_left: float = 30.0
var _active: bool = false
var _found_evidence: Array = []
var _target_evidence: Array = []
var _target_decoys: Array = []
var _trace_charges: int = 1
var _trace_active: bool = false

var _props: Array = [] # List of prop dictionaries
var _camera_shake: float = 0.0
var _smashed_count: int = 0

# -- Prop Definitions --
const TYPE_LIGHT = 0
const TYPE_MEDIUM = 1
const TYPE_HEAVY = 2

# -- Debris pool --
var _debris_mesh: BoxMesh
var _debris_shape: BoxShape3D
var _debris_pool: Array[RigidBody3D] = []
const MAX_DEBRIS = 30

# -- Input --
var _touch_start: Vector2
var _is_dragging: bool = false
var _click_queue: Array[Vector2] = []

func _ready() -> void:
	_init_debris_pool()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	
	_target_evidence = cfg.get("evidence", [])
	_target_decoys = cfg.get("decoys", [])
	_trace_charges = 1 if cfg.get("trace", true) else 0
	
	# Determine time based on last scene stars
	var last_stars = cfg.get("_last_stars", 3)
	if last_stars >= 3:
		_time_left = 45.0
	elif last_stars == 2:
		_time_left = 30.0
	else:
		_time_left = 15.0
		
	# Panic lighting if 1 star
	if last_stars <= 1:
		ambient_light.light_color = Color(1.0, 0.4, 0.3)
		vignette.color = Color(1.0, 0.0, 0.0, 0.2)
	
	if _trace_charges <= 0:
		trace_label.visible = false
	else:
		trace_label.text = "↑ TRACE (%d)" % _trace_charges
	
	_generate_room()
	_update_ui()
	_active = true

func _init_debris_pool() -> void:
	_debris_mesh = BoxMesh.new()
	_debris_mesh.size = Vector3(0.3, 0.3, 0.3)
	var dmat = StandardMaterial3D.new()
	dmat.albedo_color = Color(0.4, 0.4, 0.4)
	_debris_mesh.surface_set_material(0, dmat)
	
	_debris_shape = BoxShape3D.new()
	_debris_shape.size = Vector3(0.3, 0.3, 0.3)
	
	for i in range(MAX_DEBRIS):
		var rb = RigidBody3D.new()
		var col = CollisionShape3D.new()
		col.shape = _debris_shape
		rb.add_child(col)
		var mesh = MeshInstance3D.new()
		mesh.mesh = _debris_mesh
		rb.add_child(mesh)
		debris_container.add_child(rb)
		rb.freeze = true
		rb.visible = false
		_debris_pool.append(rb)

func _generate_room() -> void:
	# Define a grid for placing props
	var grid = []
	for x in range(-3, 4, 2):
		for z in range(-3, 4, 2):
			grid.append(Vector3(x, 0, z))
	grid.shuffle()
	
	# Determine contents
	var contents = []
	for e in _target_evidence: contents.append({"type": "evidence", "data": e})
	for d in _target_decoys: contents.append({"type": "decoy", "data": d})
	while contents.size() < 10:
		contents.append({"type": "empty"})
	contents.shuffle()
	
	# Spawn props
	for i in range(min(grid.size(), contents.size())):
		var pos = grid[i]
		var content = contents[i]
		
		var p_type = TYPE_LIGHT
		var r = randf()
		if r > 0.8: p_type = TYPE_HEAVY
		elif r > 0.4: p_type = TYPE_MEDIUM
		
		# If it holds evidence, slight bias towards making it heavier
		if content["type"] == "evidence" and p_type == TYPE_LIGHT:
			if randf() > 0.5: p_type = TYPE_MEDIUM
			
		_spawn_prop(pos, p_type, content)

func _spawn_prop(pos: Vector3, type: int, content: Dictionary) -> void:
	var node = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.8
	
	var hp = 1
	var col_shape = BoxShape3D.new()
	
	if type == TYPE_LIGHT:
		hp = 1
		var b = BoxMesh.new()
		b.size = Vector3(1, 1, 1)
		mesh_inst.mesh = b
		mat.albedo_color = Color(0.6, 0.5, 0.4) # Cardboard brown
		col_shape.size = Vector3(1.5, 1.5, 1.5)
		pos.y = 0.5
	elif type == TYPE_MEDIUM:
		hp = 1
		var b = BoxMesh.new()
		b.size = Vector3(1.5, 1.2, 1.0)
		mesh_inst.mesh = b
		mat.albedo_color = Color(0.3, 0.4, 0.5) # Steel desk
		col_shape.size = Vector3(2.0, 1.8, 1.5)
		pos.y = 0.6
	elif type == TYPE_HEAVY:
		hp = 1
		var b = BoxMesh.new()
		b.size = Vector3(1.2, 2.0, 1.2)
		mesh_inst.mesh = b
		mat.albedo_color = Color(0.2, 0.2, 0.2) # Dark safe/server
		col_shape.size = Vector3(1.8, 2.5, 1.8)
		pos.y = 1.0
		
	# Subtle tells
	if content["type"] == "evidence":
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.3, 0.3)
		mat.emission_energy_multiplier = 0.5
		
	mesh_inst.set_surface_override_material(0, mat)
	node.add_child(mesh_inst)
	
	var area = Area3D.new()
	var col = CollisionShape3D.new()
	col.shape = col_shape
	area.add_child(col)
	node.add_child(area)
	
	prop_container.add_child(node)
	node.position = pos
	
	var p_data = {
		"node": node,
		"mesh": mesh_inst,
		"mat": mat,
		"area": area,
		"hp": hp,
		"max_hp": hp,
		"content": content,
		"active": true
	}
	area.set_meta("prop_idx", _props.size())
	_props.append(p_data)

func _process(delta: float) -> void:
	if _camera_shake > 0:
		_camera_shake = move_toward(_camera_shake, 0.0, delta * 6.0)
		var offset = randf_range(-_camera_shake, _camera_shake) * 0.1
		camera.h_offset = offset
		camera.v_offset = offset
	else:
		camera.h_offset = 0
		camera.v_offset = 0

	if not _active: return
	
	_time_left -= delta
	if _time_left <= 0:
		_time_left = 0
		_finish_scene()
		
	if _time_left < 10.0 and int(_time_left * 10) % 5 == 0:
		vignette.color.a = 0.4
	else:
		vignette.color.a = lerp(vignette.color.a, 0.0, delta * 5.0)
		
	_update_ui()

func _update_ui() -> void:
	var m = int(_time_left) / 60
	var s = int(_time_left) % 60
	timer_label.text = "%02d:%02d" % [m, s]
	progress_label.text = "%d / %d FOUND" % [_found_evidence.size(), _target_evidence.size()]
	
	if _time_left < 10.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _unhandled_input(event: InputEvent) -> void:
	if not _active: return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.is_pressed()
		var pos = event.position

		if pressed:
			_touch_start = pos
			_is_dragging = false
			_click_queue.append(pos)
		else:
			if _is_dragging:
				var swipe_vec = pos - _touch_start
				if swipe_vec.y < -100 and abs(swipe_vec.x) < 100:
					_trigger_trace()
			_is_dragging = false

	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		var mask = 1
		if event is InputEventMouseMotion:
			mask = event.button_mask & MOUSE_BUTTON_MASK_LEFT
		if mask != 0:
			_is_dragging = true
			if event.position.distance_to(_touch_start) > 20:
				var swipe_vec = event.position - _touch_start
				if swipe_vec.y < -50 and abs(swipe_vec.x) < 50:
					pass
				else:
					_click_queue.append(event.position)

func _physics_process(_delta: float) -> void:
	if _click_queue.is_empty(): return
	var space_state = get_world_3d().direct_space_state
	for screen_pos in _click_queue:
		var from = camera.project_ray_origin(screen_pos)
		var dir = camera.project_ray_normal(screen_pos)
		var to = from + dir * 100.0

		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query)

		if result:
			var col = result.collider
			if col is Area3D:
				if col.has_meta("prop_idx"):
					_hit_prop(col.get_meta("prop_idx"))
				elif col.has_meta("item"):
					_collect_item(col)
	_click_queue.clear()

func _hit_prop(idx: int) -> void:
	var p = _props[idx]
	if not p["active"]: return
	
	p["hp"] -= 1
	
	if p["hp"] > 0:
		_camera_shake = 0.3
		var mat: StandardMaterial3D = p["mat"]
		var orig = mat.albedo_color
		mat.albedo_color = Color(1.0, 0.8, 0.8)
		var t = p["node"].create_tween()
		t.tween_property(mat, "albedo_color", orig, 0.15)
		
		# Shrink slightly per hit
		var s = float(p["hp"]) / float(p["max_hp"])
		p["mesh"].scale = Vector3(1.0, 0.8 + 0.2 * s, 1.0)
		return
		
	# SMASH
	p["active"] = false
	p["mesh"].visible = false
	p["area"].queue_free()
	_smashed_count += 1
	_camera_shake = 0.8
	
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.02 * Engine.time_scale).timeout
	Engine.time_scale = 1.0
	
	_spawn_debris(p["node"].global_position)
	
	var c = p["content"]
	if c["type"] != "empty":
		_reveal_item(p["node"].global_position, c)

func _reveal_item(pos: Vector3, content: Dictionary) -> void:
	var node = Node3D.new()
	var mesh = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = Vector3(0.6, 0.6, 0.6)
	mesh.mesh = b
	
	var mat = StandardMaterial3D.new()
	var is_decoy = content["type"] == "decoy"
	var col = Color(0.8, 0.2, 0.2) if is_decoy else Color(0.2, 0.8, 0.8)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.0
	mesh.set_surface_override_material(0, mat)
	node.add_child(mesh)
	
	var area = Area3D.new()
	var col_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.5, 1.5, 1.5)
	col_shape.shape = shape
	area.add_child(col_shape)
	area.set_meta("item", content)
	node.add_child(area)
	
	prop_container.add_child(node)
	node.global_position = pos + Vector3(0, 0.5, 0)
	
	var t = node.create_tween()
	node.scale = Vector3.ZERO
	t.tween_property(node, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _spawn_debris(pos: Vector3) -> void:
	for i in range(5):
		var rb = _debris_pool.pop_front()
		_debris_pool.append(rb)
		rb.visible = true
		rb.freeze = true
		rb.global_position = pos + Vector3(randf_range(-0.5, 0.5), randf_range(0.2, 1.0), randf_range(-0.5, 0.5))
		rb.freeze = false
		rb.linear_velocity = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO
		var imp = (Vector3.UP + Vector3(randf_range(-1,1), 0, randf_range(-1,1))).normalized() * randf_range(5.0, 10.0)
		rb.apply_central_impulse(imp)
		rb.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 5.0)

func _collect_item(area: Area3D) -> void:
	var content = area.get_meta("item")
	var is_decoy = content["type"] == "decoy"
	var data = content["data"]
	
	if is_decoy:
		_time_left -= 2.0
		_camera_shake = 0.5
		vignette.color = Color(1, 0, 0, 0.5)
	else:
		if not data in _found_evidence:
			_found_evidence.append(data)
			
	var node = area.get_parent()
	var t = node.create_tween()
	t.tween_property(node, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
	t.tween_property(node, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(node.queue_free)
	
	if not is_decoy and _found_evidence.size() >= _target_evidence.size():
		await get_tree().create_timer(0.5).timeout
		_finish_scene()

func _trigger_trace() -> void:
	if _trace_charges <= 0 or _trace_active: return
	_trace_charges -= 1
	_trace_active = true
	trace_label.text = "↑ TRACE (%d)" % _trace_charges
	
	for p in _props:
		if p["active"] and p["content"]["type"] == "evidence":
			var mat: StandardMaterial3D = p["mat"]
			mat.emission_energy_multiplier = 4.0
			var t = p["node"].create_tween()
			t.tween_interval(2.0)
			t.tween_property(mat, "emission_energy_multiplier", 0.5, 1.0)
			
		elif p["active"]:
			var mat: StandardMaterial3D = p["mat"]
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.2
			var t = p["node"].create_tween()
			t.tween_interval(2.0)
			t.tween_property(mat, "albedo_color:a", 1.0, 1.0)
			t.tween_callback(func(): mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED)
			
	await get_tree().create_timer(3.0).timeout
	_trace_active = false

func _finish_scene() -> void:
	if not _active: return
	_active = false
	Engine.time_scale = 1.0
	
	var smashed_everything = float(_smashed_count) / float(max(_props.size(), 1)) > 0.8
	Mirror.record_search(smashed_everything)
	
	if _on_done.is_valid():
		_on_done.call({"evidence": _found_evidence})
	queue_free()
