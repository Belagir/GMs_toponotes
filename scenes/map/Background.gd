extends Sprite2D

## The Background class manages everything related to the background map.
## 
## The Background's main task is to create, manage and get rid of instances of 
## the [Pin] class placed on it. 
## The class can be saved to and loaded from a byte array. Those saves include
## pins taht are child of the node.

# pin scene for instanciation purposes
const _PinScene : PackedScene = preload("res://scenes/pin/pin.tscn")

# To remember the zoom level of the camera so pins can be created with  widgets
# already scaled. 
var _zoom_level := Vector2(1, 1)
# To remember the last z-level affected to a pin.
var _max_pin_z_level : int = 1


func _ready() -> void:
	GlobalEvents.requested_new_default_pin.connect(_add_default_pin)
	GlobalEvents.requested_change_of_background_image.connect(_on_changed_image)
	GlobalEvents.requested_map_wipe.connect(reset_map)
	GlobalEvents.changed_zoom_level.connect(func(new_zoom : Vector2): _zoom_level = new_zoom)
	GlobalEvents.switched_pin_state.connect(_bring_pin_up)
	
	self.add_to_group(SaveFile.GROUP_SAVED_NODES)


## Loads the node's important information from a byte buffer.
## Modifications read from the buffer are applied and will overide the node's 
## current state.
##     [br][code]version[/code] : version of the program the save originates from
##     [br][code]buffer[/code] : byte buffer the saved data is read from
func load_node_from(version : int, buffer : PackedByteArray) -> void:
	var image : Image
	var new_texture : Texture2D
	var image_info : Dictionary = {}
	var image_data : PackedByteArray
	var byte_offset : int = 0
	
	# fetch image dimensions
	image_info["width"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	image_info["height"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	# fetch image format
	image_info["format"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	# fetch uncompressed image data length
	image_info["data length"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	# fetch compressed image data length
	image_info["compressed data length"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	
	# fetch image data and decompress it
	image_data = buffer \
					.slice(byte_offset, byte_offset+image_info["compressed data length"]) \
					.decompress(image_info["data length"], FileAccess.COMPRESSION_FASTLZ)
	byte_offset += image_info["compressed data length"]
	
	# try to interpret the image data as an Image type
	image = Image.create_from_data(image_info["width"], image_info["height"], false, image_info["format"], image_data)
	if not image:
		return;
	
	# oh happy path
	self.reset_map()
	
	# assign texture
	new_texture = ImageTexture.create_from_image(image)
	GlobalEvents.requested_change_of_background_image.emit(new_texture)
	
	# fetch pins data and decode it
	image_info["pins number"] = buffer.decode_u32(byte_offset)
	byte_offset += 4
	self._decode_all_pins_from(version, buffer.slice(byte_offset), image_info["pins number"])


## Resets the map to a blank and empty state. 
## This will delete : 
## [br] - all the pins ;
## [br] - the currently loaded texture.
func reset_map() -> void:
	self.texture.queue_free()
	self.texture = null
	for child in get_children():
		if child is Pin: child.queue_free()
	GlobalEvents.changed_something_on_the_map.emit()

## Saves the node's important information to a byte buffer.
##    [br][code]buffer[/code] : target buffer which content will be replaced with 
## the node's save data
func save_node_to(buffer : PackedByteArray) -> SaveFile.SAVEFILE_ERROR:
	var image := self.texture.get_image()
	var image_data := image.get_data()
	var image_data_compressed := image_data.compress(FileAccess.COMPRESSION_FASTLZ)
	var tmp_buffer : PackedByteArray = []
	
	# we want to convert the texture to an image to compress and store it
	if (not image) or (len(image_data) == 0) or (len(image_data_compressed) == 0):
		return SaveFile.SAVEFILE_ERROR.FATAL
	
	buffer.resize(20)
	
	# image size
	buffer.encode_u32(0, image.get_width())
	buffer.encode_u32(4, image.get_height())
	# image format
	buffer.encode_u32(8, image.get_format())
	# uncompressed image byte length
	buffer.encode_u32(12, len(image_data))
	# compressed image byte length
	buffer.encode_u32(16, len(image_data_compressed))
	
	buffer.append_array(image_data_compressed)
	
	# using a temporary buffer to be sure to use encode_u32() so the decoding is not guesswork
	tmp_buffer.resize(4)
	tmp_buffer.encode_u32(0, self._number_of_pins())
	buffer.append_array(tmp_buffer)
	self._append_encode_all_pins(buffer)
	
	return SaveFile.SAVEFILE_ERROR.NONE


# add a default, blank pin where the mouse is, provided the pin can be placed on the current texture
func _add_default_pin(where : Vector2) -> void:
	# verifications for valid positionning
	if not self.texture:
		return
	if (where.x <= 0) or (where.x >= self.texture.get_size().x) or (where.y <= 0) or (where.y >= self.texture.get_size().y):
		return
	
	# adding the pin
	var new_pin := self._add_pin()
	new_pin.move_to(where)
	GlobalEvents.changed_something_on_the_map.emit()


# Adds a pin.
func _add_pin() -> Pin:
	var new_pin := _PinScene.instantiate() as Pin
	self.add_child(new_pin)
	new_pin.change_control_nodes_scale(_zoom_level)
	_max_pin_z_level += 1
	new_pin.z_index = _max_pin_z_level
	return new_pin


# appends the pin's binary data to the provided buffer.
func _append_encode_all_pins(buffer : PackedByteArray) -> void:
	var children : Array[Node] = self.get_children()
	var pin_buffer : PackedByteArray = []
	var child_pin : Pin = null
	
	for child in children:
		child_pin = child as Pin
		if child_pin:
			child_pin.to_byte_array(pin_buffer)
			buffer.append_array(pin_buffer)


# bring one pin all the way up and notify of this action the rest of the program 
func _bring_pin_up(pin : Pin, _old_state: String, new_state : String) -> void:
	if new_state == "Selected":
		GlobalEvents.brought_pin_upward_z_level.emit(pin.z_index)
		pin.z_index = _max_pin_z_level


# decode the pin's binary data from the provided buffer and adds them to the node.
func _decode_all_pins_from(version : int, buffer : PackedByteArray, nb_pins : int) -> void:
	var new_pin : Pin
	var byte_offset : int = 0
	var size_pin_data : int = 0
	
	for i in range(nb_pins):
		new_pin = self._add_pin()
		size_pin_data = new_pin.from_byte_array(version, buffer.slice(byte_offset))
		byte_offset += size_pin_data


# Returns the number of pins held by the background. Low performance !
func _number_of_pins() -> int:
	var children : Array[Node] = self.get_children()
	var nb_pins : int = 0
	for child in children:
		if child is Pin:
			nb_pins += 1
	return nb_pins


# code executed when a new texture is selected (from some other node) to be the background image.
func _on_changed_image(new_texture : Texture2D) -> void:
	var old_size : Vector2 = self.texture.get_size() if self.texture else Vector2(0, 0)
	var new_size : Vector2 = new_texture.get_size() if new_texture else Vector2(0, 0)
	GlobalEvents.changed_background_image_dimensions.emit(old_size, new_size)
	self.texture = new_texture
	GlobalEvents.changed_something_on_the_map.emit()

