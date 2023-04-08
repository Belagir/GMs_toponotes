extends Camera2D

# Global events listened to :
# - background_image_dimensions_changed  -> to update the remembered background dimensions and limit 
#   camera movement
# - pin_deselected -> to make the distinction between a click to deselect pins or add a new one
#
# Global events sent :
# - zoom_level_changed -> the zoom level changed
# - pin_request_all_deselection  -> deselect all pins
# - new_default_pin -> add a pin

# kind of zoom action
enum ZOOM { IN, OUT }


@export_group("zoom settings")
# maximum zoom allowed
@export_range(1, 4) var zoom_max : float = 3
# minimum zoom allowed
@export_range(0.1, 1) var zoom_min : float = 0.1
# zoom multiplier each mouse wheel increment
@export_range(1, 2, 0.05) var zoom_step : float = 1.2
@export_group("")

# map dimensions for bound checking
var _map_dimensions : Vector2 = Vector2(0, 0)


func _ready() -> void:
	# listen to map dimension updates to preserve bound check correctness
	GlobalEvents.background_image_dimensions_changed.connect(_update_map_dimensions)


func _unhandled_input(event : InputEvent) -> void:
	# only the zooming is handled directly by the camera, other inputs are managed by the owned 
	# state machine node
	if event.is_action("map zoom"):
		_change_zoom(ZOOM.IN)
	elif event.is_action("map dezoom"):
		_change_zoom(ZOOM.OUT)


# drags the camera along a mouse movement
func drag_camera(mouse_motion : InputEventMouseMotion, cam_start : Vector2, drag_start : Vector2) -> void:
	self.position = ((drag_start - mouse_motion.position) / self.zoom) + cam_start
	self.position = keep_in_my_map(self.position)


func keep_in_my_map(coords : Vector2) -> Vector2:
	coords.x = clamp(coords.x, 0.0, _map_dimensions.x)
	coords.y = clamp(coords.y, 0.0, _map_dimensions.y)
	
	return coords


# changes zoom upward or downward
func _change_zoom(kind : ZOOM) -> void:
	var modifier : int = 1 if kind == ZOOM.IN else -1
	
	self.zoom *=  Vector2(zoom_step ** modifier, zoom_step ** modifier)
	self.zoom = clamp(zoom, Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))
	GlobalEvents.zoom_level_changed.emit(self.zoom)
	
	self.position = self.position + ((-modifier) * (self.position - get_global_mouse_position()) * (zoom_step-1))
	self.position = keep_in_my_map(self.position)


# updates the known map dimensions 
func _update_map_dimensions(_old_dim : Vector2, new_dim : Vector2) -> void:
	_map_dimensions = new_dim
	self.position = keep_in_my_map(self.position)
