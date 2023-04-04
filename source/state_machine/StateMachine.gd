class_name StateMachine
extends Node

@export var initial_state : NodePath = NodePath()
@onready var state : State = get_node(initial_state) : get = _get_state


func _ready() -> void:
	self.state.on_enter({})


func _unhandled_input(event : InputEvent) -> void:
	self.state.on_input(event)


func get_state_name() -> StringName:
	if self.state:
		return self.state.name
	else:
		return ""


func _get_state() -> State:
	return state


func transition_to(next_state_path : String, args : Dictionary = {}) -> void:
	var target_state : State = null
	
	if not has_node(next_state_path):
		return
	
	target_state = get_node(next_state_path) as State
	
	self.state.on_leave()
	self.state = target_state
	self.state.on_enter(args)

