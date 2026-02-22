class_name RoundContext
extends RefCounted

enum Phase {START, BRIEFING, CHAOS, SHUFFLE, PREVIEW, RESULTS}

var round_number: int = 0
var current_phase: Phase = Phase.START
var active_debuffs: Array[Debuff] = []
var available_actions: Array[ActionButton] = []
var past_choices: Array[String] = []
var past_chaos_events: Array[int] = []

func _init() -> void:
	pass
