extends SceneTree

func _init():
    var root = Node3D.new()
    root.name = "Breach_ChopShop"
    root.set_script(load("res://scenes/breach/breach.gd"))
    
    var cam = Camera3D.new()
    cam.name = "Camera3D"
    cam.position = Vector3(10, 10, 10)
    cam.look_at(Vector3.ZERO, Vector3.UP)
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.size = 15.0
    # Camera should be child of a fixed anchor, not root, so rotating root rotates the room!
    var cam_anchor = Node3D.new()
    cam_anchor.name = "CamAnchor"
    cam_anchor.add_child(cam)
    # Actually wait, if root rotates, everything inside root rotates. We don't want camera to rotate.
    # So we'll let main scene handle camera, or just put it outside root in the actual level.
    # For now, put it in root, but the script rotates the `Diorama` pivot instead of `root`.
    
    var diorama = Node3D.new()
    diorama.name = "DioramaPivot"
    root.add_child(diorama)
    root.add_child(cam_anchor) # sibling to diorama
    
    # Update script to rotate DioramaPivot
    var script = load("res://scenes/breach/breach.gd")
    
    var floor = CSGBox3D.new()
    floor.name = "GarageFloor"
    floor.size = Vector3(10, 1, 10)
    floor.position = Vector3(0, -0.5, 0)
    diorama.add_child(floor)
    
    var wall = CSGBox3D.new()
    wall.name = "BackWall"
    wall.size = Vector3(10, 5, 1)
    wall.position = Vector3(0, 2.5, -4.5)
    diorama.add_child(wall)
    
    for i in range(5):
        var crate = CSGBox3D.new()
        crate.name = "VoxelCrate_" + str(i)
        crate.size = Vector3(1, 1, 1)
        crate.position = Vector3(randf_range(-4, 4), 0.5, randf_range(-3, 3))
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(0.6, 0.4, 0.2) # Wood
        crate.material_override = mat
        diorama.add_child(crate)
        
    var burner = CSGBox3D.new()
    burner.name = "Clue_BurnerPhone"
    burner.size = Vector3(0.2, 0.1, 0.4)
    burner.position = Vector3(0, 1.0, 0) # Hidden inside a crate ideally
    var bmat = StandardMaterial3D.new()
    bmat.albedo_color = Color(0.1, 0.1, 0.1)
    burner.material_override = bmat
    diorama.add_child(burner)
        
    var packed = PackedScene.new()
    for c in root.get_children():
        c.owner = root
        if c.name == "DioramaPivot":
            for gc in c.get_children():
                gc.owner = root
        if c.name == "CamAnchor":
            for gc in c.get_children():
                gc.owner = root
                
    packed.pack(root)
    ResourceSaver.save(packed, "res://scenes/breach/breach.tscn")
    print("Breach Diorama Built!")
    quit()
