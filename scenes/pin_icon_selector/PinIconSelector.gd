class_name PinIconSelector
extends HBoxContainer

## Enable the selection of a pin appearance among several.
##
## This node will generate a pin appearance for each registered texture. Each 
## time an icon is changed, the signal [signal selected_new_icon] is emitted.

const _pin_appearance_scene = preload("res://scenes/pin_appearance/PinAppearance.tscn")


## Emitted when the user selects a new icon
signal selected_new_icon(Texture2D, int)

## Array of textures that will be avaible to the user for selection
@export var available_icons_textures : Array[Texture2D] = []


var _stored_icons : Array[PinAppearance] = []
var _pos_selected_icon : int = 0

func _ready() -> void:
	var tmp_pin_appearance : PinAppearance = null
	
	for icon_texture in available_icons_textures:
		tmp_pin_appearance = _pin_appearance_scene.instantiate() as PinAppearance
		self.add_child(tmp_pin_appearance)
		_stored_icons.push_back(tmp_pin_appearance)
		tmp_pin_appearance.icon_texture = icon_texture
		tmp_pin_appearance.hide()
	
	self.visibility_changed.connect(_update_icon_previews)
	self.resized.connect(_update_icon_previews)
	self.sort_children.connect(_update_icon_previews)
	self.selected_new_icon.connect(func(_t, _i): _update_icon_previews())
	
	$ButtonLeft.pressed.connect(_slide_icons.bind(-1))
	$ButtonRight.pressed.connect(_slide_icons.bind(1))

## Switchs to a certain pin appearance determined by its index. If the index is 
## out of bounds, the value is wrapped around.
func switch_to(index : int) -> void:
	_pos_selected_icon = posmod(index, _stored_icons.size());
	self.selected_new_icon.emit(_stored_icons[_pos_selected_icon].icon_texture, _pos_selected_icon)


func _set_icon_preview(target : Control, icon : PinAppearance) -> void:
	icon.scale = target.size / icon.get_size_px()
	icon.position = Vector2(target.position) + 0.5 * (icon.scale * icon.get_size_px())
	icon.show()


func _slide_icons(difference : int) -> void:
	switch_to(_pos_selected_icon + difference)


func _update_icon_previews() -> void:
	var nb_of_icons := _stored_icons.size()
	if (nb_of_icons == 0):
		return
	
	for icon in _stored_icons:
		icon.hide()
	
	_set_icon_preview($IconPreviewLeft, _stored_icons[posmod(_pos_selected_icon - 1, nb_of_icons)])
	_set_icon_preview($IconPreviewMain, _stored_icons[posmod(_pos_selected_icon, nb_of_icons)])
	_set_icon_preview($IconPreviewRight, _stored_icons[posmod(_pos_selected_icon + 1, nb_of_icons)])
