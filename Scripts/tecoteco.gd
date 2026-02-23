extends Node3D

@export var bob_speed: float = 2.0
@export var bob_amount: float = 0.2
@export var tilt_amount: float = 1.0

var time_passed := 0.0
var pitch_target := 0.0 # x rotation from altitude feedback
var drift_target := 0.0 # x position from fuel feedback

func _ready():
	GameState.metrics_changed.connect(_on_metrics_changed)

func _process(delta):
	time_passed += delta

	# Gentle bob
	position.y = sin(time_passed * bob_speed) * bob_amount

	# Subtle side tilt
	rotation.z = deg_to_rad(sin(time_passed * bob_speed) * tilt_amount)

func _on_metrics_changed():
	_update_altitude_feedback()
	_update_fuel_feedback()

func _update_altitude_feedback():
	var t = create_tween()
	if GameState.correct_altitude > 5.0:
		t.tween_property(self, "rotation_degrees:x", -8.0, 0.4)
	elif GameState.correct_altitude < 5.0:
		t.tween_property(self, "rotation_degrees:x", 8.0, 0.4)
	else:
		t.tween_property(self, "rotation_degrees:x", 0.0, 0.4)

func _update_fuel_feedback():
	var t = create_tween()
	if GameState.fuel_level < 4.0:
		t.tween_property(self, "position:x", 4.0, 0.4)
	elif GameState.fuel_level < 6.0:
		t.tween_property(self, "position:x", 2.0, 0.4)
	else:
		t.tween_property(self, "position:x", 0.0, 0.4)
