extends Node3D

@onready var camera = $Camera3D
@onready var light = $DirectionalLight3D
@onready var env = $WorldEnvironment
@onready var props = $Props

var _time = 0.0

func _ready():
	var district_id = GameState.run.get("district", "market_mile")
	var d = GameTheme.get_district(district_id)
	GameTheme.apply_environment(env.environment, light, district_id)
	
	# Spawn a bunch of abstract scenery boxes
	for i in range(30):
		var mesh_inst = MeshInstance3D.new()
		var b = BoxMesh.new()
		b.size = Vector3(randf_range(1.0, 3.0), randf_range(2.0, 10.0), randf_range(1.0, 3.0))
		mesh_inst.mesh = b
		var mat = StandardMaterial3D.new()
		mat.albedo_color = d["wall_color"]
		mesh_inst.set_surface_override_material(0, mat)
		mesh_inst.position = Vector3(randf_range(-15, 15), b.size.y / 2.0 - 2.0, randf_range(-15, 15))
		props.add_child(mesh_inst)

func _process(delta: float):
	_time += delta
	camera.position.x = sin(_time * 0.1) * 8.0
	camera.position.z = cos(_time * 0.1) * 8.0
	camera.look_at(Vector3.ZERO)
