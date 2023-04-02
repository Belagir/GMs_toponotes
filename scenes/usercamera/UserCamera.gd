extends Camera2D

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

# camera start position in the event of dragging
var _camera_start_pos : Vector2 = Vector2(0, 0)
# mouse start position in the event of dragging
var _dragging_start_pos : Vector2 = Vector2(0, 0)

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
func drag_camera(mouse_motion : InputEventMouseMotion) -> void:
	self.position = ((_dragging_start_pos - mouse_motion.position) / self.zoom) + _camera_start_pos
	_keep_camera_in_bounds()

# starts dragging from a certain mouse position
func toggle_dragging_from(mouse_action : InputEventMouse) -> void:
	_dragging_start_pos = mouse_action.position
	_camera_start_pos = self.position

# changes zoom upward or downward
func _change_zoom(kind : ZOOM) -> void:
	var modifier : int = 1 if kind == ZOOM.IN else -1
	
	self.zoom *=  Vector2(zoom_step ** modifier, zoom_step ** modifier)
	self.zoom = clamp(zoom, Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))
	
	self.position = self.position + ((-modifier) * (self.position - get_global_mouse_position()) * (zoom_step-1))
	_keep_camera_in_bounds()

# clamps the camera's postion inside the known map dimensions
func _keep_camera_in_bounds() -> void:
	self.position.x = clamp(self.position.x, 0.0, _map_dimensions.x)
	self.position.y = clamp(self.position.y, 0.0, _map_dimensions.y)

# updates the known map dimensions 
func _update_map_dimensions(new_dim : Vector2) -> void:
	_map_dimensions = new_dim
	_keep_camera_in_bounds()
