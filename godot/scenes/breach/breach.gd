extends Node3D

## Breach Scene — Smash-search through containers to bag evidence.
## Blocks are individual nodes with visible gaps and outlines for readability.
## Touch targets are generous. TRACE pulses a sonar ring outward.

@onready var camera: Camera3D = $Camera3D
@onready var block_container: Node3D = $BlockContainer
@onready var debris_container: Node3D = $DebrisContainer
@onready var evidence_container: Node3D = $EvidenceContainer
@onready var timer_label: Label = $UI/TopBar/TimerLabel
@onready var progress_label: Label = $UI/TopBar/ProgressLabel
@onready var trace_overlay: ColorRect = $UI/TraceOverlay
@onready var trace_label: Label = $UI/TraceLabel

# -- Colors --
const COL_LIGHT = Color(0.22, 0.35, 0.42)       # Blue-grey container block
const COL_LIGHT_EDGE = Color(0.28, 0.42, 0.50)   # Lighter edge highlight
const COL_HEAVY = Color(0.12, 0.18, 0.22)        # Dark heavy block
const COL_HEAVY_EDGE = Color(0.18, 0.25, 0.30)   # Heavy edge
const COL_HEAVY_CRACK = Color(0.45, 0.25, 0.15)  # Orange crack highlight
const COL_EVI = Color(0.27, 0.84, 0.78)          # Teal evidence glow
const COL_DECOY = Color(0.55, 0.23, 0.18)        # Red decoy
const COL_FLASH = Color(1.0, 0.95, 0.7)          # White-yellow hit flash
const COL_FLOOR = Color(0.07, 0.11, 0.13)

# -- State --
var _cfg: Dictionary
var _on_done: Callable
var _time_left: float = 60.0
var _active: bool = false
var _found_evidence: Array = []
var _target_evidence: Array = []
var _target_decoys: Array = []
var _evidence_nodes: Dictionary = {}  # Vector3i -> Node3D

var _smashed_count: int = 0
var _total_blocks: int = 0
var _camera_shake: float = 0.0

var _trace_charges: int = 1
var _trace_active: bool = false

# -- Block data --
var _blocks: Dictionary = {}  # Vector3i -> { node, health, is_heavy, mat, area }
const BLOCK_SIZE = 0.92  # Slightly smaller than 1.0 grid = visible gaps
const BLOCK_GAP = 1.0    # Grid spacing

# -- Shared resources --
var _light_mat: StandardMaterial3D
var _heavy_mat: StandardMaterial3D
var _light_mesh: BoxMesh
var _heavy_mesh: BoxMesh

# -- Debris pool --
var _debris_mesh: BoxMesh
var _debris_shape: BoxShape3D
var _debris_pool: Array[RigidBody3D] = []
const MAX_DEBRIS = 24

# -- Input --
var _touch_start: Vector2
var _is_dragging: bool = false
var _click_queue: Array[Vector2] = []

func _ready() -> void:
	_create_shared_resources()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	_time_left = float(cfg.get("time_s", 45.0))
	_target_evidence = cfg.get("evidence", [])
	_target_decoys = cfg.get("decoys", [])
	_trace_charges = 1 if cfg.get("trace", true) else 0
	
	if _trace_charges <= 0:
		trace_label.visible = false
	else:
		trace_label.text = "↑ TRACE (%d)" % _trace_charges
	
	_generate_level()
	_update_ui()
	_active = true

# --------------- SHARED RESOURCES ---------------

