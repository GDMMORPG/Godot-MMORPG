extends Node

enum Context {
	UNKNOWN = 0,
	SERVER = 1,
	CLIENT = 2,
}

var current_context: Context = Context.UNKNOWN

func _ready() -> void:
	if Engine.is_editor_hint():
		return # Do not run in editor mode.

	if OS.has_feature("dedicated_server"):
		_server_setup()
	else:
		_client_setup()

func _server_setup() -> void:
	current_context = Context.SERVER
	
	const LOAD_SCRIPT: String = "res://scripts/server/ServerInit.gd"
	var server_node: Node = Node.new()
	server_node.name = "ServerInit"
	var server_script: Script = load(LOAD_SCRIPT)
	server_node.set_script(server_script)
	add_child(server_node)

func _client_setup() -> void:
	current_context = Context.CLIENT

	const LOAD_SCRIPT: String = "res://scripts/client/ClientInit.gd"
	var client_node: Node = Node.new()
	client_node.name = "ClientInit"
	var client_script: Script = load(LOAD_SCRIPT)
	client_node.set_script(client_script)
	add_child(client_node)