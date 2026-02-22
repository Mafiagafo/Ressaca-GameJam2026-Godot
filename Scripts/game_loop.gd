extends Control

var round_context: RoundContext
var ui_manager: UIManager
var action_manager: ActionManager

func _ready() -> void:
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
	var kept_debuffs: Array[Debuff] = []
	for d in round_context.active_debuffs:
		d.duration -= 1
		if d.duration > 0:
			kept_debuffs.append(d)
	round_context.active_debuffs = kept_debuffs
	change_phase(RoundContext.Phase.BRIEFING)

func execute_phase_briefing():
	var msg = "Round %d Briefing\n\n" % round_context.round_number
	if GameState.fuel_level <= 3.0:
		msg += "WARNING: Critical Fuel Levels!\n"
	if GameState.correct_altitude <= 3.0:
		msg += "WARNING: Low Altitude!\n"
	if GameState.structural_hp <= 3.0:
		msg += "WARNING: Structural Integrity Failing!\n"
	
	if msg == "Round %d Briefing\n\n" % round_context.round_number:
		msg += "All systems nominal. Maintain current heading."
		
	ui_manager.show_briefing(round_context.round_number, msg)

func execute_phase_chaos():
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
	
	ui_manager.show_chaos(msg, chaos_roll != 3)

func execute_phase_shuffle():
	round_context.available_actions = action_manager.get_shuffled_actions(round_context.past_choices, 3)
	change_phase(RoundContext.Phase.PREVIEW)

func execute_phase_preview():
	ui_manager.show_action_selection(round_context.available_actions)

func execute_phase_results(action: ActionButton):
	if action.effects.has("correct_altitude"): GameState.correct_altitude += action.effects["correct_altitude"]
	if action.effects.has("fuel_level"): GameState.fuel_level += action.effects["fuel_level"]
	if action.effects.has("punctual_arrival"): GameState.punctual_arrival += action.effects["punctual_arrival"]
	if action.effects.has("structural_hp"): GameState.structural_hp += action.effects["structural_hp"]
	if action.effects.has("passenger_comfort"): GameState.passenger_comfort += action.effects["passenger_comfort"]
	if action.effects.has("company_trust"): GameState.company_trust += action.effects["company_trust"]
	
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
		if GameState.is_game_over():
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
