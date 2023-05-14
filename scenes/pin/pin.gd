class_name Pin
extends Node2D

## The Pin node represents a pin placed by the user on the map.
##
## A pin is a markdown note (editable through the [NoteTextEdit] child node) 
## associated to an icon (pickable through the [PinIconSelector] child node).
## [br] 
## [br]
## The Pin class can transition to any of the following states :
## [br] [b]Ignored[/b] : the pin does not display any additional widget or 
## information, and does not respond to any user input.
## [br] [b]Highlighted[/b] : the pin displays some additional information in an
## unobstructive way.
## [br] [b]Selected[/b] : the pin is currently selected by the user and should
## display its associated note.
## [br] [b]Examined[/b] : the pin configuration is reviewed by the user and 
## configuration widgets should be shown.
## [br] [b]ResizeActivated[/b] : the pin is being actively resized. Size is 
## shown and the scale od the node changes depending of user input.
## [br] [b]DeletingInitiated[/b] : the pin's deletion timer has been clicked by
## the user. If it runs out, the pin is queued for deletion.
## [br]
## The pin can switch from any state to any state. The pin will never switch to 
## a state by itself. 


## Number of displayed characters from the associated note when the pin is 
## highlighted.
const DISPLAYED_CHARACTERS_HIGHLIGHTED : int = 20


@export_group("pin sizing")
## Minimum size (as diameter in pixels) of a pin.
@export_range(10, 1000, 1) var min_pin_size_px : int = 60
## Maximum size (as diameter in pixels) of a pin.
@export_range(10, 1000, 1) var max_pin_size_px : int = 600
## Default size (as diameter in pixels) of a pin.
@export_range(10, 1000, 1) var default_pin_size_px : int = 150
@export_group("")


# pin components for ease of (and typed) access
@onready var _animation_player := $AnimationPlayer as AnimationPlayer

@onready var _delete_button := $DeleteButton as TextureButton
@onready var _delete_timer := $DeleteButton/DeletionTimer as Timer

@onready var _excerpt_container := $CenterContainer as CenterContainer
@onready var _excerpt_label := $CenterContainer/ExcerptLabel as Label

@onready var _icon_selector := $PinIconSelector as PinIconSelector

@onready var _pin_body := $PinBody as Area2D
@onready var _pin_body_shape := $PinBody/CollisionShape2DBody as CollisionShape2D
@onready var _pin_appearance := $PinBody/PinAppearance as PinAppearance

@onready var _note_edit := $NoteTextEdit as NoteTextEdit
@onready var _resize_handle := $ResizeHandle as TextureButton
@onready var _size_label := $SizeLabel as Label

@onready var _state_machine := $StateMachine as StateMachine


# this is the "original position" of the pin, updated everytime it is moved directly by the user.
# it can be used to adapt the position of the pin with no losses in the event of a background image change. 
var _original_position : Vector2

# current index of the texture chosen in the array of texture held in the appearance selector.
var _icon_texture_index : int = 0

func _ready() -> void:
	(_pin_body_shape.shape as CircleShape2D).radius = _pin_appearance.get_size_px().x / 2
	_pin_body.mouse_entered.connect(_toggle_hovered.bind(true))
	_pin_body.mouse_exited.connect(_toggle_hovered.bind(false))
	
	_resize_handle.button_down.connect(to_state.bind("ResizeActivated"))
	_delete_button.button_down.connect(to_state.bind("DeletingInitiated"))
	
	_note_edit.text_changed.connect(_note_text_changed)
	
	_icon_selector.selected_new_icon.connect(_change_appearance)
	_icon_selector.switch_to(_icon_texture_index)
	
	self.to_size(Vector2(default_pin_size_px, default_pin_size_px))
	
	GlobalEvents.requested_deselection_of_all_pins.connect(_deselect_self)
	GlobalEvents.changed_zoom_level.connect(change_control_nodes_scale)
	GlobalEvents.changed_background_image_dimensions.connect(_adapt_position_to_image_dim)
	GlobalEvents.brought_pin_upward_z_level.connect(_bring_down)
	
	_note_edit.text_changed.emit()
	self.play_animation("drop", 2.5)


## Changes the scale of the control nodes so while their position will follow 
## the node, their scale will not follow the camera's zoom.
## [br][code]new_zoom_level[/code] : camera's current zoom level
func change_control_nodes_scale(new_zoom_level : Vector2) -> void:
	for child in self.get_children():
		if child.is_in_group("unscaling"):
			child.scale.x = 1.0 / new_zoom_level.x
			child.scale.y = 1.0 / new_zoom_level.y


## Quick and dirty deletion timer access.
func deletion_timer() -> Timer:
	return _delete_timer


