extends ModchartModifier

const SWAG_WIDTH:float = 112.0
const HALF_WIDTH:float = 56.0
const SCREEN_HEIGHT:float = 720.0

func get_id() -> String:
	return "drunk"

func get_sub_modifier_ids() -> Array[String]:
	var axes = ["_x", "_y", "_z"]
	var props = [
		["_speed", "_offset", "_period"],
		["_speed", "_offset"],
		["_offset", "_period"],
		["_speed", "_offset", "_period"],
		["_speed", "_offset"],
		["_offset", "_period"]
	]
	var shids = ["drunk", "tipsy", "bumpy", "drunkTan", "tipsyTan", "bumpyTan"]
	var submods:Array[String] = []
	
	var key_count:int = manager.key_count if "key_count" in manager else 4

	for i in range(shids.size()):
		var mod = shids[i]
		for a in range(axes.size()):
			var axe = axes[a]
			if a == (i % axes.size()):
				axe = ""
			submods.append(mod + axe)
			var p = props[i]
			for prop in p:
				submods.append(mod + axe + prop)
			
			for d in range(key_count):
				submods.append(mod + axe + str(d))
				for prop in p:
					submods.append(mod + axe + str(d) + prop)
					
	if submods.has("drunk"):
		submods.erase("drunk")
	return submods

func adjust(axis:String, val:float, plr:int) -> float:
	var legacy_z = manager.get_other_value("legacyZAxis", plr) if manager.has_method("get_other_value") else 0.0
	if (axis.begins_with("Z") or axis.begins_with("TanZ")) and legacy_z > 0.0:
		return val / 1280.0
	return val

func apply_drunk(axis:String, player:int, time:float, diff:float, data:float, math_func:Callable = Callable()) -> float:
	if math_func.is_null():
		math_func = func(x:float):return cos(x)
		
	var perc = get_value(player) if axis == "" else get_value(player, "drunk" + axis)
	var speed = get_value(player, "drunk" + axis + "Speed")
	var period = get_value(player, "drunk" + axis + "Period")
	var offset = get_value(player, "drunk" + axis + "Offset")
	
	if perc != 0.0:
		var angle = time * (1.0 + speed) + data * ((offset * 0.2) + 0.2) + diff * ((period * 10.0) + 10.0) / SCREEN_HEIGHT
		return adjust(axis, perc * (math_func.call(angle) * HALF_WIDTH), player)
	return 0.0

func apply_tipsy(axis:String, player:int, time:float, diff:float, data:float, math_func:Callable = Callable()) -> float:
	if math_func.is_null():
		math_func = func(x:float):return cos(x)
		
	var perc = get_value(player, "tipsy" + axis)
	var speed = get_value(player, "tipsy" + axis + "Speed")
	var offset = get_value(player, "tipsy" + axis + "Offset")
	
	if perc != 0.0:
		return adjust(axis, perc * (math_func.call(time * ((speed * 1.2) + 1.2) + data * ((offset * 1.8) + 1.8))) * SWAG_WIDTH * 0.4, player)
	return 0.0

func apply_bumpy(axis:String, player:int, time:float, diff:float, data:float, math_func:Callable = Callable()) -> float:
	if math_func.is_null():
		math_func = func(x:float):return sin(x)
		
	var perc = get_value(player, "bumpy" + axis)
	var period = get_value(player, "bumpy" + axis + "Period")
	var offset = get_value(player, "bumpy" + axis + "Offset")
	
	if perc != 0.0 and period != -1.0:
		var angle = (diff + (100.0 * offset)) / ((period * 24.0) + 24.0)
		return adjust(axis, perc * 40.0 * math_func.call(angle), player)
	return 0.0

func get_position(position:Vector3, origin:Variant, type:ModchartManager.ObjectType, visual_time:float, direction:int, player:int) -> Vector3:
	var pos := position
	var time:float = manager.adapter.get_song_time()
	var diff:float = visual_time - manager.adapter.get_song_time()
	var data:float = float(direction)
	
	var fn_cos = func(x:float):return cos(x)
	var fn_sin = func(x:float):return sin(x)
	var fn_tan = func(x:float):return tan(x)

	# Base axes
	pos.x += apply_drunk("", player, time, diff, data, fn_cos) \
		+ apply_tipsy("X", player, time, diff, data, fn_cos) \
		+ apply_bumpy("X", player, time, diff, data, fn_sin)
		
	pos.y += apply_drunk("Y", player, time, diff, data, fn_cos) \
		+ apply_tipsy("", player, time, diff, data, fn_cos) \
		+ apply_bumpy("Y", player, time, diff, data, fn_sin)
		
	pos.z += apply_drunk("Z", player, time, diff, data, fn_cos) \
		+ apply_tipsy("Z", player, time, diff, data, fn_cos) \
		+ apply_bumpy("", player, time, diff, data, fn_sin)

	# Direction-specific
	var d_str = str(direction)
	pos.x += apply_drunk(d_str, player, time, diff, data, fn_cos) \
		+ apply_tipsy("X" + d_str, player, time, diff, data, fn_cos) \
		+ apply_bumpy("X" + d_str, player, time, diff, data, fn_sin)
		
	pos.y += apply_drunk("Y" + d_str, player, time, diff, data, fn_cos) \
		+ apply_tipsy(d_str, player, time, diff, data, fn_cos) \
		+ apply_bumpy("Y" + d_str, player, time, diff, data, fn_sin)
		
	pos.z += apply_drunk("Z" + d_str, player, time, diff, data, fn_cos) \
		+ apply_tipsy("Z" + d_str, player, time, diff, data, fn_cos) \
		+ apply_bumpy(d_str, player, time, diff, data, fn_sin)

	# Tangent
	pos.x += apply_drunk("Tan", player, time, diff, data, fn_tan) \
		+ apply_tipsy("TanX", player, time, diff, data, fn_tan) \
		+ apply_bumpy("TanX", player, time, diff, data, fn_tan)
		
	pos.y += apply_drunk("TanY", player, time, diff, data, fn_tan) \
		+ apply_tipsy("Tan", player, time, diff, data, fn_tan) \
		+ apply_bumpy("TanY", player, time, diff, data, fn_tan)
		
	pos.z += apply_drunk("TanZ", player, time, diff, data, fn_tan) \
		+ apply_tipsy("TanZ", player, time, diff, data, fn_tan) \
		+ apply_bumpy("Tan", player, time, diff, data, fn_tan)

	# Tangent column
	pos.x += apply_drunk("Tan" + d_str, player, time, diff, data, fn_tan) \
		+ apply_tipsy("TanX" + d_str, player, time, diff, data, fn_tan) \
		+ apply_bumpy("TanX" + d_str, player, time, diff, data, fn_tan)
		
	pos.y += apply_drunk("TanY" + d_str, player, time, diff, data, fn_tan) \
		+ apply_tipsy("Tan" + d_str, player, time, diff, data, fn_tan) \
		+ apply_bumpy("TanY" + d_str, player, time, diff, data, fn_tan)
		
	pos.z += apply_drunk("TanZ" + d_str, player, time, diff, data, fn_tan) \
		+ apply_tipsy("TanZ" + d_str, player, time, diff, data, fn_tan) \
		+ apply_bumpy("Tan" + d_str, player, time, diff, data, fn_tan)

	return pos
