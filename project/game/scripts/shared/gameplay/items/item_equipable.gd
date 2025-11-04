class_name ItemEquipable extends Item

enum EquipSlot {
	HEAD,
	SHOULDERS,
	CHEST,
	LEGS,
	FEET,
	HANDS,
	WEAPON_MAIN_HAND,
	WEAPON_OFF_HAND,
}

@export var equip_slot: EquipSlot
@export var attributes: Array[AttributeBase]
