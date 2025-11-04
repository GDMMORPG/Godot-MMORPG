@tool
extends Label

func _ready() -> void:
	text = "v%s" % ProjectSettings.get_setting("application/config/version")
	# Detect if we are running from the editor.
	if Engine.is_editor_hint() or OS.has_feature("editor"):
		text += " (Editor)"