extends Sprite2D

const PinScene : PackedScene = preload("res://scenes/pin/pin.tscn")


func _ready() -> void:
	GlobalEvents.new_default_pin.connect(_add_default_pin)
	GlobalEvents.changed_background_texture.connect(_on_changed_image)


func _on_changed_image(new_texture : Texture2D) -> void:
	var old_size : Vector2 = self.texture.get_size() if self.texture else Vector2(0, 0)
	var new_size : Vector2 = new_texture.get_size() if new_texture else Vector2(0, 0)
	GlobalEvents.emit_signal("background_image_dimensions_changed", old_size, new_size)
	self.texture = new_texture


func _add_default_pin(current_zoom_level : Vector2) -> void:
	var where := self.get_global_mouse_position()
	if (where.x <= 0) or (where.x >= self.texture.get_size().x) or (where.y <= 0) or (where.y >= self.texture.get_size().y):
		return
	
	var new_pin : Pin = PinScene.instantiate() as Pin
	self.add_child(new_pin)
	new_pin.move_to(where)
	new_pin.change_note_scale(current_zoom_level)
