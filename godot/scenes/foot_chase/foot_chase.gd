extends Node3D

@onready var distance_label = $UI/DistanceLabel
@onready var player = $Player
@onready var suspect = $Suspect
@onready var camera = $Camera3D
@onready var obstacle_container = $ObstacleContainer
@onready var scenery_container = $SceneryContainer

var _cfg: Dictionary
var _on_done: Callable
var _active: bool = false
var _distance: float = 100.0

var _touch_start: Vector2
var _is_dragging: bool = false

var lanes = [-2.5, 0.0, 2.5]
var current_lane_index = 1
var target_x = 0.0

var world_speed = 15.0 # m/s
var stun_time = 0.0

# Materials and Meshes
var low_mesh: BoxMesh
var high_mesh: BoxMesh
var scenery_mesh: BoxMesh
var low_mat: StandardMaterial3D
var high_mat: StandardMaterial3D
var sc_mat: StandardMaterial3D

var obstacle_pool: Array[Node3D] = []
var scenery_pool: Array[Node3D] = []

var spawn_timer = 0.0
var scenery_spawn_timer = 0.0
var hits = 0

var camera_shake_timer = 0.0
var camera_shake_intensity = 0.0
var camera_base_pos: Vector3

var player_y = 0.0
var player_state = 0 # 0: run, 1: vault, 2: slide
var state_timer = 0.0

func _ready():
	_init_resources()
	_init_pools()
	camera_base_pos = camera.position
	
	# Initial scenery
	for i in range(10):
		_spawn_scenery(-i * 10.0)

func _init_resources():
	low_mesh = BoxMesh.new()
	low_mesh.size = Vector3(2.0, 0.8, 1.0)
	low_mat = StandardMaterial3D.new()
	low_mesh.material = low_mat
	
	high_mesh = BoxMesh.new()
	high_mesh.size = Vector3(2.0, 0.2, 1.0)
	high_mat = StandardMaterial3D.new()
	high_mesh.material = high_mat
	
	scenery_mesh = BoxMesh.new()
	scenery_mesh.size = Vector3(2.0, 5.0, 2.0)
	sc_mat = StandardMaterial3D.new()
	scenery_mesh.material = sc_mat

func _init_pools():
	for i in range(20):
		var obs = Node3D.new()
		var mesh_inst = MeshInstance3D.new()
		obs.add_child(mesh_inst)
		obstacle_container.add_child(obs)
		obs.visible = false
		obstacle_pool.append(obs)
		
	for i in range(20):
		var sc = Node3D.new()
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = scenery_mesh
		mesh_inst.position = Vector3(0, 2.5, 0)
		sc.add_child(mesh_inst)
		scenery_container.add_child(sc)
		sc.visible = false
		scenery_pool.append(sc)

func present(cfg: Dictionary, on_done: Callable) -> void:
	_cfg = cfg
	_on_done = on_done
	_distance = 100.0
	_active = true
	hits = 0
	stun_time = 0.0
	current_lane_index = 1
	target_x = lanes[current_lane_index]
	player.position.x = target_x
	player.position.y = 0.5
	camera.position = camera_base_pos

func _process(delta: float) -> void:
	if not _active: return
	
	var current_speed = world_speed
	if stun_time > 0:
		stun_time -= delta
		current_speed = world_speed * 0.3
		
	_distance -= current_speed * delta * 0.2 # 100m takes ~33s if no stun
	if _distance < 0:
		_distance = 0
	
	# Move player
	player.position.x = lerp(player.position.x, target_x, delta * 10.0)
	
	# Player state (vault/slide)
	if player_state != 0:
		state_timer -= delta
		if player_state == 1: # vault
			player.position.y = 0.5 + sin((1.0 - (state_timer / 0.8)) * PI) * 1.5
		elif player_state == 2: # slide
			player.scale.y = 0.5
			player.position.y = 0.25
			
		if state_timer <= 0:
			player_state = 0
			player.position.y = 0.5
			player.scale.y = 1.0
	
	# Camera movement (bob + shake)
	var cam_x = lerp(camera.position.x, player.position.x * 0.5, delta * 5.0)
	camera.position.x = cam_x
	
	if camera_shake_timer > 0:
		camera_shake_timer -= delta
		camera.position.x = cam_x + randf_range(-camera_shake_intensity, camera_shake_intensity)
		camera.position.y = camera_base_pos.y + randf_range(-camera_shake_intensity, camera_shake_intensity)
	else:
		camera.position.y = lerp(camera.position.y, camera_base_pos.y, delta * 5.0)
		
	if _distance <= 0:
		_finish_scene()
		return
		
	distance_label.text = "%dm" % int(_distance)
	
	# Suspect distance representation
	suspect.position.z = -3.0 - (_distance * 0.4)
	suspect.position.x = sin(Time.get_ticks_msec() * 0.002) * 2.0
	
	_process_world(delta, current_speed)
	_check_collisions()

