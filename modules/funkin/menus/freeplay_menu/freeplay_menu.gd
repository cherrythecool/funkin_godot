class_name FreeplayMenu
extends Node2D


static var index: int = 0
static var difficulty_index: int = 0

@export var list: Array[String] = []
@export_dir var songs_folder: String = "res://modules/funkin/songs":
	set(v):
		songs_folder = v

		if songs_folder.ends_with("/"):
			songs_folder = songs_folder.left(-1)

@onready var background: Sprite2D = %background
var target_background_color: Color = Color.WHITE
@onready var songs: Node = %songs
var song_nodes: Array[FreeplaySongNode] = []

@onready var song_player: AudioStreamPlayer = %song_player
@onready var track_timer: Timer = %track_timer
@onready var info_panel: Panel = %info_panel

var list_song: String:
	get:
		return list[index]

var current_song: String:
	get:
		return get_song_name(list_song, difficulty)

var difficulties: PackedStringArray:
	get:
		return get_song_difficulties(list_song)

var difficulty: String:
	get:
		return difficulties[difficulty_index]

var active: bool = true
var previous_song: String

signal song_changed(index: int)
signal difficulty_changed(difficulty: StringName)


func _ready() -> void:
	randomize()
	assert(not list.is_empty(), "You need a list to have freeplay work correctly.")

	for i: int in list.size():
		load_song(i)

	if song_nodes.is_empty():
		active = false
		GlobalAudio.get_player("MENU/CANCEL").play()
		SceneManager.transition_to_packed(load("uid://b7fwxsepnt38j"))
		printerr("Freeplay has no songs, returning.")
		return

	change_selection()

	for node: FreeplaySongNode in song_nodes:
		node.position = node.get_target_position()

	target_background_color = song_nodes[index].meta.icon.color
	background.modulate = target_background_color


func _process(delta: float) -> void:
	background.modulate = background.modulate.lerp(target_background_color, delta * 5.0)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if not event.is_pressed():
		return

	if event.is_action(&"menu_cancel"):
		active = false
		GlobalAudio.get_player("MENU/CANCEL").play()
		SceneManager.transition_to_packed(load("uid://b7fwxsepnt38j"))
	if event.is_action(&"menu_accept"):
		active = false
		select_song.call_deferred()
	if event.is_action(&"freeplay_open_characters"):
		active = false
		GlobalAudio.get_player(^"MENU/CANCEL").play()
		SceneManager.transition_to_packed(load("uid://62vvv8x8t7nm"))

	if event.is_action(&"menu_up") or event.is_action(&"menu_down"):
		change_selection(roundi(Input.get_axis(&"menu_up", &"menu_down")))
	if event.is_action(&"menu_left") or event.is_action(&"menu_right"):
		change_difficulty(roundi(Input.get_axis(&"menu_left", &"menu_right")))


func get_song_name(song: String, diff: String) -> String:
	if not ResourceLoader.exists("%s/%s/meta.tres" % [songs_folder, song]):
		return song.to_lower()

	var meta: SongMetadata =  load("%s/%s/meta.tres" % [songs_folder, song])
	if not is_instance_valid(meta):
		return song.to_lower()

	if meta.difficulty_song_overrides.has(diff):
		return meta.difficulty_song_overrides.get(diff).to_lower()

	return song.to_lower()


func get_song_difficulties(song: String) -> PackedStringArray:
	if not ResourceLoader.exists("%s/%s/meta.tres" % [songs_folder, song]):
		return ["easy", "normal", "hard"]

	var meta: SongMetadata = load("%s/%s/meta.tres" % [songs_folder, song])
	if not is_instance_valid(meta):
		return ["easy", "normal", "hard"]

	return meta.difficulties


func change_selection(amount: int = 0) -> void:
	index = wrapi(index + amount, 0, song_nodes.size())
	song_changed.emit(index)
	change_difficulty()
	previous_song = current_song

	track_timer.start(0.0)

	if amount != 0:
		GlobalAudio.get_player("MENU/SCROLL").play()
	for i: int in song_nodes.size():
		var node: FreeplaySongNode = song_nodes[i]
		node.target_y = i - index
		node.modulate.a = 1.0 if node.target_y == 0 else 0.6

	if is_instance_valid(song_nodes[index].meta):
		target_background_color = song_nodes[index].meta.icon.color
	else:
		target_background_color = Color("a1a1a1")


func change_difficulty(amount: int = 0) -> void:
	difficulty_index = wrapi(difficulty_index + amount, 0, difficulties.size())
	info_panel.difficulty_count = difficulties.size()
	if difficulties.is_empty():
		difficulty_changed.emit(&"N/A")
	else:
		difficulty_changed.emit(difficulties[difficulty_index])

	# there has been a change and the song should switch
	if current_song != previous_song:
		track_timer.start(0.0)
		previous_song = current_song


func select_song() -> void:
	if difficulties.is_empty():
		active = true
		return

	var song_folder := "%s/%s" % [songs_folder, current_song]
	Game.chart = Chart.load_chart(song_folder, difficulty)
	if not is_instance_valid(Game.chart):
		active = true
		return

	Game.songs_folder = songs_folder
	Game.song = current_song
	Game.difficulty = difficulty.to_lower()
	Game.mode = Game.PlayMode.FREEPLAY
	Game.playlist.clear()
	SceneManager.transition_to_packed(load("uid://da8mu3oqto3qq"))


func load_song(i: int) -> void:
	var song: String = list[i]
	if get_song_difficulties(song).is_empty():
		printerr("Song is missing any difficulties!")
		return

	var song_name: String = get_song_name(song, "")
	var meta_path: String = "%s/%s/meta.tres" % [songs_folder, song_name]
	var meta_exists: bool = ResourceLoader.exists(meta_path, "SongMetadata")
	var meta: SongMetadata
	if meta_exists:
		meta = load(meta_path)

	if not is_instance_valid(meta):
		meta = SongMetadata.new()
		meta.display_name = song_name.to_pascal_case()

	if not is_instance_valid(meta.icon):
		meta.icon = Icon.new()

	var node: FreeplaySongNode = FreeplaySongNode.new()
	node.position = Vector2.ZERO
	node.text = meta.get_full_name()
	node.target_y = i
	node.meta = meta
	song_nodes.push_back(node)
	songs.add_child(node)

	var icon: Sprite2D = Icon.create_sprite(meta.icon)
	# 37.5 = 150.0 * 0.25
	icon.position = Vector2(node.size.x + 75.0, 37.5)
	node.add_child(icon)


func _load_tracks() -> void:
	if not Tracks.tracks_exist(current_song, songs_folder):
		return

	GlobalAudio.music.stop()
	song_player.stream = Tracks.tracks_load(current_song, songs_folder)
	song_player.play()


func _on_finished() -> void:
	song_player.play()
