class_name ModchartManager extends Sprite2D

enum ObjectType
{
	RECEPTOR,
	NOTE
}

var modifiers:Array[ModchartModifier] = [
	preload("uid://xx6vbrj002o4").new(self) # drunk
]

var adapter:ModchartAdapter
var timeline:ModchartTimeline

var players:Array[ModchartPlayer] = []

var container:SubViewportContainer
var sub_viewport:SubViewport

var receptors:Node3D
var notes:Node3D

var camera:Camera3D

func _init(adapter:Variant) -> void:
	if adapter is GDScript:
		adapter = adapter.new()
	elif adapter is PackedScene:
		adapter = adapter.instantiate()
	
	self.adapter = adapter
	
	container = SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	sub_viewport = SubViewport.new()
	sub_viewport.size = Global.game_size
	sub_viewport.transparent_bg = true
	
	camera = Camera3D.new()
	
	receptors = Node3D.new()
	notes = Node3D.new()
	
	sub_viewport.add_child(receptors)
	sub_viewport.add_child(notes)
	sub_viewport.add_child(camera)
	container.add_child(sub_viewport)
	add_child(container)
	
	for id in adapter.get_player_count():
		var player = ModchartPlayer.new()
		player.id = id
		for mod in modifiers:
			player.values.set(mod.get_id(), 0)
			for submod in mod.get_sub_modifier_ids():
				player.values.set(submod, 0)
		players.push_back(player)
		
	timeline = ModchartTimeline.new(self)
	
	if is_instance_valid(adapter.get_modchart_layer()):
		adapter.get_modchart_layer().add_child(self)
	
var object_cache:Dictionary[Variant, ModchartObject] = {}

func _process(delta: float) -> void:
	var start_z_pos:float = 4.9
	
	timeline.process_step(adapter.get_song_step())
	
	for receptor in adapter.get_receptors():
		var receptor_3d:ModchartObject = object_cache.get(receptor)
		if !object_cache.has(receptor):
			receptor_3d = ModchartObject.new(adapter.get_note_sprite(receptor))
			receptors.add_child(receptor_3d)
			object_cache.set(receptor, receptor_3d)
			
		receptor.visible = false
		var pos:Vector3 = Vector3(receptor.global_position.x, receptor.global_position.y, 0)
		for mod in modifiers:
			pos = mod.get_position(pos, receptor, ObjectType.RECEPTOR, adapter.get_receptor_direction(receptor), adapter.get_receptor_player(receptor))
		
		receptor_3d.global_position = camera.project_position(Vector2(pos.x, pos.y), start_z_pos)
	for note in adapter.get_notes():
		var note_3d:ModchartObject = object_cache.get(note)
		if !object_cache.has(note):
			note_3d = ModchartObject.new(adapter.get_note_sprite(note))
			notes.add_child(note_3d)
			object_cache.set(note, note_3d)
		
		note.visible = false
		var pos:Vector3 = Vector3(note.global_position.x, note.global_position.y, 1)
		for mod in modifiers:
			pos = mod.get_position(pos, note, ObjectType.NOTE, adapter.get_note_direction(note), adapter.get_receptor_player(note))
		note_3d.global_position = camera.project_position(Vector2(pos.x, pos.y), start_z_pos + (pos.z - 1))
		print((pos.z - 1))


# Modifier functions

func set_value(mod: String, value: float, player: int = -1) -> void:
	if player == -1:
		for plr in players:
			plr.values.set(mod, value)
	else: players[player].values.set(mod, value)
	
func set_percent(mod: String, percent: float, player: int = -1) -> void:
	set_value(mod, percent/100, player)

func get_value(mod: String, player: int = 0) -> float: 
	return players[player].values.get(mod, 0)

func get_percent(mod: String, player: int = 0) -> float: 
	return get_value(mod, player) * 100

func queue_set_value(step: int, mod: String, value: float, player: int = -1) -> void:
	var event: ModchartSetEvent = ModchartSetEvent.new(self, timeline)
	event.exec_step = step
	event.modifier = mod
	event.value = value
	event.player = player
	timeline.add_event(event)

func queue_set_percent(step: int, mod: String, percent: float, player: int = -1) -> void:
	queue_set_value(step, mod, percent/100, player)

func queue_ease_value(exec_step: int, end_step: int, mod: String, value: float, target_trans:Tween.TransitionType, target_ease:Tween.EaseType, player: int = -1, start_value: Variant = null) -> void:
	var event: ModchartEaseEvent = ModchartEaseEvent.new(self, timeline)
	event.exec_step = exec_step
	event.end_step = end_step
	event.modifier = mod
	event.value = value
	event.target_trans = target_trans
	event.target_ease = target_ease
	event.player = player
	if start_value != null: event.start_value = start_value
	timeline.add_event(event)

func queue_ease_percent(exec_step: int, end_step: int, mod: String, percent: float, target_trans:Tween.TransitionType, target_ease:Tween.EaseType, player: int = -1, start_percent: Variant = null) -> void:
	var start_value: Variant = null
	if start_percent != null: start_value = start_percent / 100
	queue_ease_value(exec_step, end_step, mod, percent/100, target_trans, target_ease, player, start_value)

func queue_func(exec_step: int, end_step: int, function: Callable) -> void:
	var event: ModchartFunctionEvent = ModchartFunctionEvent.new(self, timeline)
	event.exec_step = exec_step
	event.end_step = end_step
	event.function = function
	timeline.add_event(event)

func queue_func_once(exec_step: int, function: Callable) -> void:
	queue_func(exec_step, -1, function)
