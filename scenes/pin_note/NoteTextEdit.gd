class_name NoteTextEdit
extends TabContainer


signal text_changed()


var text : String :
	get:
		return $Edition.text
	set(new_text):
		$Edition.text = new_text
		self._actualize_rich_text()


var rich_text : String :
	get:
		return $Note.get_parsed_text()


func _ready() -> void:
	$Note.visibility_changed.connect(_actualize_rich_text)
	$Note.finished.connect(func(): self.text_changed.emit())


func _actualize_rich_text() -> void:
	if not $Note.visible:
		return
	$Note.md_set_whole_text($Edition.text)
