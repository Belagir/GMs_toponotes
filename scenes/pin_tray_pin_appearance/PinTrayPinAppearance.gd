extends Control
class_name PinTrayPinAppearance

var _my_appearance : PinAppearance = null
var _pin_tray_container : Container = null


func _init(appearance : PinAppearance, container : Container) -> void:
	_my_appearance = appearance
	_pin_tray_container = container


func _ready() -> void:
	_my_appearance.scale = Vector2(_pin_tray_container.size.x, _pin_tray_container.size.x) / _my_appearance.get_size_px()
	_my_appearance.position = _my_appearance.get_size_px() * _my_appearance.scale / 2
	
	self.set_custom_minimum_size(_my_appearance.get_size_px() * _my_appearance.scale)
	self.add_child(_my_appearance)
