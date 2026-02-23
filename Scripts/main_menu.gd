extends Control

@onready var start_button: Button = %StartButton

var sfx_hover: AudioStreamPlayer
var sfx_confirm: AudioStreamPlayer

func _ready() -> void:
	BGMManager.play_menu_music()

	sfx_hover = AudioStreamPlayer.new()
	sfx_hover.stream = load("res://Assets/Sound/Hover.wav")
	add_child(sfx_hover)

	sfx_confirm = AudioStreamPlayer.new()
	sfx_confirm.stream = load("res://Assets/Sound/Switch.wav")
	add_child(sfx_confirm)

	start_button.mouse_entered.connect(func(): sfx_hover.play())
	start_button.pressed.connect(_on_start_game_pressed)

func _on_start_game_pressed() -> void:
	sfx_confirm.play()
	BGMManager.stop_music()
	# Wait one frame so the sound fires before the scene changes
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://Scenes/GameLoop.tscn")
