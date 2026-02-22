extends Node

@export var camera_rig: Node3D
@export var side_point: Node3D
@export var airplane: Node3D

@export var intro_duration := 5.0
@export var orbit_distance := 12.0
@export var orbit_height := 4.0
@export var orbit_speed := 1.5

var angle := 0.0
var intro_running := true

func _ready():
	await run_intro()
	transition_to_gameplay()

func _process(delta):
	if intro_running:
		angle += orbit_speed * delta
		
		var offset = Vector3(
			cos(angle) * orbit_distance,
			orbit_height,
			sin(angle) * orbit_distance
		)
		
		camera_rig.global_position = airplane.global_position + offset
		camera_rig.look_at(airplane.global_position)

func run_intro() -> void:
	intro_running = true
	await get_tree().create_timer(intro_duration).timeout
	intro_running = false
	
func transition_to_gameplay():
	var tween = create_tween()
	
	tween.tween_property(
		camera_rig,
		"global_transform",
		side_point.global_transform,
		2.0
	)
