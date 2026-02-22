extends Control

var round_context: RoundContext
var ui_manager: UIManager
var action_manager: ActionManager

func _ready() -> void:
	GameState.reset_metrics()
	action_manager = ActionManager.new()
	ui_manager = UIManager.new(
		self,
		_on_next_pressed,
		_on_action_pressed,
		_on_action_hovered,
		_on_action_unhovered,
		action_manager.get_all_actions()
	)
	
	round_context = RoundContext.new()
	ui_manager.update_meters_ui()
	_process_phase()

func _process_phase() -> void:
	ui_manager.hide_all_panels()
	
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

func execute_phase_round_start():
	round_context.round_number += 1
	
	if GameState.is_victory(round_context.round_number):
		change_phase(RoundContext.Phase.RESULTS)
		ui_manager.show_victory_screen()
		return
		
	GameState.is_foggy = false
	GameState.is_radio_silent = false
	GameState.has_instrument_failure = false
	GameState.has_locked_controls = false
	GameState.has_panic = false
	var kept_debuffs: Array[Debuff] = []
	for d in round_context.active_debuffs:
		d.duration -= 1
		if d.duration > 0:
			kept_debuffs.append(d)
	round_context.active_debuffs = kept_debuffs
	change_phase(RoundContext.Phase.BRIEFING)

func execute_phase_briefing():
	var msg = "Last Round Briefing!\n\n" if round_context.round_number == 6 else "Round %d Briefing\n\n" % round_context.round_number
	
	var is_nominal = true
	if GameState.fuel_level <= 3.0:
		msg += "WARNING: Critical Fuel Levels!\n"
		is_nominal = false
	if GameState.correct_altitude <= 3.0:
		msg += "WARNING: Low Altitude!\n"
		is_nominal = false
	if GameState.structural_hp <= 3.0:
		msg += "WARNING: Structural Integrity Failing!\n"
		is_nominal = false
	
	if is_nominal:
		msg += "All systems nominal. Maintain current heading."
		
	ui_manager.show_briefing(round_context.round_number, msg)

func execute_phase_chaos():
	# Build a pool of all event IDs (0-8), shuffle, pick first not previously used
	var all_events: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	var pool: Array[int] = []
	for e in all_events:
		if not round_context.past_chaos_events.has(e):
			pool.append(e)
	
	# If all events used (more rounds than events), reset pool
	if pool.is_empty():
		pool = all_events.duplicate()
		round_context.past_chaos_events.clear()
	
	pool.shuffle()
	var chaos_roll = pool[0]
	round_context.past_chaos_events.append(chaos_roll)
	
	var msg = "Chaos Event:\n\n"
	if chaos_roll == 0:
		msg += "Turbulence! Altitude -3."
		GameState.correct_altitude -= 3.0
	elif chaos_roll == 1:
		msg += "Headwind! Fuel -3."
		GameState.fuel_level -= 3.0
	elif chaos_roll == 2:
		msg += "Angry Passengers! Comfort -3."
		GameState.passenger_comfort -= 3.0
	elif chaos_roll == 3:
		msg += "Foggy Skies! Action previews hidden."
		GameState.is_foggy = true
	elif chaos_roll == 4:
		msg += "Radio Silence! Communication actions disabled."
		GameState.is_radio_silent = true
	elif chaos_roll == 5:
		msg += "Instrument Failure! Meters show false data."
		GameState.has_instrument_failure = true
	elif chaos_roll == 6:
		msg += "Locked Controls! Need to force a decision."
		GameState.has_locked_controls = true
	elif chaos_roll == 7:
		msg += "Panic in the Cabin! Comfort and Trust penalties doubled."
		GameState.has_panic = true
	else:
		msg += "Clear Skies. No negative effects."
	
	ui_manager.update_meters_ui()
	ui_manager.show_chaos(msg, chaos_roll != 8)

func execute_phase_shuffle():
	round_context.available_actions = action_manager.get_shuffled_actions(round_context.past_choices, 3)
	change_phase(RoundContext.Phase.PREVIEW)

func execute_phase_preview():
	ui_manager.show_action_selection(round_context.available_actions)

func execute_phase_results(action: ActionButton):
	for key in action.effects:
		var val = action.effects[key]
		if GameState.has_panic and (key == "passenger_comfort" or key == "company_trust") and val < 0:
			val *= 2.0
		if key == "correct_altitude": GameState.correct_altitude += val
		elif key == "fuel_level": GameState.fuel_level += val
		elif key == "punctual_arrival": GameState.punctual_arrival += val
		elif key == "structural_hp": GameState.structural_hp += val
		elif key == "passenger_comfort": GameState.passenger_comfort += val
		elif key == "company_trust": GameState.company_trust += val
	
	round_context.past_choices.push_front(action.id)
	if round_context.past_choices.size() > 3:
		round_context.past_choices.pop_back()
		
	ui_manager.show_results(action, GameState.is_game_over())

# --- Input Callbacks ---

func _on_next_pressed():
	if round_context.current_phase == RoundContext.Phase.BRIEFING:
		change_phase(RoundContext.Phase.CHAOS)
	elif round_context.current_phase == RoundContext.Phase.CHAOS:
		change_phase(RoundContext.Phase.SHUFFLE)
	elif round_context.current_phase == RoundContext.Phase.RESULTS:
		if GameState.is_game_over() or GameState.is_victory(round_context.round_number):
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
		else:
			change_phase(RoundContext.Phase.START)

func _on_action_pressed(action: ActionButton):
	if round_context.current_phase == RoundContext.Phase.PREVIEW:
		change_phase(RoundContext.Phase.RESULTS)
		execute_phase_results(action)

func _on_action_hovered(action: ActionButton):
	if round_context.current_phase == RoundContext.Phase.PREVIEW:
		ui_manager.update_preview_label(action)

func _on_action_unhovered():
	if round_context.current_phase == RoundContext.Phase.PREVIEW:
		ui_manager.update_preview_label(null)
