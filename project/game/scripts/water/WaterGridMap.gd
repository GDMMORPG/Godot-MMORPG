@tool
class_name WaterGridMap extends GridMap

@export var water_material: Material

func _ready() -> void:
	mesh_library = MeshLibrary.new()
	mesh_library.create_item(0)

	cell_size_changed.connect(_on_cell_size_changed)
	_on_cell_size_changed()

func _on_cell_size_changed() -> void:
	var water_mesh = BoxMesh.new()
	water_mesh.size = cell_size
	water_mesh.material = water_material
	mesh_library.set_item_mesh(0, water_mesh)
