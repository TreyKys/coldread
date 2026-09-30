extends SceneTree

func _init():
    print("Building Lagoon City Geometry (Chapter 1)...")
    var root = Node3D.new()
    root.name = "LagoonCity_OpenWorld"
    
    # 1. Procedural Environment
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
    
    var wet_mat = StandardMaterial3D.new()
    wet_mat.albedo_color = Color(0.12, 0.12, 0.14)
    wet_mat.roughness = 0.15
    wet_mat.metallic = 0.2
    
    var building_mat = StandardMaterial3D.new()
    building_mat.albedo_color = Color(0.2, 0.2, 0.2)
    
    # --- REGION 1: THE MAINLAND (Expressways) ---
    var mainland = Node3D.new()
    mainland.name = "Mainland"
    root.add_child(mainland)
    
    var bridge = CSGBox3D.new()
    bridge.name = "Road_4th_Freedom_Bridge"
    bridge.size = Vector3(30, 1, 500)
    bridge.position = Vector3(0, 0, 250)
    bridge.material_override = wet_mat
    mainland.add_child(bridge)
    
    var expressway = CSGBox3D.new()
    expressway.name = "Road_Independence_Expressway"
    expressway.size = Vector3(40, 1, 400)
    expressway.position = Vector3(0, 0, -200)
    expressway.material_override = wet_mat
    mainland.add_child(expressway)
    
    for i in range(20):
        var b = CSGBox3D.new()
        b.size = Vector3(randf_range(10, 30), randf_range(20, 80), randf_range(10, 30))
        b.position = Vector3(randf_range(-100, -30), b.size.y/2.0, randf_range(-400, 0))
        b.material_override = building_mat
        mainland.add_child(b)
        
        var b2 = CSGBox3D.new()
        b2.size = Vector3(randf_range(10, 30), randf_range(20, 80), randf_range(10, 30))
        b2.position = Vector3(randf_range(30, 100), b2.size.y/2.0, randf_range(-400, 0))
        b2.material_override = building_mat
        mainland.add_child(b2)
        
    # --- REGION 2: MARKET MILE ---
    var market = Node3D.new()
    market.name = "Market_Mile"
    market.position = Vector3(-150, 0, -100)
    root.add_child(market)
    
    var weavers = CSGBox3D.new()
    weavers.name = "Road_Weavers_Lane"
    weavers.size = Vector3(6, 1, 150)
    weavers.material_override = wet_mat
    market.add_child(weavers)
    
    var neon_mat = StandardMaterial3D.new()
    neon_mat.emission_enabled = true
    neon_mat.emission = Color(1, 0.2, 0.8)
    neon_mat.emission_energy_multiplier = 4.0
    
    for i in range(40):
        var b = CSGBox3D.new()
        b.size = Vector3(randf_range(5, 10), randf_range(5, 15), randf_range(5, 10))
        var side = 1 if i % 2 == 0 else -1
        b.position = Vector3(side * randf_range(4, 15), b.size.y/2.0, randf_range(-75, 75))
        b.material_override = building_mat
        market.add_child(b)
        
        if randf() > 0.5:
            var sign = CSGBox3D.new()
            sign.size = Vector3(1, 2, 0.2)
            sign.position = b.position + Vector3(side * 2, -2, 0)
            sign.material_override = neon_mat
            market.add_child(sign)

    # --- ADD SQUAD CAR ---
    var car = preload("res://scenes/player/squad_car.tscn").instantiate()
    car.name = "SquadCar"
    car.position = Vector3(0, 5, -200) # Start on Independence Expressway
    root.add_child(car)

    var packed = PackedScene.new()
    # Need to set owner for packed scene children to be saved!
    for child in root.get_children():
        child.owner = root
        if child.name == "Mainland" or child.name == "Market_Mile":
            for grand in child.get_children():
                grand.owner = root
    
    packed.pack(root)
    var dir = DirAccess.open("res://")
    if not dir.dir_exists("scenes/world"):
        dir.make_dir_recursive("scenes/world")
        
    var err = ResourceSaver.save(packed, "res://scenes/world/open_world.tscn")
    if err == OK:
        print("Lagoon City Level Geometry Saved!")
    else:
        print("ERROR SAVING: ", err)
    quit()
