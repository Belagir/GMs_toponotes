class_name NoteTextEdit
extends TabContainer


## Allows the edition and display of a markdown-powered note.
##
## The node is composed of two tabs : a display tab and an edition tab.
## The display tab is powered by a custom [MarkdownRichTextLabel].


## Emitted when the displayed text has changed. THe display text only changes 
## when the markdown text is set.
signal text_changed()


@onready var _edition_control : TextEdit = $Edition as TextEdit
@onready var _note_display_control : MarkdownRichTextLabel = $Note as MarkdownRichTextLabel


## This is the edited markdown text. This is translated to some BBCode rich text
## when the property is set.
var text : String :
	get:
		return _edition_control.text
	set(new_text):
		_edition_control.text = new_text
		self._actualize_rich_text()


## This is the displayed, read-only, BBCode rich text. 
var rich_text : String :
	get:
		return _note_display_control.get_parsed_text()
	set(new_text): pass


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
