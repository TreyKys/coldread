extends Node3D

## 3D Breach Scene — Destructible voxel environment for evidence searching.
## Built for Godot 4.x / Mobile.

@onready var camera = $Camera3D
@onready var grid_map = $GridMap
@onready var debris_container = $DebrisContainer
@onready var evidence_container = $EvidenceContainer
@onready var timer_label = $UI/TopBar/TimerLabel
@onready var progress_label = $UI/TopBar/ProgressLabel
@onready var trace_overlay = $UI/TraceOverlay

const COL_EVI = Color("45D6C6")
const COL_BRICK = Color("8c3b2d")
const COL_CONTAINER = Color("2d4c5c")

var _cfg: Dictionary
var _on_done: Callable
var _time_left: float = 45.0
var _active: bool = false
var _found_evidence: Array = []
var _target_evidence: Array = []
var _evidence_nodes: Dictionary = {}

var _smashed_count: int = 0
var _total_blocks: int = 0
var _camera_shake: float = 0.0

var _voxel_mesh: BoxMesh
var _voxel_mat: StandardMaterial3D

# Input tracking
var _touch_start: Vector2
var _is_dragging: bool = false
var _drag_timer: float = 0.0
var _last_hit_cell := Vector3i(-999, -999, -999)

func _ready() -> void:
	_setup_mesh_library()

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	_time_left = float(cfg.get("time_limit", 60.0))
	
	var ev_ids = cfg.get("evidence", [])
	if ev_ids is Array:
		_target_evidence = ev_ids
		
	_generate_level()
	_update_ui()
	_active = true

func _setup_mesh_library() -> void:
	var library = MeshLibrary.new()
	_voxel_mesh = BoxMesh.new()
	_voxel_mesh.size = Vector3(1, 1, 1)
	
	_voxel_mat = StandardMaterial3D.new()
	_voxel_mat.albedo_color = COL_CONTAINER
	_voxel_mat.roughness = 0.8
	_voxel_mat.metallic = 0.2
	_voxel_mesh.surface_set_material(0, _voxel_mat)
	
	library.create_item(0)
	library.set_item_mesh(0, _voxel_mesh)
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, 1, 1)
	library.set_item_shapes(0, [shape, Transform3D.IDENTITY])
	
	grid_map.mesh_library = library

func _generate_level() -> void:
	grid_map.clear()
	for child in debris_container.get_children():
		child.queue_free()
	for child in evidence_container.get_children():
		child.queue_free()
		
	_smashed_count = 0
	
	# Create a blocky container shape
	var sx = 8
	var sy = 5
	var sz = 6
	_total_blocks = 0
	
	for x in range(-sx/2, sx/2):
		for y in range(sy):
			for z in range(-sz/2, sz/2):
				grid_map.set_cell_item(Vector3i(x, y, z), 0)
				_total_blocks += 1
				
	for ev_id in _target_evidence:
		_place_evidence(ev_id, sx, sy, sz)

func _place_evidence(id: String, sx: int, sy: int, sz: int) -> void:
	var px = randi_range(-sx/2 + 1, sx/2 - 2)
	var py = randi_range(0, sy - 2)
	var pz = randi_range(-sz/2 + 1, sz/2 - 2)
	var pos = Vector3i(px, py, pz)
	
	var ev_node = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COL_EVI
	mat.emission_enabled = true
	mat.emission = COL_EVI
	mat.emission_energy_multiplier = 0.0 # Hidden initially
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
	ev_node.set_meta("evidence_id", id)
	ev_node.set_meta("mat", mat)
	
	_evidence_nodes[pos] = ev_node

func _process(delta: float) -> void:
	if _camera_shake > 0:
		_camera_shake = move_toward(_camera_shake, 0.0, delta * 5.0)
		camera.h_offset = randf_range(-_camera_shake, _camera_shake) * 0.1
		camera.v_offset = randf_range(-_camera_shake, _camera_shake) * 0.1
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
	
	var t = _target_evidence.size()
	var f = _found_evidence.size()
	progress_label.text = "%d / %d FOUND" % [f, t]

