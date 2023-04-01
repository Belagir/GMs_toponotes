extends Sprite2D

const Pin = preload("res://scenes/pin/pin.gd")
const PinScene : PackedScene = preload("res://scenes/pin/pin.tscn")


func _ready() -> void:
	GlobalEvents.new_default_pin.connect(_add_default_pin)
	GlobalEvents.changed_background_texture.connect(_on_changed_image)


func _on_changed_image(new_texture : Texture2D) -> void:
	if self.texture != null:
		self.texture.free()
	self.texture = new_texture


func _add_default_pin(where : Vector2) -> void:
	var new_pin : Pin = PinScene.instantiate() as Pin
	new_pin.position = where
	new_pin.to_size(Vector2(50, 50))
	self.add_child(new_pin)
