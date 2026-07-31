extends Label


func _ready() -> void:
	text = text.replace("$VERSION", Global.version)
