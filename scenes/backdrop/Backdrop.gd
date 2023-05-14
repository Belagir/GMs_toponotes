extends Control

@onready var viewport = get_viewport()

@export var minimum_size := Vector2(1920.0, 1080.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	viewport.size_changed.connect(_on_resize)
	_on_resize()


func _on_resize() -> void:
	var current_size := viewport.get_window().size;
	
	var scale_factor := minimum_size.y / current_size.y
	var new_size := Vector2(current_size.x * scale_factor, minimum_size.y)
	
	if new_size.y < minimum_size.y:
		scale_factor = minimum_size.y / new_size.y
		new_size = Vector2(new_size.x * scale_factor, minimum_size.y)
	if new_size.x < minimum_size.x:
		scale_factor = minimum_size.x/new_size.x
		new_size = Vector2(minimum_size.x, new_size.y*scale_factor)
