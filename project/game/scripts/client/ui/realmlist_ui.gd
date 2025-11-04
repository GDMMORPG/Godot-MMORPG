extends Control

const RealmListRowUI = preload("res://scripts/client/ui/realmlist_row_ui.gd")
const RealmListRowScene = preload("res://scenes/ui/login/realmlist_row.tscn")

@export_file("*.tscn") var character_selection: String
@onready var realms_container: VBoxContainer = %RealmsContainer

const REALM_SETTINGS: String = "user://%s/realms.json"

func _ready() -> void:
	self.visible = false

func _login_ui_state_changed(new_state: int) -> void:
	match new_state:
		2: # CONNECTING
			load_realmlist(true)

func load_realmlist(skippable: bool = false) -> void:
	var realm_list: Array = await Gateway.get_realmlist()

	if skippable:
		var oauth_url: String = Gateway.get_url()
		var oauth_url_hex: String = oauth_url.to_utf8_buffer().hex_encode()
		var realm_settings: Dictionary = load_server_settings(oauth_url_hex)
		if not realm_settings.is_empty():
			Log.info("Loaded server settings for realm: ", oauth_url_hex)
			if realm_settings.has('last_realm'):
				var last_realm: String = realm_settings['last_realm']
				Log.info("Last realm: ", last_realm)
				return # Skip realmlist if last realm is set

	for child in realms_container.get_children():
		child.queue_free()

	for realm_data in realm_list:
		var realm_row: RealmListRowUI = RealmListRowScene.instantiate()
		realm_row.data = realm_data
		realms_container.add_child(realm_row)
		realm_row.connect_button.pressed.connect(func () -> void:
			var realm_address: String = realm_data.get("address", "")
			if realm_address == "":
				Log.error("Realm address is empty.")
				return
			Log.info("User selected realm with address: ", realm_address)
			ClientInit.set_realm_address(realm_address)
			get_tree().change_scene_to_file(character_selection)
		)

	visible = true

### Load server settings from file.
func load_server_settings(realm: String) -> Dictionary:
	var path: String = REALM_SETTINGS % realm
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Log.error("Failed to open server settings file: ", path)
		return {}
	var content: String = file.get_as_text()
	file.close()
	var settings: Dictionary = JSON.parse_string(content)
	return settings
