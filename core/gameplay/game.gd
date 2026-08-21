class_name Game
extends Node


enum PlayMode {
	FREEPLAY = 0,
	STORY = 1,
	OTHER = 2,
}

static var songs_folder: String = "res://modules/funkin/songs"
static var song: StringName = &"bopeebo"
static var difficulty: StringName = &"hard"
static var chart: Chart = null
static var mode: PlayMode = PlayMode.FREEPLAY
static var exit_scene: String = ""

static var instance: Game = null
static var playlist: Array[GamePlaylistEntry] = []
static var last_song_health: float = -1.0

@export var strumlines: Dictionary[StringName, StrumlineManager] = {
	&"player": null,
	&"opponent": null,
}

@export var asset_loader: AssetLoader
@export var pause_menu: PackedScene

@onready var song_player: AudioStreamPlayer = %song_player
@onready var rating_calculator: RatingCalculator = %rating_calculator

@onready var hud_layer: CanvasLayer = %hud_layer

var events_index: int = 0

@export var hud: Node
#var player_field: NoteField = null
#var opponent_field: NoteField = null

var song_started: bool = false
var save_score: bool = true

## Each note type is stored here for use in any note field.
var note_types: Dictionary[StringName, PackedScene] = {}

var playing: bool = true
var scroll_speed: float:
	set(value):
		scroll_speed = value
		scroll_speed_changed.emit(value)

var assets: SongAssets
var metadata: SongMetadata

@export var player: Character
@export var opponent: Character
@export var spectator: Character
@export var stage: Stage

var health: float = 50.0
var score: int = 0:
	set(value):
		if score != value:
			score = value
			score_changed.emit(score)

var misses: int = 0
var combo: int = 0

var accuracy: float = 0.0:
	get:
		if is_instance_valid(rating_calculator):
			return rating_calculator.accuracy

		return 0.0

var rank: StringName:
	get:
		if is_instance_valid(rating_calculator):
			return rating_calculator.rank

		return &"N/A"

var skin: HUDSkin

var persist_camera_on_exit: bool = false

signal hud_setup
signal ready_post
signal process_post(delta: float)
signal song_start
signal event_prepare(event: EventData)
signal event_hit(event: EventData)
signal song_finished
signal back_to_menus
signal scroll_speed_changed(value: float)
signal died
signal botplay_changed(botplay: bool)
signal score_changed(value: int)
@warning_ignore("unused_signal") signal unpaused


func _init() -> void:
	instance = self


func _ready() -> void:
	# we set to inherit to bypass the automatic pausing
	# from scene transitions (it makes the countdown &
	# potentially other things a lil' wonky, mostly sounds)
	process_mode = Node.PROCESS_MODE_INHERIT

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.use_accumulated_input = false

	GlobalAudio.music.stop()

	song_player.stream = Tracks.tracks_load(song, songs_folder)
	song_player.finished.connect(finish_song.bind(false, false))

	if not is_instance_valid(song_player.stream):
		printerr("Failed to load tracks for current song! Returning...")
		finish_song(true, false)
		return

	load_chart()
	reset_conductor()

	if is_instance_valid(asset_loader):
		load_assets()
		load_from_assets()

	if strumlines.has(&"player"):
		var plr_strums := strumlines[&"player"]
		plr_strums.note_hit.connect(_on_note_hit)
		plr_strums.note_missed.connect(_on_note_miss)

		if player and not player.strumline:
			player.strumline = plr_strums

	if strumlines.has(&"opponent"):
		if opponent and not opponent.strumline:
			opponent.strumline = strumlines[&"opponent"]

	setup_hud()

	if is_instance_valid(asset_loader):
		asset_loader.load_scripts(song, songs_folder)

	load_events()

	ready_post.emit()


func _exit_tree() -> void:
	if instance != self:
		return

	instance = null

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.use_accumulated_input = true

	last_song_health = -1.0

	# Mostly for modules, might be helpful somewhere else too though
	if not persist_camera_on_exit:
		GameCamera2D.reset_persistent_values()


