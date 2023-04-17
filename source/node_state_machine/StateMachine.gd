class_name StateMachine
extends Node

## This finite state machine uses the node architecture of Godot's engine.
##
## This node store its states as child nodes so they can intercept user inputs.

## The first state the machine starts with.
@export var initial_state : NodePath = NodePath()
## Current state of the machine.
@onready var state : State = get_node(initial_state) : get = _get_state


func _ready() -> void:
	self.state.on_enter({})


func _unhandled_input(event : InputEvent) -> void:
	self.state.on_input(event)


## Returns the current state name.
func get_state_name() -> StringName:
	if self.state:
		return self.state.name
	else:
		return ""


func _get_state() -> State:
	return state


## Transition to the requested state and execute the on_enter and on_leave code. 
func transition_to(next_state_path : String, args : Dictionary = {}) -> void:
	var target_state : State = null
	
	if not has_node(next_state_path):
		return
	
	target_state = get_node(next_state_path) as State
	
	self.state.on_leave()
	self.state = target_state
	self.state.on_enter(args)

