extends Node3D

## Standoff Scene - Slow motion target selection
## Player must tap the correct target before the timer expires.

@onready var camera: Camera3D = $Camera3D
@onready var target_container: Node3D = $TargetContainer
@onready var timer_label: Label = $UI/TimerLabel
@onready var instruction_label: Label = $UI/InstructionLabel
@onready var flash_rect: ColorRect = $UI/FlashRect

var _cfg: Dictionary
var _on_done: Callable
var _active: bool = false
var _time_left: float = 5.0
var _targets_data: Array = []

var _target_nodes: Array = []
var _correct_id: String = ""

const COL_TARGET = Color(0.8, 0.2, 0.2)
const COL_CORRECT_FLASH = Color(0.2, 0.8, 0.8)
const COL_WRONG_FLASH = Color(0.8, 0.1, 0.1)

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	_time_left = float(cfg.get("time_s", 5.0))
	_targets_data = cfg.get("targets", [])
	
	for t in _targets_data:
		if t.get("correct", false):
			_correct_id = String(t.get("id", ""))
			break
			
	Engine.time_scale = 0.3 # Slow motion
	
	_spawn_targets()
	
	flash_rect.color.a = 1.0
	var tw = create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, 1.0)
	
	_active = true

func _spawn_targets() -> void:
	var count = _targets_data.size()
	var spacing = 3.0
	var start_x = -(count - 1) * spacing / 2.0
	
	for i in range(count):
		var t_data = _targets_data[i]
		
		# 3D Node
		var node = Node3D.new()
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1, 2, 1)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = COL_TARGET
		box.surface_set_material(0, mat)
		mesh_inst.mesh = box
		node.add_child(mesh_inst)
		
		var area = Area3D.new()
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(1.5, 2.5, 1.5) # Generous touch target
		col.shape = shape
		area.add_child(col)
		area.set_meta("id", String(t_data.get("id", "")))
		node.add_child(area)
		
		target_container.add_child(node)
		node.position = Vector3(start_x + i * spacing, 1.0, -8.0 + randf_range(-1, 1))
		
		# 2D Label
		var label = Label.new()
		label.text = String(t_data.get("label", ""))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		$UI/Labels.add_child(label)
		
		_target_nodes.append({"node": node, "label": label})

func _process(delta: float) -> void:
	# Keep time relative to real time for the timer
	var real_delta = delta / Engine.time_scale if Engine.time_scale > 0 else 0.0
	
	if _active:
		_time_left -= real_delta
		if _time_left <= 0:
			_time_left = 0
			_resolve("")
			
		timer_label.text = "%.1f" % _time_left
		
		# Slow camera push in
		camera.position.z -= delta * 2.0
		
	# Update label positions
	for item in _target_nodes:
		if is_instance_valid(item["node"]) and is_instance_valid(item["label"]):
			var screen_pos = camera.unproject_position(item["node"].global_position + Vector3(0, 1.5, 0))
			item["label"].position = screen_pos - Vector2(item["label"].size.x / 2.0, 30)

func _unhandled_input(event: InputEvent) -> void:
	if not _active: return
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.is_pressed():
			var space_state = get_world_3d().direct_space_state
			var from = camera.project_ray_origin(event.position)
			var dir = camera.project_ray_normal(event.position)
			
			var query = PhysicsRayQueryParameters3D.create(from, from + dir * 100.0)
			query.collide_with_areas = true
			var result = space_state.intersect_ray(query)
			
			if result and result.collider is Area3D:
				_resolve(result.collider.get_meta("id"))

func _resolve(hit_id: String) -> void:
	_active = false
	Engine.time_scale = 1.0
	
	var clean = (hit_id == _correct_id) and hit_id != ""
	
	flash_rect.color = COL_CORRECT_FLASH if clean else COL_WRONG_FLASH
	flash_rect.color.a = 0.8
	var tw = create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, 0.5)
	
	if clean:
		instruction_label.text = "CLEAN HIT"
		instruction_label.add_theme_color_override("font_color", COL_CORRECT_FLASH)
	else:
		instruction_label.text = "MESSY"
		instruction_label.add_theme_color_override("font_color", COL_WRONG_FLASH)
		
	await get_tree().create_timer(1.0).timeout
	
	if _on_done.is_valid():
		_on_done.call({"clean": clean})
	queue_free()

func _exit_tree() -> void:
	Engine.time_scale = 1.0
