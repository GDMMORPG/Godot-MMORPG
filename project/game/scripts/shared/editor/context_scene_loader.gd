@tool
class_name ContextSceneLoader extends Node

enum Context {
	NONE = 0,
	CLIENTSIDE = 1 << 0,
	SERVERSIDE = 1 << 1,
	EDITOR_ONLY = 1 << 2,
	BOTH = CLIENTSIDE | SERVERSIDE
}

@export_flags("ClientSide:1", "ServerSide:2", "EditorOnly:4", "Both:3") var context: int = Context.NONE

@export_file("*.tscn") var append_scene: String = ""
var _append_scene_localizedpath: String = ""
@export var disable_saving: bool = false

@export_tool_button("Load Scene") var load_scene_button: Callable = _ready

var scene_instance: Node = null
var _saving: bool = false

func _ready() -> void:
	# Clear all existing children.
	_saving = true
	for child in get_children():
		child.free()
	_saving = false

	# Check if the context is correct.
	var should_run = false
	
	# Check if EDITOR_ONLY flag is set and we're in editor
	if context & Context.EDITOR_ONLY != 0 and Engine.is_editor_hint():
		should_run = true
	
	# Check if SERVERSIDE flag is set and we're in server context
	if context & Context.SERVERSIDE != 0 and ContextInit.current_context == ContextInit.Context.SERVER:
		should_run = true
	
	# Check if CLIENTSIDE flag is set and we're in client context
	if context & Context.CLIENTSIDE != 0 and ContextInit.current_context == ContextInit.Context.CLIENT:
		should_run = true
	
	# If no matching context found, return early
	if not should_run:
		return

	if append_scene == "":
		return

	if Engine.is_editor_hint():
		# Make sure this node is an editable instance in the editor.
		get_tree().edited_scene_root.set_editable_instance(self, true)

	# Check if the scene file exists.
	if FileAccess.file_exists(append_scene) == false:
		# During editor, warn the user and create a new scene upon saving.
		if Engine.is_editor_hint():
			push_warning("Scene file does not exist: %s. A new scene will be created upon saving." % append_scene)
			_append_scene_localizedpath = append_scene
			scene_file_path = append_scene
			_try_save_scene_instance()
		else: # In non-editor mode, just cleanup.
			queue_free()
		return

	# Convert the UID to a localized path.
	_append_scene_localizedpath = ResourceUID.uid_to_path(append_scene)

	var scene_resource = load(append_scene)
	if scene_resource == null:
		push_error("Failed to load scene: %s" % append_scene)
		return
	
	if scene_instance != null:
		scene_instance.free()

	scene_instance = scene_resource.instantiate()
	add_child(scene_instance)

	# Move all children out of the scene and into this node.
	_saving = true
	for child in scene_instance.get_children():
		child.reparent(self)
		child.owner = self
	scene_instance.queue_free()
	scene_instance = null
	_saving = false
	self.scene_file_path = append_scene

func _enter_tree() -> void:
	# Make sure the scene instance is editable.
	if Engine.is_editor_hint():
		self.child_order_changed.connect(_try_save_scene_instance)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		self.child_order_changed.disconnect(_try_save_scene_instance)


func _try_save_scene_instance() -> void:
	if disable_saving:
		return
	if not Engine.is_editor_hint():
		return
	if _saving:
		print("Save already in progress, skipping.")
		return

	_saving = true

	var scene: Node = Node.new()
	scene.name = "SceneRoot"
	get_tree().edited_scene_root.add_child.call_deferred(scene)

	self.child_order_changed.disconnect(_try_save_scene_instance)
	await get_tree().create_timer(0.1).timeout

	for child in get_children():
		child.reparent(scene)
		child.owner = scene

	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(scene)
	if result != OK:
		push_error("Failed to pack scene for saving: %s" % _append_scene_localizedpath)
		_saving = false
		return
	result = ResourceSaver.save(packed_scene, _append_scene_localizedpath)
	if result != OK:
		push_error("Failed to save scene: %s [%s]" % [_append_scene_localizedpath, error_string(result)])
		_saving = false
		return

	# Reparent children back to this node.
	for child in scene.get_children():
		child.reparent(self)
		child.owner = self

	# Free the temporary scene root.
	scene.queue_free()

	_saving = false
	self.child_order_changed.connect(_try_save_scene_instance)

	# print("Scene saved: %s" % _append_scene_localizedpath)
