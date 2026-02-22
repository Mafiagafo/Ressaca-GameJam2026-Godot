class_name UIManager
extends RefCounted

var root: Control
var alt_bar: ProgressBar
var fuel_bar: ProgressBar
var time_bar: ProgressBar
var hp_bar: ProgressBar
var comfort_bar: ProgressBar
var trust_bar: ProgressBar
var actions_panel: PanelContainer

var center_msg_box: VBoxContainer
var msg_label: Label
var next_btn: Button
var preview_label: Label

var arrow_indicators: Dictionary = {}
var tex_arrow_up: Texture2D
var tex_arrow_down: Texture2D

func _init(p_root: Control, on_next_pressed: Callable, on_action_pressed: Callable, on_action_hovered: Callable, on_action_unhovered: Callable, all_actions: Array[ActionButton]) -> void:
	root = p_root
	
	alt_bar = root.get_node("%AltitudeBar")
	fuel_bar = root.get_node("%FuelBar")
	time_bar = root.get_node("%TimeBar")
	hp_bar = root.get_node("%HPBar")
	comfort_bar = root.get_node("%ComfortBar")
	trust_bar = root.get_node("%TrustBar")
	actions_panel = root.get_node("ActionsPanel")
	
	GameState.metrics_changed.connect(update_meters_ui)
	
	_load_arrow_textures()
	_setup_dynamic_ui(on_next_pressed)
	_setup_arrow_indicators()
	_connect_action_buttons(all_actions, on_action_pressed, on_action_hovered, on_action_unhovered)

func _load_arrow_textures():
	tex_arrow_up = load("res://Assets/UI/ArrowUp.png")
	tex_arrow_down = load("res://Assets/UI/ArrowDown.png")
	
	if not tex_arrow_up:
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.GREEN)
		tex_arrow_up = ImageTexture.create_from_image(img)
	if not tex_arrow_down:
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.RED)
		tex_arrow_down = ImageTexture.create_from_image(img)

func _setup_dynamic_ui(on_next_pressed: Callable):
	preview_label = Label.new()
	preview_label.text = "Hover an action for preview..."
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(preview_label)
	preview_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	preview_label.offset_bottom = -210
	
	center_msg_box = VBoxContainer.new()
	root.add_child(center_msg_box)
	center_msg_box.set_anchors_preset(Control.PRESET_CENTER)
	
	msg_label = Label.new()
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_msg_box.add_child(msg_label)
	
	next_btn = Button.new()
	next_btn.text = "Continue"
	next_btn.pressed.connect(on_next_pressed)
	center_msg_box.add_child(next_btn)

func _setup_arrow_indicators():
	var bars = {
		"correct_altitude": alt_bar,
		"fuel_level": fuel_bar,
		"punctual_arrival": time_bar,
		"structural_hp": hp_bar,
		"passenger_comfort": comfort_bar,
		"company_trust": trust_bar
	}
	
	for stat in bars:
		var bar: ProgressBar = bars[stat]
		var hbox = HBoxContainer.new()
		bar.add_sibling(hbox)
		bar.get_parent().move_child(hbox, bar.get_index())
		bar.get_parent().remove_child(bar)
		hbox.add_child(bar)
		
		var icon_up = TextureRect.new()
		icon_up.texture = tex_arrow_up
		icon_up.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon_up.custom_minimum_size = Vector2(20, 20)
		icon_up.hide()
		
		var icon_down = TextureRect.new()
		icon_down.texture = tex_arrow_down
		icon_down.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon_down.custom_minimum_size = Vector2(20, 20)
		icon_down.hide()
		
		hbox.add_child(icon_up)
		hbox.add_child(icon_down)
		
		arrow_indicators[stat] = {"up": icon_up, "down": icon_down}

func _connect_action_buttons(all_actions: Array[ActionButton], on_action_pressed: Callable, on_action_hovered: Callable, on_action_unhovered: Callable):
	var btn_nodes = [
		root.get_node("%ClimbHigh"), root.get_node("%SmoothAscent"), root.get_node("%MaxEconomy"), root.get_node("%PullPower"),
		root.get_node("%Accelerate"), root.get_node("%Reduce"), root.get_node("%Aggressive"), root.get_node("%Stabilize"),
		root.get_node("%SmoothFlight"), root.get_node("%CalmingAd"), root.get_node("%KeepSchedule"), root.get_node("%ReportDelay")
	]
	
	for i in range(all_actions.size()):
		var action = all_actions[i]
		var btn = btn_nodes[i]
		btn.pressed.connect(func(): on_action_pressed.call(action))
		btn.mouse_entered.connect(func(): on_action_hovered.call(action))
		btn.mouse_exited.connect(func(): on_action_unhovered.call())

