extends Control


@export var parent: FreeplayMenu

@export var song_label: Label
@export var difficulty_label: Label
@export var score_panel: Panel
@export var reset_panel: Panel

var song: StringName
var difficulty: StringName
var difficulty_count: int = 0
var score_data: Dictionary
var song_index: int
var song_meta: SongMetadata


func _ready() -> void:
	if parent:
		parent.song_changed.connect(_on_song_changed)
		parent.difficulty_changed.connect(_on_difficulty_changed)

	_process(0.0)


func _process(_delta: float) -> void:
	update_other_panels()


func _on_song_changed(index: int) -> void:
	song_index = index
	song_meta = parent.song_nodes[song_index].meta
	if is_instance_valid(song_meta):
		song_label.text = song_meta.get_full_name()
	else:
		song_label.text = parent.song_nodes[song_index].text


func _on_difficulty_changed(new_difficulty: StringName) -> void:
	var difficulty_map: Dictionary[String, StringName] = {}
	if is_instance_valid(song_meta):
		difficulty_map = song_meta.difficulty_song_overrides
	difficulty = new_difficulty

	if difficulty_map.has(difficulty):
		song = difficulty_map.get(difficulty).to_lower()
	else:
		song = parent.list[song_index].to_lower()

	reset_panel.song = song
	reset_panel.difficulty = difficulty

	score_data = Scores.get_score(song, difficulty)
	score_panel.refresh(score_data)

	if difficulty_count > 1:
		difficulty_label.text = '< %s >' % difficulty.to_lower().to_upper()
		difficulty_label.visible = true
		custom_minimum_size.y = 48.0
	else:
		difficulty_label.visible = false
		custom_minimum_size.y = 24.0

	update_other_panels()


# TODO: make this a less stupid idea for organization of code-
func update_other_panels() -> void:
	size.x = 256.0
	custom_minimum_size.x = max(
		256.0,
		song_label.get_bound_minimum_size().x + 8.0,
		difficulty_label.get_bound_minimum_size().x + 8.0,
	)
