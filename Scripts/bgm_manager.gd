extends AudioStreamPlayer

func _ready() -> void:
	stream = load("res://Assets/Music/Logo - Funky Chill 2 loop.wav")
	bus = "Master"

func play_menu_music() -> void:
	if not playing:
		play()

func stop_music() -> void:
	stop()
