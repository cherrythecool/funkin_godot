@tool
@icon("animate_symbol_2d.svg")
class_name AnimateSymbol2D
extends Node2D
## Node that plays out a symbol from Flash/Adobe Animate.
##
## Symbols can be stored in different formats but are accepted
## as any [AnimateSymbolLibrary] and are played back similar to
## an [AnimatedSprite2D] with this node.
## [br][br][b]Note[/b]: Some [AnimateSymbolLibrary] formats may not always
## support certain properties.
## [br][br]
## The built in formats support as much as possible, but it is not guaranteed.


## Emitted when [member symbol] changes.
## [br][br]
## [b]Note:[/b] This is equivalent to [signal AnimatedSprite2D.animation_changed].
signal symbol_changed

## Emitted when the animation reaches the end, or the start if it is played in reverse. When the animation finishes, it pauses the playback.
## [br][br]
## [b]Note:[/b] This signal is not emitted if an animation is looping.
signal animation_finished

## Emitted when the animation loops.
signal animation_looped

## Emitted when [member frame] changes.
signal frame_changed

## Emitted when [member symbol_library] changes.
## [br][br]
## [b]Note:[/b] This is equivalent to [signal AnimatedSprite2D.sprite_frames_changed].
signal symbol_library_changed

@export_group("Symbol", "symbol_")

## The list of [AnimateSymbolLibrary]s currently loaded
## in this [AnimateSymbol2D].
@export var symbol_libraries: Array[AnimateSymbolLibrary] = []

## The index of the current [AnimateSymbolLibrary] in
## the [member AnimateSymbol2D.symbol_libraries] array.
## [br][br]
## [b]Note:[/b] Changing this does [b]NOT[/b] reset the current [member frame]
## to allow a sprite to be changed between different variations or
## spritesheets without losing the current frame index.
@export var symbol_library_index: int = 0:
	set(value):
		value = clampi(value, 0, maxi(symbol_libraries.size() - 1, 0))

		if symbol_library_index != value:
			symbol_library_index = value
			symbol_library_changed.emit()
			_clear_canvas_item_pool()
			notify_property_list_changed()
			_queue_redraw()

		_frame = _frame

@export_tool_button("Reparse Current", "Reload") var _symbol_reparse := reparse_current
@export_tool_button("Cache Current", "Save") var _symbol_cache := cache_current

@export_group("Animation")

## The current symbol from the [member current_library].
## If this value is changed, the [member frame] counter and the
## [member frame_progress] are reset.
@export var symbol := &"":
	set(value):
		if symbol != value:
			symbol = value
			symbol_changed.emit()
			frame = 0
			_queue_redraw()

## The displayed animation frame's index. Setting this property also resets [member frame_progress].
## If this is not desired, use [method set_frame_and_progress].
@export var frame: int = 0:
	set(value):
		_frame = value
		_frame_progress = 0.0
	get:
		return _frame

## The speed scaling ratio. For example, if this value is [code]1[/code], then the animation
## plays at normal speed. If it's [code]0.5[/code], then it plays at half speed. If it's [code]2[/code],
## then it plays at double speed.
## [br][br]
## If set to a negative value, the animation is played in reverse. If set to [code]0[/code],
## the animation will not advance.
@export var speed_scale: float = 1.0

## [code]true[/code] if the current animation is playing, if set to true will
## start playback.
@export var playing := false

## If [code]true[/code], the current playing animation will loop infinitely.
@export var loop := false

## The key of the symbol to play when the scene loads. (Empty to play nothing)
@export var autoplay: StringName = &""

@export_group("Offset")

## If [code]true[/code], [i]tries[/i] to center the current animation
## based on its bounding box.
@export var centered := true:
	set(value):
		if centered != value:
			centered = value
			_queue_redraw()

## Offsets the current frame by this amount in pixels.
@export var offset := Vector2.ZERO:
	set(value):
		if offset != value:
			offset = value
			_queue_redraw()

## Flips the current frame horizontally based on its center point.
@export var flip_h := false:
	set(value):
		if flip_h != value:
			flip_h = value
			_queue_redraw()

## Flips the current frame vertically based on its center point.
@export var flip_v := false:
	set(value):
		if flip_v != value:
			flip_v = value
			_queue_redraw()

## The progress value between [code]0.0[/code] and [code]1.0[/code] until the
## current frame transitions to the next frame.
## [br][br]
## [b]Note:[/b] If the animation is playing backwards, the value still transitions from [code]0.0[/code] to [code]1.0[/code].
var frame_progress: float:
	set(v):
		_frame_progress = clampf(v, 0.0, 1.0)
	get:
		return minf(_frame_progress, 1.0)

