extends SceneTree

func _init():
    var project_settings = ProjectSettings
    project_settings.set_setting("editor/movie_writer/movie_file", "res://output_movie.avi")
    project_settings.save()
    quit()
