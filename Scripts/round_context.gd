class_name RoundContext
extends RefCounted

enum Phase {START, BRIEFING, CHAOS, SHUFFLE, PREVIEW, RESULTS}

var round_number: int = 1
var current_phase: Phase = Phase.START
var active_debuffs: Array[Debuff] = []
var available_actions: Array[ActionButton] = []

func _init() -> void:
	pass
