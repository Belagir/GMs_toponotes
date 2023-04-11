class_name NoteTextEdit
extends TabContainer


signal text_changed()


@onready var _edition_control : TextEdit = $Edition as TextEdit
@onready var _note_display_control : MarkdownRichTextLabel = $Note as MarkdownRichTextLabel


var text : String :
	get:
		return _edition_control.text
	set(new_text):
		_edition_control.text = new_text
		self._actualize_rich_text()


var rich_text : String :
	get:
		return _note_display_control.get_parsed_text()


func _ready() -> void:
	_note_display_control.visibility_changed.connect(_actualize_rich_text)
	_note_display_control.finished.connect(func(): self.text_changed.emit())
	self.visibility_changed.connect(_bring_note_tab_forward)


func _actualize_rich_text() -> void:
	_note_display_control.md_set_whole_text(_edition_control.text)


func _bring_note_tab_forward() -> void:
	self.current_tab = 0
	_actualize_rich_text()
	_note_display_control.finished.emit()
