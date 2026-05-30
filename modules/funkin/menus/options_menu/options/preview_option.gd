class_name PreviewOption
extends Option


@export var preview: PackedScene
@export var current_preview: Node

var current: Node


func _focus() -> void:
	if not is_instance_valid(preview):
		return

	current = preview.instantiate()
	current_preview.add_child(current)


func _unfocus() -> void:
	if is_instance_valid(current):
		current.queue_free()
