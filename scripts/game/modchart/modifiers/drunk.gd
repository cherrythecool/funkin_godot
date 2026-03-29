class_name DrunkModifier extends ModchartModifier

func _init() -> void:
	super([
		"tipsy",
		"bumpy",
		"drunk_speed",
		"drunk_offset",
		"drunk_period",
		"tipsy_speed",
		"tipsy_offset",
		"bumpy_offset",
		"bumpy_period",
		
		"tip_z",
		"tip_z_Speed",
		"tip_z_offset",
		
		"drunk_z",
		"drunk_z_speed",
		"drunk_z_offset",
		"drunk_z_period"
	])

func get_receptor(receptor:Receptor, field:NoteField, player:int) -> void:
	_get_drunk(receptor, player, field.receptors.find(receptor))

func get_note(note:Note, player:int) -> void:
	_get_drunk(note, player, note.data.direction % note.directions.size())
	
func _get_drunk(obj:Node2D, player:int, column: int) -> void:
	var drunk_perc: float = get_value(player)
	var tipsy_perc: float = submods.get("tipsy").get_value(player)
	var bumpy_perc: float =  submods.get("bumpy").get_value(player)
	var tip_z_perc: float = submods.get("tip_z").get_value(player)

	var time: float = Conductor.instance.time
	var vis_diff: float = 0
	if obj is Note:
		vis_diff = -((time - obj.data.time) * 450.0 * Game.instance.scroll_speed)
	
	if tipsy_perc != 0:
		var speed: float = submods.get("tipsy_speed").get_value(player)
		var offset: float = submods.get("tipsy_offset").get_value(player)
		
		obj.position.y += tipsy_perc * (cos((time*((speed*1.2)+1.2) + column*((offset * 1.8)+1.8))) *112*.4)
	
	if drunk_perc != 0:
		var speed: float = submods.get("drunk_speed").get_value(player)
		var period: float = submods.get("drunk_period").get_value(player)
		var offset: float = submods.get("drunk_offset").get_value(player)
		
		var angle: float = time * (1+speed) + column *( (offset*0.2) + 0.2) + vis_diff * ( (period*10) + 10) /Global.game_size.y
		obj.position.x += drunk_perc * (cos(angle) * 112 * 0.5)
	
	if tip_z_perc != 0:
		var speed: float = submods.get("tip_z_speed").get_value(player)
		var offset: float = submods.get("tip_z_offset").get_value(player)
		obj.z_index += tip_z_perc * (cos((time * ((speed * 1.2) + 1.2) + column * ((offset * 1.8) + 3.2))) * 0.15)
	
	if bumpy_perc != 0:
		var period: float = submods.get("bumpy_period").get_value(player)
		var offset: float = submods.get("bumpy_offset").get_value(player)
		var angle = (vis_diff + (100.0 * offset)) / ((period * 16.0) + 16.0)
		obj.z_index += (bumpy_perc * 40 * sin(angle))/250