var _current_library: AnimateSymbolLibrary:
	set(value):
		if _current_library == value:
			return
		if is_instance_valid(_current_library):
			_disconnect_from_library(_current_library)

		_current_library = value

		if is_instance_valid(_current_library):
			_connect_to_library(_current_library)

		_queue_redraw()

var _frame_progress: float = 0.0
var _frame: int = 0:
	set(value):
		if is_instance_valid(_current_library):
			value = clampi(value, 0, maxi(get_symbol_length() - 1, 0))

		if _frame != value:
			_frame = value
			frame_changed.emit()
			_queue_redraw()

var _last_symbol_libraries: Array[AnimateSymbolLibrary]
var _last_backbuffer_transform: Transform2D
var _last_values: Dictionary[StringName, Variant]

# Pool is cleared when node is freed OR when library changes
var _canvas_item_pool: Array[RID]
var _cached_rects: Dictionary[RID, Rect2]
var _frame_dirty := false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			set_process(true)

			if (not autoplay.is_empty()) and not Engine.is_editor_hint():
				symbol = autoplay
				frame = 0
				playing = true

		NOTIFICATION_READY:
			_last_backbuffer_transform = _get_backbuffer_transform()
			_last_var_setup(&"self_modulate")
			_last_var_setup(&"material")
			_last_var_setup(&"light_mask")
			_process_animation(0.0)

		NOTIFICATION_EXIT_TREE:
			_clear_canvas_item(true)

		NOTIFICATION_PROCESS:
			if _last_symbol_libraries != symbol_libraries:
				if Engine.is_editor_hint():
					_update_editor_library_signals()
				else:
					_last_symbol_libraries = symbol_libraries

				notify_property_list_changed()
				frame = frame

			_process_animation(get_process_delta_time())

			for key: StringName in _last_values:
				_last_var_check(key)

			var backbuffer_transform := _get_backbuffer_transform()
			if backbuffer_transform != _last_backbuffer_transform:
				_last_backbuffer_transform = backbuffer_transform

				if (not _frame_dirty) and is_instance_valid(_current_library):
					_current_library.update_2d(self)

			_frame_dirty = false


func _validate_property(property: Dictionary) -> void:
	match property.get("name"):
		"symbol", "autoplay":
			property.hint = PROPERTY_HINT_PLACEHOLDER_TEXT
			property.hint_string = "Name or Prefix"

			if not (
				is_instance_valid(_current_library) and
				not _current_library.has_symbols_with_commas
			):
				return

			var symbols := _current_library.get_symbol_list()
			if symbols.is_empty():
				return

			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = AnimateSymbolLibrary.format_symbol_list(symbols)
		"symbol_library_index":
			property.hint_string = ""

			if symbol_libraries.is_empty():
				property.hint = PROPERTY_HINT_NONE
				return

			property.hint = PROPERTY_HINT_ENUM

			for i: int in symbol_libraries.size():
				var filename := "N/A"
				var library: AnimateSymbolLibrary = symbol_libraries[i]
				if is_instance_valid(library):
					filename = library.get_filename()

				property.hint_string += "%d - %s" % [i, filename]
				if i != symbol_libraries.size() - 1:
					property.hint_string += ","


func _draw() -> void:
	if is_instance_valid(_current_library):
		_current_library.draw_2d(self)
	else:
		_clear_canvas_item(true)


## Plays the animation with key [param symbol_name].
## [br][br]
## If this method is called with that same animation name, or with no name
## parameter, the assigned animation will resume playing if it was paused.
func play(symbol_name: StringName = &"", from_end: bool = false) -> void:
	playing = true

	if not symbol_name.is_empty():
		if symbol != symbol_name:
			if from_end:
				frame = maxi(get_symbol_length(symbol_name) - 1, 0)
			else:
				frame = 0

		symbol = symbol_name


## Pauses the currently playing animation.
## The [member frame] and [member frame_progress] will be kept and calling [method play] without
## arguments will resume the animation from the current playback position.
func pause() -> void:
	playing = false


## Stops the currently playing animation. The animation position is reset to [code]0[/code].
func stop() -> void:
	frame = 0
	playing = false


## Returns the actual playing speed of current symbol or [code]0[/code] if not playing.
## This speed is the [member speed_scale] property otherwise.
## [br][br]
## Returns a negative value if the current animation is playing backwards.
func get_playing_speed() -> float:
	if playing:
		return speed_scale
	else:
		return 0.0


## Sets [member frame] and [member frame_progress] to the given values.
## Unlike setting [member frame], this method does not reset the [member frame_progress]
## to [code]0.0[/code] implicitly.
func set_frame_and_progress(new_frame: int, progress: float) -> void:
	_frame = new_frame
	frame_progress = progress


## Convenient function to get the length of the currently playing [member symbol]
## or any other [param symbol_name].
func get_symbol_length(symbol_name: StringName = &"") -> int:
	if is_instance_valid(_current_library):
		return _current_library.get_symbol_length(symbol if symbol_name.is_empty() else symbol_name)
	else:
		return 0


