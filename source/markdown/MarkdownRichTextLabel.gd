class_name MarkdownRichTextLabel
extends RichTextLabel


enum MD_KEYWORD { NONE, ITALICS, EMPHASIS, CODE_SPAN }

const _md_keyword_to_bbcall = { \
		MD_KEYWORD.ITALICS   : "push_italics", \
		MD_KEYWORD.EMPHASIS  : "push_bold", \
		MD_KEYWORD.CODE_SPAN : "push_mono", \
}

var _markdown_automaton : BareStateMachine


class MarkdownDecoderState_Empty:
	var owner_machine : BareStateMachine
	
	func on_message(msg : String) -> Variant:
		var letter : String = msg[0]
		
		if (letter  == "*") or (letter == "_"):
			owner_machine.transition_to("italics", { "character" = letter })
			return { "key" = null, "consume" = 1 }
		elif (letter == "`"):
			return { "key" = MD_KEYWORD.CODE_SPAN, "consume" = 1 }
		return { "key" = MD_KEYWORD.NONE, "consume" = 1 }


class MarkdownDecoderState_Italics:
	var owner_machine : BareStateMachine
	var character : String
	
	func on_enter(args : Dictionary) -> void:
		self.character = args["character"]
	
	func on_message(msg : String) -> Variant:
		if (msg.length() == 0) or (msg[0] != self.character):
			return { "key" = MD_KEYWORD.ITALICS, "consume" = 0 }
		return { "key" = MD_KEYWORD.EMPHASIS, "consume" = 1 }


func _ready() -> void:
	_markdown_automaton = BareStateMachine.new()
	_markdown_automaton.set_state("empty", MarkdownDecoderState_Empty.new())
	_markdown_automaton.set_state("italics", MarkdownDecoderState_Italics.new())


# replace the buffer by the translation of the new text. Use this in the case of a deletion event 
# that will mess with the internal buffer's BBCode stack
func md_set_whole_text(new_md_text : String) -> void:
	self.clear()
	self.md_append_text(new_md_text)


# append some markdown text at the end of the internal buffer.
func md_append_text(more_md_text : String) -> void:
	var keyword_automaton_result : Variant = null 
	
	while more_md_text.length() > 0:
		# automaton loop initialisation
		keyword_automaton_result = { "key" = null, "consume" = 0}
		_markdown_automaton.jumpstart("empty")
		# fetch the next markdown keyword, if it exists
		while (keyword_automaton_result["key"] == null):
			# if the "key" is null it means that the keyword is still undetermined
			keyword_automaton_result = _markdown_automaton.send_message(more_md_text)
			# if the machine signals that nothing has to be consumed, we cut the loop
			if keyword_automaton_result["consume"] == 0:
				continue
			# not a keyword, add the text as is
			if keyword_automaton_result["key"] == MD_KEYWORD.NONE:
				self.append_text(more_md_text.left(keyword_automaton_result["consume"]))
			# a keyword, execute the related funciton
			elif keyword_automaton_result["key"] != null:
				self.call(_md_keyword_to_bbcall[keyword_automaton_result["key"]])
			# consume the string
			more_md_text = more_md_text.right(-keyword_automaton_result["consume"])


