@tool
class_name ZoneGridMap
extends GridMap

@export var zones: Array[ZoneData] = []
@export var transparency: float = 0.3

@export_tool_button("Refresh Zones") var refresh_zones_button: Callable = _on_cell_size_changed

func _ready() -> void:
	set_notify_transform(true)
	set_process_input(Engine.is_editor_hint())
	set_process(Engine.is_editor_hint())
	set_physics_process(false)

	# Setup mesh library.
	cell_size_changed.connect(_on_cell_size_changed)
	_on_cell_size_changed()

func _on_cell_size_changed() -> void:
	mesh_library = MeshLibrary.new()
	for i in zones.size():
		mesh_library.create_item(i)
		var zone = zones[i]
		var zone_mesh: Mesh = null
		if Engine.is_editor_hint():
			zone_mesh = BoxMesh.new()
			zone_mesh.size = Vector3(cell_size.x, cell_size.z, cell_size.y)
			var zone_material = StandardMaterial3D.new()
			zone_material.albedo_color = zone.editor_color
			zone_material.albedo_color.a = transparency
			zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			zone_material.no_depth_test = true
			zone_material.flags_transparent = true
			zone_mesh.material = zone_material
		else:
			zone_mesh = Mesh.new() # Empty mesh for runtime, since this is purely data.
		mesh_library.set_item_mesh(i, zone_mesh)
		mesh_library.set_item_name(i, zone.name)
