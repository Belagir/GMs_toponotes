extends HBoxContainer

signal action_change_background(path : String)


var _bg_image_path : String = ""


func _on_load_button_pressed() -> void:
	($ChangeImageButton/ChangeImageFileDialog as FileDialog).show()


func _on_load_file_dialog_file_selected(path : String) -> void:
	_bg_image_path = path
	_load_image_as_bg(_bg_image_path)


func _on_refresh_button_pressed() -> void:
	_load_image_as_bg(_bg_image_path)


func _load_image_as_bg(path : String) -> void:
	if (path == null) or (not FileAccess.file_exists(path)): return
	
	var buffer := Image.load_from_file(path)
	var texture : Texture = ImageTexture.create_from_image(buffer)
	
	if (texture != null):
		GlobalEvents.emit_signal("changed_background_texture", texture)
		GlobalEvents.emit_signal("background_image_dimensions_changed", texture.get_size())
