class_name ServerInit extends Node

static var _instance : ServerInit = null

const GAMESERVER_PORT: int = 4242
var _gameserver_socket: ENetMultiplayerPeer

func _ready() -> void:
	_instance = self

	_initialize()

static func get_instance() -> ServerInit:
	return _instance

func _initialize() -> void:
	_setup_server()

func _setup_server() -> void:
	_gameserver_socket = ENetMultiplayerPeer.new()
	var result = _gameserver_socket.create_server(GAMESERVER_PORT, 32)
	if result != OK:
		Log.error("Failed to create server on port %d" % GAMESERVER_PORT)
		Log.error("Error code: %d" % result)
		Log.fatal("Reason: %s" % error_string(result))
		return
	multiplayer.multiplayer_peer = _gameserver_socket
	Log.info("Server started on port %d" % GAMESERVER_PORT)