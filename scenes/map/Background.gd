extends Sprite2D

const PinScene : PackedScene = preload("res://scenes/pin/pin.tscn")


func _ready() -> void:
	GlobalEvents.new_default_pin.connect(_add_default_pin)
	GlobalEvents.changed_background_texture.connect(_on_changed_image)
	
	self.add_to_group(SaveFile.GROUP_SAVED_NODES)


func _on_changed_image(new_texture : Texture2D) -> void:
	var old_size : Vector2 = self.texture.get_size() if self.texture else Vector2(0, 0)
	var new_size : Vector2 = new_texture.get_size() if new_texture else Vector2(0, 0)
	GlobalEvents.emit_signal("background_image_dimensions_changed", old_size, new_size)
	self.texture = new_texture


func _add_default_pin(current_zoom_level : Vector2) -> void:
	var where := self.get_global_mouse_position()
	if not self.texture:
		return
	
	if (where.x <= 0) or (where.x >= self.texture.get_size().x) or (where.y <= 0) or (where.y >= self.texture.get_size().y):
		return
	
	var new_pin : Pin = PinScene.instantiate() as Pin
	self.add_child(new_pin)
	new_pin.move_to(where)
	new_pin.change_note_scale(current_zoom_level)


func save_node_to(buffer : PackedByteArray) -> void:
	var image := self.texture.get_image()
	var image_data := image.get_data()
	
	buffer.resize(16)
	
	buffer.encode_u32(0, image.get_width())
	buffer.encode_u32(4, image.get_height())
	buffer.encode_u32(8, image.get_format())
	buffer.encode_u32(12, len(image_data))
	
	buffer.append_array(image_data)


func load_node_from(_version : int, buffer : PackedByteArray) -> void:
	var image : Image
	var new_texture : Texture2D
	var image_info : Dictionary = {}
	var image_data : PackedByteArray
	
	image_info["width"] = buffer.decode_u32(0)
	image_info["height"] = buffer.decode_u32(4)
	image_info["format"] = buffer.decode_u32(8)
	image_info["data length"] = buffer.decode_u32(12)
	
	image_data = buffer.slice(16)
	
	image = Image.create_from_data(image_info["width"], image_info["height"], false, image_info["format"], image_data)
	if not image:
		return;
	
	new_texture = ImageTexture.create_from_image(image)
	GlobalEvents.changed_background_texture.emit(new_texture)

