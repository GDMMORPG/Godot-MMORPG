extends Control

@onready var location_icon: TextureRect = $LocationIcon
@onready var connection_icon: TextureRect = $ConnectionIcon
@onready var name_label: RichTextLabel = $NameLabel
@onready var connect_button: Button = $ConnectButton

const LOCATION_ICON: Dictionary = {
	"US": preload("res://content/flaticons/flags/united-states.png"),
	"UK": preload("res://content/flaticons/flags/united-kingdom.png"),
	"FR": preload("res://content/flaticons/flags/france.png"),
	"DE": preload("res://content/flaticons/flags/germany.png"),
	"IT": preload("res://content/flaticons/flags/italy.png"),
}

const CONNECTION_ICON: Dictionary = {
	"low": preload("res://content/material-icons/wifi_1_bar_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.png"),
	"medium": preload("res://content/material-icons/wifi_2_bar_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.png"),
	"high": preload("res://content/material-icons/wifi_24dp_E3E3E3_FILL0_wght400_GRAD0_opsz24.png"),
}
const CONNECTION_COLORS: Dictionary = {
	"low": Color.RED,
	"medium": Color.YELLOW,
	"high": Color.GREEN,
}

var data: Dictionary:
	set(value):
		data = value
		if self.is_node_ready():
			_update_ui()

func _ready() -> void:
	_update_ui()

	# Set up a timer to update the ping every 30 seconds.
	var timer: Timer = Timer.new()
	timer.wait_time = 30.0
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_update_ui)
	add_child(timer)

func _update_ui() -> void:
	name_label.text = data.get("name", "Unknown Realm")
	location_icon.texture = LOCATION_ICON.get(data.get("location-flag", "US"), LOCATION_ICON["US"]) as Texture2D
	location_icon.tooltip_text = data.get("location", "Unknown Location")
	var ping: int = await _ping_test()
	var selected_texture: Texture2D = CONNECTION_ICON["low"] as Texture2D
	var selected_color: Color = CONNECTION_COLORS["low"]
	var selected_tooltip: String = "Connection: Unreachable"
	
	if ping != -1:
		if ping < 100:
			selected_texture = CONNECTION_ICON["high"] as Texture2D
			selected_color = CONNECTION_COLORS["high"]
			selected_tooltip = "Connection: Excellent (%d ms)" % ping
		elif ping < 200:
			selected_texture = CONNECTION_ICON["medium"] as Texture2D
			selected_color = CONNECTION_COLORS["medium"]
			selected_tooltip = "Connection: Fair (%d ms)" % ping
		else:
			selected_texture = CONNECTION_ICON["low"] as Texture2D
			selected_color = CONNECTION_COLORS["low"]
			selected_tooltip = "Connection: Poor (%d ms)" % ping

	connection_icon.texture = selected_texture
	connection_icon.modulate = selected_color
	connection_icon.tooltip_text = selected_tooltip

func _ping_test() -> int:
	var address: String = data.get("address", "")
	var ip: String = address
	var port: int = 4242
	if address.find(":") != -1:
		var parts: Array = address.split(":")
		ip = parts[0]
		port = int(parts[1])
	
	var tcp: StreamPeerTCP = StreamPeerTCP.new()
	var start_time := Time.get_ticks_msec()

	var err := tcp.connect_to_host(ip, port)
	if err != OK:
		return -1
	
	while tcp.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		if get_tree() == null:
			return -1 # Tree was changed.
		await get_tree().process_frame

	if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return -1

	var end_time := Time.get_ticks_msec()
	var ping: int = end_time - start_time

	return ping
