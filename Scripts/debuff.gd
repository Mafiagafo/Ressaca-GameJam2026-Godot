class_name Debuff
extends RefCounted

var id: String
var duration: int
var effect_type: String
var magnitude: float

func _init(_id: String, _duration: int, _effect_type: String, _magnitude: float) -> void:
	id = _id
	duration = _duration
	effect_type = _effect_type
	magnitude = _magnitude
