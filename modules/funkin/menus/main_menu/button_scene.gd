extends MainMenuButton


@export_file("*.tscn") var scene_path: String


func accept() -> bool:
	if not ResourceLoader.exists(scene_path):
		return super()

	SceneManager.transition_to_packed(load(scene_path))
	return true
