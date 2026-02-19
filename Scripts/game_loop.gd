extends Control

@onready var alt_bar: ProgressBar = %AltitudeBar
@onready var fuel_bar: ProgressBar = %FuelBar
@onready var time_bar: ProgressBar = %TimeBar
@onready var hp_bar: ProgressBar = %HPBar
@onready var comfort_bar: ProgressBar = %ComfortBar
@onready var trust_bar: ProgressBar = %TrustBar

func _ready() -> void:
	GameState.metrics_changed.connect(_update_ui)
	_update_ui()
	_connect_buttons()

func _update_ui() -> void:
	alt_bar.value = GameState.correct_altitude
	fuel_bar.value = GameState.fuel_level
	time_bar.value = GameState.punctual_arrival
	hp_bar.value = GameState.structural_hp
	comfort_bar.value = GameState.passenger_comfort
	trust_bar.value = GameState.company_trust
	
	_check_game_over()

func _check_game_over() -> void:
	if GameState.is_game_over():
		# For now, just reload or go to menu. Ideally show "Game Over" screen.
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _connect_buttons() -> void:
	# Altitude
	%ClimbHigh.pressed.connect(func(): _apply_choice(2.0, -1.5, 0, -1.0, 0, 0))
	%SmoothAscent.pressed.connect(func(): _apply_choice(1.0, -0.5, 0, -0.2, 0, 1.0))
	
	# Fuel
	%MaxEconomy.pressed.connect(func(): _apply_choice(0, 1.0, -1.0, 0, -0.5, 0))
	%PullPower.pressed.connect(func(): _apply_choice(0.5, -2.0, 1.0, -1.0, 0, 0))
	
	# Punctuality (Speed)
	%Accelerate.pressed.connect(func(): _apply_choice(0, -1.5, 2.0, 0, -1.0, 1.0))
	%Reduce.pressed.connect(func(): _apply_choice(0, -0.5, -2.0, 0, 1.0, -1.5))
	
	# Structural HP
	%Aggressive.pressed.connect(func(): _apply_choice(0, 0, 0, -2.5, -2.0, 0))
	%Stabilize.pressed.connect(func(): _apply_choice(0, 0, -0.5, 2.0, 0, -0.5))
	
	# Comfort
	%SmoothFlight.pressed.connect(func(): _apply_choice(0, 0, -1.0, 0, 2.0, -0.5))
	%CalmingAd.pressed.connect(func(): _apply_choice(0, 0, 0, 0, 1.0, 0))
	
	# Trust (Pressure)
	%KeepSchedule.pressed.connect(func(): _apply_choice(0, -1.0, 1.5, -1.0, 0, 2.0))
	%ReportDelay.pressed.connect(func(): _apply_choice(0, 0, -0.5, 0, -0.5, 3.0))

func _apply_choice(alt, fuel, punc, hp, comf, trust) -> void:
	GameState.correct_altitude += alt
	GameState.fuel_level += fuel
	GameState.punctual_arrival += punc
	GameState.structural_hp += hp
	GameState.passenger_comfort += comf
	GameState.company_trust += trust
