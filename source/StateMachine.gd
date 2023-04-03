class_name StateMachine
extends Node

@export var initial_state : NodePath = NodePath()
@onready var _state : State = get_node(initial_state) : get = _get_state


func _ready() -> void:
	_state.on_enter({})


func _unhandled_input(event : InputEvent) -> void:
	_state.on_input(event)


func _get_state() -> State:
	return _state


func transition_to(next_state_path : String, args : Dictionary = {}) -> void:
	var target_state : State = null
	
	if not has_node(next_state_path):
		return
	
	print("transition to ", next_state_path)
	target_state = get_node(next_state_path) as State
	
	_state.on_leave()
	_state = target_state
	_state.on_enter(args)

