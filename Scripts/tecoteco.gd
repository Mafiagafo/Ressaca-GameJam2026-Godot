extends Node3D

@export var bob_speed: float = 2.0
@export var bob_amount: float = 0.2
@export var tilt_amount: float = 1.0

var time_passed := 0.0

func _process(delta):
	time_passed += delta
	
	# Movimento vertical suave (como turbulência leve)
	position.y = sin(time_passed * bob_speed) * bob_amount
	
	# Inclinação lateral simulando navegação
	rotation.z = deg_to_rad(sin(time_passed * bob_speed) * tilt_amount)
