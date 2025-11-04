@tool
extends Resource

const PATH := "res://addons/protocolregistration/saved_protocols.tres"

@export var protocols: Array[String] = []

func Save() -> void:
	ResourceSaver.save(self, PATH)

static func Load() -> Resource:
	if FileAccess.file_exists(PATH):
		return load(PATH)
	return null

static func LoadOrCreate() -> Resource:
	var resource: Resource = Load()
	if resource == null:
		resource = Resource.new()
		ResourceSaver.save(resource, PATH)
	return resource
