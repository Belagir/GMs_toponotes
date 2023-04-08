class_name Pin
extends Node2D


@export_group("pin sizing")
@export_range(10, 1000, 1) var min_pin_size_px : int = 60
@export_range(10, 1000, 1) var max_pin_size_px : int = 600
@export_range(10, 1000, 1) var default_pin_size_px : int = 150
@export_group("")


@onready var _pin_body := $PinBody as Area2D
@onready var _pin_body_shape := $PinBody/CollisionShape2DBody as CollisionShape2D
@onready var _pin_body_sprite := $PinBody/SpriteBase as Sprite2D
@onready var _note_edit := $NoteTextEdit as TextEdit
@onready var _state_machine := $StateMachine as StateMachine
@onready var _resize_handle := $ResizeHandle as TextureButton
@onready var _delete_button := $DeleteButton as TextureButton
@onready var _delete_timer := $DeleteButton/DeletionTimer as Timer
@onready var _size_label := $SizeLabel as Label


# this is the "original position" of the pin, updated everytime it is moved directly by the user.
# it can be used to adapt the position of the pin with no losses in the event of a background image change. 
var _original_position : Vector2


func _ready() -> void:
	(_pin_body_shape.shape as CircleShape2D).radius = (_pin_body_sprite.texture as Texture2D).get_size().x / 2
	_pin_body.mouse_entered.connect(_pin_hovered.bind(true))
	_pin_body.mouse_exited.connect(_pin_hovered.bind(false))
	
	_resize_handle.button_down.connect(_state_machine.transition_to.bind("ResizeActivated"))
	_delete_button.button_down.connect(_state_machine.transition_to.bind("DeletingInitiated"))
	
	self.to_size(Vector2(default_pin_size_px, default_pin_size_px))
	
	GlobalEvents.pin_request_all_deselection.connect(to_state.bind("Ignored"))
	GlobalEvents.zoom_level_changed.connect(change_note_scale)
	GlobalEvents.background_image_dimensions_changed.connect(_adapt_position_to_image_dim)


# change the scale of the NoteEdit child
func change_note_scale(new_zoom_level : Vector2) -> void:
	_note_edit.scale.x = 1.0 / new_zoom_level.x
	_note_edit.scale.y = 1.0 / new_zoom_level.y


# quick and dirty deletion timer access
func deletion_timer() -> Timer:
	return _delete_timer


func to_byte_array(buffer : PackedByteArray) -> SaveFile.SAVEFILE_ERROR:
	buffer.resize(20)
	
	# position
	buffer.encode_float(0, self.position.x)
	buffer.encode_float(4, self.position.y)
	# radius
	buffer.encode_float(8, self._pin_body.scale.x)
	buffer.encode_float(12, self._pin_body.scale.y)
	# note text
	buffer.encode_u32(16, self._note_edit.text.length())
	buffer.append_array(self._note_edit.text.to_utf8_buffer())
	
	return SaveFile.SAVEFILE_ERROR.NONE


func from_byte_array(_version : int, buffer : PackedByteArray) -> int:
	var decoded_info : Dictionary = {}
	var byte_offset : int = 0
	
	decoded_info["pos x"] = buffer.decode_float(byte_offset)
	byte_offset += 4
	decoded_info["pos y"] = buffer.decode_float(byte_offset)
	byte_offset += 4
	
	decoded_info["scale x"] = buffer.decode_float(byte_offset)
	byte_offset += 4
	decoded_info["scale y"] = buffer.decode_float(byte_offset)
	byte_offset += 4
	
	decoded_info["note length"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	decoded_info["note content"] = buffer.slice(byte_offset, byte_offset + decoded_info["note length"]).get_string_from_utf8()
	byte_offset += (decoded_info["note content"] as String).length()
	
	self.move_to(Vector2(decoded_info["pos x"], decoded_info["pos y"]))
	self._pin_body.scale = Vector2(decoded_info["scale x"], decoded_info["scale y"])
	self._note_edit.text = decoded_info["note content"]
	self._state_machine.transition_to("Ignored")
	
	return byte_offset


# move the pin to another position
func move_to(target : Vector2) -> void:
	self.position = target
	_original_position = self.position


func set_visibility_associated_note(seen : bool) -> void:
	if seen:
		_note_edit.show()
	else:
		_note_edit.hide()


func set_visibility_config_things(seen : bool) -> void:
	if seen:
		_resize_handle.show()
		_delete_button.show()
	else:
		_resize_handle.hide()
		_delete_button.hide()


func set_visibility_size_label(seen : bool) -> void:
	if seen:
		_size_label.show()
	else:
		_size_label.hide()


func size() -> Vector2:
	var radius_circle : float = 0.0
	if _pin_body_shape:
		radius_circle = _pin_body_shape.shape.radius
	return _pin_body.scale * (2 * radius_circle)


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
	_delete_button.position.y = (-real_size.y / 2) - (_delete_button.size.y * _delete_button.scale.y)


# change the state of the pin to another state
func to_state(new_state : StringName) -> void:
	(_state_machine as StateMachine).transition_to(new_state)


func _adapt_position_to_image_dim(old_dim : Vector2, new_dim : Vector2) -> void:
	self.position = self.position * (new_dim / old_dim)


# signal that this pin is hovered
func _pin_hovered(entered : bool) -> void:
	GlobalEvents.emit_signal("pin_hover", self, entered)

