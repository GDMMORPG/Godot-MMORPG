extends Node

signal on_change_state(new_state: State)

enum State {
	NONE,
	LOGGING_IN,
	CONNECTING,
	ERROR
}

var current_state: State = State.NONE

@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_panel_title: Label = $InfoPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var info_panel_message: RichTextLabel = $InfoPanel/MarginContainer/VBoxContainer/MessageLabel
@onready var info_panel_button: Button = $InfoPanel/MarginContainer/VBoxContainer/Button
@onready var realm_list: Node = $RealmList

func _ready() -> void:
	info_panel.visible = false

func _on_button_on_authenticated(jwt: String) -> void:
	info_panel.visible = true
	info_panel_title.text = "Connecting"
	info_panel_message.text = "Collecting Realmlist..."
	info_panel_button.visible = true
	info_panel_button.text = "Cancel"
	info_panel_button.disabled = false

	ClientInit.set_jwt_token(jwt)
	current_state = State.CONNECTING
	on_change_state.emit(current_state)

func _on_button_on_failure(reason: String) -> void:
	info_panel.visible = true
	info_panel_title.text = "Error"
	info_panel_message.text = "%s" % reason
	info_panel_button.visible = true
	info_panel_button.text = "Close"
	info_panel_button.disabled = false
	current_state = State.ERROR
	on_change_state.emit(current_state)

func _on_login_button_pressed() -> void:
	info_panel.visible = true
	info_panel_title.text = "Logging In"
	info_panel_message.text = "Please wait while we log you in..."
	info_panel_button.visible = true
	info_panel_button.text = "Cancel"
	info_panel_button.disabled = false
	current_state = State.LOGGING_IN
	on_change_state.emit(current_state)

func _on_infopanel_button_pressed() -> void:
	match current_state:
		State.LOGGING_IN:
			AuthAPI.cancel()
			info_panel.visible = false
			current_state = State.NONE
			on_change_state.emit(current_state)
		State.CONNECTING:
			# Handle connecting state cancellation if needed
			info_panel.visible = false
			current_state = State.NONE
			on_change_state.emit(current_state)
			# Todo :: Cancel connection attempt
		State.ERROR:
			info_panel.visible = false
			current_state = State.NONE
			on_change_state.emit(current_state)


func _on_realm_list_on_user_prompt_realmlist() -> void:
	info_panel.visible = false
	current_state = State.NONE
	on_change_state.emit(current_state)
	realm_list.visible = true
