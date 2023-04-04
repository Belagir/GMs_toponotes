class_name Pin
extends Node2D


@export_group("pin sizing")
@export_range(10, 1000, 1) var min_pin_size_px : int = 60
@export_range(10, 1000, 1) var max_pin_size_px : int = 600
@export_range(10, 1000, 1) var default_pin_size_px : int = 150
@export_group("")


@onready var _pin_body : Area2D = $PinBody as Area2D
@onready var _pin_body_shape : CollisionShape2D = $PinBody/CollisionShape2DBody as CollisionShape2D
@onready var _pin_body_sprite : Sprite2D = $PinBody/SpriteBase as Sprite2D
@onready var _note_edit : TextEdit = $NoteTextEdit as TextEdit
@onready var _state_machine : StateMachine = $StateMachine as StateMachine
@onready var _resize_handle : TextureButton = $ResizeHandle as TextureButton
@onready var _delete_button : TextureButton = $DeleteButton as TextureButton
@onready var _delete_timer : Timer = $DeleteButton/DeletionTimer as Timer
@onready var _size_label : Label = $SizeLabel as Label


func _ready() -> void:
	(_pin_body_shape.shape as CircleShape2D).radius = (_pin_body_sprite.texture as Texture2D).get_size().x / 2
	_pin_body.mouse_entered.connect(_pin_hovered.bind(true))
	_pin_body.mouse_exited.connect(_pin_hovered.bind(false))
	
	_resize_handle.button_down.connect(_state_machine.transition_to.bind("ResizeActivated"))
	_delete_button.button_down.connect(_state_machine.transition_to.bind("DeletingInitiated"))
	
	self.to_size(Vector2(default_pin_size_px, default_pin_size_px))
	
	GlobalEvents.pin_request_all_deselection.connect(to_state.bind("Ignored"))
	GlobalEvents.zoom_level_changed.connect(change_note_scale)


# change the scale of the NoteEdit child
func change_note_scale(new_zoom_level : Vector2) -> void:
	_note_edit.scale.x = 1.0 / new_zoom_level.x
	_note_edit.scale.y = 1.0 / new_zoom_level.y


# quick and dirty deletion timer access
func deletion_timer() -> Timer:
	return _delete_timer


# move the pin to another position
func move_to(target : Vector2) -> void:
	self.position = target


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


# signal that this pin is hovered
func _pin_hovered(entered : bool) -> void:
	GlobalEvents.emit_signal("pin_hover", self, entered)

