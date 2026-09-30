extends Control

signal choice_made(decision)

func _ready():
    $VBoxContainer/BtnGiveDrive.pressed.connect(func():
        choice_made.emit("give_exclusive")
        _close()
    )
    $VBoxContainer/BtnSmashCamera.pressed.connect(func():
        choice_made.emit("smash_camera")
        _close()
    )

func _close():
    queue_free()
