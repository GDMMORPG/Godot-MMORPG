class_name ActorAttributes extends Resource

@export_category("Base Stats")
@export var base_health: int = 100
@export var base_mana: int = 50
@export var base_stamina: int = 10

@export_category("Core Attributes")
@export var base_strength: int = 10
@export var base_agility: int = 10
@export var base_intelligence: int = 10
@export var base_spirit: int = 10

func calculate_movement_speed() -> float:
	# Simple formula: base speed + (agility * 0.5)
	var speed = 5.0
	speed += base_agility * 0.5
	return speed