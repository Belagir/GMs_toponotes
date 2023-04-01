extends Camera2D

const Pin = preload("res://scenes/pin/pin.gd")

enum ZOOM { IN, OUT }


@export_range(0.01, 0.1, 0.01) var zoom_step : float = 0.04
@export_range(1, 4) var zoom_max : float = 3
@export_range(0.1, 1) var zoom_min : float = 0.1

var _is_dragging : bool = false
var _has_moved : bool = false
var _dragging_start_pos : Vector2 = Vector2(0, 0)
var _camera_start_pos : Vector2 = Vector2(0, 0)

var _map_dimensions : Vector2 = Vector2(0, 0)

var _pin_hovered : Pin = null
var _pin_selected : Pin = null


func _ready() -> void:
	GlobalEvents.background_image_dimensions_changed.connect(_update_map_dimensions)
	GlobalEvents.pin_hover.connect(_update_pin_hovered)


func _unhandled_input(event : InputEvent) -> void:
	var mouse_motion : InputEventMouseMotion = event as InputEventMouseMotion
	var mouse_button : InputEventMouseButton = event as InputEventMouseButton
	
	if mouse_button != null:
		_toggle_dragging_from(mouse_button)
		if _pin_hovered != null:
			if (mouse_button.is_action_released("pin add")):
				_pin_hovered.to_state(Pin.PIN_STATE.SELECTED)
		else:
			GlobalEvents.pin_deselection.emit()
			if event.is_action("pin add") and (not _is_dragging) and (not _has_moved):
				GlobalEvents.new_default_pin.emit(self.get_global_mouse_position())
			_has_moved = not mouse_button.is_pressed()
	elif (mouse_motion != null) and _is_dragging:
		_drag_camera(mouse_motion)
	
	if event.is_action("map zoom"):
		_change_zoom(ZOOM.IN)
	elif event.is_action("map dezoom"):
		_change_zoom(ZOOM.OUT)


func _update_map_dimensions(new_dim : Vector2) -> void:
	_map_dimensions = new_dim


func _update_pin_hovered(pin : Node2D, entered : bool) -> void:
	if entered:
		_pin_hovered = pin as Pin
	else:
		_pin_hovered = null


func _toggle_dragging_from(mouse_action : InputEventMouse) -> void:
	_is_dragging = mouse_action.is_pressed()
	_dragging_start_pos = mouse_action.position
	_camera_start_pos = self.position


func _drag_camera(mouse_motion : InputEventMouseMotion) -> void:
	_has_moved = true
	self.position = ((_dragging_start_pos - mouse_motion.position) / self.zoom) + _camera_start_pos
	self.position.x = clamp(self.position.x, 0.0, _map_dimensions.x)
	self.position.y = clamp(self.position.y, 0.0, _map_dimensions.y)


func _change_zoom(kind : ZOOM) -> void:
	var modifier : float = 1.0 if kind == ZOOM.IN else -1.0
	self.zoom += modifier * Vector2(zoom_step, zoom_step)
	self.zoom = clamp(zoom, Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))