## If there is a valid [AnimateSymbolLibrary] active this function caches the data
## from the library using [method AnimateSymbolLibrary.cache].
func cache_current() -> void:
	if is_instance_valid(_current_library):
		_current_library.cache()


## If there is a valid [AnimateSymbolLibrary] active this function reparses the data
## from the library using [method AnimateSymbolLibrary.parse].
func reparse_current() -> void:
	if is_instance_valid(_current_library):
		_current_library.parse()


func _connect_to_library(library: AnimateSymbolLibrary) -> void:
	if not library.symbols_changed.is_connected(_on_symbols_changed):
		library.symbols_changed.connect(_on_symbols_changed)
	if not library.redraw_requested.is_connected(_on_redraw_requested):
		library.redraw_requested.connect(_on_redraw_requested)

	_on_symbols_changed()


func _disconnect_from_library(library: AnimateSymbolLibrary) -> void:
	if library.symbols_changed.is_connected(_on_symbols_changed):
		library.symbols_changed.disconnect(_on_symbols_changed)
	if library.redraw_requested.is_connected(_on_redraw_requested):
		library.redraw_requested.disconnect(_on_redraw_requested)


func _on_symbols_changed() -> void:
	notify_property_list_changed()

	if is_instance_valid(_current_library):
		var has_symbol: bool = _current_library.has_symbol(symbol)
		var no_symbols: bool = _current_library.get_symbol_list().is_empty()
		if has_symbol or no_symbols:
			return

	symbol = &""


func _update_editor_library_signals() -> void:
	for library: AnimateSymbolLibrary in _last_symbol_libraries:
		if is_instance_valid(library):
			library.path_changed.disconnect(notify_property_list_changed)

	_last_symbol_libraries = symbol_libraries

	for library: AnimateSymbolLibrary in symbol_libraries:
		if is_instance_valid(library):
			library.path_changed.connect(notify_property_list_changed)

	notify_property_list_changed()


func _on_redraw_requested() -> void:
	_queue_redraw()


func _queue_redraw() -> void:
	_frame_dirty = true
	queue_redraw()


func _get_backbuffer_transform() -> Transform2D:
	return get_viewport().get_stretch_transform() * get_global_transform_with_canvas()


func _clear_canvas_item(clear_pool: bool) -> void:
	RenderingServer.canvas_item_clear(get_canvas_item())

	if clear_pool:
		_clear_canvas_item_pool()


func _clear_canvas_item_pool() -> void:
	for rid: RID in _canvas_item_pool:
		if not rid.is_valid():
			continue

		RenderingServer.canvas_item_clear(rid)
		RenderingServer.free_rid(rid)

	_canvas_item_pool.clear()


func _reset_canvas_item_pool() -> void:
	for rid: RID in _canvas_item_pool:
		if not rid.is_valid():
			continue

		RenderingServer.canvas_item_clear(rid)
		RenderingServer.canvas_item_set_parent(rid, RID())


func _last_var_setup(variable: StringName) -> void:
	_last_values[variable] = get(variable)


func _last_var_check(variable: StringName) -> void:
	var current: Variant = get(variable)
	if _last_values[variable] != current:
		_last_values[variable] = current
		_queue_redraw()


func _process_animation(delta: float) -> void:
	if symbol_libraries.is_empty():
		symbol_library_index = 0
		_current_library = null
		_frame_progress = 0.0
		return

	if symbol_library_index > symbol_libraries.size() - 1:
		symbol_library_index = symbol_libraries.size() - 1

	_current_library = symbol_libraries[symbol_library_index]

	if (not is_instance_valid(_current_library)) or not playing:
		_frame_progress = 0.0
		return

	var frames_per_second := _current_library.get_framerate()
	var seconds_per_frame := 1.0 / frames_per_second
	_frame_progress += absf(delta * frames_per_second * speed_scale)

	while _frame_progress >= 1.0:
		var frames_added := int(signf(speed_scale))
		_frame_progress -= 1.0

		if frames_added == 0:
			continue

		var animation_length := get_symbol_length()
		var length_index := maxi(animation_length - 1, 0)
		if loop:
			var looped := (
				_frame + frames_added >= animation_length or
				_frame + frames_added < 0
			)

			_frame = wrapi(
				_frame + frames_added,
				0,
				animation_length,
			)

			if looped:
				animation_looped.emit()
		else:
			var finished := (
				frame + frames_added <= 0 or
				frame + frames_added >= length_index
			)

			_frame = clampi(
				_frame + frames_added,
				0,
				length_index,
			)

			if finished:
				_frame_progress = 0.0
				playing = false
				animation_finished.emit()
