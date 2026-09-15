extends Character


@export_group("Material References")
@export var abot_speakers: CanvasItem
@export var eyes_background: CanvasItem
@export var eyes: CanvasItem
@export var visualizer_background: CanvasItem

var camera_side: StringName = &"player"


func _ready() -> void:
	var event_manager: EventManager = get_tree().get_first_node_in_group(&"EventManager")
	if event_manager:
		event_manager.event_hit.connect(_on_event_hit)


func _process(_delta: float) -> void:
	if camera_side == &"opponent" and eyes.frame >= 13:
		eyes.playing = false
		eyes.frame = 13


func _on_event_hit(event: EventData) -> void:
	if event.name.to_lower() != &'camera pan':
		return

	var side: StringName = event.data.get(&"side")
	# prevent middle character from fucking with us :+1:
	if side != &"player" and side != &"opponent":
		return

	camera_side = side
	if event.time <= 0.0:
		if camera_side == &"player":
			eyes.frame = 31
			eyes.playing = false
		else:
			eyes.frame = 13
			eyes.playing = false

		return

	if camera_side == &"player":
		eyes.frame = 13
		eyes.playing = true
	else:
		eyes.frame = 0
		eyes.playing = true


func set_character_material(new_material: Material) -> void:
	super(new_material)

	abot_speakers.material = new_material
	eyes_background.material = new_material
	eyes.material = new_material
	visualizer_background.material = new_material
