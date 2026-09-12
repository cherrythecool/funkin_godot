extends Control


static var selected_static: int = 0

var selected: int = 0:
	set(value):
		selected = value
		selected_static = selected

		for index: int in get_child_count():
			get_child(index).modulate.a = 1.0 if index == selected else 0.6



func _ready() -> void:
	space_children()
	selected = selected_static


func space_children() -> void:
	var y: float = 16.0
	for child: TextureRect in get_children():
		child.position.y = y
		y += child.size.y + 32.0