func _create_shared_resources() -> void:
	_light_mat = StandardMaterial3D.new()
	_light_mat.albedo_color = COL_LIGHT
	_light_mat.roughness = 0.75
	
	_heavy_mat = StandardMaterial3D.new()
	_heavy_mat.albedo_color = COL_HEAVY
	_heavy_mat.roughness = 0.6
	
	_light_mesh = BoxMesh.new()
	_light_mesh.size = Vector3(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	_light_mesh.surface_set_material(0, _light_mat)
	
	_heavy_mesh = BoxMesh.new()
	_heavy_mesh.size = Vector3(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	_heavy_mesh.surface_set_material(0, _heavy_mat)
	
	_debris_mesh = BoxMesh.new()
	_debris_mesh.size = Vector3(0.35, 0.35, 0.35)
	var dmat = StandardMaterial3D.new()
	dmat.albedo_color = COL_LIGHT
	dmat.roughness = 0.8
	_debris_mesh.surface_set_material(0, dmat)
	
	_debris_shape = BoxShape3D.new()
	_debris_shape.size = Vector3(0.35, 0.35, 0.35)

# --------------- LEVEL GENERATION ---------------

func _generate_level() -> void:
	_smashed_count = 0
	_total_blocks = 0
	
	var sx = 8
	var sy = 5
	var sz = 6
	
	for x in range(-sx / 2, sx / 2):
		for y in range(sy):
			for z in range(-sz / 2, sz / 2):
				var pos = Vector3i(x, y, z)
				var is_heavy = randf() > 0.8
				_spawn_block(pos, is_heavy)
				_total_blocks += 1
	
	for ev_dict in _target_evidence:
		_place_item(ev_dict, false, sx, sy, sz)
	for decoy_dict in _target_decoys:
		_place_item(decoy_dict, true, sx, sy, sz)
	
	# Empty red herrings (hollow pockets inside the wall)
	for i in range(4):
		var pos = _get_random_pos(sx, sy, sz)
		if _blocks.has(pos):
			_remove_block_silent(pos)

func _spawn_block(pos: Vector3i, is_heavy: bool) -> void:
	var node = Node3D.new()
	
	# Main mesh
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = _heavy_mesh if is_heavy else _light_mesh
	# Give each block its own material so we can flash it individually
	var mat = (_heavy_mat if is_heavy else _light_mat).duplicate()
	mesh_inst.set_surface_override_material(0, mat)
	node.add_child(mesh_inst)
	
	# Collision area for touch detection (slightly bigger than visual for generous targets)
	var area = Area3D.new()
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(BLOCK_GAP, BLOCK_GAP, BLOCK_GAP)  # Full grid cell = generous touch
	col.shape = shape
	area.add_child(col)
	area.set_meta("block_pos", pos)
	node.add_child(area)
	
	block_container.add_child(node)
	node.position = Vector3(pos.x * BLOCK_GAP, pos.y * BLOCK_GAP, pos.z * BLOCK_GAP)
	
	_blocks[pos] = {
		"node": node,
		"health": 2 if is_heavy else 1,
		"is_heavy": is_heavy,
		"mat": mat,
		"mesh": mesh_inst,
		"area": area,
	}

func _remove_block_silent(pos: Vector3i) -> void:
	if _blocks.has(pos):
		_blocks[pos]["node"].queue_free()
		_blocks.erase(pos)
		_total_blocks -= 1

func _get_random_pos(sx: int, sy: int, sz: int) -> Vector3i:
	for _i in range(100):
		var pos = Vector3i(
			randi_range(-sx / 2 + 1, sx / 2 - 2),
			randi_range(0, sy - 2),
			randi_range(-sz / 2 + 1, sz / 2 - 2)
		)
		if not _evidence_nodes.has(pos):
			return pos
	return Vector3i(0, 1, 0)

func _place_item(item_dict: Dictionary, is_decoy: bool, sx: int, sy: int, sz: int) -> void:
	var pos = _get_random_pos(sx, sy, sz)
	
	var ev_node = Node3D.new()
	
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.55, 0.55, 0.55)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COL_DECOY if is_decoy else COL_EVI
	mat.emission_enabled = true
	mat.emission = COL_DECOY if is_decoy else COL_EVI
	mat.emission_energy_multiplier = 0.0  # Hidden until nearby block smashed
	box.surface_set_material(0, mat)
	mesh_inst.mesh = box
	ev_node.add_child(mesh_inst)
	
	# Generous tap area for evidence
	var area = Area3D.new()
	var col = CollisionShape3D.new()
	var c_shape = BoxShape3D.new()
	c_shape.size = Vector3(1.2, 1.2, 1.2)  # Very generous touch target
	col.shape = c_shape
	area.add_child(col)
	ev_node.add_child(area)
	
	evidence_container.add_child(ev_node)
	ev_node.position = Vector3(pos.x * BLOCK_GAP, pos.y * BLOCK_GAP, pos.z * BLOCK_GAP)
	ev_node.set_meta("item", item_dict)
	ev_node.set_meta("is_decoy", is_decoy)
	ev_node.set_meta("mat", mat)
	ev_node.set_meta("grid_pos", pos)
	
	_evidence_nodes[pos] = ev_node

# --------------- GAME LOOP ---------------

func _process(delta: float) -> void:
	if _camera_shake > 0:
		_camera_shake = move_toward(_camera_shake, 0.0, delta * 6.0)
		camera.h_offset = randf_range(-_camera_shake, _camera_shake) * 0.08
		camera.v_offset = randf_range(-_camera_shake, _camera_shake) * 0.08
	else:
		camera.h_offset = 0
		camera.v_offset = 0

	if not _active:
		return
	_time_left -= delta
	if _time_left <= 0:
		_time_left = 0
		_finish_scene()
	_update_ui()

func _update_ui() -> void:
	var m = int(_time_left) / 60
	var s = int(_time_left) % 60
	timer_label.text = "%02d:%02d" % [m, s]
	progress_label.text = "%d / %d FOUND" % [_found_evidence.size(), _target_evidence.size()]

# --------------- INPUT ---------------

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

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
				# Pure upward swipe = TRACE gesture, don't smash
				if swipe_vec.y < -50 and abs(swipe_vec.x) < 50:
					pass
				else:
					_click_queue.append(event.position)

func _physics_process(_delta: float) -> void:
	if _click_queue.is_empty():
		return
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
				if col.has_meta("block_pos"):
					# Hit a block
					_hit_block(col.get_meta("block_pos"))
				elif col.get_parent() != null and col.get_parent().has_meta("item"):
					# Hit evidence
					_collect(col.get_parent())
	_click_queue.clear()

# --------------- BLOCK SMASHING ---------------

func _hit_block(pos: Vector3i) -> void:
	if not _blocks.has(pos):
		return
	var data = _blocks[pos]
	data["health"] -= 1

	if data["health"] > 0:
		# Cracked but not broken — flash orange and shake
		_flash_block(data, COL_HEAVY_CRACK, 0.3)
		_camera_shake = 0.4
		if AudioDirector.has_method("play_sfx"):
			AudioDirector.call("play_sfx", "crack")
		return

	# SHATTER
	var world_pos = data["node"].position
	_camera_shake = 1.0
	_smashed_count += 1

	if AudioDirector.has_method("play_sfx"):
		AudioDirector.call("play_sfx", "smash")

	# Spawn debris at the block's position
	_spawn_debris(world_pos)

	# Remove the block
	data["node"].queue_free()
	_blocks.erase(pos)

	# Hit-stop
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.02 * Engine.time_scale).timeout
	Engine.time_scale = 1.0

	# Reveal nearby evidence
	for ev_pos in _evidence_nodes.keys():
		var ev_node = _evidence_nodes[ev_pos]
		if is_instance_valid(ev_node) and ev_pos.distance_to(pos) < 2.5:
			var mat = ev_node.get_meta("mat")
			mat.emission_energy_multiplier = 3.0
			var t = ev_node.create_tween()
			t.tween_interval(2.0)
			t.tween_property(mat, "emission_energy_multiplier", 1.0, 0.8)

