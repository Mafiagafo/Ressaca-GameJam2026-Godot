class_name ActionButton
extends RefCounted

var id: String
var display_name: String
var effects: Dictionary

func _init(_id: String, _name: String, _effects: Dictionary) -> void:
	id = _id
	display_name = _name
	effects = _effects
