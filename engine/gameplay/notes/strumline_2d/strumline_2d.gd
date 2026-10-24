class_name Strumline2D
extends Node2D


const FNF_SCROLL_DISTANCE_MULT: float = 450.0

@export var parent: StrumlineManager:
	set = _set_parent

@export var skin: NoteSkin = null:
	set = _set_skin

@export var use_game_scroll_speed: bool = true
@export var scroll_speed: float = 1.0:
	set(value):
		if scroll_speed != value:
			scroll_speed = value
			_update_holds = true

@export var downscroll: bool = false:
	set(value):
		if downscroll != value:
			downscroll = value
			_update_holds = true

@export_group("References")

@export var receptors: Array[Receptor2D] = []
@export var underlay: CanvasItem

@export_group("Notes")

## Spawn window used at 1.0 scroll speed, is divided by scroll speed
## in actual usage though.
@export var notes_spawn_window: float = 1.5
@export var notes_parent: Node
@export var default_note_scene: PackedScene = load("uid://b6b6gdk3o56wm")
@export var other_note_scenes: Dictionary[StringName, PackedScene] = {}

var notes_have_spawned: Array[bool] = []

var _spawning_index := 0
var _update_holds := false


func _ready() -> void:
	var game := Game.instance
	if use_game_scroll_speed and is_instance_valid(game):
		_on_game_scroll_speed_changed(game.scroll_speed)
		game.scroll_speed_changed.connect(_on_game_scroll_speed_changed)

	Conductor.rate_changed.connect(_on_conductor_rate_changed)

	var rating_manager: RatingManager = get_tree().get_first_node_in_group(&"RatingManager")
	if rating_manager:
		rating_manager.applied_rating.connect(_on_applied_rating)

	update_skin()


func _process(_delta: float) -> void:
	if not parent:
		return

	spawn_notes()

	for i: int in receptors.size():
		var receptor: Receptor2D = receptors[i]
		update_notes(receptor)

		var parent_state := parent.receptor_states[i]
		var animation_state := receptor.get_animation_from_state(parent_state)
		if animation_state != receptor.last_played_anim:
			if (not parent.cpu) or (parent.cpu and not receptor.is_playing()):
				receptor.play_animation(animation_state)

	_update_holds = false


func get_distance_from_time(time: float, real_scroll_speed: float) -> float:
	return time * real_scroll_speed * FNF_SCROLL_DISTANCE_MULT


func get_note_hold_height(note: Note2D, real_scroll_speed: float) -> float:
	return get_distance_from_time(note.data.length + note.sustain_offset, real_scroll_speed)


func get_all_notes() -> Array[Note2D]:
	var array: Array[Note2D] = []
	for receptor: Receptor2D in receptors:
		array.append_array(receptor.notes)

	return array


func spawn_notes() -> void:
	var note_count := parent.notes.size()
	if note_count == 0:
		return

	var time := parent.get_time()
	var real_scroll_speed := get_scroll_speed()
	var spawn_until := time + (notes_spawn_window / real_scroll_speed)
	_spawning_index = maxi(_spawning_index, parent.notes_index)

	while _spawning_index < note_count:
		var note := parent.notes[_spawning_index]
		if note.time > spawn_until:
			break

		var current_index := _spawning_index
		_spawning_index += 1

		if notes_have_spawned[current_index]:
			continue

		if note.direction > receptors.size() - 1:
			printerr("Tried to spawn note with direction %d, outside range of receptors (%d)" % [
				note.direction,
				receptors.size(),
			])
			continue

		var receptor := receptors[note.direction]
		var note_node: Note2D = default_note_scene.instantiate()
		note_node.direction = receptor.direction
		note_node.data = note
		note_node.index = current_index

		if note.length <= 0.0:
			note_node.hold_clip.hide()
		else:
			note_node.hold_clip.size.y = get_note_hold_height(note_node, real_scroll_speed)
			note_node.hold_clip.scale.y = -1.0 if downscroll else 1.0

		note_node.apply_skin(skin)

		receptor.notes.push_back(note_node)
		notes_parent.add_child(note_node)
		notes_have_spawned[current_index] = true


