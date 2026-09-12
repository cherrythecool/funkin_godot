extends MainMenuButton


func accept() -> bool:
	if not ResourceLoader.exists(MainMenu.freeplay_scene):
		return super()

	SceneManager.transition_to_file(MainMenu.freeplay_scene)
	return true
