@tool
extends HBoxContainer

signal request_delete
signal on_edit_name_changed(new_name: String)

const ProtocolRegistrationManagement := preload("res://addons/protocolregistration/ui/protocol_registration_management.gd")

@onready var textedit: TextEdit = $TextEdit

var protocol_management: ProtocolRegistrationManagement = null
var protocol_name: String = "":
	set(value):
		textedit.text = value
	get:
		return textedit.text

func _ready() -> void:
	if textedit == null:
		push_error("TextEdit node is null in ProtocolRow")
		# queue_free()
		return
	if protocol_management == null:
		push_error("ProtocolRegistrationManagement instance is null in ProtocolRow")
		# queue_free()
		return

	textedit.text_changed.connect(_on_text_edit_text_changed)

func _on_text_edit_text_changed() -> void:
	on_edit_name_changed.emit(protocol_name)

func _on_request_delete() -> void:
	request_delete.emit()
