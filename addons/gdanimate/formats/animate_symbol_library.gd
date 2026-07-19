@tool
@abstract
class_name AnimateSymbolLibrary
extends Resource


signal redraw_requested
signal symbols_changed
signal path_changed

@export_tool_button("Parse", "Reload") var parse_button := parse
@export_tool_button("Cache", "Save") var cache_button := cache

@export_storage var has_symbols_with_commas := false


static func format_symbol_list(symbols: PackedStringArray) -> String:
	if symbols.is_empty():
		return " "

	var keys := Array(symbols)
	keys.sort_custom(sort_alphabetically)
	return " ," + ",".join(keys)


static func sort_alphabetically(a: Variant, b: Variant) -> bool:
	if "to_lower" in a and "to_lower" in b:
		return a.to_lower() < b.to_lower()

	return a < b


static func string_has_no_commas(string: String) -> bool:
	return not string.contains(",")


static func check_symbols_have_commas(symbols: PackedStringArray) -> bool:
	var symbols_array := Array(symbols)
	return symbols_array.all(string_has_no_commas)


@abstract
func parse() -> void


@abstract
func cache() -> void


@abstract
func draw_2d(target: AnimateSymbol2D) -> void


@abstract
func get_framerate() -> float


@abstract
func get_filename() -> StringName


@abstract
func get_symbol_list() -> PackedStringArray


@abstract
func get_symbol_length(key: StringName) -> int


@abstract
func get_symbol_rect(key: StringName) -> Rect2


@abstract
func has_symbol(symbol: StringName) -> bool
