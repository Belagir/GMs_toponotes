class_name PinHoveredAwareState
extends State

## This State class listens for pin hovered events.

var _pins_hovered : Array[Pin] = []


func on_enter(args : Dictionary) -> void:
	GlobalEvents.hovered_pin_by_mouse.connect(_update_pin_hovered)
	if args.has("pins hovered"):
		_pins_hovered = args["pins hovered"]


func on_leave() -> void:
	GlobalEvents.hovered_pin_by_mouse.disconnect(_update_pin_hovered)
	

func _update_pin_hovered(pin : Pin, entered : bool) -> void:
	if entered:
		_pins_hovered.insert(_pins_hovered.bsearch_custom(pin, _pin_is_over_other), pin)
	else:
		_pins_hovered.remove_at(_pins_hovered.bsearch_custom(pin, _pin_is_over_other))


func _pin_is_over_other(pin1 : Pin, pin2 : Pin) -> bool:
	return pin1.z_index > pin2.z_index