func _process_world(delta: float, speed: float) -> void:
	# Move obstacles
	for obs in obstacle_container.get_children():
		if obs.visible:
			obs.position.z += speed * delta
			if obs.position.z > 5.0:
				obs.visible = false
				
	# Move scenery
	for sc in scenery_container.get_children():
		if sc.visible:
			sc.position.z += speed * delta
			if sc.position.z > 10.0:
				sc.visible = false
				
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = randf_range(0.8, 1.5)
		_spawn_obstacle(-40.0)
		
	scenery_spawn_timer -= delta
	if scenery_spawn_timer <= 0:
		scenery_spawn_timer = 0.5
		_spawn_scenery(-40.0)

func _spawn_obstacle(z_pos: float):
	var obs = _get_free_obstacle()
	if obs:
		var lane_idx = randi() % 3
		obs.position = Vector3(lanes[lane_idx], 0, z_pos)
		obs.visible = true
		
		var type = randi() % 2
		obs.set_meta("type", type) # 0 = low, 1 = high
		obs.set_meta("hit", false)
		var mesh_inst = obs.get_child(0) as MeshInstance3D
		if type == 0:
			mesh_inst.mesh = low_mesh
			mesh_inst.position = Vector3(0, 0.4, 0)
		else:
			mesh_inst.mesh = high_mesh
			mesh_inst.position = Vector3(0, 1.5, 0)
			
func _get_free_obstacle() -> Node3D:
	for obs in obstacle_pool:
		if not obs.visible: return obs
	return null

func _spawn_scenery(z_pos: float):
	# Left
	var sc_l = _get_free_scenery()
	if sc_l:
		sc_l.visible = true
		sc_l.position = Vector3(-4.5, 0, z_pos)
	# Right
	var sc_r = _get_free_scenery()
	if sc_r:
		sc_r.visible = true
		sc_r.position = Vector3(4.5, 0, z_pos)

func _get_free_scenery() -> Node3D:
	for sc in scenery_pool:
		if not sc.visible: return sc
	return null
	
func _check_collisions():
	if stun_time > 0: return
	
	var p_pos = player.position
	for obs in obstacle_container.get_children():
		if obs.visible and not obs.get_meta("hit", true):
			if abs(obs.position.z - p_pos.z) < 0.8 and abs(obs.position.x - p_pos.x) < 0.8:
				var type = obs.get_meta("type")
				var hit = false
				if type == 0: # low, need to vault
					if player_state != 1 or player.position.y < 1.0:
						hit = true
				else: # high, need to slide
					if player_state != 2:
						hit = true
						
				if hit:
					obs.set_meta("hit", true)
					_apply_hit()

func _apply_hit():
	hits += 1
	stun_time = 1.0
	camera_shake_timer = 0.3
	camera_shake_intensity = 0.4
	# Obstacle hit - no Mirror event for this, just a stun penalty

func _unhandled_input(event: InputEvent) -> void:
	if not _active: return
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = event.is_pressed()
		var pos = event.position
		
		if pressed:
			_touch_start = pos
			_is_dragging = true
		else:
			if _is_dragging:
				var swipe_vec = pos - _touch_start
				if swipe_vec.length() > 50:
					if abs(swipe_vec.x) > abs(swipe_vec.y):
						if swipe_vec.x > 0:
							Mirror.record_swipe("right")
							if current_lane_index < 2:
								current_lane_index += 1
								target_x = lanes[current_lane_index]
						else:
							Mirror.record_swipe("left")
							if current_lane_index > 0:
								current_lane_index -= 1
								target_x = lanes[current_lane_index]
					else:
						if swipe_vec.y < 0:
							Mirror.record_swipe("up")
							if player_state == 0:
								player_state = 1
								state_timer = 0.8
						else:
							Mirror.record_swipe("down")
							if player_state == 0:
								player_state = 2
								state_timer = 0.8
			_is_dragging = false

func _finish_scene() -> void:
	if not _active: return
	_active = false
	
	camera_shake_timer = 0.5
	camera_shake_intensity = 0.5
	
	var t = create_tween()
	t.tween_property(camera, "position:z", camera.position.z - 2.0, 0.5)
	
	await get_tree().create_timer(0.6).timeout
		
	if _on_done.is_valid():
		var stars = 3
		if hits >= 2: stars = 2
		if hits >= 4: stars = 1
		_on_done.call({"stars": stars})
	queue_free()