func update_notes(receptor: Receptor2D) -> void:
	var time := parent.get_time()
	var real_scroll_speed := get_scroll_speed()
	var receptor_position := receptor.position
	var scroll_scale := -1.0 if downscroll else 1.0
	var notes := receptor.notes
	var parent_index := parent.notes_index
	var notes_to_remove: Array[Note2D] = []

	for note_node: Note2D in notes:
		if not is_instance_valid(note_node):
			notes_to_remove.push_back(note_node)
			continue

		if note_node.index < parent_index:
			note_node.queue_free()
			notes_to_remove.push_back(note_node)
			continue

		var note := note_node.data
		if _update_holds and note.length > 0.0:
			note_node.hold_clip.scale.y = scroll_scale

			var clip_height := get_note_hold_height(note_node, real_scroll_speed)
			if note_node.hold_clip.size.y != clip_height:
				note_node.hold_clip.size.y = clip_height

		if (
			note_node.data.state == NoteData.NoteState.HIT or
			note_node.data.state == NoteData.NoteState.MISSED
		):
			note_node.queue_free()
			notes_to_remove.push_back(note_node)
			continue
		elif note_node.data.state == NoteData.NoteState.HELD:
			if note_node.animated_node is CanvasItem:
				note_node.animated_node.visible = false

			note_node.position = receptor_position
			note_node.hold_rect.position.y = get_distance_from_time(note.time - note_node.sustain_offset - time, real_scroll_speed)
		elif note_node.data.state == NoteData.NoteState.ALIVE:
			note_node.position = (
				receptor_position +
				Vector2(
					0,
					get_distance_from_time(note.time - time, real_scroll_speed) * scroll_scale
				)
			)

	for removed: Note2D in notes_to_remove:
		notes.erase(removed)


func update_skin() -> void:
	if not is_instance_valid(skin):
		return

	for receptor: Receptor2D in receptors:
		receptor.apply_skin(skin)

	var all_notes := get_all_notes()
	for note: Note2D in all_notes:
		note.apply_skin(skin)


## Exists so scroll speed can look consistent at higher playback rates.
func get_scroll_speed() -> float:
	return scroll_speed / Conductor.rate


func _on_note_hit(note_data: NoteData) -> void:
	var receptor := receptors[note_data.direction]
	var first_hit := note_data.state == NoteData.NoteState.ALIVE
	var holding_anim := (
		note_data.state == NoteData.NoteState.HELD and
		receptor.hold_timer >= Conductor.beat_delta / 4.0
	)

	if first_hit or holding_anim:
		receptor.hold_timer = 0.0
		receptor.play_animation(&"confirm", true)

	if note_data.state != NoteData.NoteState.ALIVE or receptor.notes.is_empty():
		return

	# note: this only works because input only ever hits the first note
	# time-wise, so if that was ever changed then this would need to be adjusted
	var note_node: Note2D = receptor.notes[0]
	if note_data.length <= 0.0:
		note_node.queue_free()
		receptor.notes.remove_at(0)
		return

	var time := parent.get_time()
	if time >= note_data.time:
		return

	note_node.sustain_offset = note_data.time - time
	note_node.hold_clip.size.y = get_note_hold_height(note_node, get_scroll_speed())


func _set_parent(new_parent: StrumlineManager) -> void:
	if parent == new_parent:
		return

	if parent:
		parent.note_hit.disconnect(_on_note_hit)
		parent.notes_loaded.disconnect(_on_notes_loaded)
		parent.notes_pushed.disconnect(_on_notes_pushed)
		parent.notes_cleared.disconnect(_on_notes_cleared)

	parent = new_parent

	if parent:
		parent.note_hit.connect(_on_note_hit)
		parent.notes_loaded.connect(_on_notes_loaded)
		parent.notes_pushed.connect(_on_notes_pushed)
		parent.notes_cleared.connect(_on_notes_cleared)

		if underlay:
			underlay.visible = not parent.cpu


func _set_skin(new_skin: NoteSkin) -> void:
	if skin == new_skin:
		return

	skin = new_skin
	update_skin()


func _on_notes_loaded() -> void:
	for receptor: Receptor2D in receptors:
		for note: Note2D in receptor.notes:
			if is_instance_valid(note):
				note.queue_free()

		receptor.notes.clear()

	notes_have_spawned.resize(parent.notes.size())
	notes_have_spawned.fill(false)
	_spawning_index = 0


func _on_notes_pushed() -> void:
	notes_have_spawned.resize(parent.notes.size())


func _on_notes_cleared() -> void:
	for receptor: Receptor2D in receptors:
		for note: Note2D in receptor.notes:
			if is_instance_valid(note):
				note.queue_free()

		receptor.notes.clear()

	notes_have_spawned.clear()
	_spawning_index = 0


func _on_applied_rating(rating: Rating, note: NoteData, _health_mult: float) -> void:
	if parent.notes[parent.last_hit_index] != note:
		return
	if rating.accuracy_percent != 100.0 or note.direction >= receptors.size():
		return

	receptors[note.direction].play_splash()


func _on_game_scroll_speed_changed(value: float) -> void:
	scroll_speed = value


func _on_conductor_rate_changed(_rate: float) -> void:
	_update_holds = true
