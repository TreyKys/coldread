extends Node3D

var speed = 15.0
var distance = 100.0

@onready var player = $Player
@onready var camera = $Camera3D
@onready var obstacle_spawner = $ObstacleSpawner

var current_lane = 1 # 0: left, 1: mid, 2: right
var target_x = 0.0

func _process(delta):
    distance -= delta * 5.0
    if distance <= 0:
        print("Suspect tackled!")
        queue_free()
        
    # Input
    if Input.is_action_just_pressed("ui_left") and current_lane > 0:
        current_lane -= 1
    elif Input.is_action_just_pressed("ui_right") and current_lane < 2:
        current_lane += 1
        
    target_x = (current_lane - 1) * 3.0
    player.position.x = lerp(player.position.x, target_x, delta * 10.0)
    
    # Move obstacles toward player
    for obs in obstacle_spawner.get_children():
        obs.position.z += speed * delta
        if obs.position.z > 5:
            obs.queue_free()
            
    # Spawn new
    if randf() < 0.05:
        var lane = randi() % 3
        var obs = CSGBox3D.new()
        obs.size = Vector3(2, 1, 1)
        obs.position = Vector3((lane - 1) * 3.0, 0.5, -50)
        obstacle_spawner.add_child(obs)
