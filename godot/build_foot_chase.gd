extends SceneTree

func _init():
    var root = Node3D.new()
    root.name = "FootChase_WeaversLane"
    root.set_script(load("res://scenes/foot_chase/foot_chase.gd"))
    
    var cam = Camera3D.new()
    cam.name = "Camera3D"
    cam.position = Vector3(0, 3, 5)
    cam.rotation_degrees = Vector3(-15, 0, 0)
    root.add_child(cam)
    
    var floor = CSGBox3D.new()
    floor.name = "Ground"
    floor.size = Vector3(10, 1, 200)
    floor.position = Vector3(0, -0.5, -90)
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.2, 0.2, 0.2)
    floor.material_override = mat
    root.add_child(floor)
    
    var player = CSGBox3D.new()
    player.name = "Player"
    player.size = Vector3(1, 2, 1)
    player.position = Vector3(0, 1, 0)
    root.add_child(player)
    
    var spawner = Node3D.new()
    spawner.name = "ObstacleSpawner"
    root.add_child(spawner)
    
    var packed = PackedScene.new()
    for c in root.get_children():
        c.owner = root
    packed.pack(root)
    ResourceSaver.save(packed, "res://scenes/foot_chase/foot_chase.tscn")
    print("Foot Chase Built!")
    quit()
