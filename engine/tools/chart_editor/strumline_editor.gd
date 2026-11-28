extends PanelContainer


@export var key_label: Label

@export var color_1 := Color.GRAY
@export var color_2 := Color.DIM_GRAY

@export var note_directions: Array[StringName] = [&"left", &"down", &"up", &"right"]
@export var note_frames: SpriteFrames = null

var target: Strumline
var target_key: StringName
var target_index: int = 0
var mouse_active := false
var snapping_value: float = 1.0
var prev_hover := false
var selected_notes: Array[NoteData] = []


func _ready() -> void:
	if not note_frames:
		note_frames = load("uid://b3r2xop0whqyf")

	if key_label:
		key_label.text = target_key.capitalize()
		key_label.tooltip_text = target_key

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _process(_delta: float) -> void:
	queue_redraw()
	update_mouse_state()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"chart_place_note") or event.is_action_pressed(&"chart_remove_note"):
		if event is not InputEventMouseButton:
			return

		event = event as InputEventMouseButton
		if (
			event.window_id == get_window().get_window_id() and
			not get_global_rect().has_point(event.global_position)
		):
			selected_notes.clear()


func _gui_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed(&"chart_remove_note") or
		(event is InputEventMouseMotion and Input.is_action_pressed(&"chart_remove_note"))
	):
		var closest := get_my_current_note()
		if closest:
			target.notes.erase(closest)
			target.sort_notes()

	if event.is_action_pressed(&"chart_place_note") and target:
		var closest := get_my_current_note()
		if closest:
			selected_notes.clear()
			selected_notes.push_back(closest)
		else:
			selected_notes.clear()
			var draw_info := get_draw_info()
			var grid_size: float = draw_info[&"grid_size"]
			var note_column_offset: int = draw_info[&"note_column_offset"]
			var mouse := get_snapped_mouse_position(grid_size, Vector2(1.0, snapping_value))
			var grid_position := mouse / grid_size
			var step := Conductor.step + note_column_offset + grid_position.y
			target_index = 0

			if step < 0:
				return

			var note := NoteData.new()
			note.time = Conductor.get_time_at_step(step, Conductor.timing_changes)
			note.direction = int(grid_position.x)
			NoteData.set_timings(note, Conductor.timing_changes)
			target.add_note(note)
			target.sort_notes()
			selected_notes.push_back(note)


func get_my_current_note() -> NoteData:
	var draw_info := get_draw_info()
	var grid_size: float = draw_info[&"grid_size"]
	var note_column_offset: int = draw_info[&"note_column_offset"]
	var snapped_mouse := get_snapped_mouse_position(grid_size, Vector2(1.0, snapping_value))
	var snapped_grid_position := snapped_mouse / grid_size
	var snapped_step := Conductor.step + note_column_offset + snapped_grid_position.y

	var mouse := get_grid_mouse_position(grid_size)
	var grid_position := mouse / grid_size
	var step := Conductor.step + note_column_offset + grid_position.y
	target_index = 0

	var notes := target.notes.filter(func(note_: NoteData) -> bool:
		return absf(note_.step - snapped_step) <= 0.25
	)

	var closest: NoteData = null
	for note: NoteData in notes:
		if note.direction != int(grid_position.x):
			continue

		if (not closest) or absf(note.step - step) < absf(closest.step - step):
			closest = note

	return closest


func _draw() -> void:
	if not target:
		return

	#var current_time := Conductor.time

	var draw_info := get_draw_info()
	var grid_size: float = draw_info[&"grid_size"]
	var rows: int = draw_info[&"rows"]
	var columns: int = draw_info[&"columns"]
	var column_range: Array = draw_info[&"column_range"]
	var column_end_offset: int = draw_info[&"column_end_offset"]
	var first_column_offset: int = draw_info[&"first_column_offset"]
	var last_column_offset: int = draw_info[&"last_column_offset"]
	var note_column_offset: int = draw_info[&"note_column_offset"]

	var current_step := Conductor.step
	var offset := -current_step * grid_size
	var first_column: int = floori(current_step + first_column_offset)
	var last_column: int = floori(current_step + last_column_offset)

	for column: int in column_range:
		for row: int in rows:
			var rect := Rect2(grid_size * float(row), grid_size * float(column), grid_size, grid_size)
			rect.position.y = wrapf(rect.position.y + offset, -grid_size, (columns + 1 + column_end_offset) * grid_size)
			draw_rect(
				rect,
				color_1 if (column + row) % 2 == 0 else color_2,
			)

	if mouse_active:
		var rect := Rect2(
			get_snapped_mouse_position(grid_size, Vector2(1.0, snapping_value)),
			Vector2(grid_size, grid_size),
		)
		draw_rect(rect, Color.WHITE)

	var notes := target.notes
	var note_range := range(target_index, notes.size())
	for index: int in note_range:
		var note := notes[index]
		var note_step := note.step
		var sustain_step := note.sustain_step
		if sustain_step < first_column:
			target_index += 1
			continue

		if note_step > (last_column - note_column_offset):
			break

		var note_mod := Color.WHITE
		if note in selected_notes:
			note_mod = Color.DIM_GRAY

		if note.length > 0.0:
			var sustain_anim := &"%s sustain" % note_directions[note.direction]
			var sustain_texture := note_frames.get_frame_texture(sustain_anim, 0)

			var tail_anim := &"%s sustain end" % note_directions[note.direction]
			var tail_texture := note_frames.get_frame_texture(tail_anim, 0)

			var tail_rect := Rect2(
				grid_size * float(note.direction),
				grid_size * (note_step - current_step - float(note_column_offset)),
				grid_size * 0.333,
				grid_size * (sustain_step - note_step),
			)

			tail_rect.position += Vector2(
				(grid_size - tail_rect.size.x) / 2.0,
				grid_size / 2.0,
			)

			if tail_rect.size.y > grid_size / 2.0:
				var sustain_rect := tail_rect
				sustain_rect.size.y -= grid_size / 2.0
				draw_texture_rect(sustain_texture, sustain_rect, false, note_mod)

			tail_rect.position.y += maxf(tail_rect.size.y - (grid_size / 2.0), 0.0)
			tail_rect.size.y = minf(grid_size / 2.0, tail_rect.size.y)
			draw_texture_rect(tail_texture, tail_rect, false, note_mod)

		var rect := Rect2(
			grid_size * float(note.direction),
			grid_size * (note_step - current_step - float(note_column_offset)),
			grid_size,
			grid_size,
		)
		rect.position += (Vector2(grid_size, grid_size) - rect.size) / 2.0

		var note_anim := &"%s note" % note_directions[note.direction]
		var note_texture := note_frames.get_frame_texture(note_anim, 0)
		draw_texture_rect(note_texture, rect, false, note_mod)

	var line_height := 4.0
	draw_rect(
		Rect2(
			0,
			(-note_column_offset * grid_size) + (grid_size / 2.0) - (line_height / 2.0),
			grid_size * float(rows),
			line_height,
		),
		Color.WHITE
	)


