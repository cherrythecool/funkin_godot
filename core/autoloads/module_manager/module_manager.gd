extends CanvasLayer


@export var mods_replace_contents: bool = false

@export var selected := 0
@export var disabled := false
@export var module_panel: PackedScene

@onready var main_panel: Panel = %selection_panel
@onready var scroll_container: ScrollContainer = %scroll_container
@onready var module_container: VBoxContainer = %vbox

var mods_path: String = "./mods"

var current_module: String

var current_modules: Array


func _ready() -> void:
	if OS.has_feature("mobile"):
		mods_path = "user://mods"

	hide()

	Settings.set_default_settings(&"module", {
		"current_module": "funkin",
	})

	Settings.load_settings(&"module")
	Settings.setting_changed.connect(_on_setting_changed)
	current_module = Settings.get_setting(&"module", "current_module")

	load_mods_folder()
	load_modules_list()

	if current_modules.has(current_module):
		selected = current_modules.find(current_module)


func _input(event: InputEvent) -> void:
	if disabled or not event.is_pressed():
		return

	if event.is_action(&"module_select"):
		visible = not visible

		if visible:
			load_modules_list()
			recreate_panels()
			change_selection()

		get_viewport().set_input_as_handled()

	if not visible:
		return

	if event.is_action(&"menu_up"):
		get_viewport().set_input_as_handled()
		change_selection(-1)
	elif event.is_action(&"menu_down"):
		get_viewport().set_input_as_handled()
		change_selection(1)
	elif event.is_action(&"menu_accept"):
		get_viewport().set_input_as_handled()
		hide()
		Settings.set_setting(&"module", "current_module", current_modules[selected])
		SceneManager.swap_to_path("res://core/main.tscn")
	elif event.is_action(&"menu_cancel"):
		get_viewport().set_input_as_handled()
		hide()


func _on_setting_changed(file: StringName, key: Variant) -> void:
	if file == &"module" and key == "current_module":
		current_module = Settings.get_setting(&"module", "current_module")


func load_mods_folder() -> void:
	if disabled or OS.has_feature("editor"):
		return

	var dir: DirAccess
	if OS.has_feature("mobile"):
		dir = DirAccess.open("user://")
	else:
		dir = DirAccess.open("./")

	if not dir:
		printerr("Failed to open mods parent directory! Cannot load any modules!")
		return

	dir.make_dir("mods")

	var mods_dir := DirAccess.open(mods_path)

	if not mods_dir:
		printerr("Failed to open mods directory! Cannot load any modules!")
		return

	var mods := Array(mods_dir.get_files())
	mods = mods.filter(module_pck_filter)

	for mod: String in mods:
		var path := "%s/%s" % [mods_path, mod]
		var success := ProjectSettings.load_resource_pack(path, mods_replace_contents)
		if not success:
			printerr("Failed to load resource pack at path %s!" % path)
		else:
			print("Successfully loaded resource pack at path %s!" % path)


func load_modules_list() -> void:
	current_modules = Array(ResourceLoader.list_directory("res://modules"))
	current_modules = current_modules.filter(module_path_filter)
	current_modules.sort()

	# Remove all the `/`s
	for i: int in current_modules.size():
		current_modules[i] = current_modules[i].left(-1)


func module_path_filter(path: String) -> bool:
	if not path.ends_with("/"):
		return false

	return ResourceLoader.exists("res://modules/%smodule.tscn" % path)


func module_pck_filter(path: String) -> bool:
	return path.get_extension() == "pck"


func recreate_panels() -> void:
	GameUtils.free_children_from(module_container)

	for module: String in current_modules:
		var panel := module_panel.instantiate()
		panel.name = &"module_%s" % module
		panel.get_node(^"%module_name").text = module
		module_container.add_child(panel)

	if Global.game_size.y >= 128.0:
		main_panel.size.y = 48.0 + clampf(module_container.get_minimum_size().y, 40.0, Global.game_size.y - 48.0)
	else:
		main_panel.size.y = 128.0

	main_panel.position.y = (Global.game_size.y - main_panel.size.y) / 2.0


func change_selection(amount: int = 0) -> void:
	if current_modules.is_empty():
		selected = 0
		return

	selected = clampi(selected + amount, 0, current_modules.size() - 1)

	for i: int in module_container.get_child_count():
		var node := module_container.get_child(i)
		var selected_panel := node.get_node(^"%selected_panel")
		var module_name := node.get_node(^"%module_name")

		if selected == i:
			selected_panel.show()
			module_name.modulate.a = 1.0
			scroll_container.ensure_control_visible(selected_panel)
		else:
			selected_panel.hide()
			module_name.modulate.a = 0.6


func _on_open_folder_pressed() -> void:
	if OS.has_feature("editor"):
		return

	var dir := DirAccess.open(mods_path)
	if not dir:
		printerr("Error opening mods directory: %s" % DirAccess.get_open_error())
		return

	OS.shell_show_in_file_manager(dir.get_current_dir())
