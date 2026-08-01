class_name StrumlineRenderer2D
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

@export var spacing := 112.0
@export var scroll_speed := 1.0
@export var splash_alpha := 0.8
@export var underlay_alpha := 0.0
@export var downscroll := false

@export_group("Animations", "animations_")
@export var animations_note: Array[StringName] = [&"left note", &"down note", &"up note", &"right note"]
@export var animations_sustain: Array[StringName] = [&"left sustain", &"down sustain", &"up sustain", &"right sustain"]
@export var animations_tail: Array[StringName] = [&"left sustain end", &"down sustain end", &"up sustain end", &"right sustain end"]

var _note_textures: Array[Texture2D]
var _sustain_textures: Array[Texture2D]
var _tail_textures: Array[Texture2D]

var _receptor_positions: PackedVector2Array


func _process(delta: float) -> void:
	if not is_instance_valid(parent):
		return

	var receptor_frames := skin.get_receptor_frames()

	for i: int in receptors.size():
		var state := parent.receptor_states[i]
		var receptor := receptors[i]
		receptor.hold_timer += delta

		var animation_length := (
			receptor_frames.get_frame_count(receptor.animation_name) /
			receptor_frames.get_animation_speed(receptor.animation_name)
		)

		if receptor.animation_state != state:
			if (not parent.cpu) or receptor.animation_progress >= animation_length:
				receptor.animation_state = state
				receptor.animation_progress = 0.0
			else:
				receptor.animation_progress += delta
		else:
			receptor.animation_progress += delta

		receptor.splash_progress += delta

	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(parent):
		return

	if use_skin_texture_filter:
		texture_filter = skin.note_filter

	var time := Conductor.time
	var scaled_scroll_speed := scroll_speed / Conductor.rate
	var spawn_time: float = 0.8 / (0.45 * absf(scaled_scroll_speed))

	var receptor_frames := skin.get_receptor_frames()
	var receptor_scale := skin.receptor_scale
	_receptor_positions.resize(receptors.size())

	if underlay_alpha > 0.0:
		draw_rect(
			Rect2(
				Vector2(
					-spacing * 2.0,
					-position.y,
				),
				Vector2(
					spacing * receptors.size(),
					720.0,
				)
			),
			Color(Color.BLACK, underlay_alpha)
		)

	for i: int in receptors.size():
		var receptor := receptors[i]
		var receptor_anim := receptor.animation_name

		var anim_length := receptor_frames.get_frame_count(receptor_anim)
		if anim_length == 0:
			continue

		var frame := floori(receptor.animation_progress * receptor_frames.get_animation_speed(receptor_anim))
		var texture := receptor_frames.get_frame_texture(
			receptor_anim,
			mini(frame, anim_length - 1)
		)

		_receptor_positions[i] = Vector2(
			(i * spacing) - (spacing * 1.5),
			0.0
		)

		draw_texture_rect(
			texture,
			Rect2(
				_receptor_positions[i] - (texture.get_size() * receptor_scale / 2.0),
				texture.get_size() * receptor_scale,
			),
			false
		)

	var note_frames := skin.get_note_frames()

	_note_textures.resize(animations_note.size())
	_sustain_textures.resize(animations_sustain.size())
	_tail_textures.resize(animations_tail.size())

	for index: int in range(parent.notes_index, parent.notes.size()):
		var note := parent.notes[index]
		if time < note.time - spawn_time:
			break

		var receptor_position := _receptor_positions[note.direction]

		# TODO: looping note anims ig
		var texture := _note_textures[note.direction]
		if not texture:
			texture = note_frames.get_frame_texture(animations_note[note.direction], 0)
			_note_textures[note.direction] = texture

		var sustain_texture := _sustain_textures[note.direction]
		if not sustain_texture:
			sustain_texture = get_sustain_texture(note.direction, 0, false)
			_sustain_textures[note.direction] = sustain_texture

		var tail_texture := _tail_textures[note.direction]
		if not tail_texture:
			tail_texture = get_sustain_texture(note.direction, 0, true)
			_tail_textures[note.direction] = tail_texture

		draw_sustain(note, sustain_texture, tail_texture, receptor_position)

		if note.state == NoteData.NoteState.ALIVE:
			draw_note(note, texture, receptor_position)

	var splash_frames := skin.get_splash_frames()
	var splash_scale := skin.splash_scale

	for i: int in receptors.size():
		var receptor := receptors[i]
		var splash_anim := receptor.splash_animation

		if not splash_frames.has_animation(splash_anim):
			continue

		var anim_length := splash_frames.get_frame_count(splash_anim)
		if anim_length == 0:
			continue

		var frame := floori(receptor.splash_progress * splash_frames.get_animation_speed(splash_anim))
		if frame > anim_length - 1:
			continue

		var texture := splash_frames.get_frame_texture(
			splash_anim,
			frame
		)

		if not texture:
			continue

		var receptor_position := _receptor_positions[i]
		draw_texture_rect(
			texture,
			Rect2(
				receptor_position - (texture.get_size() * splash_scale / 2.0),
				texture.get_size() * splash_scale,
			),
			false,
			Color(Color.WHITE, splash_alpha)
		)


