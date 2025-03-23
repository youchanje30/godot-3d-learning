extends Node3D

@export var size : Vector3
@export var passages : Array[Node3D]
@onready var area_3d: Area3D = $"Room Surface/Area3D"

func get_size()->Vector3:
	return size

func get_passage_data():
	var data = []
	for passage in passages:
		var add = []
		add.append(passage.global_position)
		#add.append(passage.get_direction())
		add.append(passage.get_angle())
		data.append(add)
	return data

#func _process(delta: float) -> void:
	#print(area_3d.has_overlapping_areas())

func has_overlapping()->bool:
	return area_3d.has_overlapping_areas()

func Attach(pos, angle):
	var room_size = get_size()
	if angle == 90 or angle == -90:
		room_size = Vector3(room_size.z, room_size.y, room_size.x)
	var attach_dir = Vector3(int(sin(deg_to_rad(angle))), 0, int(cos(deg_to_rad(angle))))
	var new_room_pos = pos + attach_dir * (room_size / 2.0)
	
	# set angle, rotate
	self.global_position = new_room_pos
	set_global_rotation_degrees(Vector3(0, angle, 0))
