class_name ActionManager
extends RefCounted

var master_actions: Array[ActionButton] = []

func _init() -> void:
	master_actions = [
		ActionButton.new("climb_high", "Climb High", {"correct_altitude": 2.0, "fuel_level": - 2.0, "structural_hp": - 2.0}),
		ActionButton.new("smooth_ascent", "Smooth Ascent", {"correct_altitude": 1.0, "company_trust": 0.5, "fuel_level": - 2.0, "structural_hp": - 1.0}),
		ActionButton.new("max_economy", "Max Economy", {"fuel_level": 1.5, "punctual_arrival": - 2.0, "passenger_comfort": - 1.0}),
		ActionButton.new("pull_power", "Pull Power", {"correct_altitude": 0.5, "punctual_arrival": 1.0, "fuel_level": - 2.0, "structural_hp": - 1.0}),
		ActionButton.new("accelerate", "Accelerate", {"punctual_arrival": 2.0, "company_trust": 0.5, "fuel_level": - 3.0, "passenger_comfort": - 2.0}),
		ActionButton.new("reduce", "Reduce Speed", {"fuel_level": 0.5, "passenger_comfort": 2.0, "correct_altitude": - 1.0, "punctual_arrival": - 2.0, "company_trust": - 1.0}),
		ActionButton.new("aggressive", "Aggressive Manu.", {"correct_altitude": 1.5, "punctual_arrival": 1.5, "structural_hp": - 3.0, "passenger_comfort": - 3.0}),
		ActionButton.new("stabilize", "Stabilize Struct.", {"structural_hp": 3.0, "correct_altitude": - 1.0, "punctual_arrival": - 2.0, "company_trust": - 2.0}),
		ActionButton.new("smooth_flight", "Smooth Flight", {"passenger_comfort": 2.0, "punctual_arrival": - 2.0, "company_trust": - 2.0}),
		ActionButton.new("calming_ad", "Calming Ad", {"passenger_comfort": 1.0, "company_trust": - 2.0}),
		ActionButton.new("keep_schedule", "Keep Schedule", {"punctual_arrival": 1.5, "company_trust": 0.5, "fuel_level": - 2.0, "structural_hp": - 2.0}),
		ActionButton.new("report_delay", "Report Delay", {"company_trust": 2.0, "punctual_arrival": - 2.0, "passenger_comfort": - 2.0})
	]

func get_shuffled_actions(past_choices: Array[String], count: int = 3) -> Array[ActionButton]:
	var valid_pool: Array[ActionButton] = []
	for action in master_actions:
		if not past_choices.has(action.id):
			valid_pool.append(action)
			
	if valid_pool.size() < count:
		valid_pool = master_actions.duplicate()
	
	valid_pool.shuffle()
	return valid_pool.slice(0, count)

func get_all_actions() -> Array[ActionButton]:
	return master_actions
