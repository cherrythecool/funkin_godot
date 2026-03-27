extends ModchartModifier
class_name DrunkModifier

func _init() -> void:
	super([
		"drunk_speed"
	])

func receptor(receptor:Receptor, field:NoteField, player:int) -> void:
	var drunk_perc: float = get_value(player)
	var receptor_id: int = field.receptors.find(receptor)
	var time: float = Game.instance.conductor.time
	
	if drunk_perc != 0:
		var speed: float = _scale(submods.get("drunk_speed").get_value(player), 0, 1, 1, 2)
		receptor.position.x += drunk_perc * (cos((time + receptor_id*0.2)*speed) * 112*0.5)

func note(note:Note, player:int) -> void:
	var drunk_perc: float = get_value(player)
	var time: float = Game.instance.conductor.time
	
	if drunk_perc != 0:
		var speed: float = _scale(submods.get("drunk_speed").get_value(player), 0, 1, 1, 2)
		note.position.x += (drunk_perc*(cos((time + (note.data.direction % 2)*.2 + note.position.y*10/Global.game_size.x)*speed) * 112*0.5))

func _scale(x:float,l1:float,h1:float,l2:float,h2:float) -> float:
	return ((x - l1) * (h2 - l2) / (h1 - l1) + l2)
