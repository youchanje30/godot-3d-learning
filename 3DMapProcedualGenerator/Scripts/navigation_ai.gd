extends CharacterBody3D


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

func _unhandled_input(event: InputEvent) -> void:
	## 현재는 위치를 랜덤으로 설정하나, 랜덤으로 주변 위치에 대해 이동 가능한 정점으로 도착점을 정하면 되겠다.
	if event.is_action_pressed("ui_accept"):
		var random_pos := Vector3.ZERO
		random_pos.x = randf_range(-5.0, 5.0)
		random_pos.z = randf_range(-5.0, 5.0)
		navigation_agent_3d.target_position = random_pos

func _physics_process(delta: float) -> void:
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity = direction * 5
	move_and_slide()