func update_meters_ui() -> void:
	if not root.is_inside_tree(): return
	var t = root.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	var f_alt = randf_range(0.0, 10.0) if GameState.has_instrument_failure else GameState.correct_altitude
	var f_fuel = randf_range(0.0, 10.0) if GameState.has_instrument_failure else GameState.fuel_level
	var f_time = randf_range(0.0, 10.0) if GameState.has_instrument_failure else GameState.punctual_arrival
	var f_hp = randf_range(0.0, 10.0) if GameState.has_instrument_failure else GameState.structural_hp
	var f_comf = randf_range(0.0, 10.0) if GameState.has_instrument_failure else GameState.passenger_comfort
	var f_trust = randf_range(0.0, 10.0) if GameState.has_instrument_failure else GameState.company_trust
	
	t.tween_property(alt_bar, "value", f_alt, 0.5)
	t.tween_property(fuel_bar, "value", f_fuel, 0.5)
	t.tween_property(time_bar, "value", f_time, 0.5)
	t.tween_property(hp_bar, "value", f_hp, 0.5)
	t.tween_property(comfort_bar, "value", f_comf, 0.5)
	t.tween_property(trust_bar, "value", f_trust, 0.5)

func hide_all_panels():
	actions_panel.hide()
	center_msg_box.hide()
	preview_label.hide()

func show_briefing(round_number: int, content: String):
	pop_in(center_msg_box)
	msg_label.text = content
	next_btn.text = "Continue"

func show_chaos(content: String, should_shake: bool):
	pop_in(center_msg_box)
	msg_label.text = content
	next_btn.text = "Continue"
	if should_shake:
		shake_screen()

func show_action_selection(available_actions: Array[ActionButton]):
	var grid = actions_panel.get_node("GridContainer")
	for node in grid.get_children():
		node.hide()
		if node is Button:
			node.disabled = false
			
	var shown_buttons: Array[Button] = []
		
	for action in available_actions:
		for node in grid.get_children():
			if node is Button and node.text == action.display_name:
				node.show()
				if GameState.is_radio_silent and (action.id == "keep_schedule" or action.id == "report_delay"):
					node.disabled = true
				shown_buttons.append(node)
				break
				
	if GameState.has_locked_controls:
		var active_btns = shown_buttons.filter(func(b): return not b.disabled)
		active_btns.shuffle()
		for i in range(min(2, active_btns.size() - 1)):
			active_btns[i].disabled = true
				
	slide_up(actions_panel)
	preview_label.show()
	preview_label.modulate.a = 0.0
	var t = root.create_tween()
	t.tween_property(preview_label, "modulate:a", 1.0, 0.5)
	preview_label.text = "Wait for choice..."

func update_preview_label(action: ActionButton):
	if action == null:
		preview_label.text = "Wait for choice..."
		hide_all_arrows()
		return
		
	hide_all_arrows()
	
	if GameState.is_foggy:
		preview_label.text = "Preview [%s]: ??? (Instruments Failing)" % action.display_name
		return
		
	var p_text = "Preview [%s]: " % action.display_name
	
	for key in action.effects:
		var val = action.effects[key]
		p_text += "%s %s%s  " % [key, "+" if val > 0 else "", str(val)]
		
		if arrow_indicators.has(key):
			if val > 0:
				arrow_indicators[key]["up"].show()
				pulse_arrow(arrow_indicators[key]["up"])
			elif val < 0:
				arrow_indicators[key]["down"].show()
				pulse_arrow(arrow_indicators[key]["down"])
			
	preview_label.text = p_text

func show_results(action: ActionButton, is_game_over: bool):
	actions_panel.hide()
	preview_label.hide()
	hide_all_arrows()
	pop_in(center_msg_box)
	
	var msg = "Action applied: " + action.display_name + "\n\n"
	if is_game_over:
		msg += "GAME OVER. Critical Failure."
		next_btn.text = "Return to Menu"
	else:
		msg += "You survived this round."
		next_btn.text = "Next Round"
		
	msg_label.text = msg

func hide_all_arrows():
	for stat in arrow_indicators:
		arrow_indicators[stat]["up"].hide()
		arrow_indicators[stat]["down"].hide()

func pulse_arrow(node: TextureRect):
	var t = root.create_tween().set_loops(0)
	t.tween_property(node, "modulate:a", 0.3, 0.3)
	t.tween_property(node, "modulate:a", 1.0, 0.3)

func pop_in(node: Control):
	node.show()
	node.scale = Vector2.ZERO
	node.pivot_offset = node.size / 2.0
	var t = root.create_tween()
	t.tween_property(node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func slide_up(node: Control):
	node.show()
	node.modulate.a = 0.0
	node.position.y += 50
	var t = root.create_tween().set_parallel(true)
	t.tween_property(node, "modulate:a", 1.0, 0.4)
	t.tween_property(node, "position:y", node.position.y - 50, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func shake_screen():
	var start_pos = root.position
	var t = root.create_tween()
	for i in range(6):
		t.tween_property(root, "position", start_pos + Vector2(randf_range(-15, 15), randf_range(-15, 15)), 0.05)
	t.tween_property(root, "position", start_pos, 0.05)
