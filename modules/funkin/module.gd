extends Node


func _ready() -> void:
	TitleScreen.in_intro = true
	MainMenu.freeplay_scene = "uid://3rua2gpac5p8"
	SceneManager.replace_transitions_with(load("uid://6c6svnfsdils"))
	SceneManager.swap_to_packed(load("uid://cxk008iuw4n7u"))
