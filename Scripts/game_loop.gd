extends Control

@onready var alt_bar: ProgressBar = %AltitudeBar
@onready var fuel_bar: ProgressBar = %FuelBar
@onready var time_bar: ProgressBar = %TimeBar
@onready var hp_bar: ProgressBar = %HPBar
@onready var comfort_bar: ProgressBar = %ComfortBar
@onready var trust_bar: ProgressBar = %TrustBar
@onready var actions_panel = $ActionsPanel

var round_context: RoundContext
var master_actions: Array[ActionButton] = []

var center_msg_box: VBoxContainer
var msg_label: Label
var next_btn: Button
var preview_label: Label

func _ready() -> void:
	GameState.metrics_changed.connect(_update_ui)
	_setup_dynamic_ui()
	_init_master_actions()
	round_context = RoundContext.new()
	_update_ui()
	_process_phase()

func _setup_dynamic_ui():
	preview_label = Label.new()
	preview_label.text = "Hover an action for preview..."
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(preview_label)
	preview_label.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	preview_label.offset_bottom = -210
	
	center_msg_box = VBoxContainer.new()
	add_child(center_msg_box)
	center_msg_box.set_anchors_preset(PRESET_CENTER)
	
	msg_label = Label.new()
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_msg_box.add_child(msg_label)
	
	next_btn = Button.new()
	next_btn.text = "Continue"
	next_btn.pressed.connect(_on_next_pressed)
	center_msg_box.add_child(next_btn)

func _init_master_actions():
	master_actions = [
		ActionButton.new("climb_high", "Climb High", {"correct_altitude": 2.0, "fuel_level": - 1.5, "structural_hp": - 1.0}),
		ActionButton.new("smooth_ascent", "Smooth Ascent", {"correct_altitude": 1.0, "fuel_level": - 0.5, "structural_hp": - 0.2, "company_trust": 1.0}),
		ActionButton.new("max_economy", "Max Economy", {"fuel_level": 1.0, "punctual_arrival": - 1.0, "passenger_comfort": - 0.5}),
		ActionButton.new("pull_power", "Pull Power", {"correct_altitude": 0.5, "fuel_level": - 2.0, "punctual_arrival": 1.0, "structural_hp": - 1.0}),
		ActionButton.new("accelerate", "Accelerate", {"fuel_level": - 1.5, "punctual_arrival": 2.0, "passenger_comfort": - 1.0, "company_trust": 1.0}),
		ActionButton.new("reduce", "Reduce Speed", {"fuel_level": - 0.5, "punctual_arrival": - 2.0, "passenger_comfort": 1.0, "company_trust": - 1.5}),
		ActionButton.new("aggressive", "Aggressive Manu.", {"structural_hp": - 2.5, "passenger_comfort": - 2.0}),
		ActionButton.new("stabilize", "Stabilize Struct.", {"punctual_arrival": - 0.5, "structural_hp": 2.0, "company_trust": - 0.5}),
		ActionButton.new("smooth_flight", "Smooth Flight", {"punctual_arrival": - 1.0, "passenger_comfort": 2.0, "company_trust": - 0.5}),
		ActionButton.new("calming_ad", "Calming Ad", {"passenger_comfort": 1.0}),
		ActionButton.new("keep_schedule", "Keep Schedule", {"fuel_level": - 1.0, "punctual_arrival": 1.5, "structural_hp": - 1.0, "company_trust": 2.0}),
		ActionButton.new("report_delay", "Report Delay", {"punctual_arrival": - 0.5, "passenger_comfort": - 0.5, "company_trust": 3.0})
	]
	
	var btn_nodes = [
		%ClimbHigh, %SmoothAscent, %MaxEconomy, %PullPower,
		%Accelerate, %Reduce, %Aggressive, %Stabilize,
		%SmoothFlight, %CalmingAd, %KeepSchedule, %ReportDelay
	]
	
	for i in range(master_actions.size()):
		var action = master_actions[i]
		var btn = btn_nodes[i]
		btn.pressed.connect(func(): _on_action_pressed(action))
		btn.mouse_entered.connect(func(): _on_action_hovered(action))
		btn.mouse_exited.connect(func(): _on_action_unhovered())

func _update_ui() -> void:
	var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(alt_bar, "value", GameState.correct_altitude, 0.5)
	t.tween_property(fuel_bar, "value", GameState.fuel_level, 0.5)
	t.tween_property(time_bar, "value", GameState.punctual_arrival, 0.5)
	t.tween_property(hp_bar, "value", GameState.structural_hp, 0.5)
	t.tween_property(comfort_bar, "value", GameState.passenger_comfort, 0.5)
	t.tween_property(trust_bar, "value", GameState.company_trust, 0.5)

func _process_phase() -> void:
	actions_panel.hide()
	center_msg_box.hide()
	preview_label.hide()
	
	match round_context.current_phase:
		RoundContext.Phase.START:
			execute_phase_round_start()
		RoundContext.Phase.BRIEFING:
			execute_phase_briefing()
		RoundContext.Phase.CHAOS:
			execute_phase_chaos()
		RoundContext.Phase.SHUFFLE:
			execute_phase_shuffle()
		RoundContext.Phase.PREVIEW:
			execute_phase_preview()
		RoundContext.Phase.RESULTS:
			pass

func change_phase(new_phase: RoundContext.Phase) -> void:
	round_context.current_phase = new_phase
	_process_phase()

func _on_next_pressed():
	if round_context.current_phase == RoundContext.Phase.BRIEFING:
		change_phase(RoundContext.Phase.CHAOS)
	elif round_context.current_phase == RoundContext.Phase.CHAOS:
		change_phase(RoundContext.Phase.SHUFFLE)
	elif round_context.current_phase == RoundContext.Phase.RESULTS:
		if GameState.is_game_over():
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
		else:
			change_phase(RoundContext.Phase.START)

