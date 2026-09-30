extends SceneTree

func _init():
    print("Wiring Squad Car into Open World...")
    var packed = load("res://scenes/world/open_world.tscn")
    if not packed:
        print("Failed to load open_world.tscn")
        quit()
        return
        
    var root = packed.instantiate()
    
    # Check if car already exists
    if not root.has_node("SquadCar"):
        var car_scene = load("res://scenes/player/squad_car.tscn")
        if car_scene:
            var car = car_scene.instantiate()
            car.name = "SquadCar"
            # Position it on the Independence Expressway
            car.position = Vector3(0, 5, -200)
            root.add_child(car)
            car.owner = root
            print("Car added to scene.")
        else:
            print("Failed to load squad_car.tscn")
            
    # Save it back
    var new_packed = PackedScene.new()
    new_packed.pack(root)
    ResourceSaver.save(new_packed, "res://scenes/world/open_world.tscn")
    print("Wiring complete!")
    quit()
