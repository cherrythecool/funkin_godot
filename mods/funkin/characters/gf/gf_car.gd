extends Character


@export var speakers: AnimatedSprite


func set_character_material(new_material: Material) -> void:
	super(new_material)

	speakers.material = new_material
