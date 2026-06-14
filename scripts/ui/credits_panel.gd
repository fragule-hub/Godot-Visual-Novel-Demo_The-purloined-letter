extends Control

@onready var _close_btn: Button = %CloseBtn
@onready var _content_vbox: VBoxContainer = $MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/ContentVBox

var _inner_vbox: VBoxContainer

const CREDITS_PATH := "res://data/credits.json"

const DEFAULT_CAT_SIZE := 24
const DEFAULT_CAT_COLOR := Color(0.35, 0.65, 0.72, 0.7)
const DEFAULT_ENTRY_SIZE := 28
const DEFAULT_ENTRY_COLOR := Color(0.85, 0.92, 0.94, 1)

const LINK_COLOR := Color(0.4, 0.8, 0.88, 1)
const ROW_SEPARATION := 24

var _overlay: KND_OverlayPanel


func _ready() -> void:
	_close_btn.pressed.connect(_on_close_pressed)
	_load_credits()


func _load_credits() -> void:
	var file := FileAccess.open(CREDITS_PATH, FileAccess.READ)
	if not file:
		push_error("CreditsPanel: cannot open %s" % CREDITS_PATH)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_error("CreditsPanel: JSON parse error — %s" % json.get_error_message())
		return

	var data: Dictionary = json.data

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	_content_vbox.add_child(margin)

	_inner_vbox = VBoxContainer.new()
	_inner_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(_inner_vbox)

	for cat: Dictionary in data.get("categories", []):
		var cat_size: int = cat.get("size", DEFAULT_CAT_SIZE)
		var cat_label := Label.new()
		cat_label.text = "── %s ──" % cat.get("name", "")
		cat_label.add_theme_font_size_override("font_size", cat_size)
		cat_label.add_theme_color_override("font_color", DEFAULT_CAT_COLOR)
		cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_inner_vbox.add_child(cat_label)

		for entry: Dictionary in cat.get("entries", []):
			if entry.has("link"):
				_add_link_row(entry, entry.get("size", DEFAULT_ENTRY_SIZE))
			else:
				_add_text_entry(entry, entry.get("size", DEFAULT_ENTRY_SIZE))


func _add_link_row(entry: Dictionary, font_size: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_SEPARATION)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_label := Label.new()
	name_label.text = entry.get("name", "")
	name_label.custom_minimum_size.x = 50
	name_label.add_theme_font_size_override("font_size", font_size)
	name_label.add_theme_color_override("font_color", DEFAULT_ENTRY_COLOR)
	row.add_child(name_label)

	var link_rtl := RichTextLabel.new()
	link_rtl.bbcode_enabled = true
	link_rtl.fit_content = true
	link_rtl.scroll_active = false
	link_rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	link_rtl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	link_rtl.add_theme_color_override("default_color", LINK_COLOR)
	link_rtl.add_theme_font_size_override("normal_font_size", font_size)
	link_rtl.add_theme_font_size_override("bold_font_size", font_size)
	link_rtl.add_theme_font_size_override("italics_font_size", font_size)
	var url: String = entry.get("link", "")
	var link_text: String = entry.get("link_text", url)
	link_rtl.text = "[center][url=%s]%s[/url][/center]" % [url, link_text]
	link_rtl.meta_clicked.connect(_on_link_clicked)
	row.add_child(link_rtl)

	_inner_vbox.add_child(row)


func _add_text_entry(entry: Dictionary, font_size: int) -> void:
	var label := Label.new()
	label.text = entry.get("name", "")
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", DEFAULT_ENTRY_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inner_vbox.add_child(label)


func _on_close_pressed() -> void:
	if _overlay:
		_overlay.close()


func _on_link_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
