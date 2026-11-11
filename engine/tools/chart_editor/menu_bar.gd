extends MenuBar


@export var chart: PopupMenu
@export var songs: PopupMenu


func _ready() -> void:
	chart.remove_item(1)
	chart.add_submenu_node_item("Open", songs, 1)
	chart.set_item_index(chart.item_count - 1, 1)
