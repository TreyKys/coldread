extends Node3D

var speed = 40.0
var distance_to_van = 50.0

@onready var player_car = $SquadCar
@onready var ghost_van = $GhostVan
@onready var camera = $Camera3D

func _process(delta):
    # Arcada Ramming Mechanics
    var target_fov = 70.0
    if Input.is_action_pressed("ui_up"): # NITRO
        speed = 60.0
        target_fov = 90.0
        distance_to_van -= delta * 5.0
    else:
        speed = 40.0
        
    camera.fov = lerp(camera.fov, target_fov, delta * 3.0)
    
    if distance_to_van <= 5.0:
        print("Van Rammed! Transition to Pier 3 Shootout.")
        queue_free()
