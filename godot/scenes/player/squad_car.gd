extends VehicleBody3D

@export var max_engine_force = 300.0
@export var max_steer = 0.4
@export var braking_force = 15.0

@onready var camera_mount = $CameraMount
@onready var camera = $CameraMount/ChaseCamera

var _current_steer = 0.0
var _frame_count = 0

func _physics_process(delta):
    # Auto-drive for the movie recording
    engine_force = max_engine_force * 0.8
    _current_steer = move_toward(_current_steer, 0.0, delta * 2.5)
    steering = _current_steer
    
    var speed = linear_velocity.length()
    var target_fov = clamp(70.0 + (speed * 0.8), 70.0, 100.0)
    camera.fov = lerp(camera.fov, target_fov, delta * 3.0)
    
    if speed > 10.0:
        var shake = sin(Time.get_ticks_msec() * 0.05) * 0.02 * (speed / 30.0)
        camera.h_offset = lerp(camera.h_offset, shake, delta * 10.0)

func _process(delta):
    _frame_count += 1
    if _frame_count == 30:
        get_viewport().get_texture().get_image().save_png("res://screenshot_1.png")
    elif _frame_count == 150:
        get_viewport().get_texture().get_image().save_png("res://screenshot_2.png")
    elif _frame_count == 300:
        get_viewport().get_texture().get_image().save_png("res://screenshot_3.png")
    elif _frame_count == 600:
        get_tree().quit() # 10 seconds at 60fps = 600 frames
