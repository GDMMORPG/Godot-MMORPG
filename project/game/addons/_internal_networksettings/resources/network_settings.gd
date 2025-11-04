class_name NetworkSettings extends Resource

const LOCATION: String = "res://.godot/editor_network_settings.tres"

@export var gateway_url: String = "http://localhost:8080"
@export var gateway_server_token: String = "default_server_token"

static func Load() -> NetworkSettings:
	if not ResourceLoader.exists(LOCATION):
		return null # Don't send errors if the file doesn't exist
	var settings: NetworkSettings = ResourceLoader.load(LOCATION)
	return settings

func Save() -> void:
	ResourceSaver.save(self, LOCATION)

static func LoadOrCreate() -> NetworkSettings:
	var settings: NetworkSettings = Load()
	if settings == null:
		settings = NetworkSettings.new()
		settings.Save()
	return settings