func _process(delta: float) -> void:
	_process_post.call_deferred(delta)

	if not playing:
		return

	if health <= 0.0:
		died.emit()
		Gameover.character_path = player.death_character
		Gameover.character_position = player.global_position
		persist_camera_on_exit = true
		SceneManager.swap_to_file("uid://c05dah5aarqg8")
		return

	if (
		not song_started and
		Conductor.raw_time >= 0.0 and
		Conductor.active and
		not song_player.playing
	):
		start_song()

	while events_index < chart.events.size() and \
			Conductor.time >= chart.events[events_index].time:
		event_hit.emit(chart.events[events_index])
		events_index += 1


func _process_post(delta: float) -> void:
	process_post.emit(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event.is_echo():
		return
	if not playing:
		return

	if event.is_action(&"game_pause"):
		var menu: CanvasLayer = pause_menu.instantiate()
		add_child(menu)
		process_mode = Node.PROCESS_MODE_DISABLED
		Conductor.active = false
	elif event.is_action(&"menu_cancel"):
		finish_song(true)

	if event.is_action(&"toggle_botplay") and strumlines.has(&"player"):
		save_score = false

		var plr_strums := strumlines[&"player"]
		plr_strums.cpu = not plr_strums.cpu
		botplay_changed.emit(not plr_strums.cpu)

	if not OS.is_debug_build():
		return
	if event.is_action(&"skip_time"):
		save_score = false
		skip_to(Conductor.raw_time + 10.0)


func _on_note_miss(note: NoteData) -> void:
	misses += 1
	score -= 10
	combo = 0

	if strumlines.has(note.strumline):
		var hit_window := strumlines[note.strumline].hit_window
		rating_calculator.add_hit(hit_window, hit_window)

	health = clampf(health - 2.0, 0.0, 100.0)


func _on_note_hit(note: NoteData) -> void:
	if note.state != NoteData.NoteState.ALIVE:
		return

	combo += 1

	if not is_instance_valid(rating_calculator):
		return

	var difference: float = Conductor.time - note.time
	if strumlines.has(&"player") and strumlines[&"player"].cpu:
		difference = 0.0

	if strumlines.has(note.strumline):
		rating_calculator.add_hit(absf(difference), strumlines[note.strumline].hit_window)

	var rating: Rating = rating_calculator.get_rating(absf(difference))
	health = clampf(health + rating.health, 0.0, 100.0)
	score += rating.score


func start_song(from_position: float = 0.0) -> void:
	song_player.play(from_position)

	Conductor.target_audio = song_player
	Conductor.raw_time = from_position
	Conductor.rate = Conductor.internal_rate

	song_start.emit()
	song_started = true


func finish_song(force: bool = false, sound: bool = true) -> void:
	# TODO: make parts of this replacable or more separated so u can customize in ur modules :3
	if not playing:
		return

	song_finished.emit()

	if force:
		save_score = false

	playing = false

	if save_score:
		var current_score: Dictionary = Scores.get_score(song, difficulty)
		if str(current_score.get("score", "N/A")) == "N/A" or score > current_score.get("score"):
			Scores.set_score(song, difficulty, {
				"score": score,
				"misses": misses,
				"accuracy": accuracy,
				"rank": rank
			})

	if not (playlist.is_empty() or force):
		var new_song: StringName = playlist[0].name
		var new_difficulty: StringName = playlist[0].difficulty

		chart = null
		song = new_song
		difficulty = new_difficulty.to_lower()
		playlist.pop_front()
		SceneManager.swap_to_file(SongLoader.get_scene_path(song, songs_folder))
		last_song_health = health
		return

	chart = null
	playlist.clear()

	if sound:
		GlobalAudio.get_player("MENU/CANCEL").play()

	back_to_menus.emit()

	if not exit_scene.is_empty():
		SceneManager.transition_to_file(exit_scene)
		exit_scene = ""
		return

	match mode:
		PlayMode.STORY:
			SceneManager.transition_to_file("uid://dcf86iwg6mn3d")
		PlayMode.FREEPLAY:
			SceneManager.transition_to_file(MainMenu.freeplay_scene)
		_:
			SceneManager.transition_to_file("uid://cxk008iuw4n7u")


func load_chart() -> void:
	if not is_instance_valid(chart):
		chart = Chart.load_chart("%s/%s" % [songs_folder, song], difficulty)

	var custom_speed: float = Settings.get_setting(&"core", "note_scroll_value")
	match Settings.get_setting(&"core", "note_scroll_method"):
		"chart_multiplier":
			scroll_speed = chart.scroll_speed * custom_speed
		"constant":
			scroll_speed = custom_speed

	chart.sort()

	#var note_type_paths: PackedStringArray = [
		#"res://modules/%s/notes/types" % ModuleManager.current_module,
		#"res://core/notes/types",
	#]
#
	#for strumline: Dictionary in chart.strumlines.values():
		#for raw_type: String in strumline[&"note_types"]:
			#var type := StringName(raw_type)
			#if (
				#note_types.has(type) or
				#note_types.has(type.to_snake_case())
			#):
				#continue

			#var scene := Note.load_note_type(type, note_type_paths)
			#if is_instance_valid(scene):
				#note_types[type] = scene

	for key: StringName in strumlines:
		if not chart.strumlines.has(key):
			continue

		var manager: StrumlineManager = strumlines[key]
		if not is_instance_valid(manager):
			continue

		manager.load_notes(chart.strumlines[key][&"notes"])


func load_assets() -> void:
	if ResourceLoader.exists("%s/%s/meta.tres" % [songs_folder, song]):
		metadata = load("%s/%s/meta.tres" % [songs_folder, song])
	if not is_instance_valid(metadata):
		metadata = SongMetadata.new()
		metadata.display_name = song.to_pascal_case()

	if ResourceLoader.exists("%s/%s/assets.tres" % [songs_folder, song]):
		assets = load("%s/%s/assets.tres" % [songs_folder, song])
	if not is_instance_valid(assets):
		assets = load("uid://dm8kpip52j8kf")


func load_from_assets() -> void:
	asset_loader.assets = assets
	asset_loader.metadata = metadata
	asset_loader.load_assets()


func setup_hud() -> void:
	hud_setup.emit()


func reset_conductor() -> void:
	Conductor.reset()
	Conductor.append_timing_changes(chart.timing_changes)
	Conductor.calculate_beat()
	Conductor.raw_time = (-4.0 * Conductor.beat_delta) + Conductor.offset
	Conductor.beat_hit.emit.call_deferred(-4)


func load_events() -> void:
	if not chart.events.is_empty():
		if is_instance_valid(asset_loader):
			asset_loader.load_events(chart.events)

		for event: EventData in chart.events:
			event_prepare.emit(event)

		# we do int(time * 1000.0) because if it"s less than 1 ms
		# after the start of a song (i"ve seen this in base game charts before)
		# then we should still call it lmfao (like camera pans)
		while (not chart.events.is_empty()) and events_index < chart.events.size() \
				and int(chart.events[events_index].time * 1000.0) <= 0.0:
			if not chart.events[events_index].trigger_before_countdown:
				break

			event_hit.emit(chart.events[events_index])
			events_index += 1


func skip_to(seconds: float) -> void:
	if not song_started:
		start_song(seconds)
	else:
		if not is_instance_valid(Conductor.target_audio):
			Conductor.raw_time = seconds
		else:
			if is_instance_valid(Conductor.target_audio.stream):
				if seconds >= Conductor.target_audio.stream.get_length():
					finish_song(false, false)
					return

			if not Conductor.target_audio.playing:
				Conductor.target_audio.play(seconds)
			else:
				Conductor.target_audio.seek(seconds)

			Conductor.sync_to_target(0.0)

	Conductor.calculate_beat()

	for key: StringName in strumlines:
		strumlines[key].skip_missed_notes(1.0)
