extends PauseMenu


func select(option: StringName) -> void:
	if option == &"options":
		OptionsMenu.target_scene = get_tree().current_scene.scene_file_path

	super(option)