func _unhandled_input(event: InputEvent) -> void:
	if not _active: return
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.is_pressed() if event is InputEventScreenTouch else event.pressed
		var pos = event.position
		
		if pressed:
			_touch_start = pos
			_is_dragging = false
			_drag_timer = 0.0
			_last_hit_cell = Vector3i(-999, -999, -999)
			_process_hit(pos)
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
		else:
			mask = 1 # ScreenDrag is always pressed
			
		if mask != 0:
			_is_dragging = true
			if event.position.distance_to(_touch_start) > 20:
				_process_hit(event.position)

func _process_hit(screen_pos: Vector2) -> void:
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	var to = from + dir * 100.0
	
	var space_state = get_world_3d().direct_space_state
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
				_smash_block(cell_pos, result.normal)
		elif col.get_parent() != null and col.get_parent().has_meta("evidence_id"):
			_collect(col.get_parent())

func _smash_block(cell: Vector3i, hit_normal: Vector3) -> void:
	grid_map.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
	_smashed_count += 1
	_camera_shake = 1.0
	
	if AudioDirector.has_method("play_sfx"):
		AudioDirector.call("play_sfx", "smash")
	
	# Spawn physics debris (4 mini blocks)
	for i in range(4):
		var rb = RigidBody3D.new()
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.5, 0.5, 0.5)
		col.shape = shape
		rb.add_child(col)
		
		var mesh = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.5, 0.5, 0.5)
		bm.surface_set_material(0, _voxel_mat)
		mesh.mesh = bm
		rb.add_child(mesh)
		
		debris_container.add_child(rb)
		rb.global_position = grid_map.map_to_local(cell) + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		var impulse = (hit_normal * -1 + Vector3.UP * 0.5 + Vector3(randf_range(-0.5,0.5), 0, randf_range(-0.5,0.5))).normalized() * randf_range(8.0, 12.0)
		rb.apply_central_impulse(impulse)
		rb.apply_torque_impulse(Vector3(randf(), randf(), randf()) * 4.0)
		
		# Auto cleanup
		var tween = create_tween()
		tween.tween_interval(2.0 + randf())
		tween.tween_property(mesh, "scale", Vector3.ZERO, 0.5)
		tween.tween_callback(rb.queue_free)
		
	# Hit stop juice
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.02 * Engine.time_scale).timeout
	Engine.time_scale = 1.0
	
	# Reveal evidence if uncovered
	for pos in _evidence_nodes.keys():
		if pos.distance_to(cell) < 2.0:
			var mat = _evidence_nodes[pos].get_meta("mat")
			mat.emission_energy_multiplier = 2.0

func _collect(node: Node3D) -> void:
	var id = node.get_meta("evidence_id")
	if not id in _found_evidence:
		_found_evidence.append(id)
		if AudioDirector.has_method("play_sfx"):
			AudioDirector.call("play_sfx", "evidence_find")
		
		var tween = create_tween()
		tween.tween_property(node, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
		tween.tween_property(node, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(node.queue_free)
		_update_ui()
		
		if _found_evidence.size() >= _target_evidence.size():
			await get_tree().create_timer(0.5).timeout
			_finish_scene()

func _trigger_trace() -> void:
	var tween = create_tween()
	tween.tween_property(trace_overlay, "color:a", 0.3, 0.2)
	tween.tween_property(trace_overlay, "color:a", 0.0, 0.5)
	
	for pos in _evidence_nodes.keys():
		var node = _evidence_nodes[pos]
		if is_instance_valid(node):
			var mat = node.get_meta("mat")
			mat.emission_energy_multiplier = 4.0
			var t2 = create_tween()
			t2.tween_interval(1.5)
			t2.tween_property(mat, "emission_energy_multiplier", 0.0, 1.0)

func _finish_scene() -> void:
	if not _active: return
	_active = false
	
	# Mirror recording
	var ratio = float(_smashed_count) / float(max(_total_blocks, 1))
	if Mirror.has_method("record_event"):
		var style = "smashed_everything" if ratio > 0.3 else "precise"
		Mirror.call("record_event", "breach_method", {"style": style, "ratio": ratio})
	
	if _on_done.is_valid():
		_on_done.call({"evidence": _found_evidence})
	queue_free()
