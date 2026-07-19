class_name SymbolDictionary
extends Object


static func parse_symbol(
	symbol: Dictionary,
	optimized: bool,
	output_dict: Dictionary[StringName, TextureAtlasSymbol],
) -> void:
	var key: String = symbol.get("SN" if optimized else "SYMBOL_name")
	output_dict[StringName(key)] = TextureAtlasSymbol.parse(symbol, optimized)


static func parse_array(
	array: Array,
	optimized: bool,
	output_dict: Dictionary[StringName, TextureAtlasSymbol],
) -> void:
	for symbol: Dictionary in array:
		parse_symbol(symbol, optimized, output_dict)


static func load_symbols_directory(
	optimized: bool,
	dir: DirAccess,
	folder: String,
	output_dict: Dictionary[StringName, TextureAtlasSymbol],
) -> void:
	if dir == null:
		return

	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if dir.current_is_dir() and name != "." and name != "..":
			load_symbols_directory(
				optimized,
				DirAccess.open(dir.get_current_dir() + "/" + name),
				folder + name + "/",
				output_dict,
			)
		elif name.get_extension() == "json":
			var raw: String = FileAccess.get_file_as_string(dir.get_current_dir() + "/" + name)
			var json: Variant = JSON.parse_string(raw)
			if json == null:
				printerr("Failed to parse %s as JSON!" % [folder + name])
				return

			if json is not Dictionary:
				printerr("JSON for symbol %s must be a Dictionary!" % [folder + name])
				return

			json = json as Dictionary

			var symbol_name: String = folder + name.get_file().get_basename()
			output_dict[StringName(symbol_name)] = TextureAtlasSymbol.parse(json, optimized)

		name = dir.get_next()
