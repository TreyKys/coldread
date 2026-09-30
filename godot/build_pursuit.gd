extends SceneTree

func _init():
    var root = Node3D.new()
    root.name = "Pursuit_DeltaHighway"
    root.set_script(load("res://scenes/pursuit/pursuit.gd"))
    
    var cam = Camera3D.new()
    cam.name = "Camera3D"
    cam.position = Vector3(0, 3, 7)
    cam.rotation_degrees = Vector3(-10, 0, 0)
    root.add_child(cam)
    
    var floor = CSGBox3D.new()
    floor.name = "HighwayFloor"
    floor.size = Vector3(30, 1, 300)
    floor.position = Vector3(0, -0.5, -140)
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.1, 0.1, 0.1)
    floor.material_override = mat
    root.add_child(floor)
    
    var player = CSGBox3D.new()
    player.name = "SquadCar"
    player.size = Vector3(2, 1.5, 4)
    player.position = Vector3(0, 0.75, 0)
    root.add_child(player)
    
    var van = CSGBox3D.new()
    van.name = "GhostVan"
    van.size = Vector3(2.5, 2.5, 5)
    van.position = Vector3(0, 1.25, -50)
    var vmat = StandardMaterial3D.new()
    vmat.albedo_color = Color(0.8, 0.1, 0.1)
    van.material_override = vmat
    root.add_child(van)
    
    var packed = PackedScene.new()
    for c in root.get_children():
        c.owner = root
    packed.pack(root)
    
    var dir = DirAccess.open("res://")
    dir.make_dir_recursive("scenes/pursuit")
    ResourceSaver.save(packed, "res://scenes/pursuit/pursuit.tscn")
    print("Pursuit Built!")
    quit()
