extends ScrollContainer


class CountedAppearance:
	var appearance : PinTrayPinAppearance
	var counter : int
	
	func _init(pin_app : PinAppearance, start_count : int, container : Container):
		self.appearance = PinTrayPinAppearance.new(pin_app, container)
		self.counter = start_count


## dictionary from hashes of appearances to their associated appearances and a counter
var _shown_appearances : Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalEvents.changed_pin_appearance.connect(_process_appearance.bind(false))
	GlobalEvents.removed_pin_appearance.connect(_process_appearance.bind(true))


func _process_appearance(pin_app : PinAppearance, removed : bool) -> void:
	var hash_value = pin_app.hash_of_sprites()
	if _shown_appearances.has(hash_value):
		if removed and (_shown_appearances[hash_value].counter <= 1):
			$VBoxContainer.remove_child(_shown_appearances[hash_value].appearance)
			_shown_appearances.erase(hash_value)
		elif removed:
			_shown_appearances[hash_value].counter -= 1
		else:
			_shown_appearances[hash_value].counter += 1
	elif not removed:
		_shown_appearances[hash_value] = CountedAppearance.new(pin_app, 1, self)
		$VBoxContainer.add_child(_shown_appearances[hash_value].appearance)
