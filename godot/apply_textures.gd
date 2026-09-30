extends SceneTree

func _init():
    print("Applying Textures and Level Details (V3)...")
    var packed = load("res://scenes/world/open_world.tscn")
    var root = packed.instantiate()
    
    # 1. Setup Materials safely using ImageTexture
    var conc_img = Image.load_from_file("res://assets/textures/concrete_albedo.png")
    var conc_norm = Image.load_from_file("res://assets/textures/concrete_normal.png")
    var build_img = Image.load_from_file("res://assets/textures/building_albedo.png")
    var build_em = Image.load_from_file("res://assets/textures/building_emissive.png")
    
    var concrete_mat = StandardMaterial3D.new()
    concrete_mat.albedo_texture = ImageTexture.create_from_image(conc_img)
    concrete_mat.normal_enabled = true
    concrete_mat.normal_texture = ImageTexture.create_from_image(conc_norm)
    concrete_mat.uv1_scale = Vector3(10, 10, 10)
    
    var building_mat = StandardMaterial3D.new()
    building_mat.albedo_texture = ImageTexture.create_from_image(build_img)
    building_mat.emission_enabled = true
    building_mat.emission_texture = ImageTexture.create_from_image(build_em)
    building_mat.uv1_scale = Vector3(5, 10, 5)
    
    # 2. Apply to Mainland & Market Mile
    var mainland = root.get_node("Mainland")
    for child in mainland.get_children():
        if child is CSGBox3D and "Road" not in child.name:
            child.material_override = building_mat
    
    var market = root.get_node("Market_Mile")
    for child in market.get_children():
        if child is CSGBox3D and "Road" not in child.name:
            if child.size.x < 2.0:
                pass # neon
            else:
                child.material_override = building_mat

    # 3. Barricade
    var bridge = mainland.get_node("Road_4th_Freedom_Bridge")
    if not bridge.has_node("Barricade_Setpiece"):
        var barricade = Node3D.new()
        barricade.name = "Barricade_Setpiece"
        barricade.position = Vector3(0, 1, -100)
        bridge.add_child(barricade)
        
        for i in range(3):
            var truck = CSGBox3D.new()
            truck.size = Vector3(4, 5, 12)
            truck.position = Vector3((i-1)*10, 2.5, randf_range(-5, 5))
            truck.rotation_degrees = Vector3(0, randf_range(-45, 45), 90)
            var mat = StandardMaterial3D.new()
            mat.albedo_color = Color(0.8, 0.1, 0.1)
            truck.material_override = mat
            truck.use_collision = true
            barricade.add_child(truck)

    # Re-save
    var new_packed = PackedScene.new()
    for child in root.get_children():
        child.owner = root
        for grand in child.get_children():
            grand.owner = root
            for great in grand.get_children():
                great.owner = root
                
    new_packed.pack(root)
    ResourceSaver.save(new_packed, "res://scenes/world/open_world.tscn")
    print("Textures and Barricades Applied Successfully!")
    quit()
