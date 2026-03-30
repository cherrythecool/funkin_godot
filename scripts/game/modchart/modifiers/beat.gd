# https://github.com/nebulazorua/andromeda-engine-legacy/blob/master/source/modchart/modifiers/BeatModifier.hx
class_name BeatModifier extends ModchartModifier

func _init() -> void:
	super([])

func get_object(object: Node, _field: NoteField, _column:int, player: int) -> void:
	var percent: float = get_value(player)
	if percent == 0:
		return
		
	var visual_diff: float = 0
	if object is Note:
		visual_diff = -((Conductor.instance.time - object.data.time) * 450.0 * Game.instance.scroll_speed)

	var accel_time: float = 0.3 
	var total_time: float = 0.7 

	var beat: float = Conductor.instance.beat + accel_time 
	var even_beat: bool = fmod(beat, 2.0) >= 1.0

	if beat < 0:
		return

	beat = fmod(beat, 1.0)
	
	if beat >= total_time:
		return

	var amount: float = 0.0
	if beat < accel_time:
		amount = remap(beat, 0, accel_time, 0, 1)
		amount *= amount
	else:
		amount = remap(beat, accel_time, total_time, 1, 0)
		amount = 1.0 - (1.0 - amount) * (1.0 - amount)

	if even_beat:
		amount *= -1.0

	var shift: float = 40.0 * amount * sin((visual_diff / 30.0) + (PI / 2.0))
	object.position.x += percent * shift
