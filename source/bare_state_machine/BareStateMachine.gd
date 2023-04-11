class_name BareStateMachine
extends Object


var _states : Dictionary = { }
var _current_state : Object = null


func set_state(identifier : String, new_state : Object) -> void:
	new_state.owner_machine = self
	_states[identifier] = new_state


func jumpstart(identifier : String) -> void:
	if _states.has(identifier):
		_current_state = _states[identifier]


func send_message(msg : Variant) -> Variant:
	if not _current_state:
		return null
	return _current_state.on_message.call(msg)


func transition_to(identifier : String, args : Dictionary) -> void:
	if not _states.has(identifier):
		return
	
	if _current_state:
		if (_current_state.has_method("on_leave")): _current_state.on_leave.call()
	_current_state = _states[identifier]
	if (_current_state.has_method("on_enter")): _current_state.on_enter.call(args)
