extends Node

signal metrics_changed

# Global game metrics (Range: 0 - 10)
# All metrics follow rule: 10 = Good, 0 = Bad
var correct_altitude: float = 10.0:
	set(value):
		correct_altitude = clamp(value, 0.0, 10.0)
		metrics_changed.emit()

var fuel_level: float = 10.0:
	set(value):
		fuel_level = clamp(value, 0.0, 10.0)
		metrics_changed.emit()

var punctual_arrival: float = 10.0:
	set(value):
		punctual_arrival = clamp(value, 0.0, 10.0)
		metrics_changed.emit()

var structural_hp: float = 10.0:
	set(value):
		structural_hp = clamp(value, 0.0, 10.0)
		metrics_changed.emit()

var passenger_comfort: float = 10.0:
	set(value):
		passenger_comfort = clamp(value, 0.0, 10.0)
		metrics_changed.emit()

var company_trust: float = 10.0:
	set(value):
		company_trust = clamp(value, 0.0, 10.0)
		metrics_changed.emit()

var is_foggy: bool = false
var is_radio_silent: bool = false
var has_instrument_failure: bool = false
var has_locked_controls: bool = false
var has_panic: bool = false

func reset_metrics() -> void:
	correct_altitude = 10.0
	fuel_level = 10.0
	punctual_arrival = 10.0
	structural_hp = 10.0
	passenger_comfort = 10.0
	company_trust = 10.0
	is_foggy = false
	is_radio_silent = false
	has_instrument_failure = false
	has_locked_controls = false
	has_panic = false

func is_game_over() -> bool:
	# Game over if any critical metric hits 0
	return correct_altitude <= 0 or fuel_level <= 0 or structural_hp <= 0 or company_trust <= 0

func is_victory() -> bool:
	# Victory connection logic will be handled by the GameLoop script based on progression
	# For now, we return false as placeholder or check if survival criteria met
	return false
