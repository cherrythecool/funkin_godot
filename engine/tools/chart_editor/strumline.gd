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


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"chart_place_note") and target:
		var draw_info := get_draw_info()
		var grid_size: float = draw_info[&"grid_size"]
		var note_column_offset: int = draw_info[&"note_column_offset"]
		var mouse := get_snapped_mouse_position(grid_size)
		var grid_position := mouse / grid_size
		var step := Conductor.step + note_column_offset + grid_position.y
		target_index = 0

		var note := NoteData.new()
		note.time = Conductor.get_time_at_step(step, Conductor.timing_changes)
		note.direction = int(grid_position.x)
		NoteData.set_timings(note, Conductor.timing_changes)
		target.add_note(note)
		target.sort_notes()
	if event.is_action_pressed(&"chart_remove_note"):
		pass


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
			get_snapped_mouse_position(grid_size),
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
				draw_texture_rect(sustain_texture, sustain_rect, false)

			tail_rect.position.y += maxf(tail_rect.size.y - (grid_size / 2.0), 0.0)
			tail_rect.size.y = minf(grid_size / 2.0, tail_rect.size.y)
			draw_texture_rect(tail_texture, tail_rect, false)

		var rect := Rect2(
			grid_size * float(note.direction),
			grid_size * (note_step - current_step - float(note_column_offset)),
			grid_size,
			grid_size,
		)
		rect.position += (Vector2(grid_size, grid_size) - rect.size) / 2.0

		var note_anim := &"%s note" % note_directions[note.direction]
		var note_texture := note_frames.get_frame_texture(note_anim, 0)
		draw_texture_rect(note_texture, rect, false)

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
	var current_step := Conductor.step
	return -(current_step - int(Conductor.step)) * grid_size


func get_snapped_mouse_position(grid_size: float) -> Vector2:
	var fractional_offset := get_fractional_offset(grid_size)
	var mouse_position := get_local_mouse_position()
	var grid_position := Vector2(
		int(mouse_position.x / grid_size),
		int((mouse_position.y - fractional_offset) / grid_size),
	) * grid_size
	return grid_position + Vector2(0, fractional_offset)


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