func execute_phase_round_start():
	round_context.round_number += 1
	var kept_debuffs: Array[Debuff] = []
	for d in round_context.active_debuffs:
		d.duration -= 1
		if d.duration > 0:
			kept_debuffs.append(d)
	round_context.active_debuffs = kept_debuffs
	change_phase(RoundContext.Phase.BRIEFING)

func execute_phase_briefing():
	_pop_in(center_msg_box)
	var msg = "Round %d Briefing\n\n" % round_context.round_number
	if GameState.fuel_level <= 3.0:
		msg += "WARNING: Critical Fuel Levels!\n"
	if GameState.correct_altitude <= 3.0:
		msg += "WARNING: Low Altitude!\n"
	if GameState.structural_hp <= 3.0:
		msg += "WARNING: Structural Integrity Failing!\n"
	
	if msg == "Round %d Briefing\n\n" % round_context.round_number:
		msg += "All systems nominal. Maintain current heading."
		
	msg_label.text = msg

func execute_phase_chaos():
	_pop_in(center_msg_box)
	var chaos_roll = randi() % 4
	var msg = "Chaos Event:\n\n"
	if chaos_roll == 0:
		msg += "Turbulence! Altitude -1."
		GameState.correct_altitude -= 1.0
	elif chaos_roll == 1:
		msg += "Headwind! Fuel -1."
		GameState.fuel_level -= 1.0
	elif chaos_roll == 2:
		msg += "Angry Passengers! Comfort -1."
		GameState.passenger_comfort -= 1.0
	else:
		msg += "Clear Skies. No negative effects."
	
	msg_label.text = msg
	
	if chaos_roll != 3:
		_shake_screen()

func execute_phase_shuffle():
	# 1. Hide all buttons first
	for node in actions_panel.get_node("GridContainer").get_children():
		node.hide()
	
	# 2. Build a pool of valid actions that were not chosen in the last 3 rounds
	var valid_pool: Array[ActionButton] = []
	for action in master_actions:
		if not round_context.past_choices.has(action.id):
			valid_pool.append(action)
			
	# Validation: If we have fewer than 3 valid actions (shouldn't happen with 12 total), refill
	if valid_pool.size() < 3:
		valid_pool = master_actions.duplicate()
	
	# 3. Shuffle and pick exactly 3
	valid_pool.shuffle()
	round_context.available_actions = valid_pool.slice(0, 3)
	
	# 4. Show the UI buttons for those 3 picked actions
	var grid = actions_panel.get_node("GridContainer")
	for action in round_context.available_actions:
		for node in grid.get_children():
			if node is Button and node.text == action.display_name:
				node.show()
				break
				
	change_phase(RoundContext.Phase.PREVIEW)

func execute_phase_preview():
	_slide_up(actions_panel)
	preview_label.show()
	preview_label.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(preview_label, "modulate:a", 1.0, 0.5)
	preview_label.text = "Wait for choice..."

func _on_action_hovered(action: ActionButton):
	if round_context.current_phase != RoundContext.Phase.PREVIEW: return
	var p_text = "Preview [%s]: " % action.display_name
	for key in action.effects:
		p_text += "%s %s%s  " % [key, "+" if action.effects[key] > 0 else "", str(action.effects[key])]
	preview_label.text = p_text

func _on_action_unhovered():
	if round_context.current_phase != RoundContext.Phase.PREVIEW: return
	preview_label.text = "Wait for choice..."

func _on_action_pressed(action: ActionButton):
	if round_context.current_phase == RoundContext.Phase.PREVIEW:
		change_phase(RoundContext.Phase.RESULTS)
		execute_phase_results(action)

func execute_phase_results(action: ActionButton):
	actions_panel.hide()
	preview_label.hide()
	_pop_in(center_msg_box)
	
	if action.effects.has("correct_altitude"): GameState.correct_altitude += action.effects["correct_altitude"]
	if action.effects.has("fuel_level"): GameState.fuel_level += action.effects["fuel_level"]
	if action.effects.has("punctual_arrival"): GameState.punctual_arrival += action.effects["punctual_arrival"]
	if action.effects.has("structural_hp"): GameState.structural_hp += action.effects["structural_hp"]
	if action.effects.has("passenger_comfort"): GameState.passenger_comfort += action.effects["passenger_comfort"]
	if action.effects.has("company_trust"): GameState.company_trust += action.effects["company_trust"]
	
	var msg = "Action applied: " + action.display_name + "\n\n"
	if GameState.is_game_over():
		msg += "GAME OVER. Critical Failure."
		next_btn.text = "Return to Menu"
	else:
		msg += "You survived this round."
		next_btn.text = "Next Round"
		
	msg_label.text = msg
	
	# Record the action id, limit to last 3
	round_context.past_choices.push_front(action.id)
	if round_context.past_choices.size() > 3:
		round_context.past_choices.pop_back()

func _pop_in(node: Control):
	node.show()
	node.scale = Vector2.ZERO
	# Pivot from center approx
	node.pivot_offset = node.size / 2.0
	var t = create_tween()
	t.tween_property(node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _slide_up(node: Control):
	node.show()
	node.modulate.a = 0.0
	node.position.y += 50
	var t = create_tween().set_parallel(true)
	t.tween_property(node, "modulate:a", 1.0, 0.4)
	t.tween_property(node, "position:y", node.position.y - 50, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _shake_screen():
	var start_pos = position
	var t = create_tween()
	for i in range(6):
		t.tween_property(self, "position", start_pos + Vector2(randf_range(-15, 15), randf_range(-15, 15)), 0.05)
	t.tween_property(self, "position", start_pos, 0.05)
