extends Node3D

@export var monster_scene: PackedScene
@export var num_monsters: int = 3
@export var spawn_delay: float = 0.5

@onready var navigation_manager = $NavigationManager
@onready var spawn_points = $SpawnPoints
@onready var player = $Player

var active_monsters: Array[Node] = []
var path_visualization: MeshInstance3D
var debug_path_points: Array[MeshInstance3D] = []

func _ready() -> void:
	# 내비게이션 메시 베이킹
	await get_tree().create_timer(0.1).timeout
	$NavigationRegion3D.bake_navigation_mesh()
	
	# 몬스터 스폰
	spawn_monsters()
	
	# 디버그 시각화 설정
	setup_debug_visualization()

func spawn_monsters() -> void:
	for i in range(num_monsters):
		await get_tree().create_timer(spawn_delay).timeout
		spawn_monster()

func spawn_monster() -> void:
	if not monster_scene:
		push_error("Monster scene not set!")
		return
	
	var spawn_points_array = spawn_points.get_children()
	if spawn_points_array.is_empty():
		return
	
	var spawn_point = spawn_points_array[randi() % spawn_points_array.size()]
	var monster = monster_scene.instantiate()
	add_child(monster)
	monster.global_position = spawn_point.global_position
	active_monsters.append(monster)

func setup_debug_visualization() -> void:
	path_visualization = $Debug/PathVisualization
	path_visualization.visible = false  # 초기에는 숨김

func _process(_delta: float) -> void:
	# 디버그 시각화 업데이트
	if Input.is_action_just_pressed("toggle_debug"):
		toggle_debug_visualization()
	
	if path_visualization.visible:
		update_debug_visualization()

func toggle_debug_visualization() -> void:
	path_visualization.visible = not path_visualization.visible
	
	# 기존 디버그 포인트 정리
	for point in debug_path_points:
		point.queue_free()
	debug_path_points.clear()

func update_debug_visualization() -> void:
	for monster in active_monsters:
		if not is_instance_valid(monster):
			continue
			
		var agent_navigator = monster.get_node("AgentNavigator")
		if not agent_navigator:
			continue
			
		# 현재 경로 가져오기
		var current_path = navigation_manager.get_current_path(monster.get_instance_id())
		
		# 경로 시각화
		visualize_path(current_path)

func visualize_path(path: Array) -> void:
	# 기존 포인트 제거
	for point in debug_path_points:
		point.queue_free()
	debug_path_points.clear()
	
	# 새 경로 시각화
	for point in path:
		var new_point = path_visualization.duplicate()
		add_child(new_point)
		new_point.global_position = point
		new_point.visible = true
		debug_path_points.append(new_point)

# 플레이어 이동 처리 (테스트용)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = from
		query.to = to
		
		var result = space_state.intersect_ray(query)
		if result:
			player.global_position = result.position 
