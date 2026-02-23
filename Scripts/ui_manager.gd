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

var center_msg_box: Control
var msg_label: Label
var next_btn: Button
var preview_label: Label

var arrow_indicators: Dictionary = {}
var tex_arrow_up: Texture2D
var tex_arrow_down: Texture2D

var sfx_hover: AudioStreamPlayer
var sfx_confirm: AudioStreamPlayer
var sfx_error: AudioStreamPlayer

# -- Icon map: action id -> texture path
const ACTION_ICONS: Dictionary = {
	"climb_high": "res://Assets/UI/icons/Climb high.png",
	"smooth_ascent": "res://Assets/UI/icons/Smooth ascent.png",
	"max_economy": "res://Assets/UI/icons/Fuel.png",
	"pull_power": "res://Assets/UI/icons/Pull power.png",
	"accelerate": "res://Assets/UI/icons/Accelerate.png",
	"reduce": "res://Assets/UI/icons/Reduce speed.png",
	"aggressive": "res://Assets/UI/icons/Agressive Manu.png",
	"stabilize": "res://Assets/UI/icons/Stabilize struct.png",
	"smooth_flight": "res://Assets/UI/icons/Smooth Flight.png",
	"calming_ad": "res://Assets/UI/icons/Calming ad.png",
	"keep_schedule": "res://Assets/UI/icons/Keep schedule - Transparent.png",
	"report_delay": "res://Assets/UI/icons/Report Delay - Transparent.png",
}

# Maps button node name -> action id (must align with scene button names)
const BTN_ACTION_ID: Dictionary = {
	"ClimbHigh": "climb_high",
	"SmoothAscent": "smooth_ascent",
	"MaxEconomy": "max_economy",
	"PullPower": "pull_power",
	"Accelerate": "accelerate",
	"Reduce": "reduce",
	"Aggressive": "aggressive",
	"Stabilize": "stabilize",
	"SmoothFlight": "smooth_flight",
	"CalmingAd": "calming_ad",
	"KeepSchedule": "keep_schedule",
	"ReportDelay": "report_delay",
}

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
	_setup_sounds()
	_style_progress_bars()
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

func _setup_sounds():
	var _make = func(path: String) -> AudioStreamPlayer:
		var player = AudioStreamPlayer.new()
		var stream = load(path)
		if stream:
			player.stream = stream
		player.bus = "Master"
		root.add_child(player)
		return player
	sfx_hover = _make.call("res://Assets/Sound/Hover.wav")
	sfx_confirm = _make.call("res://Assets/Sound/Switch.wav")
	sfx_error = _make.call("res://Assets/Sound/Error.wav")

func _play_hover(): if sfx_hover and sfx_hover.stream: sfx_hover.play()
func _play_confirm(): if sfx_confirm and sfx_confirm.stream: sfx_confirm.play()
func _play_error(): if sfx_error and sfx_error.stream: sfx_error.play()

func _style_progress_bars():
	var status_bar_tex: Texture2D = load("res://Assets/UI/HUD/status bar.png")
	if not status_bar_tex:
		return
	var bars: Array[ProgressBar] = [alt_bar, fuel_bar, time_bar, hp_bar, comfort_bar, trust_bar]
	for bar in bars:
		var fill_style = StyleBoxTexture.new()
		fill_style.texture = status_bar_tex
		fill_style.texture_margin_left = 2
		fill_style.texture_margin_right = 2
		fill_style.texture_margin_top = 2
		fill_style.texture_margin_bottom = 2
		bar.add_theme_stylebox_override("fill", fill_style)
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
		bar.add_theme_stylebox_override("background", bg_style)

