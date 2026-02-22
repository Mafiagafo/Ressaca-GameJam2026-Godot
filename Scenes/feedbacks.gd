extends Node3D

func _ready():
	GameState.metrics_changed.connect(_on_metrics_changed)

func _on_metrics_changed():
	_update_altitude()
	_update_fuel()

func _update_altitude():
	var t = create_tween()	
	if GameState.correct_altitude > 5.0:
		t.tween_property($tecoteco, "rotation_degrees:x", -8, 0.4)
	elif GameState.correct_altitude < 5.0:
		t.tween_property($tecoteco, "rotation_degrees:x", 8, 0.4)
	else:
		t.tween_property($tecoteco, "rotation_degrees:x", 0, 0.4)
	
func _update_fuel():
	var t = create_tween()	
	if GameState.fuel_level < 6.0:
		t.tween_property($tecoteco, "position:x", 2, 0.4)
	elif GameState.fuel_level < 4.0:
		t.tween_property($tecoteco, "position:x", 4, 0.4)
	else:
		t.tween_property($tecoteco, "position:x", 0, 0.4)
