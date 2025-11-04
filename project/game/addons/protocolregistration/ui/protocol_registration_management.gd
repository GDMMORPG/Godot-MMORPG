@tool
extends Window

const PROTOCOL_ROW_SCENE := preload("res://addons/protocolregistration/ui/protocol_row.tscn")
const ProtocolRow := preload("res://addons/protocolregistration/ui/protocol_row.gd")
const CustomProtocols := preload("res://addons/protocolregistration/custom_protocols.gd")

var protocols_container: VBoxContainer
var custom_protocols_resource: CustomProtocols = null

var _tracked: Dictionary[int, ProtocolRow] = {}

func _ready() -> void:
	close_requested.connect(queue_free)
	
	if custom_protocols_resource == null:
		push_error("CustomProtocols resource is null in ProtocolRegistrationManagement")
		# queue_free()
		return
	
	protocols_container = %ProtocolsContainer
	_reconstruct()

func _reconstruct() -> void:
	_tracked.clear()

	for child in protocols_container.get_children():
		child.queue_free()

	var index: int = 0
	for protocol in custom_protocols_resource.protocols:
		var protocol_row : ProtocolRow = _generate_protocol_row(index, protocol)
		_tracked[index] = protocol_row
		protocols_container.add_child(protocol_row)
		protocol_row.protocol_name = protocol
		index += 1

func _on_add_protocol_button_pressed() -> void:
	var index: int = _tracked.size()
	var protocol_row : ProtocolRow = _generate_protocol_row(index)
	_tracked[index] = protocol_row
	custom_protocols_resource.protocols.append("")
	custom_protocols_resource.Save()
	protocols_container.add_child(protocol_row)

func _generate_protocol_row(index: int, name: String = "") -> ProtocolRow:
	var protocol_row : ProtocolRow = PROTOCOL_ROW_SCENE.instantiate()
	protocol_row.protocol_management = self
	protocol_row.request_delete.connect(func() -> void:
		custom_protocols_resource.protocols.remove_at(index)
		custom_protocols_resource.Save()
		_reconstruct() # Rebuild to update indices
	)
	protocol_row.on_edit_name_changed.connect(func(new_name: String) -> void:
		custom_protocols_resource.protocols[index] = new_name
		custom_protocols_resource.Save()
	)
	return protocol_row