func get_note_offset(note: NoteData) -> float:
	var time_difference := note.time - Conductor.time
	var time_to_pixels := 450.0 * (scroll_speed / Conductor.rate)

	if downscroll:
		return -time_difference * time_to_pixels
	else:
		return time_difference * time_to_pixels


func draw_sustain(
	note: NoteData,
	sustain_texture: Texture2D,
	tail_texture: Texture2D,
	receptor_position: Vector2
) -> void:
	if note.length <= 0.0:
		return

	var note_scale := skin.note_scale
	var sustain_width := skin.sustain_size
	var tail_width := skin.sustain_tail_size

	var time_to_pixels := 450.0 * (scroll_speed / Conductor.rate)
	var time_difference := note.time - Conductor.time

	var sus_height: float
	var tail_size := tail_texture.get_size() * note_scale
	var sus_modulate := Color(Color.WHITE, skin.sustain_alpha)

	if note.state == NoteData.NoteState.HELD:
		sus_modulate.a = note.grace_timer / Conductor.sustain_release_delta
		sus_height = (note.length + time_difference) * time_to_pixels
		sus_height -= tail_size.y
	else:
		sus_height = note.length * time_to_pixels
		sus_height -= tail_size.y
		receptor_position.y += get_note_offset(note)

	if sus_height > 0.0:
		var sus_offset := (
			-Vector2(sustain_width / 2.0, sus_height) if downscroll
			else Vector2(-sustain_width / 2.0, 0)
		)

		draw_texture_rect(
			sustain_texture,
			Rect2(
				receptor_position + sus_offset,
				Vector2(sustain_width, sus_height),
			),
			false,
			sus_modulate,
		)
	else:
		tail_size.y += sus_height

	var tail_offset := (
		-Vector2(tail_width / 2.0, maxf(sus_height, 0.0)) - Vector2(0.0, tail_size.y) if downscroll
		else Vector2(-tail_width / 2.0, maxf(sus_height, 0.0))
	)

	draw_texture_rect(
		tail_texture,
		Rect2(
			receptor_position + tail_offset,
			Vector2(tail_width, tail_size.y * (-1.0 if downscroll else 1.0)),
		),
		false,
		sus_modulate,
	)


func draw_note(note: NoteData, texture: Texture2D, receptor_position: Vector2) -> void:
	if not texture:
		return

	var note_scale := skin.note_scale
	var note_position := receptor_position + Vector2(0.0, get_note_offset(note))

	draw_texture_rect(
		texture,
		Rect2(
			note_position - (texture.get_size() * note_scale / 2.0),
			texture.get_size() * note_scale
		),
		false,
	)


func get_sustain_texture(direction: int, frame: int, is_tail: bool) -> Texture2D:
	var cache := _tail_textures if is_tail else _sustain_textures
	if direction < cache.size():
		var cached_tex := cache[direction]
		if cached_tex and cached_tex.get_meta(&"frame") == frame:
			return cached_tex

	var anim_name := (animations_tail if is_tail else animations_sustain)[direction]
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
	cache[direction] = texture

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

	if (
		(not parent.cpu) and
		absf(Conductor.time - note.time) < 0.045 and
		note.state == NoteData.NoteState.ALIVE
	):
		receptor.splash_progress = 0.0
		receptor.splash_animation = &"%s_%d" % [receptor.direction, randi_range(1, 2)]
