extends Sprite2D


func _ready() -> void:
	if Time.get_date_dict_from_system().get("month") != 6:
		queue_free()
	else:
		show()
