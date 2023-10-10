class_name UI
extends HBoxContainer

## This node aggregates the user interface base controls.
##
## Ideally placed as a child of a [CanvasLayer].

## Extension requested by the save and load functions for the save files.
const PROGRAM_FILE_EXTENSION : String = "gmtpn"


var _bg_image_path : String = ""
var _save_path : String = ""

var _modified_sice_last_save := false


func _ready() -> void:
	# buttons spawning their dialog window
	%ChangeImageButton.pressed.connect(_center_and_show_dialog.bind(%ChangeImageButton/ChangeImageFileDialog))
	%NewButton.pressed.connect(_on_new_button_pressed)
	%SaveAsButton.pressed.connect(_center_and_show_dialog.bind(%SaveAsButton/SaveMapFileDialog))
	%SaveButton.pressed.connect(_save_map)
	%LoadButton.pressed.connect(_on_load_button_pressed)
	
	# redirect the dialog's signals to the correct functions
	%ChangeImageButton/ChangeImageFileDialog.file_selected.connect(_on_load_image_dialog_file_selected)
	%SaveAsButton/SaveMapFileDialog.file_selected.connect(_on_save_map_file_dialog_file_selected)
	%LoadButton/LoadMapFileDialog.file_selected.connect(_on_load_map_file_dialog_file_selected)
	%LoadButton/DiscardToLoadDialog.confirmed.connect(_center_and_show_dialog.bind(%LoadButton/LoadMapFileDialog))
	%NewButton/DiscardToNewDialog.confirmed.connect(_wipe_map)
	
	# refresh button
	%RefreshButton.pressed.connect(_load_image_as_bg.bind(_bg_image_path))
	GlobalEvents.changed_something_on_the_map.connect(_on_map_changed)
	
	# pin size slider
	%PinSizeHSlider.min_value = GlobalValues.PIN_SIZE_PX_MIN
	%PinSizeHSlider.max_value = GlobalValues.PIN_SIZE_PX_MAX
	%PinSizeHSlider.value = GlobalValues.PIN_SIZE_PX_DEFAULT
	%PinSizeHSlider.value_changed.connect(func(val : float): GlobalEvents.changed_pins_starting_size.emit(val as int))
	
	self.add_to_group(SaveFile.GROUP_SAVED_NODES)


## Toggle the visibility of an arbitrary control group. Available groups are :
## "new_buttons", "save_buttons", "bg_image_path_dependent".
func toggle_controls_group(group_name : String, controls_active : bool) -> void:
	for node in self.get_tree().get_nodes_in_group(group_name):
		node.disabled = not controls_active

func editable_controls_group(group_name : String, controls_active : bool) -> void:
	for node in self.get_tree().get_nodes_in_group(group_name):
		node.editable = controls_active

func save_node_to(buffer : PackedByteArray) -> SaveFile.SAVEFILE_ERROR:
	buffer.resize(4)
	buffer.encode_u32(0, %PinSizeHSlider.value)
	
	return SaveFile.SAVEFILE_ERROR.NONE

func load_node_from(_version : int, buffer : PackedByteArray) -> void:
	%PinSizeHSlider.value = buffer.decode_u32(0)

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
		_center_and_show_dialog($LoadButton/LoadMapFileDialog)
	else:
		_center_and_show_dialog(%LoadButton/DiscardToLoadDialog)


func _load_image_as_bg(path : String) -> void:
	if (path == null) or (not FileAccess.file_exists(path)): 
		return
	
	var buffer := Image.load_from_file(path)
	var texture : Texture = ImageTexture.create_from_image(buffer)
	
	if (texture != null):
		GlobalEvents.requested_change_of_background_image.emit(texture)


func _save_map() -> void:
	if FileAccess.file_exists(self._save_path):
		SaveFile.save_state_to(self.get_tree(), self._save_path)
		_modified_sice_last_save = false
	else:
		_center_and_show_dialog(%SaveAsButton/SaveMapFileDialog)


func _center_and_show_dialog(dialog : AcceptDialog) -> void:
	dialog.popup_centered()


func _on_map_changed() -> void:
	_modified_sice_last_save = true


func _on_new_button_pressed() -> void:
	if not _modified_sice_last_save:
		_wipe_map()
	else:
		_center_and_show_dialog(%NewButton/DiscardToNewDialog)


func _wipe_map() -> void:
	GlobalEvents.requested_map_wipe.emit()
	_bg_image_path = ""
	_save_path = ""
	_modified_sice_last_save = false
