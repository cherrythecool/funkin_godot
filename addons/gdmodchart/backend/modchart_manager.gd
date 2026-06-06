class_name ModchartManager extends Sprite2D

enum ObjectType
{
	RECEPTOR,
	NOTE
}

var adapter:ModchartAdapter

var modifiers:Array[ModchartModifier] = []

var players:Array[ModchartPlayer] = []

var container:SubViewportContainer
var sub_viewport:SubViewport
var note_scene:Node3D
var camera:Camera3D

func _init(adapter:Variant) -> void:
	if adapter is GDScript:
		adapter = adapter.new()
	elif adapter is String && ResourceLoader.exists(adapter):
		adapter = load(adapter).new()
	
	self.adapter = adapter
	
	container = SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	sub_viewport = SubViewport.new()
	sub_viewport.size = Global.game_size
	sub_viewport.transparent_bg = true
	
	camera = Camera3D.new()
	camera.position.z = 8
	note_scene = Node3D.new()
	
	sub_viewport.add_child(note_scene)
	sub_viewport.add_child(camera)
	container.add_child(sub_viewport)
	add_child(container)
	
	for id in adapter.get_player_count():
		var player = ModchartPlayer.new()
		player.id = id
		players.push_back(player)
	
	modifiers = [
		preload("uid://xx6vbrj002o4").new(self) # drunk
	]
	
var object_cache:Dictionary[Variant, ModchartObject] = {}

func _process(delta: float) -> void:
	var screen_center = Vector3(Global.game_size.x / 2, Global.game_size.y / 2, 0)
	var pixel_size = 0.01
	
	for receptor in adapter.get_receptors():
		var receptor_3d:ModchartObject = object_cache.get(receptor)
		if !object_cache.has(receptor):
			receptor_3d = ModchartObject.new(adapter.get_note_sprite(receptor))
			note_scene.add_child(receptor_3d)
			object_cache.set(receptor, receptor_3d)
			
		receptor.visible = false
		var pos = camera.project_position(receptor.global_position, 8)
		for mod in modifiers:
			pos = mod.get_position(pos, ObjectType.RECEPTOR, adapter.get_receptor_direction(receptor), adapter.get_receptor_player(receptor))
		# workaround of 2d scene to 3d world
		receptor_3d.global_position = pos
	for note in adapter.get_notes():
		if object_cache.has(adapter.get_note_sprite(note)):
			print("EXISTS")
		var note_3d:ModchartObject = object_cache.get(note)
		if !object_cache.has(note):
			note_3d = ModchartObject.new(adapter.get_note_sprite(note))
			note_scene.add_child(note_3d)
			object_cache.set(note, note_3d)
		
		note.visible = false
		var pos = camera.project_position(note.global_position, 8)
		for mod in modifiers:
			pos = mod.get_position(pos, ObjectType.NOTE, adapter.get_note_direction(note), adapter.get_receptor_player(note))
		# workaround of 2d scene to 3d world
		note_3d.global_position = pos
