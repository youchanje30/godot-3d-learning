extends Node
class_name RoomFactory

var room_templates: Dictionary = {}
var room_path: String

func _init(template_path: String) -> void:
	room_path = template_path
	load_templates()

func load_templates() -> void:
	var dir = DirAccess.get_files_at(room_path)
	if dir.is_empty():
		push_error("Failed to load room templates from: " + room_path)
		return
		
	for file_name in dir:
		if file_name.ends_with(".tscn"):
			var template = load(room_path + "/" + file_name)
			if template:
				room_templates[file_name] = template

func create_room(template_name: String) -> Room:
	if not room_templates.has(template_name):
		push_error("Room template not found: " + template_name)
		return null
		
	var instance = room_templates[template_name].instantiate()
	if not instance is Room:
		push_error("Invalid room template: " + template_name)
		instance.queue_free()
		return null
		
	return instance

func create_random_room() -> Room:
	if room_templates.is_empty():
		push_error("No room templates available")
		return null
		
	var template_name = room_templates.keys()[randi() % room_templates.size()]
	return create_room(template_name) 