class_name AssetLoader
extends Node


@export var assets: SongAssets
@export var metadata: SongMetadata

@export var song_player: AudioStreamPlayer
@export var characters_parent: Node
@export var stage_parent: Node
@export var hud_parent: Node

@export var scripts_parent: Node


func load_assets() -> void:
	if not is_instance_valid(assets):
		printerr("Tried to load assets without any assets!")
		return

	var player: Character = Game.instance.player
	var opponent: Character = Game.instance.opponent
	var spectator: Character = Game.instance.spectator

	if is_instance_valid(characters_parent):
		player = assets.get_player().instantiate()
		if Game.instance.strumlines.has(&"player"):
			player.strumline = Game.instance.strumlines[&"player"]

		opponent = assets.get_opponent().instantiate()
		if Game.instance.strumlines.has(&"opponent"):
			opponent.strumline = Game.instance.strumlines[&"opponent"]

		spectator = assets.get_spectator().instantiate()

		Game.instance.player = player
		Game.instance.opponent = opponent
		Game.instance.spectator = spectator

		characters_parent.add_child(spectator)
		characters_parent.add_child(player)
		characters_parent.add_child(opponent)

	if is_instance_valid(stage_parent):
		var stage: Stage = assets.get_stage().instantiate()
		Game.instance.stage = stage

		if player:
			if stage.has_node(^"player"):
				var player_point: CharacterPlacement = stage.get_node(^"player")
				if is_instance_valid(player_point):
					player_point.adjust_character(player, true)
			if not player.starts_as_player:
				player.scale *= Vector2(-1.0, 1.0)

		if opponent:
			if stage.has_node(^"opponent"):
				var opponent_point: CharacterPlacement = stage.get_node(^"opponent")
				if is_instance_valid(opponent_point):
					opponent_point.adjust_character(opponent)
			if opponent.starts_as_player:
				opponent.scale *= Vector2(-1.0, 1.0)

		if spectator:
			if stage.has_node(^"spectator"):
				var spectator_point: CharacterPlacement = stage.get_node(^"spectator")
				if is_instance_valid(spectator_point):
					spectator_point.adjust_character(spectator)

		if is_instance_valid(stage_parent):
			stage_parent.add_child(stage)

	var hud: Node = assets.get_hud().instantiate()
	var hud_skin := assets.get_hud_skin()
	if "hud_skin" in hud:
		hud.hud_skin = hud_skin

	Game.instance.hud = hud

	if is_instance_valid(hud_parent):
		hud_parent.add_child(hud)
	else:
		hud.queue_free()

	var player_renderer: SkinnedStrumlineRenderer
	var opponent_renderer: SkinnedStrumlineRenderer

	if "player_renderer" in hud:
		player_renderer = hud.player_renderer
	if "opponent_renderer" in hud:
		opponent_renderer = hud.opponent_renderer

	# Set the NoteField characters.
	if is_instance_valid(player_renderer):
		player_renderer.skin = assets.get_player_note_skin()

	if is_instance_valid(opponent_renderer):
		opponent_renderer.skin = assets.get_opponent_note_skin()

	Game.instance.pause_menu = hud_skin.get_pause_menu()

	for key: StringName in assets.note_types.keys():
		var scene: PackedScene = assets.note_types.get(key)
		if is_instance_valid(scene):
			Game.instance.note_types[key] = scene


func load_scripts(song: String, songs_folder: String) -> void:
	if not is_instance_valid(scripts_parent):
		printerr("Tried to load scripts without parent node!")
		return

	# load scripts from songs folder by default like tracks
	var script_path := "%s/%s/scripts" % [songs_folder, song]
	var files := ResourceLoader.list_directory(script_path)
	for file: String in files:
		var resource: Resource = load("%s/%s" % [script_path, file])
		if resource is PackedScene:
			var script: PackedScene = resource as PackedScene
			var script_instance: Node = script.instantiate()
			add_child(script_instance)

	if not is_instance_valid(assets):
		return

	for script: PackedScene in assets.scripts:
		if not is_instance_valid(script):
			continue

		var script_instance: Node = script.instantiate()
		add_child(script_instance)


func load_events(events: Array[EventData]) -> void:
	if not is_instance_valid(scripts_parent):
		printerr("Tried to load events without parent node!")
		return

	var loaded_events: Array[StringName] = []
	var base_path := "res://modules/%s/events" %  ModuleManager.current_module
	for event: EventData in events:
		var event_name: StringName = event.name.to_lower()
		if loaded_events.has(event_name):
			continue

		loaded_events.push_back(event_name)

		var path: String = "%s/%s.tscn" % [base_path, event_name]
		if not ResourceLoader.exists(path, "PackedScene"):
			path = "%s/%s.tscn" % [base_path, event_name.to_snake_case()]

		if not ResourceLoader.exists(path, "PackedScene"):
			continue

		var scene: PackedScene = load(path)
		scripts_parent.add_child(scene.instantiate())
