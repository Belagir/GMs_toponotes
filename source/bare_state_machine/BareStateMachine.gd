class_name BareStateMachine
extends Object

## This object is a finite state machine.
##
## The state machine can hold objects as states as long as those objects 
## implement the method [code]on_message(message : Variant)->Variant[/code].
## The object can also implement [code]on_enter(args : Dictionary)->void[/code] 
## and [code]on_leave()->void[/code], but those are not required.


var _states : Dictionary = { }
var _current_state : Object = null


## Sets a state as the object [code]new_state[/code] identified by 
## [code]identifier[/code]. This can override an existing state.
func set_state(identifier : String, new_state : Object) -> void:
	new_state.owner_machine = self
	_states[identifier] = new_state


## Jumpstarts the machine to a certain state. No on_enter or on_leave function
## is called.
func jumpstart(identifier : String) -> void:
	if _states.has(identifier):
		_current_state = _states[identifier]


## Sends an arbitrary message to the current state.
func send_message(msg : Variant) -> Variant:
	if not _current_state:
		return null
	return _current_state.on_message.call(msg)


## Transitions to another state. If the old state has an on_leave method, it gets
## called, same if the new state has an on_enter method.
func transition_to(identifier : String, args : Dictionary = {}) -> void:
	if not _states.has(identifier):
		return
	
	if _current_state:
		if (_current_state.has_method("on_leave")): _current_state.on_leave.call()
	_current_state = _states[identifier]
	if (_current_state.has_method("on_enter")): _current_state.on_enter.call(args)
