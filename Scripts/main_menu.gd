extends Control

@onready var start_button: Button = %StartButton

func _ready() -> void:
	BGMManager.play_menu_music()
	start_button.pressed.connect(_on_start_game_pressed)

func _on_start_game_pressed() -> void:
	BGMManager.stop_music()
	get_tree().change_scene_to_file("res://Scenes/GameLoop.tscn")
