class_name Actor extends Node

@export var character: PhysicsBody3D
@export var attributes: ActorAttributes

func move(delta: Vector3, step: float = 1.0) -> void:
	character.velocity = delta * attributes.calculate_movement_speed()

	character.velocity /= step
	if character is CharacterBody3D:
		character.move_and_slide()
	character.velocity *= step