func _setup_dynamic_ui(on_next_pressed: Callable):
	var action_applied_tex: Texture2D = load("res://Assets/UI/HUD/Acction Applied.png")
	var next_btn_tex: Texture2D = load("res://Assets/UI/HUD/button nextround.png")

	# --- One unified panel: floats at top-center, grows to fit content ---
	center_msg_box = PanelContainer.new()
	center_msg_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(center_msg_box)

	# Anchor to top-center with margin
	center_msg_box.anchor_left = 0.5
	center_msg_box.anchor_right = 0.5
	center_msg_box.anchor_top = 0.0
	center_msg_box.anchor_bottom = 0.0
	center_msg_box.offset_left = -270.0
	center_msg_box.offset_right = 270.0
	center_msg_box.offset_top = 20.0
	center_msg_box.offset_bottom = 20.0 # set to top so the panel grows downward freely

	# Apply Action Applied texture as background (9-patch so it stretches vertically)
	if action_applied_tex:
		var panel_style = StyleBoxTexture.new()
		panel_style.texture = action_applied_tex
		panel_style.texture_margin_left = 16
		panel_style.texture_margin_right = 16
		panel_style.texture_margin_top = 12
		panel_style.texture_margin_bottom = 12
		panel_style.content_margin_left = 24
		panel_style.content_margin_right = 24
		panel_style.content_margin_top = 18
		panel_style.content_margin_bottom = 18
		center_msg_box.add_theme_stylebox_override("panel", panel_style)
	else:
		var fallback = StyleBoxFlat.new()
		fallback.bg_color = Color(0, 0, 0, 0.85)
		fallback.content_margin_left = 24
		fallback.content_margin_right = 24
		fallback.content_margin_top = 18
		fallback.content_margin_bottom = 18
		center_msg_box.add_theme_stylebox_override("panel", fallback)

	# --- Inner VBox: stacks title, separator, body, button ---
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 10)
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_msg_box.add_child(inner_vbox)

	# Title label (white, bold) — updated each phase via msg_label
	msg_label = Label.new()
	msg_label.text = "Action Applied"
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	msg_label.add_theme_font_size_override("font_size", 17)
	inner_vbox.add_child(msg_label)

	# Invisible spacer instead of separator line
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	inner_vbox.add_child(spacer)

	# Body label — BLACK text (readable on the gray lower section of the panel)
	var body_label = Label.new()
	body_label.name = "BodyLabel"
	body_label.text = ""
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	body_label.add_theme_font_size_override("font_size", 14)
	inner_vbox.add_child(body_label)

	# --- Next button ---
	next_btn = Button.new()
	next_btn.text = "Continue"
	next_btn.custom_minimum_size = Vector2(220, 46)
	next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	next_btn.add_theme_font_size_override("font_size", 14)
	if next_btn_tex:
		var normal_style = StyleBoxTexture.new()
		normal_style.texture = next_btn_tex
		var hover_style = StyleBoxTexture.new()
		hover_style.texture = next_btn_tex
		hover_style.modulate_color = Color(0.85, 0.85, 0.85, 1.0)
		next_btn.add_theme_stylebox_override("normal", normal_style)
		next_btn.add_theme_stylebox_override("hover", hover_style)
		next_btn.add_theme_stylebox_override("pressed", normal_style)
		next_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	next_btn.pressed.connect(func(): _play_confirm(); on_next_pressed.call())
	next_btn.mouse_entered.connect(_play_hover)
	inner_vbox.add_child(next_btn)

	# Preview label below the actions panel
	preview_label = Label.new()
	preview_label.text = "Hover an action for preview..."
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	root.add_child(preview_label)
	preview_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	preview_label.offset_bottom = -10
	preview_label.offset_top = -40

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
		icon_up.custom_minimum_size = Vector2(16, 16)
		icon_up.hide()

		var icon_down = TextureRect.new()
		icon_down.texture = tex_arrow_down
		icon_down.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon_down.custom_minimum_size = Vector2(16, 16)
		icon_down.hide()

		hbox.add_child(icon_up)
		hbox.add_child(icon_down)

		arrow_indicators[stat] = {"up": icon_up, "down": icon_down}

