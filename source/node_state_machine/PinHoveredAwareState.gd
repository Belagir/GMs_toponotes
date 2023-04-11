class_name PinHoveredAwareState
extends State


var _pins_hovered : Array[Pin] = []


func on_enter(args : Dictionary) -> void:
	GlobalEvents.pin_hover.connect(_update_pin_hovered)
	if args.has("pins hovered"):
		_pins_hovered = args["pins hovered"]


func on_leave() -> void:
	GlobalEvents.pin_hover.disconnect(_update_pin_hovered)
	

func _update_pin_hovered(pin : Pin, entered : bool) -> void:
	if entered:
		_pins_hovered.insert(_pins_hovered.bsearch_custom(pin, _pin_is_over_other), pin)
		if pin.state() == "Ignored":
			pin.to_state("Highlighted")
	else:
		_pins_hovered.remove_at(_pins_hovered.bsearch_custom(pin, _pin_is_over_other))
		if pin.state() == "Highlighted":
			pin.to_state("Ignored")


func _pin_is_over_other(pin1 : Pin, pin2 : Pin) -> bool:
	return pin1.z_index > pin2.z_index

