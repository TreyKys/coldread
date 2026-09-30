extends SceneTree

func _init():
    var root = Node3D.new()
    root.name = "CoverFire_Pier3"
    root.set_script(load("res://scenes/combat/cover_fire.gd"))
    
    var cam = Camera3D.new()
    cam.name = "Camera3D"
    cam.position = Vector3(0, 1.5, 0)
    root.add_child(cam)
    
    var canvas = CanvasLayer.new()
    canvas.name = "CanvasLayer"
    root.add_child(canvas)
    
    var ret = ColorRect.new()
    ret.name = "Reticle"
    ret.color = Color(1, 0, 0, 0.5)
    ret.custom_minimum_size = Vector2(4, 4)
    ret.set_anchors_preset(Control.PRESET_CENTER)
    canvas.add_child(ret)
    
    # Enemies
    for i in range(3):
        var enemy = CSGBox3D.new()
        enemy.name = "Kite_Enemy_" + str(i)
        enemy.size = Vector3(1, 2, 1)
        enemy.position = Vector3(-5 + (i * 5), 1, -20)
        var mat = StandardMaterial3D.new()
        mat.albedo_color = Color(1, 0, 0) # Red for Kite gang
        enemy.material_override = mat
        root.add_child(enemy)
        
    var packed = PackedScene.new()
    for c in root.get_children():
        c.owner = root
    packed.pack(root)
    ResourceSaver.save(packed, "res://scenes/combat/cover_fire.tscn")
    print("Cover Fire Scene Built!")
    quit()