func _connect_action_buttons(all_actions: Array[ActionButton], on_action_pressed: Callable, on_action_hovered: Callable, on_action_unhovered: Callable):
	var btn_node_names = [
		"ClimbHigh", "SmoothAscent", "MaxEconomy", "PullPower",
		"Accelerate", "Reduce", "Aggressive", "Stabilize",
		"SmoothFlight", "CalmingAd", "KeepSchedule", "ReportDelay"
	]

	var button_bg_tex: Texture2D = load("res://Assets/UI/HUD/button.png")
	var grid = actions_panel.get_node("GridContainer")
	const BTN_SIZE = 110.0

	for i in range(all_actions.size()):
		var action = all_actions[i]
		var btn_name = btn_node_names[i]

		# We will replace the plain Button in the scene with a TextureButton
		var old_btn: Button = grid.get_node(btn_name)
		var btn_index = old_btn.get_index()

		# --- Outer VBox: holds the circle + label ---
		var vbox = VBoxContainer.new()
		vbox.set_meta("action_id", action.id)
		vbox.add_theme_constant_override("separation", 6)
		vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		# --- TextureButton for the circle background ---
		var tbtn = TextureButton.new()
		tbtn.set_meta("action_id", action.id)
		tbtn.custom_minimum_size = Vector2(BTN_SIZE, BTN_SIZE)
		tbtn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tbtn.ignore_texture_size = true
		tbtn.stretch_mode = TextureButton.STRETCH_SCALE
		if button_bg_tex:
			tbtn.texture_normal = button_bg_tex
			tbtn.texture_hover = button_bg_tex
			tbtn.texture_pressed = button_bg_tex

		# --- Icon overlay centered inside the circle ---
		var icon_path = ACTION_ICONS.get(action.id, "")
		if icon_path != "":
			var icon_tex = load(icon_path)
			if icon_tex:
				var center = CenterContainer.new()
				center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				center.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var icon_rect = TextureRect.new()
				icon_rect.texture = icon_tex
				icon_rect.modulate = Color.BLACK
				icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.custom_minimum_size = Vector2(BTN_SIZE * 0.65, BTN_SIZE * 0.65)
				icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				center.add_child(icon_rect)
				tbtn.add_child(center)

		# --- Label below button ---
		var lbl = Label.new()
		lbl.text = action.display_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		lbl.add_theme_font_size_override("font_size", 14)

		vbox.add_child(tbtn)
		vbox.add_child(lbl)

		# Swap out the old plain button node
		grid.remove_child(old_btn)
		old_btn.queue_free()
		grid.add_child(vbox)
		grid.move_child(vbox, btn_index)

		tbtn.pressed.connect(func(): _play_confirm(); on_action_pressed.call(action))
		tbtn.mouse_entered.connect(func():
			_play_hover()
			on_action_hovered.call(action))
		tbtn.mouse_exited.connect(func(): on_action_unhovered.call())
		# Error sound when clicking a disabled button
		tbtn.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if tbtn.disabled:
					_play_error())

func _find_btn_for_action(action_id: String) -> TextureButton:
	var grid = actions_panel.get_node("GridContainer")
	for node in grid.get_children():
		if node is TextureButton and node.get_meta("action_id", "") == action_id:
			return node
		if node is VBoxContainer:
			for child in node.get_children():
				if child is TextureButton and child.get_meta("action_id", "") == action_id:
					return child
	return null

func _find_container_for_action(action_id: String) -> Control:
	var grid = actions_panel.get_node("GridContainer")
	for node in grid.get_children():
		if node.get_meta("action_id", "") == action_id:
			return node
	return null

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

	_recolor_bar(alt_bar, f_alt)
	_recolor_bar(fuel_bar, f_fuel)
	_recolor_bar(time_bar, f_time)
	_recolor_bar(hp_bar, f_hp)
	_recolor_bar(comfort_bar, f_comf)
	_recolor_bar(trust_bar, f_trust)

func _recolor_bar(bar: ProgressBar, value: float):
	if value >= 5.0:
		bar.modulate = Color.GREEN
	else:
		bar.modulate = Color.RED

