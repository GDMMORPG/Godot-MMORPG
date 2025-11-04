@tool
extends EditorPlugin

func _enter_tree() -> void:
	self.add_autoload_singleton("AuthAPI", "res://addons/oauth/AuthAPI.gd")

func _exit_tree() -> void:
	self.remove_autoload_singleton("AuthAPI")
