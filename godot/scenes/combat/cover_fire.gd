extends Node3D

@export var max_health = 100
@export var current_health = 100
@export var squad_active = "Patch" # Patch or Dash

@onready var camera = $Camera3D
@onready var reticle = $CanvasLayer/Reticle

var aim_friction = 1.0
var target_enemy = null

func _process(delta):
    if Input.is_action_pressed("ui_accept"): # Simulating touch-and-hold
        camera.fov = lerp(camera.fov, 45.0, delta * 8.0) # Aim down sights
    else:
        camera.fov = lerp(camera.fov, 70.0, delta * 8.0) # Duck in cover
        
    # Aim Friction Logic
    if target_enemy != null:
        aim_friction = 0.6 # Slows down sensitivity by 40%
    else:
        aim_friction = 1.0

func swap_squad(member):
    squad_active = member
    if member == "Patch":
        # Deploy foam shield
        pass
    elif member == "Dash":
        # Speed boost
        pass
