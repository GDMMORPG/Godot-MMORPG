class_name Log extends RefCounted

enum VerbosityLevel {
	FATAL,
	ERROR,
	WARNING,
	INFO,
	DEBUG,
	TRACE,
}

static var verbosity_level: int = VerbosityLevel.DEBUG

static func info(...message: Array) -> void:
	if verbosity_level < VerbosityLevel.INFO:
		return
	_print_color("<%s> [INFO]: %s" % [_identifier(), " ".join(message)], Color.WHITE)

static func warning(...message: Array) -> void:
	if verbosity_level < VerbosityLevel.WARNING:
		return
	_print_color("<%s> [WARNING]: %s" % [_identifier(), " ".join(message)], Color.YELLOW)

static func error(...message: Array) -> void:
	if verbosity_level < VerbosityLevel.ERROR:
		return
	_print_color("<%s> [ERROR]: %s" % [_identifier(), " ".join(message)], Color.RED)

static func error_trace(...message: Array) -> void:
	if verbosity_level < VerbosityLevel.ERROR:
		return
	_print_color("<%s> [ERROR]: %s" % [_identifier(), " ".join(message)], Color.RED)
	var stack: Array = get_stack()
	for frame in stack:
		var bt_data = BacktraceData.new(frame)
		_print_color("    at %s:%d in function %s" % [bt_data.source, bt_data.line, bt_data.function], Color.RED)

static func debug(...message: Array) -> void:
	if verbosity_level < VerbosityLevel.DEBUG:
		return
	_print_color("<%s> [DEBUG]: %s" % [_identifier(), " ".join(message)], Color.LIGHT_BLUE)

static func trace(...message: Array) -> void:
	if verbosity_level < VerbosityLevel.TRACE:
		return
	_print_color("<%s> [TRACE]: %s" % [_identifier(), " ".join(message)], Color.LIGHT_PINK)
	var stack: Array = get_stack()
	for frame in stack:
		var bt_data = BacktraceData.new(frame)
		_print_color("    at %s:%d in function %s" % [bt_data.source, bt_data.line, bt_data.function], Color.LIGHT_PINK)

static func fatal(...message: Array) -> void:
	if verbosity_level < VerbosityLevel.FATAL:
		if not Engine.is_editor_hint(): # Avoid crashing the editor
			OS.crash("Fatal error occurred: %s" % " ".join(message))
		return
	_print_color("<%s> [FATAL]: %s" % [_identifier(), " ".join(message)], Color.DARK_RED)
	var stack: Array = get_stack()
	for frame in stack:
		var bt_data = BacktraceData.new(frame)
		_print_color("    at %s:%d in function %s" % [bt_data.source, bt_data.line, bt_data.function], Color.DARK_RED)

	if not Engine.is_editor_hint(): # Avoid crashing the editor
		OS.crash("Fatal error occurred: %s" % message)

static func _identifier() -> String:
	# Provide more detailed identifier info for client context
	if ContextInit.current_context == ContextInit.Context.CLIENT:
		var subtext: String = "Offline"
		if ClientInit.get_instance() != null and ClientInit.get_instance().multiplayer.has_multiplayer_peer() and not ClientInit.get_instance().multiplayer.get_multiplayer_peer() is OfflineMultiplayerPeer:
			subtext = "%s" % ClientInit.get_instance().multiplayer.get_multiplayer_peer().get_unique_id()
		return "%s | %s" % [ContextInit.Context.keys()[ContextInit.current_context], subtext]
	return "%s" % ContextInit.Context.keys()[ContextInit.current_context]

static func _print_color(message: String, color: Color) -> void:
	var colored_message = "[color=%s]%s[/color]" % [color.to_html(), message]
	print_rich(colored_message)

class BacktraceData:
	var source: String
	var line: int
	var function: String
	func _init(data: Dictionary) -> void:
		source = data.get("source", "UNKNOWNFILE")
		line = data.get("line", -1)
		function = data.get("function", "UNKNOWNFUNCTION")
	