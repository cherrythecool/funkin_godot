extends OptionButton


@export var option_name: String = "note_scroll_method"


func _ready() -> void:
	select(-1)

	var looking_for: String = SaveData.get_save_value(&"core", option_name, "")
	for index: int in item_count:
		if get_item_text(index) == looking_for:
			select(index)
			break

	item_selected.connect(_on_item_selected)


func _on_item_selected(index: int) -> void:
	SaveData.set_save_value(&"core", option_name, get_item_text(index))
