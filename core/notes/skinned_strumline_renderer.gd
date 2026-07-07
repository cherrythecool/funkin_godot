class_name SkinnedStrumlineRenderer
extends Node2D


@export var parent: StrumlineManager:
	set(v):
		if parent != v:
			if parent and parent.note_hit.is_connected(_on_note_hit):
				parent.note_hit.disconnect(_on_note_hit)

			parent = v
			parent.note_hit.connect(_on_note_hit)

@export var receptors: Array[ReceptorData] = []
@export var skin: NoteSkin
@export var use_skin_texture_filter := true

@export var spacing := 90.0
@export var scroll_speed := 1.0
@export var downscroll := false

var cached_sustain_textures: Dictionary[StringName, Texture2D]


func _process(delta: float) -> void:
	if not is_instance_valid(parent):
		return

	var receptor_frames := skin.get_receptor_frames()
	for i: int in receptors.size():
		var state := parent.receptor_states[i]
		var receptor := receptors[i]
		receptor.hold_timer += delta

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

	if use_skin_texture_filter:
		texture_filter = skin.note_filter

	var time := Conductor.time
	var scaled_scroll_speed := scroll_speed / Conductor.rate
	var spawn_time: float = 800.0 / (450.0 * absf(scaled_scroll_speed))

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
	var time_to_pixels := 450.0 * scaled_scroll_speed
	var sustain_width := skin.sustain_size
	var tail_width := skin.sustain_tail_size

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

		var time_difference := note.time - time
		var note_position := Vector2(
			receptor_position.x,
			receptor_position.y,
		)

		if downscroll:
			note_position.y -= (time_difference * time_to_pixels)
		else:
			note_position.y += (time_difference * time_to_pixels)

		var sus_height: float
		var sus_tex := get_sustain_texture(&"%s sustain" % receptor.direction, 0, false)
		var tail_tex := get_sustain_texture(&"%s sustain end" % receptor.direction, 0, false)
		var tail_size := tail_tex.get_size() * note_scale
		var sus_modulate := Color(Color.WHITE, skin.sustain_alpha)

		if note.state == NoteData.NoteState.ALIVE:
			sus_height = note.length * time_to_pixels
			sus_height -= tail_size.y

			if sus_height > 0.0:
				var sus_offset: Vector2
				if downscroll:
					sus_offset = -Vector2(sustain_width / 2.0, sus_height)
				else:
					sus_offset = Vector2(-sustain_width / 2.0, 0)

				draw_texture_rect(
					sus_tex,
					Rect2(
						note_position + sus_offset,
						Vector2(sustain_width, sus_height),
					),
					true,
					sus_modulate,
				)
			else:
				tail_size.y += sus_height

			if note.length > 0.0:
				var tail_offset: Vector2
				if downscroll:
					tail_offset = -Vector2(0.0, sus_height) - Vector2(tail_width / 2.0, tail_size.y)
				else:
					tail_offset = Vector2(-tail_width / 2.0, sus_height)

				draw_texture_rect(
					tail_tex,
					Rect2(
						note_position + tail_offset,
						Vector2(tail_width, tail_size.y * (-1.0 if downscroll else 1.0)),
					),
					false,
					sus_modulate,
				)

			draw_texture_rect(
				texture,
				Rect2(
					note_position - (texture.get_size() * note_scale / 2.0),
					texture.get_size() * note_scale
				),
				false,
			)
		elif note.state == NoteData.NoteState.HELD:
			sus_modulate.a = note.grace_timer / Conductor.sustain_release_delta
			sus_height = (note.length + time_difference) * time_to_pixels
			sus_height -= tail_size.y

			if sus_height > 0.0:
				var sus_offset: Vector2
				if downscroll:
					sus_offset = -Vector2(sustain_width / 2.0, sus_height)
				else:
					sus_offset = Vector2(-sustain_width / 2.0, 0)

				draw_texture_rect(
					sus_tex,
					Rect2(
						receptor_position + sus_offset,
						Vector2(sustain_width, sus_height),
					),
					false,
					sus_modulate,
				)
			else:
				tail_size.y += sus_height

			if note.length > 0.0:
				var tail_offset: Vector2
				if downscroll:
					tail_offset = -Vector2(tail_width / 2.0, maxf(sus_height, 0.0)) - Vector2(0.0, tail_size.y)
				else:
					tail_offset = Vector2(-tail_width / 2.0, maxf(sus_height, 0.0))

				draw_texture_rect(
					tail_tex,
					Rect2(
						receptor_position + tail_offset,
						Vector2(tail_width, tail_size.y * (-1.0 if downscroll else 1.0)),
					),
					false,
					sus_modulate,
				)


func get_sustain_texture(anim_name: StringName, frame: int, is_tail: bool) -> Texture2D:
	if cached_sustain_textures.has(anim_name):
		var cached_tex := cached_sustain_textures[anim_name]
		if cached_tex.get_meta(&"frame") == frame:
			return cached_tex

	var note_frames := skin.get_note_frames()
	if not note_frames.has_animation(anim_name):
		return null

	frame = clampi(frame, 0, note_frames.get_frame_count(anim_name))

	var texture := note_frames.get_frame_texture(anim_name, frame).duplicate()
	if texture is AtlasTexture:
		var offset := skin.sustain_tail_texture_offset if is_tail else skin.sustain_texture_offset
		texture.region = Rect2(
			texture.region.position + offset.position,
			texture.region.size + offset.size,
		)

	texture.set_meta(&"frame", frame)
	cached_sustain_textures[anim_name] = texture

	return texture


func _on_note_hit(note: NoteData) -> void:
	var receptor := receptors[note.direction]
	receptor.animation_state = StrumlineManager.ReceptorState.HIT

	if (
		(note.state == NoteData.NoteState.ALIVE) or
		(
			note.state == NoteData.NoteState.HELD and
			receptor.hold_timer >= Conductor.beat_delta / 4.0
		)
	):
		receptor.hold_timer = 0.0
		receptor.animation_progress = 0.0
