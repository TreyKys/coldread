extends Node3D

@onready var health_label = $UI/HealthLabel
@onready var player = $Player
@onready var suspect = $Suspect
@onready var camera = $Camera3D
@onready var obstacle_container = $ObstacleContainer
@onready var scenery_container = $SceneryContainer

var _cfg: Dictionary
var _on_done: Callable
var _active: bool = false

var lanes = [-4.5, -1.5, 1.5, 4.5]
var current_lane_index = 1
var target_x = -1.5

var suspect_lane_index = 1
var suspect_target_x = -1.5
var suspect_health = 100
var suspect_timer = 2.0

var world_speed = 25.0
var base_world_speed = 25.0
var nitro_active = false

var ramming = false
var ram_timer = 0.0
var ram_cooldown = 0.0
var distance_to_suspect = 15.0 # meters

var _touch_start: Vector2
var _touch_time: float
var _is_dragging: bool = false
var _is_holding: bool = false

var civilian_mesh: BoxMesh
var scenery_mesh: BoxMesh
var civ_mat: StandardMaterial3D
var sc_mat: StandardMaterial3D
var obstacle_pool: Array[Node3D] = []
var scenery_pool: Array[Node3D] = []

var spawn_timer = 0.0
var scenery_spawn_timer = 0.0
var hits = 0
var suspect_hits = 0

var camera_shake_timer = 0.0
var camera_shake_intensity = 0.0
var camera_base_pos: Vector3

func _ready():
	_init_resources()
	_init_pools()
	camera_base_pos = camera.position
	for i in range(10):
		_spawn_scenery(-i * 10.0)

func _init_resources():
	civilian_mesh = BoxMesh.new()
	civilian_mesh.size = Vector3(1.5, 1.0, 3.0)
	civ_mat = StandardMaterial3D.new()
	civilian_mesh.material = civ_mat
	
	scenery_mesh = BoxMesh.new()
	scenery_mesh.size = Vector3(2.0, 6.0, 2.0)
	sc_mat = StandardMaterial3D.new()
	scenery_mesh.material = sc_mat

func _init_pools():
	for i in range(20):
		var obs = Node3D.new()
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = civilian_mesh
		mesh_inst.position = Vector3(0, 0.5, 0)
		obs.add_child(mesh_inst)
		obstacle_container.add_child(obs)
		obs.visible = false
		obstacle_pool.append(obs)
		
	for i in range(40):
		var sc = Node3D.new()
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = scenery_mesh
		mesh_inst.position = Vector3(0, 3.0, 0)
		sc.add_child(mesh_inst)
		scenery_container.add_child(sc)
		sc.visible = false
		scenery_pool.append(sc)

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	_active = true
	suspect_health = 100
	hits = 0
	suspect_hits = 0
	distance_to_suspect = 15.0
	current_lane_index = 1
	target_x = lanes[current_lane_index]
	player.position.x = target_x
	suspect_lane_index = 1
	suspect_target_x = lanes[suspect_lane_index]
	suspect.position.x = suspect_target_x
	camera.position = camera_base_pos
	_update_ui()

func _process(delta: float) -> void:
	if not _active: return
	
	# Timers
	if ram_cooldown > 0: ram_cooldown -= delta
	if ram_timer > 0:
		ram_timer -= delta
		if ram_timer <= 0:
			ramming = false
			
	if _is_holding:
		if (Time.get_ticks_msec() - _touch_time) > 300 and not nitro_active:
			nitro_active = true
			camera_shake_timer = 999.0
			camera_shake_intensity = 0.1
	
	if not _is_holding and nitro_active:
		nitro_active = false
		camera_shake_timer = 0.0
		
	world_speed = base_world_speed * (2.0 if nitro_active else 1.0)
	
	# Movement logic
	player.position.x = lerp(player.position.x, target_x, delta * 10.0)
	suspect.position.x = lerp(suspect.position.x, suspect_target_x, delta * 8.0)
	
	var target_dist = 15.0
	if ramming:
		target_dist = 2.0
	elif distance_to_suspect > 15.0:
		target_dist = 15.0
	
	distance_to_suspect = lerp(distance_to_suspect, target_dist, delta * (10.0 if ramming else 2.0))
	suspect.position.z = -distance_to_suspect
	
	# Suspect AI
	suspect_timer -= delta
	if suspect_timer <= 0:
		suspect_timer = randf_range(1.0, 3.0)
		_suspect_decide_lane()
		
	# Camera
	var cam_x = lerp(camera.position.x, player.position.x * 0.5, delta * 5.0)
	if camera_shake_timer > 0:
		if not nitro_active:
			camera_shake_timer -= delta
		camera.position.x = cam_x + randf_range(-camera_shake_intensity, camera_shake_intensity)
		camera.position.y = camera_base_pos.y + randf_range(-camera_shake_intensity, camera_shake_intensity)
	else:
		camera.position.x = cam_x
		camera.position.y = lerp(camera.position.y, camera_base_pos.y, delta * 5.0)
		
	_process_world(delta, world_speed)
	_check_collisions()

