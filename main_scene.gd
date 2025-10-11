extends Control

var config = ConfigFile.new()
var mod_array : Dictionary
var err : Error

@onready var WindowProfile: Window = $WindowProfile
@onready var mods_path : LineEdit = $VBoxContainer/TabContainer/Settings/HBoxMods/LineMods
@onready var game_path : LineEdit = $VBoxContainer/TabContainer/Settings/HBoxGame/LineGame
@onready var option_profile : OptionButton = $VBoxContainer/TabContainer/Settings/HBoxProfile/OptionProfile
@onready var button_browse_game : Button = $VBoxContainer/TabContainer/Settings/HBoxGame/ButtonBrowseGame
@onready var button_browse_mods : Button = $VBoxContainer/TabContainer/Settings/HBoxMods/ButtonBrowseMods
@onready var mod_list : VBoxContainer = $VBoxContainer/TabContainer/Mods/ScrollContainer/VBoxModsList

func _ready() -> void:
	config.load("user://config.cfg")
	load_settings()
	if game_path.text and mods_path.text:
		for mod in mod_list.get_children():
			mod_list.remove_child(mod)
			mod.queue_free()
		if not Global.profiles.has(Global.selected_profile):
			Global.selected_profile=Global.profiles.keys()[0]
		var ml = FileAccess.open(mods_path.text.path_join(Global.profiles[Global.selected_profile]), FileAccess.READ)
		if ml:
			mod_array = str_to_var(ml.get_as_text())
			ml.close()
		refresh_mod_list(mod_list,mods_path.text)
	var i : int = 0
	for profile in Global.profiles:
		option_profile.add_item(profile)
		if profile == config.get_value("Profiles","selected_profile","Default"):
			option_profile.select(i)
		i=i+1
	WindowProfile.hide()
	
func load_settings():
	err = config.load("user://config.cfg")
	Global.selected_profile = config.get_value("Profiles","selected_profile", "Default")
	mods_path.text = config.get_value("Directories", "Mods", "")
	game_path.text = config.get_value("Directories", "Game", "")
	var read_profiles = FileAccess.open(game_path.text + "/" + Global.PROFILES, FileAccess.READ)
	while read_profiles.get_position() < read_profiles.get_length():
		var json_string = read_profiles.get_line()
		var parse_result = JSON.to_native(JSON.parse_string(json_string))
		print("Parse result: ",parse_result)
		Global.profiles = parse_result
		Global.profiles.sort()
	read_profiles.close()

func _on_button_config_profile_pressed() -> void:
	if game_path.text == "":
		button_browse_game.modulate=Color.ORANGE
		var warning = AcceptDialog.new()
		warning.title = "Error: Game not found"
		warning.dialog_text = "Add the game directory first"
		add_child(warning)
		warning.popup_centered()
		return
	if mods_path.text == "":
		button_browse_mods.modulate=Color.ORANGE
		var warning = AcceptDialog.new()
		warning.title = "Error: Mod directory not found"
		warning.dialog_text = "Add the mods directory first"
		add_child(warning)
		warning.popup_centered()
		return
	WindowProfile.popup()
	
func _on_button_browse_mods_pressed() -> void:
	button_browse_mods.modulate=Color.WHITE
	var fd: FileDialog = FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = true
	add_child(fd)
	fd.dir_selected.connect(func(path: String) -> void:
		mods_path.text = path
		fd.queue_free()
		config.set_value("Directories","Mods",path)
		config.save("user://config.cfg")
		
		for mod in mod_list.get_children():
			mod_list.remove_child(mod)
			mod.queue_free()
		refresh_mod_list(mod_list, path)
	)
	fd.popup_centered()
	
	
func _on_button_browse_game_pressed() -> void:
	button_browse_game.modulate=Color.WHITE
	var fd: FileDialog = FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = true
	add_child(fd)
	fd.dir_selected.connect(func(path: String) -> void:
		game_path.text = path
		fd.queue_free()
		config.set_value("Directories","Game",path)
		config.save("user://config.cfg")
		if !FileAccess.file_exists(path + "/" + Global.PROFILES):
			print(Global.PROFILES+" doesn't exist, creating...")
			var save_file = FileAccess.open(path + "/" + Global.PROFILES, FileAccess.WRITE)
			var data = Global.profiles
			save_file.store_line(JSON.stringify(JSON.from_native(data)))
			print("data: ",JSON.stringify(JSON.from_native(data)))
			save_file.close()
		if FileAccess.file_exists(path + "/" + Global.PROFILES):
			print(Global.PROFILES + " exists. Now loading...")
			print(path + "/" + Global.PROFILES)
			var save_file = FileAccess.open(path + "/" + Global.PROFILES, FileAccess.READ)
			while save_file.get_position() < save_file.get_length():
				var json_string = save_file.get_line()
				var parse_result = JSON.to_native(JSON.parse_string(json_string))
				print("Parse result: ",parse_result)
				Global.profiles = parse_result
				Global.profiles.sort()
			save_file.close()
			option_profile.clear()
			for profile in Global.profiles:
				option_profile.add_item(profile)
	)
	fd.popup_centered()
	