func _on_mouse_entered() -> void:
	mouse_active = true


func _on_mouse_exited() -> void:
	mouse_active = false


func _on_time_shifted() -> void:
	if (not target) or target.notes.is_empty():
		return

	var draw_info := get_draw_info()
	var note_column_offset: int = draw_info[&"first_column_offset"] + 2
	var current_step := Conductor.step
	while target_index > 0 and target.notes[target_index - 1].sustain_step > current_step + note_column_offset:
		target_index -= 1


func get_fractional_offset(grid_size: float) -> float:
	return -wrapf(Conductor.step, 0.0, 1.0) * grid_size


func get_grid_mouse_position(grid_size: float) -> Vector2:
	var fractional_offset := get_fractional_offset(grid_size)
	var mouse_position := get_local_mouse_position()
	var grid_position := Vector2(
		mouse_position.x / grid_size,
		(mouse_position.y - fractional_offset - (grid_size / 2.0)) / grid_size,
	) * grid_size
	return grid_position + Vector2(0, fractional_offset)


func get_snapped_mouse_position(grid_size: float, snap: Vector2 = Vector2.ONE) -> Vector2:
	#return Vector2(
		#Vector2i(get_grid_mouse_position(grid_size) / (grid_size * snap))
	#) * (grid_size * snap)
	var fractional_offset := get_fractional_offset(grid_size)
	var mouse_position := get_local_mouse_position()
	var grid_position := Vector2(
		mouse_position.x,
		mouse_position.y - fractional_offset,
	)
	grid_position = Vector2i(grid_position / (grid_size * snap))
	grid_position *= grid_size * snap
	grid_position.y += fractional_offset
	return grid_position


func get_draw_info() -> Dictionary[StringName, Variant]:
	if not target:
		return {}

	var grid_size: float = size.x / float(target.key_count)
	var rows: int = target.key_count
	var columns: int = floori(size.y / grid_size)
	var column_range := range(-1 -floori(float(columns) / 2.0), roundi(float(columns) / 2.0) + 1)
	var column_end_offset := 0
	if column_range.size() % 2 == 1:
		column_range.push_back(roundi(float(columns) / 2.0) + 1)
		column_end_offset = 1

	var first_column_offset: int = column_range[0]
	var last_column_offset: int = column_range[column_range.size() - 1]
	var note_column_offset := first_column_offset + 2

	return {
		&"grid_size": grid_size,
		&"rows": rows,
		&"columns": columns,
		&"column_range": column_range,
		&"column_end_offset": column_end_offset,
		&"first_column_offset": first_column_offset,
		&"last_column_offset": last_column_offset,
		&"note_column_offset": note_column_offset,
	}


func update_mouse_state() -> void:
	var draw_info := get_draw_info()
	var grid_size: float = draw_info[&"grid_size"]
	var note_column_offset: int = draw_info[&"note_column_offset"]
	var snapped_mouse := get_grid_mouse_position(grid_size)
	snapped_mouse.x = int(snapped_mouse.x / grid_size)
	var snapped_grid_position := snapped_mouse / grid_size
	var snapped_step := Conductor.step + note_column_offset + snapped_grid_position.y

	var mouse := get_grid_mouse_position(grid_size)
	var grid_position := mouse / grid_size
	var step := Conductor.step + note_column_offset + grid_position.y

	var notes := target.notes.filter(func(note_: NoteData) -> bool:
		return absf(note_.step - snapped_step) < 0.5
	)

	var closest: NoteData = null
	for note: NoteData in notes:
		if note.direction != int(grid_position.x):
			continue

		if (not closest) or absf(note.step - step) < absf(closest.step - step):
			closest = note

	var hovering: bool = false
	if closest:
		hovering = true

	var changed := false
	if Input.is_action_just_pressed(&"chart_remove_note") or Input.is_action_just_released(&"chart_remove_note"):
		changed = true
	elif Input.is_action_just_pressed(&"chart_place_note") or Input.is_action_just_released(&"chart_place_note"):
		changed = true
	elif prev_hover != hovering:
		changed = true
	prev_hover = hovering

	if changed:
		var state := CURSOR_ARROW
		if Input.is_action_pressed(&"chart_remove_note"):
			state = CURSOR_FORBIDDEN
		elif Input.is_action_pressed(&"chart_place_note"):
			state = CURSOR_DRAG
		elif hovering:
			state = CURSOR_POINTING_HAND

		mouse_default_cursor_shape = state


func _on_snap_changed(value: float) -> void:
	snapping_value = value
