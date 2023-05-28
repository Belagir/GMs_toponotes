extends Control

@onready var viewport := get_viewport()
@onready var sprite := $BackdropSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	viewport.size_changed.connect(_on_resize)
	_on_resize()


func _on_resize() -> void:
	var new_size : Vector2 = viewport.get_window().size
	var texture_size : Vector2 = sprite.texture.get_size()
	var dimension_ratios : Vector2 = new_size / texture_size
	
	sprite.scale = dimension_ratios
