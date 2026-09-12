extends MainMenuButton


@export_file("*.tscn") var scene_path: String


func accept() -> bool:
	if not ResourceLoader.exists(scene_path):
		return super()

	SceneManager.transition_to_file(scene_path)
	return true
