class_name Pin
extends Node2D

# Global events listened to :
# - pin_request_all_deselection -> will deselect the pin
# - zoom_level_changed -> will actualize the note's size
# - background_image_dimensions_changed -> to change the pin's position to match the new ratio
#
# Global events sent :
# - pin_hover -> notify the rest of the program that this pin is hovered by the mouse
# - pin_deselected -> this pin was selected and some input was sent to deselect it


const DISPLAYED_CHARACTERS_HIGHLIGHTED : int = 20


@export_group("pin sizing")
@export_range(10, 1000, 1) var min_pin_size_px : int = 60
@export_range(10, 1000, 1) var max_pin_size_px : int = 600
@export_range(10, 1000, 1) var default_pin_size_px : int = 150
@export_group("")


# pin components for ease of (and typed) access
@onready var _pin_body := $PinBody as Area2D
@onready var _pin_body_shape := $PinBody/CollisionShape2DBody as CollisionShape2D
@onready var _pin_body_sprite := $PinBody/SpriteBase as Sprite2D
@onready var _note_edit := $NoteTextEdit as TextEdit
@onready var _state_machine := $StateMachine as StateMachine
@onready var _resize_handle := $ResizeHandle as TextureButton
@onready var _delete_button := $DeleteButton as TextureButton
@onready var _delete_timer := $DeleteButton/DeletionTimer as Timer
@onready var _size_label := $SizeLabel as Label
@onready var _excerpt_container := $CenterContainer as CenterContainer
@onready var _excerpt_label := $CenterContainer/ExcerptLabel as Label


# this is the "original position" of the pin, updated everytime it is moved directly by the user.
# it can be used to adapt the position of the pin with no losses in the event of a background image change. 
var _original_position : Vector2


func _ready() -> void:
	(_pin_body_shape.shape as CircleShape2D).radius = (_pin_body_sprite.texture as Texture2D).get_size().x / 2
	_pin_body.mouse_entered.connect(_pin_hovered.bind(true))
	_pin_body.mouse_exited.connect(_pin_hovered.bind(false))
	
	_resize_handle.button_down.connect(_state_machine.transition_to.bind("ResizeActivated"))
	_delete_button.button_down.connect(_state_machine.transition_to.bind("DeletingInitiated"))
	
	_note_edit.text_changed.connect(_note_text_changed)
	
	self.to_size(Vector2(default_pin_size_px, default_pin_size_px))
	
	GlobalEvents.pin_request_all_deselection.connect(to_state.bind("Ignored"))
	GlobalEvents.zoom_level_changed.connect(change_note_scale)
	GlobalEvents.background_image_dimensions_changed.connect(_adapt_position_to_image_dim)
	GlobalEvents.bring_pins_z_level_down.connect(_bring_down)
	
	_note_edit.text_changed.emit()


# change the scale of the NoteEdit child
func change_note_scale(new_zoom_level : Vector2) -> void:
	_note_edit.scale.x = 1.0 / new_zoom_level.x
	_note_edit.scale.y = 1.0 / new_zoom_level.y
	_excerpt_container.scale.x = 1.0 / new_zoom_level.x
	_excerpt_container.scale.y = 1.0 / new_zoom_level.y


# quick and dirty deletion timer access
func deletion_timer() -> Timer:
	return _delete_timer


func to_byte_array(buffer : PackedByteArray) -> SaveFile.SAVEFILE_ERROR:
	var text_buffer : PackedByteArray = []
	
	buffer.resize(24)
	
	# position
	buffer.encode_float(0, self.position.x)
	buffer.encode_float(4, self.position.y)
	# radius
	buffer.encode_float(8, self.size().x)
	buffer.encode_float(12, self.size().y)
	# z index
	buffer.encode_u32(16, self.z_index)
	# note text
	text_buffer = self._note_edit.text.to_utf8_buffer()
	buffer.encode_u32(20, len(text_buffer))
	buffer.append_array(text_buffer)
	
	return SaveFile.SAVEFILE_ERROR.NONE


