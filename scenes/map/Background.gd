extends Sprite2D

const PinScene : PackedScene = preload("res://scenes/pin/pin.tscn")


func _ready() -> void:
	GlobalEvents.new_default_pin.connect(_add_default_pin)
	GlobalEvents.changed_background_texture.connect(_on_changed_image)


func _on_changed_image(new_texture : Texture2D) -> void:
	if self.texture != null:
		self.texture.free()
	self.texture = new_texture


func _add_default_pin() -> void:
	var where := self.get_global_mouse_position()
	if (where.x <= 0) or (where.x >= self.texture.get_size().x) or (where.y <= 0) or (where.y >= self.texture.get_size().y):
		return
	
	var new_pin : Pin = PinScene.instantiate() as Pin
	new_pin.position = where
	new_pin.to_size(Vector2(150, 150))
	self.add_child(new_pin)
