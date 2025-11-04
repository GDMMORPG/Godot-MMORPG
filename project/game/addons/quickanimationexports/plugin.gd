@tool
extends EditorPlugin

var context_menu_plugin: QuickAnimationExportsContextMenuPlugin

func _enter_tree() -> void:
    context_menu_plugin = QuickAnimationExportsContextMenuPlugin.new()
    context_menu_plugin.editor_plugin = self # Pass the EditorPlugin to the EditorContextMenuPlugin.
    self.add_context_menu_plugin(EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM, context_menu_plugin)


func _exit_tree() -> void:
    self.remove_context_menu_plugin(context_menu_plugin)
