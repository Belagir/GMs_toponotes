class_name MarkdownRichTextLabel
extends RichTextLabel

## This is a rich text label that can accept markdown syntax.
## 
## Markdown text can be passed to the node with [method md_append_text] and
## [method md_set_whole_text].

## Curently supported markdown syntax.
enum MD_KEYWORD { NONE, ITALICS, EMPHASIS, BOLD_ITALICS, CODE_SPAN }
const _md_keyword_str := { \
		"_"   : MD_KEYWORD.ITALICS, \
		"*"   : MD_KEYWORD.ITALICS, \
		"__"  : MD_KEYWORD.EMPHASIS, \
		"**"  : MD_KEYWORD.EMPHASIS, \
		"___" : MD_KEYWORD.BOLD_ITALICS, \
		"***" : MD_KEYWORD.BOLD_ITALICS, \
		"`"   : MD_KEYWORD.CODE_SPAN, \
}

var _keyword_translation := { \
		MD_KEYWORD.ITALICS       : func(rich_label : RichTextLabel): rich_label.push_italics(), \
		MD_KEYWORD.EMPHASIS      : func(rich_label : RichTextLabel): rich_label.push_bold(), \
		MD_KEYWORD.BOLD_ITALICS  : func(rich_label : RichTextLabel): rich_label.push_bold_italics(), \
		MD_KEYWORD.CODE_SPAN     : func(rich_label : RichTextLabel): rich_label.push_mono(), \
}


var _keyword_stack : Array[String] = []
var _markdown_automaton : BareStateMachine


class MarkdownDecoderState:
	var owner_machine : BareStateMachine
	var target_label : MarkdownRichTextLabel
	
	func on_message(msg : String) -> String:
		owner_machine.transition_to("anything")
		return msg
	
	func _init(target : MarkdownRichTextLabel) -> void:
		target_label = target


# --------------------------------------------------------------------------------------------------
class StateAnything extends MarkdownDecoderState:
	
	func on_message(msg : String) -> String:
		var letter : String = msg[0]
		
		if (letter  == "*") or (letter == "_"):
			owner_machine.transition_to("increment emphasis", { "character" = letter, "magnitude" = 1 })
			return msg.right(-1)
		elif (letter == "`"):
			owner_machine.transition_to("code span")
			return msg.right(-1)
		elif (letter == "\\"):
			owner_machine.transition_to("escaping")
			return msg.right(-1)
		owner_machine.transition_to("other letter")
		return msg


# --------------------------------------------------------------------------------------------------
class StateIncrementEmphasis extends MarkdownDecoderState:
	var character : String
	var magnitude : int
	
	func on_enter(args : Dictionary) -> void:
		self.character = args["character"]
		self.magnitude = args["magnitude"]
	
	func on_message(msg : String) -> String:
		if (msg[0] != self.character) or (self.magnitude >= 3):
			owner_machine.transition_to("emphasis", { "character" = self.character, "keyword" = "".rpad(self.magnitude, self.character) })
			return msg
		
		owner_machine.transition_to("increment emphasis", { "character" = self.character, "magnitude" = self.magnitude+1})
		return msg.right(-1)


# --------------------------------------------------------------------------------------------------
class StateOtherLetter extends MarkdownDecoderState:
	
	func on_message(msg : String) -> String:
		target_label.append_text(msg[0])
		owner_machine.transition_to("anything")
		return msg.right(-1)


# --------------------------------------------------------------------------------------------------
class StateEscaping extends MarkdownDecoderState:
	
	func on_message(msg : String) -> String:
		owner_machine.transition_to("other letter")
		return msg


# --------------------------------------------------------------------------------------------------
class StateEmphasis extends MarkdownDecoderState:
	
	func on_enter(args : Dictionary) -> void:
		if target_label._keywordstack_peek() == args["keyword"]:
			target_label._keywordstack_pop()
			owner_machine.transition_to("anything")
			return
		target_label._keywordstack_push(args["keyword"])
	


# --------------------------------------------------------------------------------------------------
class StateCodeSpan extends MarkdownDecoderState:
	
	func on_enter(_args : Dictionary) -> void:
		if target_label._keywordstack_peek() == "`":
			target_label._keywordstack_pop()
			owner_machine.transition_to("anything")
			return
		target_label._keywordstack_push("`")
	
	func on_message(msg : String) -> String:
		owner_machine.transition_to("format deactivated")
		return msg


# --------------------------------------------------------------------------------------------------
class StateFormatDeactivated extends MarkdownDecoderState:
	
	func on_message(msg : String) -> String:
		if msg[0] == "`":
			owner_machine.transition_to("anything")
			return msg.right(-1)
		target_label.append_text(msg[0])
		return msg.right(-1)


func _ready() -> void:
	_markdown_automaton = BareStateMachine.new()
	_markdown_automaton.set_state("anything", StateAnything.new(self))
	_markdown_automaton.set_state("other letter", StateOtherLetter.new(self))
	_markdown_automaton.set_state("escaping", StateEscaping.new(self))
	_markdown_automaton.set_state("increment emphasis", StateIncrementEmphasis.new(self))
	_markdown_automaton.set_state("emphasis", StateEmphasis.new(self))
	_markdown_automaton.set_state("code span", StateCodeSpan.new(self))
	_markdown_automaton.set_state("format deactivated", StateFormatDeactivated.new(self))


func _notification(what : int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_markdown_automaton.free()


## Replaces the buffer by the translation of the new text. Use this in the case of a deletion event 
## that will mess with the internal buffer's BBCode stack.
func md_set_whole_text(new_md_text : String) -> void:
	self.clear()
	self.md_append_text(new_md_text)


## Append some markdown text at the end of the internal buffer.
func md_append_text(more_md_text : String) -> void:
	_markdown_automaton.jumpstart("anything")
	
	while more_md_text.length() > 0:
		more_md_text = _markdown_automaton.send_message(more_md_text)
	
	while _keyword_stack.size() > 0:
		self._keywordstack_pop()


func _keywordstack_push(keyword : String) -> void:
	_keyword_stack.push_back(keyword)
	_keyword_translation[_md_keyword_str[keyword]].call(self as RichTextLabel)


func _keywordstack_peek() -> Variant:
	if _keyword_stack.size() == 0:
		return null
	return _keyword_stack.back()


func _keywordstack_pop() -> String:
	self.pop()
	return _keyword_stack.pop_back()
