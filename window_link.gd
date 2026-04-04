extends Window

var file_path : String
var characters : Array[String]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_save_links_pressed() -> void:
	var data = {}
	var file = FileAccess.open(file_path, FileAccess.READ)
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
		push_error("Failed to open file for reading: ", file_path)
	
	for child in $VBoxContainer/AspectRatioContainer/Panel/MarginContainer/GridContainer.get_children():
		if child.button_pressed:
			characters.append(child.name)
	
	if data.has("characters"):
		data["characters"].append(characters)
	else:
		data["characters"]=characters
	
	var new_file = FileAccess.open(file_path, FileAccess.WRITE)
	if new_file:
		var json_string = JSON.stringify(data, "\t")
		new_file.store_string(json_string)
		new_file.close()
		print("Successfully wrote to ", file_path)
	else:
		push_error("Failed to open file for writing: ", file_path)


func _on_close_requested() -> void:
	visible = false
