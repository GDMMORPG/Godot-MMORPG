class_name ClientInit extends Node

static var _instance : ClientInit = null

var _jwt_token: String = ""
var _realm_address: String = ""

func _ready() -> void:
	_instance = self

static func get_instance() -> ClientInit:
	return _instance

static func set_realm_address(address: String) -> void:
	_instance._realm_address = address

static func set_jwt_token(token: String) -> void:
	_instance._jwt_token = token