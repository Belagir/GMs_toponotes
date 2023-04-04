class_name State
extends Node


var _owner_state_machine : StateMachine = null


func _ready() -> void:
	_owner_state_machine = _get_state_machine(self)


func on_enter(_args : Dictionary) -> void:
	pass


func on_input(_event : InputEvent) -> void:
	pass


func on_leave() -> void:
	pass


func _get_state_machine(node : Node) -> Node:
	if (node == null) or (node as StateMachine):
		return node
	else:
		return _get_state_machine(node.get_parent())

