extends Node3D

@onready var camera = $Camera3D
@onready var grid_map = $GridMap
@onready var debris_container = $DebrisContainer
@onready var evidence_container = $EvidenceContainer
@onready var timer_label = $UI/TopBar/TimerLabel
@onready var progress_label = $UI/TopBar/ProgressLabel
@onready var trace_overlay = $UI/TraceOverlay

const COL_EVI = Color("45D6C6")
const COL_CONTAINER = Color("2d4c5c")
const COL_HEAVY = Color("1a2c35")
const COL_DECOY = Color("8c3b2d")

var _cfg: Dictionary
var _on_done: Callable
var _time_left: float = 60.0
var _active: bool = false
var _found_evidence: Array = []
var _target_evidence: Array = []
var _target_decoys: Array = []
var _evidence_nodes: Dictionary = {}

var _smashed_count: int = 0
var _total_blocks: int = 0
var _camera_shake: float = 0.0

var _trace_charges: int = 1
var _trace_active: bool = false

var _voxel_mat: StandardMaterial3D
var _heavy_mat: StandardMaterial3D
var _debris_mesh: BoxMesh
var _debris_shape: BoxShape3D
var _debris_pool: Array[RigidBody3D] = []
const MAX_DEBRIS = 30

var _touch_start: Vector2
var _is_dragging: bool = false
var _last_hit_cell := Vector3i(-999, -999, -999)
var _click_queue: Array[Vector2] = []

# Cell health mapping
var _cell_health: Dictionary = {}

func _ready() -> void:
	_setup_mesh_library()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	_time_left = float(cfg.get("time_s", 60.0))
	
	_target_evidence = cfg.get("evidence", [])
	_target_decoys = cfg.get("decoys", [])
		
	_generate_level()
	_update_ui()
	_active = true

func _setup_mesh_library() -> void:
	var library = MeshLibrary.new()
	
	_voxel_mat = StandardMaterial3D.new()
	_voxel_mat.albedo_color = COL_CONTAINER
	
	_heavy_mat = StandardMaterial3D.new()
	_heavy_mat.albedo_color = COL_HEAVY
	
	var box = BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	
	# Light container (0)
	var light_mesh = box.duplicate()
	light_mesh.surface_set_material(0, _voxel_mat)
	library.create_item(0)
	library.set_item_mesh(0, light_mesh)
	
	# Heavy container (1)
	var heavy_mesh = box.duplicate()
	heavy_mesh.surface_set_material(0, _heavy_mat)
	library.create_item(1)
	library.set_item_mesh(1, heavy_mesh)
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, 1, 1)
	library.set_item_shapes(0, [shape, Transform3D.IDENTITY])
	library.set_item_shapes(1, [shape, Transform3D.IDENTITY])
	
	grid_map.mesh_library = library
	
	_debris_mesh = BoxMesh.new()
	_debris_mesh.size = Vector3(0.5, 0.5, 0.5)
	_debris_mesh.surface_set_material(0, _voxel_mat)
	_debris_shape = BoxShape3D.new()
	_debris_shape.size = Vector3(0.5, 0.5, 0.5)

func _generate_level() -> void:
	grid_map.clear()
	_smashed_count = 0
	
	var sx = 8
	var sy = 5
	var sz = 6
	_total_blocks = 0
	
	for x in range(-sx/2, sx/2):
		for y in range(sy):
			for z in range(-sz/2, sz/2):
				var is_heavy = randf() > 0.8
				var type = 1 if is_heavy else 0
				var pos = Vector3i(x, y, z)
				grid_map.set_cell_item(pos, type)
				_cell_health[pos] = 2 if is_heavy else 1
				_total_blocks += 1
				
	for ev_dict in _target_evidence:
		_place_item(ev_dict, false, sx, sy, sz)
	for decoy_dict in _target_decoys:
		_place_item(decoy_dict, true, sx, sy, sz)
		
	# Empty red herrings
	for i in range(5):
		var pos = _get_random_pos(sx, sy, sz)
		if grid_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			grid_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)
			_cell_health.erase(pos)
			_total_blocks -= 1

func _get_random_pos(sx: int, sy: int, sz: int) -> Vector3i:
	for _i in range(100):
		var pos = Vector3i(randi_range(-sx/2 + 1, sx/2 - 2), randi_range(0, sy - 2), randi_range(-sz/2 + 1, sz/2 - 2))
		if not _evidence_nodes.has(pos):
			return pos
	return Vector3i.ZERO

func _place_item(item_dict: Dictionary, is_decoy: bool, sx: int, sy: int, sz: int) -> void:
	var pos = _get_random_pos(sx, sy, sz)
	var ev_node = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COL_DECOY if is_decoy else COL_EVI
	mat.emission_enabled = true
	mat.emission = COL_DECOY if is_decoy else COL_EVI
	mat.emission_energy_multiplier = 0.0
	box.surface_set_material(0, mat)
	mesh_inst.mesh = box
	ev_node.add_child(mesh_inst)
	
	var area = Area3D.new()
	var col = CollisionShape3D.new()
	var c_shape = BoxShape3D.new()
	c_shape.size = Vector3(1, 1, 1)
	col.shape = c_shape
	area.add_child(col)
	ev_node.add_child(area)
	
	evidence_container.add_child(ev_node)
	ev_node.global_position = grid_map.map_to_local(pos)
	ev_node.set_meta("item", item_dict)
	ev_node.set_meta("is_decoy", is_decoy)
	ev_node.set_meta("mat", mat)
	ev_node.set_meta("grid_pos", pos)
	
	_evidence_nodes[pos] = ev_node

