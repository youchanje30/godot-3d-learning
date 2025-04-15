extends Node3D

class_name NavMeshBaker

signal baking_completed(region_id: String)
signal baking_failed(region_id: String, error: String)

var navigation_mesh: NavigationMesh
var region: NavigationRegion3D

func _init(nav_region: NavigationRegion3D) -> void:
	region = nav_region
	navigation_mesh = NavigationMesh.new()

func configure_mesh(settings: NavigationSettings) -> void:
	navigation_mesh.agent_radius = settings.agent_radius
	navigation_mesh.agent_height = settings.agent_height
	navigation_mesh.agent_max_slope = settings.max_slope
	
	# 추가 설정
	navigation_mesh.cell_size = 0.25
	navigation_mesh.cell_height = 0.25
	navigation_mesh.edge_max_length = 1.0
	navigation_mesh.region_min_size = 1.0

func bake_region(region_id: String, geometry_nodes: Array) -> void:
	# 지오메트리 수집
	var geometries = []
	for node in geometry_nodes:
		if node is MeshInstance3D:
			geometries.append(node.mesh)
	
	if geometries.is_empty():
		emit_signal("baking_failed", region_id, "No geometry found")
		return
	
	# NavMesh 생성
	navigation_mesh.create_from_mesh_arrays(geometries)
	
	# 결과 적용
	region.navigation_mesh = navigation_mesh
	emit_signal("baking_completed", region_id)

func save_navmesh(region_id: String) -> void:
	var save_path = "res://Navigation/NavMesh/Baked/" + region_id + "_navmesh.res"
	var error = ResourceSaver.save(navigation_mesh, save_path)
	
	if error != OK:
		push_error("Failed to save NavMesh: " + str(error)) 
