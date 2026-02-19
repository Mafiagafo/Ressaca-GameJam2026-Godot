extends Control

@onready var start_button: Button = %StartButton

func _ready() -> void:
	# Connecting the signal via code for robustness
	start_button.pressed.connect(_on_start_game_pressed)

func _on_start_game_pressed() -> void:
	# Fancy transition could be added here later
	get_tree().change_scene_to_file("res://Scenes/GameLoop.tscn")
