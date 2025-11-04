class_name Item extends Resource

@export var item_id: int
@export var item_icon: Texture2D
@export var item_stack_size: int = 0 # -1 for unlimited stack size, 0/1 for non-stackable items, >1 for stackable items. 

func get_title() -> String:
	return tr("item.title.%d" % item_id)
func get_description() -> String:
	return tr("item.description.%d" % item_id)