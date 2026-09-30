extends SceneTree

func _init():
    var root = Control.new()
    root.name = "KemiStandoff"
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.set_script(load("res://scenes/ui/kemi_standoff.gd"))
    
    var bg = ColorRect.new()
    bg.name = "Background"
    bg.color = Color(0, 0, 0, 0.8)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(bg)
    
    var vbox = VBoxContainer.new()
    vbox.name = "VBoxContainer"
    vbox.set_anchors_preset(Control.PRESET_CENTER)
    root.add_child(vbox)
    
    var label = Label.new()
    label.name = "PromptLabel"
    label.text = "Kemi Hart shoved a camera in your face. 12,000 people are watching live."
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(label)
    
    var btn1 = Button.new()
    btn1.name = "BtnGiveDrive"
    btn1.text = "SWERVE LEFT: Give Exclusive (Ally)"
    vbox.add_child(btn1)
    
    var btn2 = Button.new()
    btn2.name = "BtnSmashCamera"
    btn2.text = "SWERVE RIGHT: Smash Camera (Rival)"
    vbox.add_child(btn2)
    
    var packed = PackedScene.new()
    for c in root.get_children():
        c.owner = root
        if c.name == "VBoxContainer":
            for gc in c.get_children():
                gc.owner = root
                
    packed.pack(root)
    var dir = DirAccess.open("res://")
    dir.make_dir_recursive("scenes/ui")
    ResourceSaver.save(packed, "res://scenes/ui/kemi_standoff.tscn")
    print("Kemi Standoff Scene Built!")
    quit()
