extends Window

var entries = ButtonGroup.new()
var passed : bool = true

@onready var profile_list : VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var main_scene : Control = $".."
@onready var button_ok : Button = $VBoxContainer/HBoxWindowProfile/ButtonOKProfile

var temp_profiles : Dictionary = {}

func _ready() -> void:
	entries.allow_unpress = true

func _on_button_ok_profile_pressed() -> void:
	passed = true
	temp_profiles = {}
	for profile in profile_list.get_children():
		profile.modulate=Color.WHITE
		#--------Check file names--------#
		var profile_name = profile.get_child(0).get_child(0)
		var profile_file = profile.get_child(0).get_child(-1)
		if not profile_file.text.ends_with(".ini"):
			profile_file.text=profile_file.text+".ini"
			highlight(profile,Color.GREEN)
		var invalid_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
		for ch in invalid_chars:
			if profile_file.text.contains(ch):
				profile_file.text=profile_file.text.replace(ch,"_")
				highlight(profile,Color.GREEN)
		if profile_file.text.contains(" "):
			profile_file.text=profile_file.text.replace(" ","")
		if profile_file.text == "" or profile_file.text == ".ini":
			profile_file.text = ""
			highlight(profile,Color.RED)
		#--------Check duplicates--------#
		if temp_profiles.has(profile_name.text) or profile_file.text in temp_profiles.values():
			highlight(profile,Color.RED)
		
		if profile.modulate == Color.WHITE:
			temp_profiles[profile_name.text]=profile_file.text
		
	if passed:
		#--------Record to Global--------#
		Global.profiles=temp_profiles
		#--------Add To Main Settings--------#
		button_ok.text="OK"
		button_ok.modulate=Color.WHITE
		main_scene.option_profile.clear()
		for profile in Global.profiles:
			main_scene.option_profile.add_item(profile)
		#--------Write to File--------#
		var profiles_path = main_scene.config.get_value("Directories", "Game")
		var save_file = FileAccess.open(profiles_path + "/" + Global.PROFILES, FileAccess.WRITE)
		var data = Global.profiles
		save_file.store_line(JSON.stringify(JSON.from_native(data)))
		print("data: ",JSON.stringify(JSON.from_native(data)))
		save_file.close()
		#--------Close--------#
		hide()
		
func highlight(line : CheckButton, colour : Color):
	passed=false
	line.modulate=colour
	button_ok.modulate=colour
	button_ok.text="Confirm?"

func _on_button_create_profile_pressed() -> void:
	add_line("New Profile", "NewProfile.ini")

func _on_about_to_popup() -> void:
	for n in profile_list.get_children():
		if n is CheckButton:
			profile_list.remove_child(n)
			n.queue_free()
	for profile in Global.profiles:
		add_line(profile, Global.profiles[profile])

func add_line(profile, file):
	print("Adding ",profile,":","file")
	var cb = CheckButton.new()
	var hbc = HBoxContainer.new()
	var line_name = LineEdit.new()
	var line_file = LineEdit.new()
	profile_list.add_child(cb)
	cb.name=profile
	cb.button_group = entries
	cb.add_child(hbc)
	hbc.size.x=600
	hbc.add_child(line_name)
	line_name.text = profile
	line_name.name = profile
	line_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	line_name.text_changed.connect(on_text_changed.bind(line_name))
	line_name.focus_entered.connect(select_profile.bind(line_name))
	line_name.placeholder_text = "Enter Profile Name"
	hbc.add_child(line_file)
	line_file.text = file
	line_file.name = file
	line_file.placeholder_text = "Enter Filename.ini"
	line_file.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	line_file.text_changed.connect(on_text_changed.bind(line_file))
	line_file.focus_entered.connect(select_profile.bind(line_file))

func on_text_changed(_new_text, line_file):
	button_ok.text = "OK"
	line_file.get_parent().get_parent().modulate=Color.WHITE
	button_ok.modulate=Color.WHITE

func select_profile(profile):
	profile.get_parent().get_parent().set_pressed(true)


func _on_button_remove_profile_pressed() -> void:
	for profile in profile_list.get_children():
		if profile.button_pressed:
			profile_list.remove_child(profile)
			profile.queue_free()
