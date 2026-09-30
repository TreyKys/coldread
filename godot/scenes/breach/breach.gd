extends Node3D

# Rotates the diorama via swipe
var target_rotation = 0.0

func _input(event):
    if event is InputEventScreenDrag or event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            target_rotation += event.relative.x * 0.01

func _process(delta):
    get_node("DioramaPivot").rotation.y = lerp_angle(get_node("DioramaPivot").rotation.y, target_rotation, delta * 5.0)

func smash_object(obj_name):
    print("Smashed ", obj_name)
    var node = get_node(obj_name)
    if node:
        node.queue_free()