func _on_button_open_mods_pressed() -> void:
	if mods_path.text != "OK" and DirAccess.dir_exists_absolute(mods_path.text):
		OS.shell_open(mods_path.text)
	else:
		push_error("Storage path is not set or invalid")
	
func _on_button_open_game_pressed() -> void:
	if DirAccess.dir_exists_absolute(game_path.text):
		OS.shell_open(game_path.text)
	else:
		push_error("Storage path is not set or invalid")
		
func _on_option_button_item_selected(index: int) -> void:
	Global.selected_profile=option_profile.get_item_text(index)
	config.set_value("Profiles","selected_profile",option_profile.get_item_text(index))
	config.save("user://config.cfg")
	var ml = FileAccess.open(mods_path.text.path_join(Global.profiles[Global.selected_profile]), FileAccess.READ)
	if ml:
		mod_array = str_to_var(ml.get_as_text())
		ml.close()
	else:
		mod_array.clear()
	for mod in mod_list.get_children():
		mod_list.remove_child(mod)
		mod.queue_free()
	refresh_mod_list(mod_list,mods_path.text)

func _on_button_refresh_list_pressed() -> void:
	var ml = FileAccess.open(mods_path.text.path_join(Global.profiles[Global.selected_profile]), FileAccess.READ)
	if ml:
		mod_array = str_to_var(ml.get_as_text())
		ml.close()
	for mod in mod_list.get_children():
		mod_list.remove_child(mod)
		mod.queue_free()
	if mods_path.text == "" or game_path.text == "":
		$VBoxContainer/TabContainer.current_tab=1
		$VBoxContainer/TabContainer/Settings/HBoxProfile/ButtonConfigProfile.emit_signal("pressed")
	else:
		refresh_mod_list(mod_list, config.get_value("Directories","Mods"))