func _suspect_decide_lane():
	var opts = []
	if suspect_lane_index > 0: opts.append(-1)
	if suspect_lane_index < 3: opts.append(1)
	if opts.size() > 0:
		if randf() > 0.5:
			suspect_lane_index += opts[randi() % opts.size()]
			suspect_target_x = lanes[suspect_lane_index]

func _process_world(delta: float, speed: float) -> void:
	for obs in obstacle_container.get_children():
		if obs.visible:
			obs.position.z += (speed * 0.5) * delta
			if obs.position.z > 10.0:
				obs.visible = false
				
	for sc in scenery_container.get_children():
		if sc.visible:
			sc.position.z += speed * delta
			if sc.position.z > 20.0:
				sc.visible = false
				
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = randf_range(1.0, 2.5) / (2.0 if nitro_active else 1.0)
		_spawn_obstacle(-60.0)
		
	scenery_spawn_timer -= delta
	if scenery_spawn_timer <= 0:
		scenery_spawn_timer = 0.3 / (2.0 if nitro_active else 1.0)
		_spawn_scenery(-60.0)

func _spawn_obstacle(z_pos: float):
	var obs = _get_free_obstacle()
	if obs:
		var lane_idx = randi() % 4
		if lane_idx == suspect_lane_index and z_pos > suspect.position.z - 10.0 and z_pos < suspect.position.z + 10.0:
			lane_idx = (lane_idx + 1) % 4
			
		obs.position = Vector3(lanes[lane_idx], 0, z_pos)
		obs.visible = true
		obs.set_meta("hit", false)

func _get_free_obstacle() -> Node3D:
	for obs in obstacle_pool:
		if not obs.visible: return obs
	return null

func _spawn_scenery(z_pos: float):
	var sc_l = _get_free_scenery()
	if sc_l:
		sc_l.visible = true
		sc_l.position = Vector3(-8.0, 0, z_pos)
	var sc_r = _get_free_scenery()
	if sc_r:
		sc_r.visible = true
		sc_r.position = Vector3(8.0, 0, z_pos)

func _get_free_scenery() -> Node3D:
	for sc in scenery_pool:
		if not sc.visible: return sc
	return null

func _check_collisions():
	var p_pos = player.position
	
	for obs in obstacle_container.get_children():
		if obs.visible and not obs.get_meta("hit", true):
			if abs(obs.position.z - p_pos.z) < 2.0 and abs(obs.position.x - p_pos.x) < 1.2:
				obs.set_meta("hit", true)
				if nitro_active:
					camera_shake_timer = 0.2
					camera_shake_intensity = 0.3
					obs.visible = false
				else:
					hits += 1
					distance_to_suspect += 10.0
					camera_shake_timer = 0.4
					camera_shake_intensity = 0.5
					ramming = false
					
	if ramming:
		if abs(suspect.position.z - p_pos.z) < 3.0 and abs(suspect.position.x - p_pos.x) < 1.5:
			ramming = false
			distance_to_suspect = 15.0
			suspect_health -= 35
			suspect_hits += 1
			camera_shake_timer = 0.5
			camera_shake_intensity = 0.8
			_update_ui()
			
			if suspect_health <= 0:
				_finish_scene(true)

func _update_ui():
	health_label.text = "Suspect: %d%%" % max(0, suspect_health)

func _unhandled_input(event: InputEvent) -> void:
	if not _active: return
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.is_pressed()
		var pos = event.position
		
		if pressed:
			_touch_start = pos
			_touch_time = Time.get_ticks_msec()
			_is_dragging = true
			_is_holding = true
		else:
			_is_holding = false
			if _is_dragging:
				var swipe_vec = pos - _touch_start
				var time_held = Time.get_ticks_msec() - _touch_time
				
				if swipe_vec.length() > 30:
					if abs(swipe_vec.x) > abs(swipe_vec.y):
						if swipe_vec.x > 0:
							if Mirror.has_method("record_swipe"): Mirror.record_swipe("right")
							if current_lane_index < 3:
								current_lane_index += 1
								target_x = lanes[current_lane_index]
						else:
							if Mirror.has_method("record_swipe"): Mirror.record_swipe("left")
							if current_lane_index > 0:
								current_lane_index -= 1
								target_x = lanes[current_lane_index]
				elif time_held < 300:
					_try_ram()
			_is_dragging = false

func _try_ram():
	if ram_cooldown <= 0 and current_lane_index == suspect_lane_index:
		ramming = true
		ram_timer = 1.0
		ram_cooldown = 2.0

func _finish_scene(success: bool) -> void:
	if not _active: return
	_active = false
	
	var stars = 0
	if success:
		stars = 3
		if hits >= 2: stars = 2
		if hits >= 4: stars = 1
		
	if _on_done.is_valid():
		_on_done.call({"stars": stars})
	queue_free()
