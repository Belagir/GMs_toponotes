extends TabContainer

func _ready() -> void:
	$Note.visibility_changed.connect(_actualize_rich_text)


func _actualize_rich_text() -> void:
	if not $Note.visible:
		return
	$Note.md_set_whole_text($Edition.text)