func hide_all_panels():
	actions_panel.hide()
	center_msg_box.hide()
	preview_label.hide()

func show_briefing(round_number: int, content: String):
	pop_in(center_msg_box)
	msg_label.text = "Round %d Briefing" % round_number if round_number < 6 else "Last Round Briefing!"
	_get_body_label().text = content
	next_btn.text = "Continue"

func _get_body_label() -> Label:
	return center_msg_box.find_child("BodyLabel", true, false) as Label

func show_chaos(content: String, should_shake: bool):
	pop_in(center_msg_box)
	msg_label.text = "Chaos Event!"
	_get_body_label().text = content
	next_btn.text = "Continue"
	if should_shake:
		shake_screen()

func show_action_selection(available_actions: Array[ActionButton]):
	var grid = actions_panel.get_node("GridContainer")
	# Hide everything first and reset disabled state
	for node in grid.get_children():
		node.hide()
		node.modulate = Color.WHITE
		if node is TextureButton:
			node.disabled = false
		elif node is VBoxContainer:
			for child in node.get_children():
				if child is TextureButton:
					child.disabled = false

	var shown_btns: Array[TextureButton] = []

	for action in available_actions:
		var container = _find_container_for_action(action.id)
		var btn = _find_btn_for_action(action.id)
		if container:
			container.show()
		elif btn:
			btn.show()
		if btn:
			if GameState.is_radio_silent and (action.id == "keep_schedule" or action.id == "report_delay"):
				btn.disabled = true
				# Gray out the parent container
				var parent = btn.get_parent()
				if parent:
					parent.modulate = Color(0.5, 0.5, 0.5, 1.0)
				else:
					btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
			shown_btns.append(btn)

	if GameState.has_locked_controls:
		var active_btns = shown_btns.filter(func(b): return not b.disabled)
		active_btns.shuffle()
		for i in range(min(2, active_btns.size() - 1)):
			active_btns[i].disabled = true
			# Gray out the parent container
			var parent = active_btns[i].get_parent()
			if parent:
				parent.modulate = Color(0.5, 0.5, 0.5, 1.0)
			else:
				active_btns[i].modulate = Color(0.5, 0.5, 0.5, 1.0)

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

	if is_game_over:
		msg_label.text = "Game Over!"
		_get_body_label().text = "CRITICAL FAILURE.\nThe plane never made it."
		next_btn.text = "Return to Menu"
	else:
		msg_label.text = "Action Applied: " + action.display_name
		_get_body_label().text = "You survived this round."
		next_btn.text = "Next Round"

func show_victory_screen():
	actions_panel.hide()
	preview_label.hide()
	hide_all_arrows()
	pop_in(center_msg_box)

	var successful_metrics = []
	if GameState.correct_altitude >= 5.0: successful_metrics.append("Altitude")
	if GameState.fuel_level >= 5.0: successful_metrics.append("Fuel")
	if GameState.punctual_arrival >= 5.0: successful_metrics.append("Punctuality")
	if GameState.structural_hp >= 5.0: successful_metrics.append("Structural HP")
	if GameState.passenger_comfort >= 5.0: successful_metrics.append("Comfort")
	if GameState.company_trust >= 5.0: successful_metrics.append("Company Trust")

	var is_perfect = successful_metrics.size() == 6
	msg_label.text = "Flight Complete: " + ("Satisfactory Travel" if is_perfect else "Awful Travel")

	var body = "You survived 6 rounds!\n\n"
	if is_perfect:
		body += "All metrics stayed above 50%.\nFantastic piloting!"
	else:
		body += "Some metrics fell below 50%.\nYour passengers won't forget this.\n\n"
		body += "Satisfactory Metrics:\n"
		if successful_metrics.is_empty():
			body += "None! It was a terrifying flight."
		else:
			for sm in successful_metrics:
				body += "- " + sm + " [OK]\n"
	body += "\nTotal Successes: %d / 6" % successful_metrics.size()
	_get_body_label().text = body
	next_btn.text = "Return to Menu"

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
