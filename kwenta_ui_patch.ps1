
$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "scripts\main.gd"

if (-not (Test-Path $path)) {
    throw "Run this script from your Kwenta project folder."
}

$source = [System.IO.File]::ReadAllText($path).Replace("`r`n", "`n")

if ($source.Contains("KWENTA_CLEAN_UI_V1")) {
    throw "This UI patch has already been applied."
}

$backup = Join-Path (Get-Location) ("main_before_ui_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".gd.bak")
Copy-Item $path $backup

function Replace-Section {
    param(
        [string]$start,
        [string]$end,
        [string]$replacement
    )

    $pattern = "(?ms)^func " + [regex]::Escape($start) + "\([^\n]*\n.*?(?=^func " + [regex]::Escape($end) + "\()"
    $match = [regex]::Match($script:source, $pattern)

    if (-not $match.Success) {
        throw "Cannot find function section: $start. Original file was not modified."
    }

    $script:source = $script:source.Substring(0, $match.Index) +
        $replacement.TrimEnd() + "`n`n" +
        $script:source.Substring($match.Index + $match.Length)
}

# 1. CLEAN GAMEPLAY HUD

$newHud = @'
# KWENTA_CLEAN_UI_V1
func _hud_panel(at: Vector2, dimensions: Vector2, fill: Color, outline: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = at
	panel.size = dimensions
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _build_hud() -> void:
	var hud := Control.new()
	hud.name = "CleanGameplayHUD"
	hud.z_index = 30
	hud.position = _ui_offset()
	hud.size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)

	# Objective — left
	goal_panel = _hud_panel(
		Vector2(116, 10),
		Vector2(456, 92),
		Color("392318", 0.96),
		Color("d8a34e")
	)
	goal_panel.name = "DailyGoalHud"
	hud.add_child(goal_panel)

	var goal_rows := VBoxContainer.new()
	goal_rows.add_theme_constant_override("separation", 9)
	goal_panel.add_child(goal_rows)

	goal_label = _label("", 20, Color("fff1c8"))
	goal_label.name = "DailyGoalTitle"
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_rows.add_child(goal_label)

	goal_progress = ProgressBar.new()
	goal_progress.name = "DailyGoalProgress"
	goal_progress.custom_minimum_size = Vector2(0, 20)
	goal_progress.show_percentage = false
	goal_progress.min_value = 0.0

	var goal_track := StyleBoxFlat.new()
	goal_track.bg_color = Color("20140e")
	goal_track.set_corner_radius_all(6)
	goal_track.border_color = Color("916339")
	goal_track.set_border_width_all(2)

	goal_progress_fill = StyleBoxFlat.new()
	goal_progress_fill.bg_color = Color("e0a33a")
	goal_progress_fill.set_corner_radius_all(5)

	goal_progress.add_theme_stylebox_override("background", goal_track)
	goal_progress.add_theme_stylebox_override("fill", goal_progress_fill)
	goal_rows.add_child(goal_progress)

	# Day and time — center
	var time_card := _hud_panel(
		Vector2(610, 10),
		Vector2(440, 92),
		Color("fff0d0", 0.97),
		Color("85512d")
	)
	hud.add_child(time_card)

	var time_row := HBoxContainer.new()
	time_row.alignment = BoxContainer.ALIGNMENT_CENTER
	time_row.add_theme_constant_override("separation", 22)
	time_card.add_child(time_row)

	day_label = _label("DAY 1", 29, Color("56331d"))
	day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_row.add_child(day_label)

	var separator := ColorRect.new()
	separator.color = Color("b99258")
	separator.custom_minimum_size = Vector2(3, 48)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_row.add_child(separator)

	clock_label = _label("8:00 AM", 29, Color("56331d"))
	clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_row.add_child(clock_label)

	# Cash — right of center
	var cash_card := _hud_panel(
		Vector2(1080, 10),
		Vector2(225, 92),
		Color("e5efcf", 0.97),
		Color("6e8d42")
	)
	hud.add_child(cash_card)

	cash_label = _label("₱150", 32, Color("34703c"))
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cash_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cash_card.add_child(cash_label)

	# Suki Meter — separate from Shop
	trust_tag = TrustTag.new().setup(
		campaign.barangay_trust, 260.0, 1.2, 3.0
	)
	trust_tag.position = Vector2(1400, 8)
	hud.add_child(trust_tag)
'@

Replace-Section "_build_hud" "_refresh_daily_goal_hud" $newHud

# 2. TUTORIAL BANNER PLACEMENT

$newTutorial = @'
func _build_tutorial_hint() -> void:
	tutorial_hint = _label("", 25, Color("fff1b8"))
	tutorial_hint.name = "TutorialHint"
	tutorial_hint.z_index = 46
	tutorial_hint.position = Vector2(410, 128) + _ui_offset()
	tutorial_hint.size = Vector2(1100, 66)
	tutorial_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_hint.add_theme_color_override("font_outline_color", Color("2b1a10"))
	tutorial_hint.add_theme_constant_override("outline_size", 7)
	tutorial_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_hint.visible = false
	add_child(tutorial_hint)
'@

Replace-Section "_build_tutorial_hint" "_build_interactive_tutorial_overlay" $newTutorial

# 3. SHOP BUTTON AND EXISTING PAUSE BUTTON

$newShop = @'
func _build_shop_button() -> void:
	shop_button = Button.new()
	shop_button.name = "ShopIconButton"
	shop_button.position = Vector2(1790, 8) + _ui_offset()
	shop_button.size = Vector2(108, 94)
	shop_button.z_index = 55
	shop_button.z_as_relative = false
	shop_button.focus_mode = Control.FOCUS_NONE
	shop_button.tooltip_text = "Open the shop"
	shop_button.visible = false

	var normal := _make_box(
		Color("805028", 0.97),
		Color("e7b35d")
	)
	var hover := _make_box(
		Color("aa7135"),
		Color("ffdc88")
	)
	var pressed_style := _make_box(
		Color("59351c"),
		Color("d99b45")
	)

	shop_button.add_theme_stylebox_override("normal", normal)
	shop_button.add_theme_stylebox_override("hover", hover)
	shop_button.add_theme_stylebox_override("pressed", pressed_style)
	shop_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var shop_icon := TextureRect.new()
	shop_icon.name = "ShopIcon"
	shop_icon.texture = SHOP_ICON_TEXTURE
	shop_icon.position = Vector2(34, 4)
	shop_icon.size = Vector2(40, 40)
	shop_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shop_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shop_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_button.add_child(shop_icon)

	var shop_text := _label("SHOP", 19, Color("fff4d6"))
	shop_text.position = Vector2(12, 50)
	shop_text.size = Vector2(84, 25)
	shop_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_button.add_child(shop_text)

	shop_button.pressed.connect(_open_shelf_shop)
	add_child(shop_button)

func _relayout_pause_control() -> void:
	if pause_menu == null:
		return

	# Preserve the existing pause button's signal and gameplay logic.
	for node in pause_menu.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if button == null:
			continue

		var identifier := button.name.to_lower()
		if button is Button:
			identifier += " " + (button as Button).text.to_lower()

		if not identifier.contains("pause"):
			continue

		button.global_position = Vector2(16, 12) + _ui_offset()
		button.size = Vector2(84, 84)
		button.z_index = 55
		return
'@

Replace-Section "_build_shop_button" "_build_debug_tools" $newShop

# 4. DISABLE SKIP DAY BUTTON

$newDebug = @'
func _build_debug_tools() -> void:
	# Skip Day has been disabled for the cleaner HUD.
	return
'@

Replace-Section "_build_debug_tools" "_debug_skip_day" $newDebug

$source = $source.Replace(
    "`tif event.keycode == KEY_F10:`n`t`t_debug_skip_day()`n",
    ""
)

# 5. SPACIOUS PRE-SHIFT NOTEBOOK

$newBriefing = @'
func _show_pre_shift_briefing() -> void:
	_ensure_daily_goal()
	var briefing = DAY_BRIEFING.new(
		campaign.day,
		daily_goal,
		CAMPAIGN_CONFIG.product_catalog
	)

	showing_pre_shift_briefing = true
	_build_clean_briefing(briefing)

	summary_panel.visible = false
	summary_backdrop.visible = true
	pre_shift_panel.visible = true

func _briefing_info_card(
	section_title: String,
	body_text: String,
	min_height: float = 140.0
) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, min_height)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("fff7e7")
	card_style.border_color = Color("d4b47d")
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(12)
	card_style.content_margin_left = 22
	card_style.content_margin_right = 22
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", card_style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)

	var heading := _label(section_title, 18, Color("9d612e"))
	content.add_child(heading)

	var description := _label(body_text, 23, Color("452b1d"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(description)

	return card

func _build_clean_briefing(briefing: DayBriefing) -> void:
	if is_instance_valid(pre_shift_panel):
		pre_shift_panel.hide()
		pre_shift_panel.queue_free()

	pre_shift_panel = PanelContainer.new()
	pre_shift_panel.name = "CleanPreShiftBriefing"
	pre_shift_panel.z_index = 42
	pre_shift_panel.position = Vector2(280, 144) + _ui_offset()
	pre_shift_panel.size = Vector2(1360, 792)
	pre_shift_panel.visible = false

	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = Color("f4e3bd")
	paper_style.border_color = Color("75502b")
	paper_style.set_border_width_all(7)
	paper_style.set_corner_radius_all(18)
	paper_style.content_margin_left = 48
	paper_style.content_margin_right = 48
	paper_style.content_margin_top = 32
	paper_style.content_margin_bottom = 28
	pre_shift_panel.add_theme_stylebox_override("panel", paper_style)
	add_child(pre_shift_panel)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)
	pre_shift_panel.add_child(page)

	# Header
	var eyebrow := _label(briefing.eyebrow, 18, Color("9b6738"))
	page.add_child(eyebrow)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 20)
	page.add_child(title_row)

	var title := _label(briefing.title, 43, Color("4c2a18"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var day_badge := _label("DAY %d" % campaign.day, 28, Color("885324"))
	day_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(day_badge)

	var line := ColorRect.new()
	line.color = Color("bd965d")
	line.custom_minimum_size = Vector2(0, 3)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(line)

	# Two-column content
	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 26)
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(content_row)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(740, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 20)
	content_row.add_child(left)

	var focus_card := _briefing_info_card(
		"TODAY'S FOCUS",
		briefing.focus,
		148
	)
	left.add_child(focus_card)

	# Shelf section with individual product tiles
	var shelf_card := PanelContainer.new()
	shelf_card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var shelf_style := StyleBoxFlat.new()
	shelf_style.bg_color = Color("fff7e7")
	shelf_style.border_color = Color("d4b47d")
	shelf_style.set_border_width_all(2)
	shelf_style.set_corner_radius_all(12)
	shelf_style.content_margin_left = 20
	shelf_style.content_margin_right = 20
	shelf_style.content_margin_top = 18
	shelf_style.content_margin_bottom = 18
	shelf_card.add_theme_stylebox_override("panel", shelf_style)
	left.add_child(shelf_card)

	var shelf_content := VBoxContainer.new()
	shelf_content.add_theme_constant_override("separation", 17)
	shelf_card.add_child(shelf_content)

	var shelf_heading := "STARTING SHELF"
	if not briefing.product_section_title.is_empty():
		shelf_heading = briefing.product_section_title

	shelf_content.add_child(
		_label(shelf_heading, 18, Color("9d612e"))
	)

	var product_grid := GridContainer.new()
	product_grid.columns = 3
	product_grid.add_theme_constant_override("h_separation", 12)
	product_grid.add_theme_constant_override("v_separation", 12)
	shelf_content.add_child(product_grid)

	if briefing.unlocked_product_names.is_empty():
		product_grid.add_child(
			_label("No new products today.", 22, Color("65462f"))
		)

	for product_name in briefing.unlocked_product_names:
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(212, 62)

		var tile_style := StyleBoxFlat.new()
		tile_style.bg_color = Color("ead4a8")
		tile_style.border_color = Color("b48a51")
		tile_style.set_border_width_all(2)
		tile_style.set_corner_radius_all(9)
		tile_style.content_margin_left = 8
		tile_style.content_margin_right = 8
		tile_style.content_margin_top = 8
		tile_style.content_margin_bottom = 8
		tile.add_theme_stylebox_override("panel", tile_style)

		var product_label := _label(
			product_name,
			18,
			Color("50331c")
		)
		product_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		product_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		product_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.add_child(product_label)
		product_grid.add_child(tile)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 20)
	content_row.add_child(right)

	right.add_child(
		_briefing_info_card(
			"SHIFT DETAILS",
			briefing.shift_detail,
			154
		)
	)

	right.add_child(
		_briefing_info_card(
			"OPTIONAL DAILY GOAL",
			"%s\n\nReward: %s" % [
				briefing.goal_title,
				briefing.goal_reward
			],
			205
		)
	)

	# Bottom action area
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 24)
	page.add_child(footer)

	var footer_hint := _label(
		"Ready for today's shift?",
		22,
		Color("765337")
	)
	footer_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(footer_hint)

	var open_button := Button.new()
	open_button.text = "OPEN STORE"
	open_button.custom_minimum_size = Vector2(320, 76)
	open_button.focus_mode = Control.FOCUS_NONE
	apply_notebook_action_button_style(open_button)
	open_button.pressed.connect(_on_summary_button_pressed)
	footer.add_child(open_button)
