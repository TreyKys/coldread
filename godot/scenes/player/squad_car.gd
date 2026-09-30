extends VehicleBody3D

@export var max_engine_force = 300.0
@export var max_steer = 0.4
@export var braking_force = 15.0

@onready var camera_mount = $CameraMount
@onready var camera = $CameraMount/ChaseCamera

var _current_steer = 0.0

func _physics_process(delta):
    var steer_input = Input.get_axis("ui_right", "ui_left")
    _current_steer = move_toward(_current_steer, steer_input * max_steer, delta * 2.5)
    steering = _current_steer
    
    var accel_input = Input.get_action_strength("ui_up")
    var brake_input = Input.get_action_strength("ui_down")
    
    if brake_input > 0:
        brake = brake_input * braking_force
        engine_force = 0.0
    else:
        brake = 0.0
        engine_force = accel_input * max_engine_force

    # Dynamic Camera FOV based on speed
    var speed = linear_velocity.length()
    var target_fov = clamp(70.0 + (speed * 0.8), 70.0, 100.0)
    camera.fov = lerp(camera.fov, target_fov, delta * 3.0)
    
    # Camera shake based on speed and bumps (simple approximation)
    if speed > 10.0:
        var shake = sin(Time.get_ticks_msec() * 0.05) * 0.02 * (speed / 30.0)
        camera.h_offset = lerp(camera.h_offset, shake, delta * 10.0)
