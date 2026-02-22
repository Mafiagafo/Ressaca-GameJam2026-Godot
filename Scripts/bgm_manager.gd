extends AudioStreamPlayer

func _ready() -> void:
	volume_db = 0.0
	bus = "Master"
	var s = load("res://Assets/Music/Logo - Funky Chill 2 loop.wav")
	if s == null:
		push_error("BGMManager: failed to load music file!")
		return
	stream = s
	# Loop by reconnecting on finish instead of modifying the shared resource
	finished.connect(func(): if playing == false: play())

func play_menu_music() -> void:
	if stream and not playing:
		volume_db = 0.0
		play()

func play_game_music() -> void:
	if stream and not playing:
		volume_db = -5.0
		play()

func stop_music() -> void:
	stop()
