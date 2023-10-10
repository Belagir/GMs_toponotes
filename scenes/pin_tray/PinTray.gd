extends ScrollContainer


var _shown_appearances_array : Array[PinAppearance] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalEvents.changed_pin_appearance.connect(_process_appearance.bind(false))
	GlobalEvents.removed_pin_appearance.connect(_process_appearance.bind(true))
	

func _process_appearance(pin_app : PinAppearance, removed : bool) -> void:
	for pa in _shown_appearances_array:
		pass
