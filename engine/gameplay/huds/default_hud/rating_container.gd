extends Node2D


@export var target: StringName = &"player"
@export var rating_sprite: Sprite2D
@export var combo_node: Node2D
@export var difference_label: Label

@export var hud_skin: HUDSkin:
	set(value):
		if hud_skin != value:
			hud_skin = value
			rating_textures = hud_skin.get_rating_textures()

var game: Game:
	get:
		if not is_instance_valid(game):
			game = Game.instance

		return game

var rating_manager: RatingManager

var rating_textures: Dictionary[StringName, Texture2D] = {}
var tween: Tween


func _enter_tree() -> void:
	modulate.a = 0.0
	show()


func _ready() -> void:
	rating_manager = get_tree().get_first_node_in_group(&"RatingManager")


func _on_hud_setup() -> void:
	if is_instance_valid(hud_skin):
		rating_sprite.texture_filter = hud_skin.rating_filter
		rating_sprite.scale = hud_skin.rating_scale
		combo_node.texture_filter = hud_skin.combo_filter
		combo_node.scale = hud_skin.combo_scale

	if target in game.strumlines:
		var strums := game.strumlines[target]
		strums.note_hit.connect(_on_note_hit)
		strums.note_missed.connect(_on_note_missed)


func _on_note_hit(note: NoteData) -> void:
	if (
		note.state != NoteData.NoteState.ALIVE or
		game.strumlines[target].cpu or
		not rating_manager
	):
		return

	var time_difference: float = Conductor.time - note.time
	difference_label.text = "%.2fms" % [time_difference * 1000.0]
	difference_label.modulate = (
		Color(0.515, 0.74, 0.962, 1.0) if time_difference < 0.0
		else Color(0.964, 0.514, 0.797, 1.0)
	)

	var rating := rating_manager.get_rating(absf(time_difference))
	if rating_textures.has(rating.name):
		rating_sprite.texture = rating_textures[rating.name]

	update_combo()

	var rating_scale := Vector2.ONE * 0.7
	if hud_skin:
		rating_scale = hud_skin.rating_scale

	modulate.a = SaveData.get_save_value(&"core", "rating_alpha")
	rating_sprite.scale = rating_scale * 1.15
	difference_label.scale = Vector2.ONE * 1.175

	tween = FunkinUtils.replace_tween(self, tween)
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(rating_sprite, ^"scale", rating_scale, 0.35)
	tween.tween_property(difference_label, ^"scale", Vector2.ONE, 0.5)
	tween.tween_property(self, ^"modulate:a", 0.0, 0.6).set_delay(0.55)

	var previous_str := "%03d" % [rating_manager.combo - 1]
	var combo_str := "%03d" % rating_manager.combo

	for number_node: Node in combo_node.get_children():
		var number := number_node as CanvasItem
		var index := int(number_node.name) - 1
		if int(combo_str[index]) > int(previous_str[index]):
			number.scale = Vector2.ONE * 1.25
			tween.tween_property(number, ^"scale", Vector2.ONE, 0.5)
		else:
			number.scale = Vector2.ONE * 1.1
			tween.tween_property(number, ^"scale", Vector2.ONE, 0.8)


func update_combo() -> void:
	var combo_spacing: float = 90.0
	if hud_skin:
		combo_spacing = hud_skin.combo_spacing

	var combo_str := "%03d" % rating_manager.combo
	var amount_of_numbers: int = combo_str.length()

	# add extra numbers if go past the amount that exist already
	while combo_node.get_child_count() < amount_of_numbers:
		var node: Node = combo_node.get_child(0).duplicate()
		node.name = str(combo_node.get_child_count() + 1)
		combo_node.add_child(node)

	combo_node.position.x = (-combo_spacing / 4.0) * (amount_of_numbers - 1)

	for i: int in combo_node.get_child_count():
		var number: Sprite2D = combo_node.get_child(i)
		if i < amount_of_numbers and hud_skin:
			number.texture = hud_skin.get_combo_atlas()
			number.texture_filter = hud_skin.combo_filter
			number.frame = int(combo_str[i])
			number.position.x = combo_spacing * i
			number.show()
		else:
			number.hide()


func _on_note_missed(_note: NoteData) -> void:
	if tween and tween.is_running():
		tween.kill()

	modulate.a = 0.0
