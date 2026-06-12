class_name SkinnedStrumlineRenderer
extends Node2D


@export var parent: StrumlineManager

@export var receptors: Array[ReceptorData] = []
@export var skin: NoteSkin

@export var spacing: float = 90.0
@export var scroll_speed: float = 1.0


func _ready() -> void:
	if not is_instance_valid(parent):
		return

	parent.note_hit.connect(_on_note_hit)


func _process(delta: float) -> void:
	if not is_instance_valid(parent):
		return

	var receptor_frames := skin.get_receptor_frames()
	for i: int in receptors.size():
		var state := parent.receptor_states[i]
		var receptor := receptors[i]
		var receptor_anim := &"%s %s" % [
			receptor.direction,
			receptor.animation,
		]

		var animation_length := receptor_frames.get_frame_count(receptor_anim) / receptor.framerate

		if receptor.animation_state != state:
			if (not parent.cpu) or receptor.animation_progress >= animation_length:
				receptor.animation_state = state
				receptor.animation_progress = 0.0
			else:
				receptor.animation_progress += delta
		else:
			receptor.animation_progress += delta

	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(parent):
		return

	var time := Conductor.time
	var spawn_time: float = 800.0 / (450.0 * absf(scroll_speed))

	var receptor_frames := skin.get_receptor_frames()
	var receptor_scale := skin.receptor_scale
	var receptor_positions: PackedVector2Array
	receptor_positions.resize(receptors.size())
	receptor_positions.fill(Vector2.ZERO)

	for i: int in receptors.size():
		var receptor := receptors[i]
		var receptor_anim := &"%s %s" % [
			receptor.direction,
			receptor.animation,
		]

		var anim_length := receptor_frames.get_frame_count(receptor_anim)
		if anim_length == 0:
			continue

		var texture := receptor_frames.get_frame_texture(
			receptor_anim,
			mini(receptor.animation_frame, anim_length - 1)
		)

		var receptor_position := Vector2(
			(i * spacing) - (spacing * 1.5),
			0.0
		)
		receptor_positions[i] = receptor_position

		draw_texture_rect(
			texture,
			Rect2(
				receptor_position - (texture.get_size() * receptor_scale / 2.0),
				texture.get_size() * receptor_scale,
			),
			false
		)

	var note_frames := skin.get_note_frames()
	var note_scale := skin.note_scale

	for index: int in range(parent.notes_index, parent.notes.size()):
		var note := parent.notes[index]
		if time < note.time - spawn_time:
			break

		var receptor := receptors[note.direction]
		var receptor_position := receptor_positions[note.direction]

		# TODO: looping note anims ig
		var texture := note_frames.get_frame_texture(&"%s note" % receptor.direction, 0)

		if not texture:
			continue

		var note_position := Vector2(
			receptor_position.x,
			receptor_position.y - ((note.time - time) * 450.0 * scroll_speed)
		)
		draw_texture_rect(
			texture,
			Rect2(
				note_position - (texture.get_size() * note_scale / 2.0),
				texture.get_size() * note_scale
			),
			false
		)


func _on_note_hit(note: NoteData) -> void:
	var receptor := receptors[note.direction]
	receptor.animation_state = StrumlineManager.ReceptorState.HIT
	receptor.animation_progress = 0.0