func refresh_mod_list(list : VBoxContainer, path : String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		printerr("Could not open directory: ", path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if (not file_name.begins_with(".")) and (not file_name.ends_with(".ini")):
			var gc = GridContainer.new()
			var cb = CheckBox.new()
			var label = Label.new()
			list.add_child(gc)
			gc.name=file_name
			gc.columns=2
			gc.add_child(cb)
			cb.name=file_name
			cb.size_flags_vertical=Control.SIZE_EXPAND_FILL
			cb.set_meta("file_path", path.path_join(file_name))
			gc.add_child(label)
			label.text=file_name
			if dir.current_is_dir():
				var sep = VSeparator.new()
				var vbc = VBoxContainer.new()
				gc.add_child(sep)
				gc.add_child(vbc)
				cb.toggled.connect(func(toggled_on) -> void:
					var children_checkbox = cb.get_parent().get_child(-1).find_children("*", "CheckBox", true, false)
					for checkbox in children_checkbox:
						checkbox.button_pressed = toggled_on
						checkbox.disabled = toggled_on
					if not toggled_on:
						var parent_checkbox = cb.get_parent().get_parent().get_parent().get_child(0)
						if parent_checkbox is CheckBox:
							parent_checkbox.set_pressed_no_signal(false)
				)
				refresh_mod_list(vbc,path.path_join(file_name))
			else:
				cb.toggled.connect(func(toggled_on) -> void:
					if not toggled_on:
						var parent_checkbox = cb.get_parent().get_parent().get_parent().get_child(0)
						if parent_checkbox is CheckBox:
							parent_checkbox.set_pressed_no_signal(false)
				)
			if mod_array.keys().has(cb.name):
					cb.button_pressed = true
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_button_add_pressed() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = true
	add_child(fd)
	fd.dir_selected.connect(func(_path: String) -> void:
		fd.queue_free()
	)
	fd.popup_centered()

func _on_button_save_pressed() -> void:
	var loading_path = game_path.text.path_join("UNION/Content/Paks/~mods")
	var loaded_mod_array : Array[String]
	var dir = DirAccess.open(loading_path)
	if dir == null:
		printerr("Could not open directory: ", loading_path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			loaded_mod_array.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	mod_array.clear()
	mod_array.merge(add_mods(mod_list, mods_path.text))
	var add : Array[String]
	var remove : Array[String]
	for item : String in mod_array.keys():
		# Item is in mod_array but not in loaded_mod_array
		if not loaded_mod_array.has(item):
			add.append(mod_array[item])
	for item in loaded_mod_array:
		# Item is in loaded_mod_array but not in the mod_array
		if not mod_array.keys().has(item):
			remove.append(loading_path.path_join(item))
	var ml = FileAccess.open(mods_path.text.path_join(Global.profiles[Global.selected_profile]),FileAccess.WRITE)
	if ml:
		ml.store_string(str(mod_array))
		ml.close()
	remove_mods(remove)
	copy_mods(add, loading_path)
	print("Final array: ", mod_array)
	
func remove_mods(mods: Array[String]) -> void:
	for path in mods:
		if FileAccess.file_exists(path):
			# It's a file, delete it
			var error = DirAccess.remove_absolute(path)
			if error == OK:
				print("Successfully removed file: ", path)
			else:
				push_error("Failed to remove file '%s'. Error code: %s" % [path, error])
				
		elif DirAccess.dir_exists_absolute(path):
			# It's a directory, delete it recursively
			var error = DirAccess.remove_absolute(path)
			if error == OK:
				print("Successfully removed directory: ", path)
			else:
				# If simple remove failed, try recursive removal
				@warning_ignore("int_as_enum_without_cast")
				error = remove_directory_recursive(path)
				if error != OK:
					push_error("Failed to remove directory '%s'. Error code: %s" % [path, error])
		else:
			print("Path does not exist, skipping: ", path)

func remove_directory_recursive(dir_path: String) -> int:
	var dir_access = DirAccess.open(dir_path.get_base_dir())
	if not dir_access:
		return ERR_CANT_OPEN
		
	var error = _remove_directory_contents_recursive(dir_path)
	if error != OK:
		return error
	# Now remove the empty directory
	return DirAccess.remove_absolute(dir_path)

func _remove_directory_contents_recursive(dir_path: String) -> int:
	var dir_access = DirAccess.open(dir_path)
	if not dir_access:
		return ERR_CANT_OPEN
		
	dir_access.list_dir_begin()
	var file_name = dir_access.get_next()
	
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir_access.get_next()
			continue
			
		var full_path = dir_path.path_join(file_name)
		
		if dir_access.current_is_dir():
			# Recursively remove subdirectory
			var error = _remove_directory_contents_recursive(full_path)
			if error != OK:
				dir_access.list_dir_end()
				return error
			# Remove the now-empty directory
			error = DirAccess.remove_absolute(full_path)
			if error != OK:
				dir_access.list_dir_end()
				return error
		else:
			# Remove file
			var error = DirAccess.remove_absolute(full_path)
			if error != OK:
				dir_access.list_dir_end()
				return error
				
		file_name = dir_access.get_next()
	
	dir_access.list_dir_end()
	return OK
	
func copy_mods(sources: Array, destination: String) -> void:
	# Ensure the destination directory exists
	DirAccess.make_dir_recursive_absolute(destination)
	
	for source_path in sources:
		if FileAccess.file_exists(source_path):
			# It's a file, copy it
			var file_name = source_path.get_file()
			var dest_file_path = destination.path_join(file_name)
			var error = DirAccess.copy_absolute(source_path, dest_file_path)
			if error != OK:
				push_error("Failed to copy file '%s'. Error code: %s" % [source_path, error])
			else:
				print("Successfully copied file: ", source_path)
				
		elif DirAccess.dir_exists_absolute(source_path):
			# It's a directory, copy it recursively
			var dir_name = source_path.get_file()
			var dest_dir_path = destination.path_join(dir_name)
			copy_directory_recursive(source_path, dest_dir_path)
		else:
			push_warning("The path '%s' does not exist and will be skipped." % source_path)

func copy_directory_recursive(source_dir: String, dest_dir: String) -> void:
	# Create the destination directory
	var make_dir_error = DirAccess.make_dir_recursive_absolute(dest_dir)
	if make_dir_error != OK:
		push_error("Could not create destination directory '%s'. Error code: %s" % [dest_dir, make_dir_error])
		return

	# Open the source directory to list its contents
	var dir_access = DirAccess.open(source_dir)
	if dir_access:
		dir_access.list_dir_begin() # Start the file listing
		var file_name = dir_access.get_next()
		
		while file_name != "":
			# Skip special navigation entries '.' and '..'
			if file_name == "." or file_name == "..":
				file_name = dir_access.get_next()
				continue
				
			var source_item_path = source_dir.path_join(file_name)
			var dest_item_path = dest_dir.path_join(file_name)
			
			if dir_access.current_is_dir():
				# If the current item is a directory, recurse into it
				copy_directory_recursive(source_item_path, dest_item_path)
			else:
				# If it's a file, copy it
				var copy_error = DirAccess.copy_absolute(source_item_path, dest_item_path)
				if copy_error != OK:
					push_error("Failed to copy file '%s'. Error code: %s" % [source_item_path, copy_error])
				else:
					print("Successfully copied file: ", source_item_path)
			
			file_name = dir_access.get_next()
		dir_access.list_dir_end() # End the file listing
	else:
		push_error("Failed to open source directory: %s" % source_dir)

func add_mods(location: VBoxContainer, path : String) -> Dictionary:
	var mods : Dictionary
	var children_nodes = location.get_children()
	for node in children_nodes:
		for child in node.get_children():
			if child is CheckBox:
				if child.button_pressed and not child.disabled:
					print("Adding: ", child.get_meta("file_path"))
					mods[child.name]=child.get_meta("file_path")
			if child is VBoxContainer:
				mods.merge(add_mods(child,path.path_join(node.name)))
	return mods


func _on_button_play_pressed() -> void:
	$VBoxContainer/HBoxContainer/ButtonSave.emit_signal("pressed")
	var steam_url = "steam://launch/2486820"
	err = OS.shell_open(steam_url)
	if err != OK:
		printerr("Failed to launch Steam game: ", steam_url)
	else:
		print("Launched Steam game: ", steam_url)
