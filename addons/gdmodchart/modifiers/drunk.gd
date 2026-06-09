extends ModchartModifier
class_name DrunkModifier

const NOTE_HALF_WIDTH: float = 56.0
const NOTE_SWAG_WIDTH: float = 112.0

func get_id() -> String:
	return "drunk"

func get_aliases() -> Dictionary:
	return {
		"tipZ": "tipsyZ",
		"tipZSpeed": "tipsyZSpeed",
		"tipZOffset": "tipsyZOffset"
	}

func _get_mod_val(player: int, sub_mod: String) -> float:
	var aliases = get_aliases()
	if aliases.has(sub_mod):
		sub_mod = aliases[sub_mod]
	
	if sub_mod.ends_with("Period") and not manager.players[player].values.has(sub_mod):
		return -1.0
		
	return get_value(player, sub_mod)

func adjust(axis: String, val: float, plr: int) -> float:
	if (axis.begins_with("Z") or axis.begins_with("TanZ")) and _get_mod_val(plr, "legacyZAxis") > 0:
		return val / 1280.0
	return val

func apply_drunk(axis: String, player: int, time: float, visual_diff: float, data: float, math_func: Callable = cos) -> float:
	var perc: float = get_value(player) if axis == "" else _get_mod_val(player, "drunk" + axis)
	var speed: float = _get_mod_val(player, "drunk" + axis + "Speed")
	var period: float = _get_mod_val(player, "drunk" + axis + "Period")
	var offset: float = _get_mod_val(player, "drunk" + axis + "Offset")

	if perc != 0.0:
		var flxg_height: float = 720.0 
		var angle: float = time * (1.0 + speed) + data * ((offset * 0.2) + 0.2) + visual_diff * ((period * 10.0) + 10.0) / flxg_height
		return adjust(axis, perc * (math_func.call(angle) * NOTE_HALF_WIDTH), player)
	return 0.0

func apply_tipsy(axis: String, player: int, time: float, visual_diff: float, data: float, math_func: Callable = cos) -> float:
	var perc: float = _get_mod_val(player, "tipsy" + axis)
	var speed: float = _get_mod_val(player, "tipsy" + axis + "Speed")
	var offset: float = _get_mod_val(player, "tipsy" + axis + "Offset")

	if perc != 0.0:
		var angle: float = (time * ((speed * 1.2) + 1.2) + data * ((offset * 1.8) + 1.8))
		return adjust(axis, perc * (math_func.call(angle) * NOTE_SWAG_WIDTH * 0.4), player)
	return 0.0

func apply_bumpy(axis: String, player: int, time: float, visual_diff: float, data: float, math_func: Callable = sin) -> float:
	var perc: float = _get_mod_val(player, "bumpy" + axis)
	var period: float = _get_mod_val(player, "bumpy" + axis + "Period")
	var offset: float = _get_mod_val(player, "bumpy" + axis + "Offset")

	if perc != 0.0 and period != -1.0:
		var angle: float = (visual_diff + (100.0 * offset)) / ((period * 24.0) + 24.0)
		return adjust(axis, perc * 40.0 * math_func.call(angle), player)
	return 0.0

func get_position(position: Vector3, object:Node, type: ModchartManager.ObjectType, direction: int, player: int) -> Vector3:
	var time: float = manager.adapter.get_song_time() 
	var visual_diff: float = position.y 
	var data: float = float(direction)
	var pos: Vector3 = position

	pos.x += apply_drunk("", player, time, visual_diff, data) + apply_tipsy("X", player, time, visual_diff, data) + apply_bumpy("X", player, time, visual_diff, data)
	pos.y += apply_drunk("Y", player, time, visual_diff, data) + apply_tipsy("", player, time, visual_diff, data) + apply_bumpy("Y", player, time, visual_diff, data)
	pos.z += apply_drunk("Z", player, time, visual_diff, data) + apply_tipsy("Z", player, time, visual_diff, data) + apply_bumpy("", player, time, visual_diff, data)

	var s_data: String = str(direction)
	pos.x += apply_drunk(s_data, player, time, visual_diff, data) + apply_tipsy("X" + s_data, player, time, visual_diff, data) + apply_bumpy("X" + s_data, player, time, visual_diff, data)
	pos.y += apply_drunk("Y" + s_data, player, time, visual_diff, data) + apply_tipsy(s_data, player, time, visual_diff, data) + apply_bumpy("Y" + s_data, player, time, visual_diff, data)
	pos.z += apply_drunk("Z" + s_data, player, time, visual_diff, data) + apply_tipsy("Z" + s_data, player, time, visual_diff, data) + apply_bumpy(s_data, player, time, visual_diff, data)

	pos.x += apply_drunk("Tan", player, time, visual_diff, data, tan) + apply_tipsy("TanX", player, time, visual_diff, data, tan) + apply_bumpy("TanX", player, time, visual_diff, data, tan)
	pos.y += apply_drunk("TanY", player, time, visual_diff, data, tan) + apply_tipsy("Tan", player, time, visual_diff, data, tan) + apply_bumpy("TanY", player, time, visual_diff, data, tan)
	pos.z += apply_drunk("TanZ", player, time, visual_diff, data, tan) + apply_tipsy("TanZ", player, time, visual_diff, data, tan) + apply_bumpy("Tan", player, time, visual_diff, data, tan)

	pos.x += apply_drunk("Tan" + s_data, player, time, visual_diff, data, tan) + apply_tipsy("TanX" + s_data, player, time, visual_diff, data, tan) + apply_bumpy("TanX" + s_data, player, time, visual_diff, data, tan)
	pos.y += apply_drunk("TanY" + s_data, player, time, visual_diff, data, tan) + apply_tipsy("Tan" + s_data, player, time, visual_diff, data, tan) + apply_bumpy("TanY" + s_data, player, time, visual_diff, data, tan)
	pos.z += apply_drunk("TanZ" + s_data, player, time, visual_diff, data, tan) + apply_tipsy("TanZ" + s_data, player, time, visual_diff, data, tan) + apply_bumpy("Tan" + s_data, player, time, visual_diff, data, tan)
	
	return pos

func get_sub_modifier_ids() -> Array[String]:
	var axes: Array[String] = ["X", "Y", "Z"]
	var props: Array[Array] = [
		["speed", "Offset", "Period"],
		["speed", "Offset"],
		["offset", "Period"],
		["speed", "Offset", "Period"],
		["speed", "Offset"],
		["offset", "Period"]
	]
	var shids: Array[String] = ["drunk", "tipsy", "bumpy", "drunkTan", "tipsyTan", "bumpyTan"]
	var submods: Array[String] = []

	for i in range(shids.size()):
		var mod: String = shids[i]
		for a in range(axes.size()):
			var axe: String = axes[a]
			if a == (i % axes.size()):
				axe = ""
			
			submods.push_back(mod + axe)
			var p: Array = props[i]
			for prop in p:
				submods.push_back(mod + axe + prop)
			
			for d in range(manager.adapter.get_key_count()):
				submods.push_back(mod + axe + str(d))
				for prop in p:
					submods.push_back(mod + axe + str(d) + prop)

	submods.erase("drunk")
	return submods
