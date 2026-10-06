extends CharacterBody3D

const SPEED = 6.0
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var cam_arm = $CameraArm
@onready var anim_player = $Model.get_node("AnimationPlayer")
@onready var model = $Model

# Mobile UI
var left_touch_id = -1
var right_touch_id = -1
var joystick_center = Vector2.ZERO
var joystick_current = Vector2.ZERO
var move_vector = Vector2.ZERO

var canvas: CanvasLayer
var joystick_base: Panel
var joystick_knob: Panel
var crosshair: ColorRect
var fire_btn: Panel
var fire_label: Label
var raycast: RayCast3D
var muzzle_flash: OmniLight3D

func _ready():

    # Setup Mobile UI dynamically
    canvas = CanvasLayer.new()
    add_child(canvas)
    
    # Virtual Joystick Base
    joystick_base = Panel.new()
    joystick_base.size = Vector2(160, 160)
    var style_base = StyleBoxFlat.new()
    style_base.bg_color = Color(0, 0, 0, 0.3)
    style_base.corner_radius_top_left = 80
    style_base.corner_radius_top_right = 80
    style_base.corner_radius_bottom_left = 80
    style_base.corner_radius_bottom_right = 80
    joystick_base.add_theme_stylebox_override("panel", style_base)
    joystick_base.pivot_offset = Vector2(80, 80)
    joystick_base.hide()
    canvas.add_child(joystick_base)
    
    # Virtual Joystick Knob
    joystick_knob = Panel.new()
    joystick_knob.size = Vector2(60, 60)
    var style_knob = StyleBoxFlat.new()
    style_knob.bg_color = Color(1, 1, 1, 0.7)
    style_knob.corner_radius_top_left = 30
    style_knob.corner_radius_top_right = 30
    style_knob.corner_radius_bottom_left = 30
    style_knob.corner_radius_bottom_right = 30
    joystick_knob.add_theme_stylebox_override("panel", style_knob)
    joystick_knob.position = Vector2(50, 50)
    joystick_base.add_child(joystick_knob)
    
    # Crosshair
    crosshair = ColorRect.new()
    crosshair.size = Vector2(6, 6)
    crosshair.color = Color(1, 1, 1, 0.8)
    crosshair.set_anchors_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-3, -3) # Centered
    canvas.add_child(crosshair)
    
    # Fire Button
    fire_btn = Panel.new()
    fire_btn.size = Vector2(100, 100)
    var style_fire = StyleBoxFlat.new()
    style_fire.bg_color = Color(1, 0.2, 0.2, 0.6)
    style_fire.corner_radius_top_left = 50
    style_fire.corner_radius_top_right = 50
    style_fire.corner_radius_bottom_left = 50
    style_fire.corner_radius_bottom_right = 50
    fire_btn.add_theme_stylebox_override("panel", style_fire)
    fire_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    fire_btn.position = Vector2(-150, -150)
    canvas.add_child(fire_btn)
    
    fire_label = Label.new()
    fire_label.text = "FIRE"
    fire_label.set_anchors_preset(Control.PRESET_CENTER)
    fire_label.position = Vector2(32, 40)
    fire_btn.add_child(fire_label)
    
    # Setup Raycast
    raycast = RayCast3D.new()
    raycast.target_position = Vector3(0, 0, -100)
    raycast.collision_mask = 1
    $CameraArm/Camera3D.add_child(raycast)
    
    # Setup Muzzle Flash
    muzzle_flash = OmniLight3D.new()
    muzzle_flash.light_color = Color(1.0, 0.8, 0.2)
    muzzle_flash.light_energy = 0
    muzzle_flash.position = Vector3(0, 1.2, 0.5)
    model.add_child(muzzle_flash)


func _input(event):
    if event is InputEventScreenTouch:
        var screen_half = get_viewport().get_visible_rect().size.x / 2.0
        
        # Check Fire button
        if event.pressed and fire_btn.get_global_rect().has_point(event.position):
            # Fire logic
            cam_arm.rotation.x += 0.05 # Recoil kick
            
            # Muzzle flash
            muzzle_flash.light_energy = 5.0
            var tween = get_tree().create_tween()
            tween.tween_property(muzzle_flash, "light_energy", 0.0, 0.1)
            
            raycast.force_raycast_update()
            if raycast.is_colliding():
                var hit_point = raycast.get_collision_point()
                print("Hit at: ", hit_point)
                
                # Spawn hit indicator
                var hit_mesh = MeshInstance3D.new()
                hit_mesh.mesh = SphereMesh.new()
                hit_mesh.mesh.radius = 0.2
                hit_mesh.mesh.height = 0.4
                var mat = StandardMaterial3D.new()
                mat.albedo_color = Color(1, 0, 0)
                hit_mesh.mesh.surface_set_material(0, mat)
                get_parent().add_child(hit_mesh)
                hit_mesh.global_position = hit_point
                
                var t = get_tree().create_tween()
                t.tween_property(hit_mesh, "scale", Vector3.ZERO, 0.5)
                t.tween_callback(hit_mesh.queue_free)
            return
            
        if event.pressed:
            if event.position.x < screen_half and left_touch_id == -1:
                left_touch_id = event.index
                joystick_center = event.position
                joystick_current = event.position
                joystick_base.position = joystick_center - joystick_base.size / 2.0
                joystick_base.show()
            elif event.position.x >= screen_half and right_touch_id == -1:
                right_touch_id = event.index
        else:
            if event.index == left_touch_id:
                left_touch_id = -1
                move_vector = Vector2.ZERO
                joystick_knob.position = Vector2(40, 40)
                joystick_base.hide()
            elif event.index == right_touch_id:
                right_touch_id = -1

    elif event is InputEventScreenDrag:
        if event.index == left_touch_id:
            joystick_current = event.position
            var dist = joystick_center.distance_to(joystick_current)
            var max_dist = 80.0
            if dist > max_dist:
                joystick_current = joystick_center + (joystick_current - joystick_center).normalized() * max_dist
            
            joystick_knob.position = (joystick_current - joystick_base.position) - joystick_knob.size / 2.0
            move_vector = (joystick_current - joystick_center) / max_dist
            
        elif event.index == right_touch_id:
            # Camera rotation
            var sensitivity = 0.005
            cam_arm.rotation.y -= event.relative.x * sensitivity
            cam_arm.rotation.x -= event.relative.y * sensitivity
            cam_arm.rotation.x = clamp(cam_arm.rotation.x, -1.2, 0.5)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta

    var input_dir = move_vector
    var forward = -cam_arm.global_transform.basis.z
    var right = cam_arm.global_transform.basis.x
    
    forward.y = 0
    right.y = 0
    forward = forward.normalized()
    right = right.normalized()

    # Apply character movement relative to camera look direction
    var direction = (forward * -input_dir.y + right * input_dir.x).normalized()
    
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
        # Rotate model to face movement direction smoothly
        var target_rotation = atan2(velocity.x, velocity.z)
        model.rotation.y = lerp_angle(model.rotation.y, target_rotation, delta * 15.0)
        
        if anim_player.current_animation != "Walking":
            anim_player.speed_scale = 1.5
        anim_player.play("Walking", 0.2) # 0.2 blend
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)
        if anim_player.current_animation != "Idle":
            anim_player.speed_scale = 1.0
        anim_player.play("Idle", 0.2)

    move_and_slide()