func _flash_block(data: Dictionary, color: Color, duration: float) -> void:
	var mat: StandardMaterial3D = data["mat"]
	var original_color = COL_HEAVY if data["is_heavy"] else COL_LIGHT
	mat.albedo_color = color
	var t = data["node"].create_tween()
	t.tween_property(mat, "albedo_color", original_color, duration)

func _spawn_debris(world_pos: Vector3) -> void:
	for i in range(3):
		var rb: RigidBody3D
		var mesh: MeshInstance3D
		if _debris_pool.size() < MAX_DEBRIS:
			rb = RigidBody3D.new()
			var col = CollisionShape3D.new()
			col.shape = _debris_shape
			rb.add_child(col)
			mesh = MeshInstance3D.new()
			mesh.mesh = _debris_mesh
			rb.add_child(mesh)
			debris_container.add_child(rb)
			_debris_pool.append(rb)
		else:
			rb = _debris_pool.pop_front()
			_debris_pool.append(rb)
			mesh = rb.get_child(1)
			mesh.scale = Vector3.ONE
			if mesh.has_meta("fade_tween"):
				var old_tween = mesh.get_meta("fade_tween")
				if is_instance_valid(old_tween):
					old_tween.kill()

		rb.freeze = true
		rb.global_position = world_pos + Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3)
		)
		rb.freeze = false
		rb.linear_velocity = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO

		var impulse = (Vector3.UP * 0.6 + Vector3(
			randf_range(-1, 1), 0, randf_range(-1, 1)
		)).normalized() * randf_range(6.0, 10.0)
		rb.apply_central_impulse(impulse)
		rb.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 3.0)

		var tween = mesh.create_tween()
		mesh.set_meta("fade_tween", tween)
		tween.tween_interval(2.0 + randf())
		tween.tween_property(mesh, "scale", Vector3.ZERO, 0.5)

