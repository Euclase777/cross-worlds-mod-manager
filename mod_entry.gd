class_name ModContainer
extends GridContainer

var config = ConfigFile.new()

@onready var checkbox = $CheckBox
@onready var button_collapse = $HBoxContainer/ButtonCollapse
@onready var mod_name = $HBoxContainer/ButtonModName
@onready var button_open = $HBoxContainer/ButtonOpenFolder
@onready var button_link = $HBoxContainer/ButtonLink
@onready var sep = $VSeparator
@onready var vbox = $VBoxContainer
@onready var version = $HBoxContainer/LabelVersion
@onready var author = $HBoxContainer/LabelAuthor

var mod_path: String
var folder: bool
var collapsed: bool
var selected: bool
var top: bool
var bottom: bool
var children_entries: Array

func _ready() -> void:
	Global.expand_collapse.connect(_expand_collapse)
	mod_name.text=mod_path.right(mod_path.length()-mod_path.rfind("/")-1)
	if FileAccess.file_exists(mod_path):
		folder = false
	else:
		folder = true
		button_collapse.visible = true
		button_open.visible = true
		button_link.visible = true
		sep.visible = true
		vbox.visible = true
		bottom = true
		var dir = DirAccess.open(mod_path)
		if dir == null:
			printerr("Could not open directory: ", mod_path)
			return
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var mod_entry = load("res://ModContainer.tscn").instantiate()
			mod_entry.mod_path=mod_path.path_join(file_name)
			vbox.add_child(mod_entry)
			children_entries.append(mod_entry)
			mod_entry.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			if DirAccess.dir_exists_absolute(mod_entry.mod_path):
				bottom=false
			file_name = dir.get_next()
		dir.list_dir_end()
		for child_entry in children_entries:
			if child_entry.mod_name.text.contains("info.json"):
				var json_as_text = FileAccess.get_file_as_string(child_entry.mod_path)
				var json_as_dict : Dictionary = JSON.parse_string(json_as_text)
				if json_as_dict:
					$WindowLink.file_path = child_entry.mod_path
					if json_as_dict.has("name"):
						mod_name.text = json_as_dict.get("name")
					if json_as_dict.has("version"):
						version.text = json_as_dict.get("version")
					if json_as_dict.has("author"):
						author.text = json_as_dict.get("author")
					if json_as_dict.has("mod_page"):
						mod_name.uri = json_as_dict.get("mod_page")
					if mod_name.uri != "":
						mod_name.set_underline_mode(LinkButton.UNDERLINE_MODE_ON_HOVER)
		config.load("user://config.cfg")
		button_collapse.button_pressed = config.get_value("Folders",mod_name.text,false)
		checkbox.button_pressed = Global.mod_array.keys().has(mod_name.text)
	if children_entries.is_empty():
		bottom = false
		vbox.visible = false
		sep.visible = false

func _on_check_box_toggled(toggled_on: bool) -> void:
	selected = toggled_on
	for child_entry in children_entries:
		child_entry.checkbox.disabled = toggled_on
		child_entry.checkbox.button_pressed = toggled_on

func _on_button_collapse_toggled(toggled_on: bool) -> void:
	if toggled_on:
		button_collapse.text = " ▶ "
		sep.visible = false
		vbox.visible = false
	else:
		button_collapse.text = " ▼ "
		sep.visible = true
		vbox.visible = true
	config.load("user://config.cfg")
	config.set_value("Folders",mod_name.text,toggled_on)
	config.save("user://config.cfg")

func _expand_collapse(tags: String, value, toggled_on):
	if get(tags) == value:
		if folder:
			button_collapse.button_pressed = toggled_on

func _on_button_open_folder_pressed() -> void:
	OS.shell_open(mod_path)

func _on_button_mod_name_pressed() -> void:
	if !folder:
		var uri = get_parent().get_parent().mod_name.uri
		if uri:
			OS.shell_open(uri)

func _on_button_link_pressed() -> void:
	$WindowLink.visible = true
	var data = {}
	var file = FileAccess.open(mod_path+"/info.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(content)
		if parse_result == OK:
			data = json.data
		else:
			push_error("Failed to parse JSON: ", json.get_error_message())
	else:
		push_error("Failed to open file for reading: ", mod_path+"/info.json")
	
	if data.has("characters"):
		for child in $WindowLink/VBoxContainer/AspectRatioContainer/Panel/MarginContainer/GridContainer.get_children():
			if data["characters"].has(child.name):
				child.button_pressed = true
			else:
				child.button_pressed = false
	else:
		print(data)