'@

Replace-Section "_show_pre_shift_briefing" "_begin_shift" $newBriefing

# 6. CONNECT THE NEW BRIEFING TO THE EXISTING SHIFT FLOW

$variableNeedle = "var showing_pre_shift_briefing := false"
if (-not $source.Contains($variableNeedle)) {
    throw "Cannot find briefing state variable."
}
$source = $source.Replace(
    $variableNeedle,
    "$variableNeedle`nvar pre_shift_panel: PanelContainer"
)

$pauseNeedle = "`tadd_child(pause_menu)"
if (-not $source.Contains($pauseNeedle)) {
    throw "Cannot find PauseMenu setup."
}
$source = $source.Replace(
    $pauseNeedle,
    "$pauseNeedle`n`tcall_deferred(`"_relayout_pause_control`")"
)

$oldClose = @'
	if showing_pre_shift_briefing:
		showing_pre_shift_briefing = false
		summary_backdrop.visible = false
		summary_panel.visible = false
'@

$newClose = @'
	if showing_pre_shift_briefing:
		showing_pre_shift_briefing = false
		summary_backdrop.visible = false
		summary_panel.visible = false
		if is_instance_valid(pre_shift_panel):
			pre_shift_panel.visible = false
'@

# Normalize line endings before comparing.
$oldClose = $oldClose.Replace("`r`n", "`n")
$newClose = $newClose.Replace("`r`n", "`n")

if (-not $source.Contains($oldClose)) {
    throw "Cannot find pre-shift close handler."
}

$source = $source.Replace($oldClose, $newClose)

# Write only after every replacement succeeds.
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $source, $utf8)

Write-Host ""
Write-Host "KWENTA UI PATCH APPLIED!" -ForegroundColor Green
Write-Host "Backup saved: $backup"
Write-Host "Updated: scripts\main.gd"
Write-Host ""
Write-Host "Open Godot and test the HUD, Pause, Shop and pre-shift briefing."