## Reads the pin's encoded data from a buffer and return the decoded data's 
## length. This will modify the pin to match the decoded data.
## [br][code]_version[/code] : program's version the of the saved data
## [br][code]buffer[/code] : byte array containing the node's data
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
	
	# fetch icon texture index
	decoded_info["icon texture"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	
	# fetch note text	
	decoded_info["note length"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	decoded_info["note content"] = buffer.slice(byte_offset, byte_offset + decoded_info["note length"]).get_string_from_utf8()
	byte_offset += decoded_info["note length"]
	
	self.move_to(Vector2(decoded_info["pos x"], decoded_info["pos y"]))
	self.to_size(Vector2(decoded_info["size x"], decoded_info["size y"]))
	self.z_index = decoded_info["z index"]
	_icon_selector.switch_to(decoded_info["icon texture"])
	self.set_note_text(decoded_info["note content"])
	self.to_state("Ignored")
	
	return byte_offset


## Move the pin to another position. No check is made to verify the validity of 
## the new position, but this will refresh the node's original position so the
## pin can be losslessly translated between different backgrounds of different 
## aspect ratios.
## [br][code]target[/code] : wanted position 
func move_to(target : Vector2) -> void:
	self.position = target
	_original_position = self.position
	GlobalEvents.changed_something_on_the_map.emit()

## Animates the pin with a custom preplaned animation.
func play_animation(animation_name : String, speed : float = 1.0) -> void:
	_animation_player.play(animation_name, -1, speed)


## Sets the pin's asociated note text to a new value.
## [br][code]text[/code] : new content for the note.
func set_note_text(text : String) -> void:
	_note_edit.text = text
	_note_edit.text_changed.emit()


## Toggles the visibility of the pin's note.
## [br][code]seen[/code] : wether to show or hide the note
func set_visibility_associated_note(seen : bool) -> void:
	if seen:
		_note_edit.show()
	else:
		_note_edit.hide()


## Toggles the visibility of the pin's excerpt.
## [br][code]seen[/code] : wether to show or hide the excerpt label
func set_visibility_excerpt_label(seen : bool) -> void:
	if seen:
		_excerpt_label.show()
	else:
		_excerpt_label.hide()


## Toggles the visibility of the pin's configuration controls.
## [br][code]seen[/code] : wether to show or hide the controls
func set_visibility_config_things(seen : bool) -> void:
	if seen:
		_resize_handle.show()
		_delete_button.show()
		_icon_selector.show()
	else:
		_resize_handle.hide()
		_delete_button.hide()
		_icon_selector.hide()


## Toggle visibility of the pin's size label.
## [br][code]seen[/code] : wether to show or hide the size label
func set_visibility_size_label(seen : bool) -> void:
	if seen:
		_size_label.show()
	else:
		_size_label.hide()


## Returns the diameter, in pixels, of the pin.
func size() -> Vector2:
	var radius_circle : float = 0.0
	if _pin_body_shape:
		radius_circle = _pin_body_shape.shape.radius
	return _pin_body.scale * (2 * radius_circle)


## Return the diameter, in pixels, of the pin, as if it were unscaled.
func size_unscaled() -> Vector2:
	var radius_circle : float = 0.0
	if _pin_body_shape:
		radius_circle = _pin_body_shape.shape.radius
	return Vector2(1, 1) * (2 * radius_circle)


## Return the current state of the pin as an unique string.
func state() -> StringName:
	return _state_machine.get_state_name()


## Saves the node's important information into a byte array, replacing its 
## content. This array can later be loaded with [method from_byte_array].
## [br][code]buffer[/code] : target buffer
func to_byte_array(buffer : PackedByteArray) -> SaveFile.SAVEFILE_ERROR:
	var text_buffer : PackedByteArray = []
	
	buffer.resize(28)
	
	# position
	buffer.encode_float(0, self.position.x)
	buffer.encode_float(4, self.position.y)
	# radius
	buffer.encode_float(8, self.size().x)
	buffer.encode_float(12, self.size().y)
	# z index
	buffer.encode_u32(16, self.z_index)
	# icon texture index
	buffer.encode_u32(20, self._icon_texture_index)
	# note text
	text_buffer = self._note_edit.text.to_utf8_buffer()
	buffer.encode_u32(24, len(text_buffer))
	buffer.append_array(text_buffer)
	
	return SaveFile.SAVEFILE_ERROR.NONE


## Sets the scale of the node according to the difference between the wanted pixel size and the pin's
## base size.
## [br][code]new_pix_size[/code] : new size of the pin node.
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
	
	_icon_selector.position.x = real_size.x / 1.5
	
	GlobalEvents.changed_something_on_the_map.emit()


## Changes the state of the pin to another state.
## [br][code]new_state[/code] : new state of the node
func to_state(new_state : StringName) -> void:
	if (_state_machine.state.name != new_state):
		GlobalEvents.switched_pin_state.emit(self, _state_machine.state.name, new_state)
		(_state_machine as StateMachine).transition_to(new_state)


# change the node's postion to match the new ratio between the two sizes
func _adapt_position_to_image_dim(old_dim : Vector2, new_dim : Vector2) -> void:
	self.position = self.position * (new_dim / old_dim)
	GlobalEvents.changed_something_on_the_map.emit()


# bring the pin's z-index down if it is above the limit
func _bring_down(limit_level : int) -> void:
	if self.z_index > limit_level:
		self.z_index -= 1


# change the appearance of the pin
func _change_appearance(apparel : Texture, new_index : int) -> void:
	_pin_appearance.icon_texture = apparel
	_icon_texture_index = new_index
	GlobalEvents.changed_something_on_the_map.emit()


func _deselect_self(exceptions : Array[Pin]) -> void:
	if not self in exceptions:
		self.to_state("Ignored")


# when the note text changes, the highlight excerpt must be updated
func _note_text_changed() -> void:
	GlobalEvents.changed_something_on_the_map.emit()
	var target_text : String = _note_edit.rich_text
	
	if (target_text.find("\n") < DISPLAYED_CHARACTERS_HIGHLIGHTED) and target_text.find("\n") != -1:
		_excerpt_label.text = target_text.get_slice("\n", 0)
	else:
		_excerpt_label.text = target_text.left(DISPLAYED_CHARACTERS_HIGHLIGHTED)
	
	_excerpt_label.text = _excerpt_label.text.strip_edges()
	_excerpt_label.text += "…" if target_text.length() > DISPLAYED_CHARACTERS_HIGHLIGHTED else ""


# Emits a signal about wether the mouse is hovering this pin or not.
func _toggle_hovered(mouse_entered : bool) -> void:
	GlobalEvents.hovered_pin_by_mouse.emit(self, mouse_entered)
