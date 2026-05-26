extends Node


func _ready() -> void:
	TitleScreen.in_intro = true
	SceneManager.replace_transitions_with(load("uid://6c6svnfsdils"))
	SceneManager.swap_to_packed(load("uid://cxk008iuw4n7u"))