func _process(delta: float) -> void:
	if _camera_shake > 0:
		_camera_shake = move_toward(_camera_shake, 0.0, delta * 5.0)
		camera.h_offset = randf_range(-_camera_shake, _camera_shake) * 0.1
		camera.v_offset = randf_range(-_camera_shake, _camera_shake) * 0.1
	else:
		camera.h_offset = 0
		camera.v_offset = 0

	if not _active: return
	_time_left -= delta
	if _time_left <= 0:
		_time_left = 0
		_finish_scene()
	_update_ui()

func _update_ui() -> void:
	var m = int(_time_left) / 60
	var s = int(_time_left) % 60
	timer_label.text = "%02d:%02d" % [m, s]
	
	var t = _target_evidence.size()
	var f = _found_evidence.size()
	progress_label.text = "%d / %d FOUND" % [f, t]

func _unhandled_input(event: InputEvent) -> void:
	if not _active: return
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.is_pressed()
		var pos = event.position
		
		if pressed:
			_touch_start = pos
			_is_dragging = false
			_last_hit_cell = Vector3i(-999, -999, -999)
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

func _physics_process(delta: float) -> void:
	if _click_queue.size() > 0:
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
				if col is GridMap:
					var local_hit = grid_map.to_local(result.position - result.normal * 0.1)
					var cell_pos = grid_map.local_to_map(local_hit)
					if cell_pos != _last_hit_cell and grid_map.get_cell_item(cell_pos) != GridMap.INVALID_CELL_ITEM:
						_last_hit_cell = cell_pos
						_hit_block(cell_pos, result.normal)
				elif col.get_parent() != null and col.get_parent().has_meta("item"):
					_collect(col.get_parent())
		_click_queue.clear()

func _hit_block(cell: Vector3i, hit_normal: Vector3) -> void:
	if not _cell_health.has(cell): return
	_cell_health[cell] -= 1
	
	if _cell_health[cell] > 0:
		_camera_shake = 0.5
		if AudioDirector.has_method("play_sfx"):
			AudioDirector.call("play_sfx", "crack")
		return
		
	grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
	_smashed_count += 1
	_camera_shake = 1.0
	if AudioDirector.has_method("play_sfx"):
		AudioDirector.call("play_sfx", "smash")
	
	_spawn_debris(cell, hit_normal)
	
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.02 * Engine.time_scale).timeout
	Engine.time_scale = 1.0
	
	for pos in _evidence_nodes.keys():
		var node = _evidence_nodes[pos]
		if is_instance_valid(node) and pos.distance_to(cell) < 2.0:
			var mat = node.get_meta("mat")
			mat.emission_energy_multiplier = 2.0
			var t = node.create_tween()
			t.tween_interval(1.5)
			t.tween_property(mat, "emission_energy_multiplier", 0.0, 1.0)

func _spawn_debris(cell: Vector3i, hit_normal: Vector3) -> void:
	for i in range(2):
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
		rb.global_position = grid_map.map_to_local(cell) + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		rb.freeze = false
		
		rb.linear_velocity = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO
		var impulse = (hit_normal * -1 + Vector3.UP * 0.5 + Vector3(randf_range(-0.5,0.5), 0, randf_range(-0.5,0.5))).normalized() * randf_range(8.0, 12.0)
		rb.apply_central_impulse(impulse)
		rb.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 4.0)
		
		var tween = mesh.create_tween()
		mesh.set_meta("fade_tween", tween)
		tween.tween_interval(2.0 + randf())
		tween.tween_property(mesh, "scale", Vector3.ZERO, 0.5)

func _collect(node: Node3D) -> void:
	if not is_instance_valid(node): return
	
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
	
	var tween = node.create_tween()
	tween.tween_property(node, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(node, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)
	_update_ui()
	
	if not is_decoy and _found_evidence.size() >= _target_evidence.size():
		await get_tree().create_timer(0.5).timeout
		_finish_scene()

func _trigger_trace() -> void:
	if _trace_charges <= 0 or _trace_active: return
	_trace_charges -= 1
	_trace_active = true
	
	var tween = trace_overlay.create_tween()
	tween.tween_property(trace_overlay, "color:a", 0.3, 0.2)
	tween.tween_property(trace_overlay, "color:a", 0.0, 0.5)
	
	for pos in _evidence_nodes.keys():
		var node = _evidence_nodes[pos]
		if is_instance_valid(node):
			var mat = node.get_meta("mat")
			mat.emission_energy_multiplier = 4.0
			var t2 = node.create_tween()
			t2.tween_interval(2.0)
			t2.tween_property(mat, "emission_energy_multiplier", 0.0, 1.0)
			
	await get_tree().create_timer(3.0).timeout
	_trace_active = false

func _finish_scene() -> void:
	if not _active: return
	_active = false
	Engine.time_scale = 1.0
	
	var smashed_everything = float(_smashed_count) / float(max(_total_blocks, 1)) > 0.4
	Mirror.record_search(smashed_everything)
	
	if _on_done.is_valid():
		_on_done.call({"evidence": _found_evidence})
	queue_free()