# read the pin's encoded data from a buffer and return the decoded data's length
# this will modify the pin to match the decoded data.
func from_byte_array(_version : int, buffer : PackedByteArray) -> int:
	var decoded_info : Dictionary = {}
	var byte_offset : int = 0
	
	# fetch position
	decoded_info["pos x"] = buffer.decode_float(byte_offset)
	byte_offset += 4
	decoded_info["pos y"] = buffer.decode_float(byte_offset)
	byte_offset += 4
	
	# fetch radius
	decoded_info["size x"] = buffer.decode_float(byte_offset)
	byte_offset += 4
	decoded_info["size y"] = buffer.decode_float(byte_offset)
	byte_offset += 4

	# fetch z index
	decoded_info["z index"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	
	# fetch note text	
	decoded_info["note length"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	decoded_info["note content"] = buffer.slice(byte_offset, byte_offset + decoded_info["note length"]).get_string_from_utf8()
	byte_offset += decoded_info["note length"]
	
	self.move_to(Vector2(decoded_info["pos x"], decoded_info["pos y"]))
	self.to_size(Vector2(decoded_info["size x"], decoded_info["size y"]))
	self.z_index = decoded_info["z index"]
	self.set_note_text(decoded_info["note content"])
	self._state_machine.transition_to("Ignored")
	
	return byte_offset


# move the pin to another position
func move_to(target : Vector2) -> void:
	self.position = target
	_original_position = self.position
	GlobalEvents.map_got_a_change.emit()


func set_note_text(text : String) -> void:
	_note_edit.text = text
	_note_edit.text_changed.emit()


# toggle visibility of the pin's note
func set_visibility_associated_note(seen : bool) -> void:
	if seen:
		_note_edit.show()
	else:
		_note_edit.hide()


# toggle visibility of the pin's config controls
func set_visibility_config_things(seen : bool) -> void:
	if seen:
		_resize_handle.show()
		_delete_button.show()
	else:
		_resize_handle.hide()
		_delete_button.hide()


# toggle visibility of the pin's size label
func set_visibility_size_label(seen : bool) -> void:
	if seen:
		_size_label.show()
	else:
		_size_label.hide()


func set_visibility_excerpt_label(seen : bool) -> void:
	if seen:
		_excerpt_label.show()
	else:
		_excerpt_label.hide()

# return the diameter, in pixels, of the pin.
func size() -> Vector2:
	var radius_circle : float = 0.0
	if _pin_body_shape:
		radius_circle = _pin_body_shape.shape.radius
	return _pin_body.scale * (2 * radius_circle)


# reurn the diameter, in pixels, of the pin, as it were unscaled
func size_unscaled() -> Vector2:
	var radius_circle : float = 0.0
	if _pin_body_shape:
		radius_circle = _pin_body_shape.shape.radius
	return Vector2(1, 1) * (2 * radius_circle)


# return the current state as an unique string
func state() -> StringName:
	return _state_machine.get_state_name()


# sets the scale of the node according to the difference between the wanted pixel size and the pin's
# base size.
func to_size(new_pix_size : Vector2) -> void:
	var my_pix_size : Vector2 = self.size_unscaled()
	var real_size : Vector2
	
	new_pix_size.x = clamp(new_pix_size.x, min_pin_size_px, max_pin_size_px)
	new_pix_size.y = clamp(new_pix_size.y, min_pin_size_px, max_pin_size_px)
	
	_pin_body.scale = new_pix_size / my_pix_size
	real_size =  my_pix_size.x * _pin_body.scale
	
	_note_edit.position.x = real_size.x / 1.5
	
	_resize_handle.position = (real_size / 2) - (_resize_handle.size * _resize_handle.scale)
	
	_size_label.position = (real_size / 2)
	_size_label.text = "( %d px x %d px )" % [new_pix_size.x, new_pix_size.y]
	
	_excerpt_container.position.y = real_size.y * 0.6
	
	_delete_button.position.y = (-real_size.y / 2) - (_delete_button.size.y * _delete_button.scale.y)
	
	GlobalEvents.map_got_a_change.emit()


# change the state of the pin to another state
func to_state(new_state : StringName) -> void:
	(_state_machine as StateMachine).transition_to(new_state)


# change the node's postion to match the new ratio between the two sizes
func _adapt_position_to_image_dim(old_dim : Vector2, new_dim : Vector2) -> void:
	self.position = self.position * (new_dim / old_dim)
	GlobalEvents.map_got_a_change.emit()


# bring the pin's z-index down if it is above the limit
func _bring_down(limit_level : int) -> void:
	if self.z_index > limit_level:
		self.z_index -= 1


# signal that this pin is hovered
func _pin_hovered(entered : bool) -> void:
	GlobalEvents.pin_hover.emit(self, entered)


# when the note text changes, the highlight excerpt must be updated
func _note_text_changed() -> void:
	GlobalEvents.map_got_a_change.emit()
	if (_note_edit.text.find("\n") < DISPLAYED_CHARACTERS_HIGHLIGHTED) and _note_edit.text.find("\n") != -1:
		_excerpt_label.text = _note_edit.text.get_slice("\n", 0)
	else:
		_excerpt_label.text = _note_edit.text.left(DISPLAYED_CHARACTERS_HIGHLIGHTED)
	
	_excerpt_label.text = _excerpt_label.text.strip_edges()
	_excerpt_label.text += "…" if _note_edit.text.length() > DISPLAYED_CHARACTERS_HIGHLIGHTED else ""
