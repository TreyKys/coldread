extends SceneTree

var frames = 0
var max_frames = 300 # 10 seconds at 30fps
var state = 0

func _init():
    print("Screenshot tool initializing...")
    
func _process(delta):
    if frames == 0:
        var root = root
        var scene = load("res://scenes/world/open_world.tscn").instantiate()
        root.add_child(scene)
        print("Scene loaded for screenshots...")
    
    frames += 1
    
    # Wait for things to settle (e.g. SDFGI cascades)
    if frames == 20:
        take_screenshot("screenshot_1.png")
    
    if frames == 40:
        # Move camera for second shot
        var car = root.get_node("LagoonCity_OpenWorld/SquadCar")
        if car: car.position += Vector3(0, 0, 50)
        take_screenshot("screenshot_2.png")
        
    if frames == 60:
        # Move camera for third shot
        var car = root.get_node("LagoonCity_OpenWorld/SquadCar")
        if car: car.position += Vector3(50, 0, 50)
        take_screenshot("screenshot_3.png")
        quit()

func take_screenshot(filename: String):
    var img = root.get_viewport().get_texture().get_image()
    var path = "res://" + filename
    img.save_png(path)
    print("Saved ", filename)
