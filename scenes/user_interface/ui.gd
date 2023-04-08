extends HBoxContainer

# Global events listened to :
# - changed_background_texture -> to activate / deactivate save and load buttons
# - map_got_a_change -> to monitor the nexessity to ask for a save when some changes might get lost
# 
# Global events sent :
# - changed_background_texture -> request a texture change for the background

const PROGRAM_FILE_EXTENSION : String = "gmtpn"


var _bg_image_path : String = ""
var _save_path : String = ""

var _modified_sice_last_save := false


func _ready() -> void:
	# buttons spawning their dialog window
	%ChangeImageButton.pressed.connect(%ChangeImageButton/ChangeImageFileDialog.show)
	%SaveAsButton.pressed.connect(%SaveAsButton/SaveMapFileDialog.show)
	%SaveButton.pressed.connect(_save_map)
	%LoadButton.pressed.connect(_on_load_button_pressed)
	
	# redirect the dialog's signals to the correct functions
	%ChangeImageButton/ChangeImageFileDialog.file_selected.connect(_on_load_image_dialog_file_selected)
	%SaveAsButton/SaveMapFileDialog.file_selected.connect(_on_save_map_file_dialog_file_selected)
	%LoadButton/LoadMapFileDialog.file_selected.connect(_on_load_map_file_dialog_file_selected)
	$LoadButton/ConfirmationDialog.confirmed.connect(%LoadButton/LoadMapFileDialog.show)
	
	# refresh button
	%RefreshButton.pressed.connect(_load_image_as_bg.bind(_bg_image_path))
	GlobalEvents.map_got_a_change.connect(_on_map_changed)


func toggle_controls_group(group_name : String, controls_active : bool) -> void:
	for node in self.get_tree().get_nodes_in_group(group_name):
		node.disabled = not controls_active


func _on_load_image_dialog_file_selected(path : String) -> void:
	_bg_image_path = path
	_load_image_as_bg(_bg_image_path)


func _on_save_map_file_dialog_file_selected(path : String) -> void:
	if path.get_extension() != PROGRAM_FILE_EXTENSION:
		path = path + "." + PROGRAM_FILE_EXTENSION
	_save_path = path
	SaveFile.save_state_to(self.get_tree(), path)
	_modified_sice_last_save = false


func _on_load_map_file_dialog_file_selected(path : String) -> void:
	var scene_root : Node = self.get_node("/root/Main")
	_save_path = path
	SaveFile.load_state_from(scene_root, path)
	_modified_sice_last_save = false


func _on_load_button_pressed() -> void:
	if not _modified_sice_last_save:
		$LoadButton/LoadMapFileDialog.show()
	else:
		$LoadButton/ConfirmationDialog.show()


func _load_image_as_bg(path : String) -> void:
	if (path == null) or (not FileAccess.file_exists(path)): 
		return
	
	var buffer := Image.load_from_file(path)
	var texture : Texture = ImageTexture.create_from_image(buffer)
	
	if (texture != null):
		GlobalEvents.changed_background_texture.emit(texture)


func _save_map() -> void:
	if FileAccess.file_exists(self._save_path):
		SaveFile.save_state_to(self.get_tree(), self._save_path)
		_modified_sice_last_save = false
	else:
		%SaveAsButton/SaveMapFileDialog.show()


func _on_map_changed() -> void:
	_modified_sice_last_save = true
