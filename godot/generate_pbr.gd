extends SceneTree

func _init():
    print("Generating Procedural PBR Textures...")
    
    # Generate Concrete Albedo & Normal
    var concrete_img = Image.create(512, 512, false, Image.FORMAT_RGBA8)
    var concrete_normal = Image.create(512, 512, false, Image.FORMAT_RGBA8)
    var concrete_noise = FastNoiseLite.new()
    concrete_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    concrete_noise.frequency = 0.05
    
    var macro_noise = FastNoiseLite.new()
    macro_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
    macro_noise.frequency = 0.01
    
    for x in range(512):
        for y in range(512):
            var n1 = (concrete_noise.get_noise_2d(x, y) + 1.0) * 0.5
            var n2 = (macro_noise.get_noise_2d(x, y) + 1.0) * 0.5
            var val = lerp(0.3, 0.45, n1 * n2)
            concrete_img.set_pixel(x, y, Color(val, val, val + 0.02, 1.0))
            
            # Simple bump to normal
            var nx = concrete_noise.get_noise_2d(x+1, y) - concrete_noise.get_noise_2d(x-1, y)
            var ny = concrete_noise.get_noise_2d(x, y+1) - concrete_noise.get_noise_2d(x, y-1)
            var normal_color = Color(nx * 0.5 + 0.5, ny * 0.5 + 0.5, 1.0, 1.0)
            concrete_normal.set_pixel(x, y, normal_color)

    var dir = DirAccess.open("res://")
    if not dir.dir_exists("assets/textures"):
        dir.make_dir_recursive("assets/textures")
        
    concrete_img.save_png("res://assets/textures/concrete_albedo.png")
    concrete_normal.save_png("res://assets/textures/concrete_normal.png")
    
    # Generate Building Windows (Emissive Map)
    var window_img = Image.create(512, 512, false, Image.FORMAT_RGBA8)
    var window_emissive = Image.create(512, 512, false, Image.FORMAT_RGBA8)
    for x in range(512):
        for y in range(512):
            # Create a grid of windows
            var is_window = (x % 64 > 10 and x % 64 < 54) and (y % 128 > 20 and y % 128 < 108)
            if is_window:
                var lit = randf() > 0.7 # 30% of windows are lit
                if lit:
                    window_img.set_pixel(x, y, Color(0.9, 0.8, 0.5))
                    window_emissive.set_pixel(x, y, Color(0.9, 0.8, 0.2))
                else:
                    window_img.set_pixel(x, y, Color(0.1, 0.1, 0.15))
                    window_emissive.set_pixel(x, y, Color.BLACK)
            else:
                var val = 0.2 + (randf() * 0.05)
                window_img.set_pixel(x, y, Color(val, val, val))
                window_emissive.set_pixel(x, y, Color.BLACK)
                
    window_img.save_png("res://assets/textures/building_albedo.png")
    window_emissive.save_png("res://assets/textures/building_emissive.png")

    print("Textures generated successfully!")
    quit()
