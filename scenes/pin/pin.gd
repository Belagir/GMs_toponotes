class_name Pin
extends Node2D


enum PIN_STATE {
	IGNORED,
	HIGHLIGHTED,
	SELECTED,
}


var _my_state : PIN_STATE = PIN_STATE.IGNORED


func _ready() -> void:
	($PinBody/CollisionShape2D.shape as CircleShape2D).radius = ($PinBody/SpriteBase.texture as Texture2D).get_size().x
	$PinBody.mouse_entered.connect(_pin_hovered.bind(true))
	$PinBody.mouse_exited.connect(_pin_hovered.bind(false))
	
	GlobalEvents.pin_request_all_deselection.connect(to_state.bind(PIN_STATE.IGNORED))
	GlobalEvents.zoom_level_changed.connect(_change_note_scale)


func state() -> PIN_STATE:
	return _my_state


# sets the scale of the node according to the difference between the wanted pixel size and the pin's
# base size.
func to_size(new_pix_size : Vector2) -> void:
	var size_texture : Vector2 = ($PinBody/SpriteBase.texture as Texture2D).get_size()
	$PinBody.scale = new_pix_size / size_texture
	$NoteTextEdit.position.x = size_texture.x * $PinBody.scale.x / 1.5


func to_state(new_state : PIN_STATE) -> void:
	# state exit
	match _my_state:
		PIN_STATE.IGNORED:
			pass
		PIN_STATE.HIGHLIGHTED:
			pass
		PIN_STATE.SELECTED:
			$NoteTextEdit.hide()
			GlobalEvents.pin_deselected.emit(self)
	
	# state enter
	match new_state:
		PIN_STATE.IGNORED:
			pass
		PIN_STATE.HIGHLIGHTED:
			pass
		PIN_STATE.SELECTED:
			$NoteTextEdit.show()
	
	_my_state = new_state


func _pin_hovered(entered : bool) -> void:
	GlobalEvents.emit_signal("pin_hover", self, entered)


func _change_note_scale(new_zoom_level : Vector2) -> void:
	$NoteTextEdit.scale.x = 1.0 / new_zoom_level.x
	$NoteTextEdit.scale.y = 1.0 / new_zoom_level.y
