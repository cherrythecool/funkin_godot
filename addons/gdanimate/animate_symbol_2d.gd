@tool
@icon("animate_symbol_2d.svg")
class_name AnimateSymbol2D
extends Node2D
## Node that plays out a Flash/Adobe Animate symbol.
##
## Symbols can be stored in different formats but are accepted
## as any [AnimateSymbolLibrary] and are played back similar to
## an [AnimatedSprite2D] with this node.
## [br][br]Note: Some [AnimateSymbolLibrary] formats may not always
## support certain properties.
## [br]Example: [member AnimateSymbol2D.centered].


signal animation_finished
signal animation_looped
signal frame_changed
signal symbol_changed
signal symbol_library_changed

@export_group("Symbol", "symbol_")

## The list of [AnimateSymbolLibrary]s currently loaded
## in this [AnimateSymbol2D].
@export var symbol_libraries: Array[AnimateSymbolLibrary] = []

## The index of the current [AnimateSymbolLibrary] in
## the [member AnimateSymbol2D.symbol_libraries] array.
@export var symbol_library_index: int = 0:
	set(value):
		value = clampi(value, 0, maxi(symbol_libraries.size() - 1, 0))
		if not symbol_libraries.is_empty():
			value %= symbol_libraries.size()

		if symbol_library_index != value:
			symbol_library_index = value
			symbol_library_changed.emit()
			_clear_canvas_item_pool()
			notify_property_list_changed()
			queue_redraw()

		_frame_internal = _frame_internal

@export_tool_button("Reparse Current", "Reload") var symbol_reparse := reparse_current
@export_tool_button("Cache Current", "Save") var symbol_cache := cache_current

@export_group("Animation Playback")
@export var symbol := &"":
	set(value):
		if symbol != value:
			symbol = value
			symbol_changed.emit()
			queue_redraw()

		_frame_internal = _frame_internal

@export var frame: int = 0:
	set(value):
		_frame_internal = value
		_frame_progress = 0.0
	get:
		return _frame_internal

@export var speed_scale: float = 1.0
@export var autoplay := false
@export var playing := false
@export var loop := false

@export_group("Offset")

## If [code]true[/code], tries to center the current animation
## based on its bounding box.
@export var centered := true:
	set(value):
		if centered != value:
			queue_redraw()
		centered = value

## Offsets the current frame by this amount in pixels.
@export var offset := Vector2.ZERO:
	set(value):
		if offset != value:
			queue_redraw()
		offset = value

## Flips the current frame horizontally based on its center point.
@export var flip_h := false:
	set(value):
		if flip_h != value:
			queue_redraw()
		flip_h = value

## Flips the current frame vertically based on its center point.
@export var flip_v := false:
	set(value):
		if flip_v != value:
			queue_redraw()
		flip_v = value

var _current_library: AnimateSymbolLibrary:
	set(value):
		if _current_library == value:
			return
		if is_instance_valid(_current_library):
			_disconnect_from_library(_current_library)

		_current_library = value
		if is_instance_valid(_current_library):
			_connect_to_library(_current_library)

		queue_redraw()

var _frame_progress: float = 0.0
var _frame_internal: int = 0:
	set(value):
		if is_instance_valid(_current_library):
			value = clampi(value, 0, maxi(get_animation_length() - 1, 0))

		if _frame_internal != value:
			_frame_internal = value
			frame_changed.emit()
			queue_redraw()

var _last_symbol_libraries: Array[AnimateSymbolLibrary]

# Pool is cleared when node is freed OR when library changes
var _canvas_item_pool: Array[RID]


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			set_process(true)

			if autoplay and not Engine.is_editor_hint():
				playing = true

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


func _validate_property(property: Dictionary) -> void:
	match property.get("name"):
		"symbol":
			property.hint = PROPERTY_HINT_PLACEHOLDER_TEXT
			property.hint_string = "Name or Prefix"

			if not is_instance_valid(_current_library):
				return
			if _current_library.has_symbols_with_commas:
				return
			var symbols: PackedStringArray = _current_library.get_symbol_list()
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


func get_animation_length() -> int:
	if is_instance_valid(_current_library):
		return _current_library.get_symbol_length(symbol)
	else:
		return 0


func cache_current() -> void:
	if is_instance_valid(_current_library):
		_current_library.cache()


func reparse_current() -> void:
	if is_instance_valid(_current_library):
		_current_library.parse()


func _clear_canvas_item(clear_pool: bool) -> void:
	RenderingServer.canvas_item_clear(get_canvas_item())

	if clear_pool:
		_clear_canvas_item_pool()


func _reset_canvas_item_pool() -> void:
	for rid: RID in _canvas_item_pool:
		if not rid.is_valid():
			continue

		RenderingServer.canvas_item_clear(rid)
		RenderingServer.canvas_item_set_parent(rid, RID())


func _clear_canvas_item_pool() -> void:
	for rid: RID in _canvas_item_pool:
		if not rid.is_valid():
			continue

		RenderingServer.canvas_item_clear(rid)
		RenderingServer.free_rid(rid)

	_canvas_item_pool.clear()


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

	var frames_per_second: float = _current_library.get_framerate()
	var seconds_per_frame := 1.0 / frames_per_second
	_frame_progress += absf(delta * frames_per_second * speed_scale)

	while _frame_progress >= 1.0:
		var frames_added := int(signf(speed_scale))
		_frame_progress -= 1.0

		if frames_added == 0:
			continue

		var animation_length: int = get_animation_length()
		var length_index := maxi(animation_length - 1, 0)
		if loop:
			var looped := (
				_frame_internal + frames_added >= animation_length or
				_frame_internal + frames_added < 0
			)

			_frame_internal = wrapi(
				_frame_internal + frames_added,
				0,
				animation_length
			)

			if looped:
				animation_looped.emit()
		else:
			var finished := (
				frame + frames_added <= 0 or
				frame + frames_added >= length_index
			)

			_frame_internal = clampi(
				_frame_internal + frames_added,
				0,
				length_index
			)

			if finished:
				_frame_progress = 0.0
				playing = false
				animation_finished.emit()


func _on_symbols_changed() -> void:
	notify_property_list_changed()

	if is_instance_valid(_current_library):
		var has_symbol: bool = _current_library.has_symbol(symbol)
		var no_symbols: bool = _current_library.get_symbol_list().is_empty()
		if has_symbol or no_symbols:
			return

	symbol = &""


func _on_redraw_requested() -> void:
	queue_redraw()


func _disconnect_from_library(library: AnimateSymbolLibrary) -> void:
	if library.symbols_changed.is_connected(_on_symbols_changed):
		library.symbols_changed.disconnect(_on_symbols_changed)
	if library.redraw_requested.is_connected(_on_redraw_requested):
		library.redraw_requested.disconnect(_on_redraw_requested)


func _connect_to_library(library: AnimateSymbolLibrary) -> void:
	if not library.symbols_changed.is_connected(_on_symbols_changed):
		library.symbols_changed.connect(_on_symbols_changed)
	if not library.redraw_requested.is_connected(_on_redraw_requested):
		library.redraw_requested.connect(_on_redraw_requested)

	_on_symbols_changed()


func _update_editor_library_signals() -> void:
	for library: AnimateSymbolLibrary in _last_symbol_libraries:
		if is_instance_valid(library):
			library.path_changed.disconnect(notify_property_list_changed)

	_last_symbol_libraries = symbol_libraries

	for library: AnimateSymbolLibrary in symbol_libraries:
		if is_instance_valid(library):
			library.path_changed.connect(notify_property_list_changed)

	notify_property_list_changed()
