extends SceneTree

func _init():
    print("Building Lagoon City Geometry V2 (Curves, Collision, Textures)...")
    var root = Node3D.new()
    root.name = "LagoonCity_OpenWorld"
    
    # 1. Environment
    var env = WorldEnvironment.new()
    var sky = Sky.new()
    var env_res = Environment.new()
    env_res.background_mode = Environment.BG_SKY
    env_res.sky = sky
    env_res.tonemap_mode = Environment.TONE_MAPPER_ACES
    env_res.ssr_enabled = true
    env_res.ssao_enabled = true
    env_res.ssil_enabled = true
    env_res.sdfgi_enabled = true
    env_res.sdfgi_cascades = 4
    env_res.sdfgi_min_cell_size = 0.2
    env_res.glow_enabled = true
    env_res.volumetric_fog_enabled = true
    env_res.volumetric_fog_density = 0.02
    env.environment = env_res
    root.add_child(env)
    
    var sun = DirectionalLight3D.new()
    sun.shadow_enabled = true
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
    sun.transform.basis = Basis().rotated(Vector3(1, 0, 0), deg_to_rad(-45)).rotated(Vector3(0, 1, 0), deg_to_rad(45))
    root.add_child(sun)
    
    # 2. Materials
    var wet_mat = StandardMaterial3D.new()
    wet_mat.albedo_color = Color(0.12, 0.12, 0.14)
    wet_mat.roughness = 0.15
    wet_mat.metallic = 0.2
    
    var building_mat = StandardMaterial3D.new()
    building_mat.albedo_color = Color(0.25, 0.25, 0.25)
    
    var neon_mat = StandardMaterial3D.new()
    neon_mat.emission_enabled = true
    neon_mat.emission = Color(1, 0.2, 0.8)
    neon_mat.emission_energy_multiplier = 4.0
    
    # --- REGION 1: THE MAINLAND (Expressways) ---
    var mainland = Node3D.new()
    mainland.name = "Mainland"
    root.add_child(mainland)
    
    # 4th Freedom Bridge (WITH COLLISION)
    var bridge = CSGBox3D.new()
    bridge.name = "Road_4th_Freedom_Bridge"
    bridge.size = Vector3(30, 1, 500)
    bridge.position = Vector3(0, 0, 250)
    bridge.material_override = wet_mat
    bridge.use_collision = true
    mainland.add_child(bridge)
    
    # Independence Expressway (Curved using CSGPolygon and Path3D approximation, but for now we'll use angled blocks to form a curve)
    # We build a 3-segment curve for the expressway
    var curve_root = Node3D.new()
    curve_root.name = "Expressway_Curve"
    mainland.add_child(curve_root)
    
    var ex1 = CSGBox3D.new()
    ex1.size = Vector3(40, 1, 200)
    ex1.position = Vector3(0, 0, -100)
    ex1.use_collision = true
    ex1.material_override = wet_mat
    curve_root.add_child(ex1)
    
    var ex2 = CSGBox3D.new()
    ex2.size = Vector3(40, 1, 200)
    ex2.position = Vector3(50, 0, -280)
    ex2.rotation_degrees = Vector3(0, -30, 0)
    ex2.use_collision = true
    ex2.material_override = wet_mat
    curve_root.add_child(ex2)
    
    var ex3 = CSGBox3D.new()
    ex3.size = Vector3(40, 1, 200)
    ex3.position = Vector3(180, 0, -420)
    ex3.rotation_degrees = Vector3(0, -60, 0)
    ex3.use_collision = true
    ex3.material_override = wet_mat
    curve_root.add_child(ex3)
    
    # Procedural Buildings placed along the curve
    for i in range(40):
        var b = CSGBox3D.new()
        b.size = Vector3(randf_range(10, 30), randf_range(30, 100), randf_range(10, 30))
        var angle = deg_to_rad(randf_range(0, -60))
        var radius = randf_range(30, 150)
        var side = 1 if i % 2 == 0 else -1
        b.position = Vector3(sin(angle) * (radius * side) + 50, b.size.y/2.0, cos(angle) * (radius * side) - 200)
        b.material_override = building_mat
        b.use_collision = true
        mainland.add_child(b)
        
    # --- REGION 2: MARKET MILE ---
    var market = Node3D.new()
    market.name = "Market_Mile"
    market.position = Vector3(180, 0, -500) # Connects to the end of the expressway curve
    market.rotation_degrees = Vector3(0, -90, 0)
    root.add_child(market)
    
    var weavers = CSGBox3D.new()
    weavers.name = "Road_Weavers_Lane"
    weavers.size = Vector3(8, 1, 300)
    weavers.material_override = wet_mat
    weavers.use_collision = true
    market.add_child(weavers)
    
    # Dense curved alleys intersecting Weaver's Lane
    for i in range(5):
        var cross = CSGBox3D.new()
        cross.size = Vector3(100, 1, 6)
        cross.position = Vector3(0, 0, -100 + (i * 40))
        cross.material_override = wet_mat
        cross.use_collision = true
        market.add_child(cross)
    
    for i in range(80):
        var b = CSGBox3D.new()
        b.size = Vector3(randf_range(5, 12), randf_range(5, 20), randf_range(5, 12))
        var side = 1 if i % 2 == 0 else -1
        b.position = Vector3(side * randf_range(6, 40), b.size.y/2.0, randf_range(-140, 140))
        b.material_override = building_mat
        b.use_collision = true
        market.add_child(b)
        
        if randf() > 0.4:
            var sign = CSGBox3D.new()
            sign.size = Vector3(1, randf_range(1,3), 0.2)
            sign.position = b.position + Vector3(side * 2, randf_range(-2, 5), 0)
            
            # Dynamic neon colors
            var local_neon = StandardMaterial3D.new()
            local_neon.emission_enabled = true
            local_neon.emission = Color(randf(), randf(), randf())
            local_neon.emission_energy_multiplier = randf_range(2.0, 5.0)
            sign.material_override = local_neon
            market.add_child(sign)

    # --- ADD SQUAD CAR ---
    var car = load("res://scenes/player/squad_car.tscn").instantiate()
    car.name = "SquadCar"
    car.position = Vector3(0, 5, -50) # Drop safely above the start of the expressway
    root.add_child(car)

    var packed = PackedScene.new()
    # Need to set owner for packed scene children to be saved!
    for child in root.get_children():
        child.owner = root
        if child.name == "Mainland" or child.name == "Market_Mile":
            for grand in child.get_children():
                grand.owner = root
                for great in grand.get_children():
                    great.owner = root
    
    packed.pack(root)
    var dir = DirAccess.open("res://")
    if not dir.dir_exists("scenes/world"):
        dir.make_dir_recursive("scenes/world")
        
    var err = ResourceSaver.save(packed, "res://scenes/world/open_world.tscn")
    if err == OK:
        print("Lagoon City Level Geometry V2 Saved! COLLISION ENABLED.")
    else:
        print("ERROR SAVING: ", err)
    quit()
