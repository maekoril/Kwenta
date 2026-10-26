class_name KwentaStyle
extends RefCounted

# One place for the paper-and-ink look. The dialogue bubble and cash tray still carry their
# own copies of these colors; they match, and can be pointed at this file later.

const PAPER := Color("#f6e7c8")
const PAPER_DARK := Color("#e8d4a8")
const INK := Color("#2b1a10")
const GOLD := Color("#e0a33a")
const FONT_PATH := "res://assets/fonts/PixelifySans-Regular.ttf"   # same font as the bubble

# --- Text hierarchy for the notebook page (px at 1920x1080) ---
# Contrast on PAPER: INK 13.7:1, INK_MUTED 6.5:1, MONEY 5.3:1 (all above the 4.5:1 minimum).
# The pixel font has one weight, so hierarchy comes from size, color, position and rules.
const INK_MUTED := Color("#6b4a2a")     # labels and captions
const MONEY := Color("#2f6b2f")         # peso amounts (same green as the cash tag)
const SIZE_H1 := 60                     # page header
const SIZE_HERO := 68                   # the one number that matters
const SIZE_BODY := 38                   # lead / paragraph text
const SIZE_ROW_LABEL := 34
const SIZE_ROW_VALUE := 40
const SIZE_SMALL := 30                  # secondary stats
const SIZE_CAPTION := 26                # eyebrows and section labels (never smaller)
const SIZE_BUTTON := 44                 # the primary action

static var _font: Font
static var _font_checked: bool = false

static func font() -> Font:
	if not _font_checked:
		_font_checked = true
		if ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH)
	return _font

static func make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	apply_font(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

static func apply_font(control: Control) -> void:
	var f := font()
	if f != null:
		control.add_theme_font_override("font", f)

static func box(bg: Color, edge: Color, margin_x: float = 18.0, margin_y: float = 12.0, radius: int = 12, border: int = 6, shadow: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = false                    # crisp, pixel-style corners
	sb.content_margin_left = margin_x
	sb.content_margin_right = margin_x
	sb.content_margin_top = margin_y
	sb.content_margin_bottom = margin_y
	sb.shadow_color = Color(0, 0, 0, 0.4)       # hard offset shadow, no blur
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, shadow)
	return sb

static func style_button(button: Button, bg: Color, font_size: int) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS   # fires on touch-down
	button.add_theme_font_size_override("font_size", font_size)
	apply_font(button)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, INK)
	button.add_theme_color_override("font_disabled_color", Color(INK, 0.4))
	button.add_theme_stylebox_override("normal", box(bg, INK, 16.0, 8.0, 12, 5, 6))
	button.add_theme_stylebox_override("hover", box(bg.lightened(0.12), INK, 16.0, 8.0, 12, 5, 6))
	button.add_theme_stylebox_override("pressed", box(bg.darkened(0.12), INK, 16.0, 8.0, 12, 5, 6))
	button.add_theme_stylebox_override("disabled", box(PAPER_DARK, Color(INK, 0.4), 16.0, 8.0, 12, 5, 6))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
