class_name PinHoveredAwareState
extends State


var _pin_hovered : Pin = null


func on_enter(args : Dictionary) -> void:
	GlobalEvents.pin_hover.connect(_update_pin_hovered)
	if args.has("pin hovered"):
		_pin_hovered = args["pin hovered"]


func on_leave() -> void:
	GlobalEvents.pin_hover.disconnect(_update_pin_hovered)
	

func _update_pin_hovered(pin : Pin, entered : bool) -> void:
	_pin_hovered = pin if entered else null
	if _pin_hovered and _pin_hovered.state() == "Ignored":
		_pin_hovered.to_state("Highlighted")