# --------------- EVIDENCE COLLECTION ---------------

func _collect(node: Node3D) -> void:
	if not is_instance_valid(node):
		return

	var is_decoy = node.get_meta("is_decoy")
	var item_dict = node.get_meta("item")

	if is_decoy:
		if AudioDirector.has_method("play_sfx"):
			AudioDirector.call("play_sfx", "failure")
		_time_left -= 5.0
	else:
		if not item_dict in _found_evidence:
			_found_evidence.append(item_dict)
			if AudioDirector.has_method("play_sfx"):
				AudioDirector.call("play_sfx", "evidence_find")

	var grid_pos = node.get_meta("grid_pos")
	if _evidence_nodes.has(grid_pos):
		_evidence_nodes.erase(grid_pos)

	# Satisfying collect animation
	var tween = node.create_tween()
	tween.tween_property(node, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(node, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)
	_update_ui()

	if not is_decoy and _found_evidence.size() >= _target_evidence.size():
		await get_tree().create_timer(0.5).timeout
		_finish_scene()

# --------------- TRACE ---------------

func _trigger_trace() -> void:
	if _trace_charges <= 0 or _trace_active:
		return
	_trace_charges -= 1
	_trace_active = true
	trace_label.text = "↑ TRACE (%d)" % _trace_charges

	# Sonar pulse overlay
	var overlay_tween = trace_overlay.create_tween()
	overlay_tween.tween_property(trace_overlay, "color:a", 0.25, 0.15)
	overlay_tween.tween_property(trace_overlay, "color:a", 0.0, 0.6)

	# Pulse all evidence — they glow brightly then fade
	for pos in _evidence_nodes.keys():
		var node = _evidence_nodes[pos]
		if is_instance_valid(node):
			var mat = node.get_meta("mat")
			mat.emission_energy_multiplier = 5.0
			var t2 = node.create_tween()
			t2.tween_interval(2.5)
			t2.tween_property(mat, "emission_energy_multiplier", 0.8, 1.5)

	# Also briefly flash all remaining blocks translucent to "see through" them
	for bpos in _blocks.keys():
		var bdata = _blocks[bpos]
		if is_instance_valid(bdata["node"]):
			var bmat: StandardMaterial3D = bdata["mat"]
			bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bmat.albedo_color.a = 0.3
			var bt = bdata["node"].create_tween()
			bt.tween_interval(2.0)
			bt.tween_property(bmat, "albedo_color:a", 1.0, 0.5)
			bt.tween_callback(func():
				bmat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			)

	await get_tree().create_timer(3.5).timeout
	_trace_active = false

# --------------- FINISH ---------------

func _finish_scene() -> void:
	if not _active:
		return
	_active = false
	Engine.time_scale = 1.0

	var smashed_everything = float(_smashed_count) / float(max(_total_blocks, 1)) > 0.4
	Mirror.record_search(smashed_everything)

	if _on_done.is_valid():
		_on_done.call({"evidence": _found_evidence})
	queue_free()
