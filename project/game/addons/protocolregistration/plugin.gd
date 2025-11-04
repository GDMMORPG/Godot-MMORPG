@tool
extends EditorPlugin

const PROTOCOL_REGISTRATION_MANAGEMENT_SCENE := preload("res://addons/protocolregistration/ui/protocol_registration_management.tscn")
const CustomProtocols := preload("res://addons/protocolregistration/custom_protocols.gd")
const ProtocolRegistrationManagement := preload("res://addons/protocolregistration/ui/protocol_registration_management.gd")

const ProtocolRegistryExporter := preload("res://addons/protocolregistration/export.gd")

var _dialog: ProtocolRegistrationManagement = null
var _saved_protocols: CustomProtocols = null
var _exporter: ProtocolRegistryExporter = null

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_tool_menu_item("Protocol Registration Management", _on_request_protocol_registration_management)
	_saved_protocols = CustomProtocols.LoadOrCreate() as CustomProtocols

	_exporter = ProtocolRegistryExporter.new()
	add_export_plugin(_exporter)

func _exit_tree() -> void:
	# Cleanup of the plugin goes here.
	remove_tool_menu_item("Protocol Registration Management")
	remove_export_plugin(_exporter)

func _on_request_protocol_registration_management() -> void:
	# Cleanup old dialog if it exists
	if _dialog:
		_dialog.queue_free()
		_dialog = null
	
	_dialog = PROTOCOL_REGISTRATION_MANAGEMENT_SCENE.instantiate()
	_dialog.custom_protocols_resource = _saved_protocols
	get_editor_interface().get_editor_main_screen().add_child(_dialog)
	_dialog.popup_centered()
