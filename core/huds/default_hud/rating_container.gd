extends Node2D


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

var rating_calculator: RatingCalculator:
	get:
		if is_instance_valid(game) and game.rating_calculator:
			return game.rating_calculator
		else:
			return null

var rating_textures: Dictionary[StringName, Texture2D] = {}
var tween: Tween

@onready var rating_sprite: Sprite2D = $rating
@onready var combo_node: Node2D = $combo
@onready var difference_label: Label = $difference_label


func _enter_tree() -> void:
	modulate.a = 0.0
	show()


func _on_hud_setup() -> void:
	if is_instance_valid(hud_skin):
		rating_sprite.texture_filter = hud_skin.rating_filter
		rating_sprite.scale = hud_skin.rating_scale
		combo_node.texture_filter = hud_skin.combo_filter
		combo_node.scale = hud_skin.combo_scale

	if &"player" in game.strumlines:
		var plr_strums := game.strumlines[&"player"]
		plr_strums.note_hit.connect(_on_note_hit)
		plr_strums.note_missed.connect(_on_note_missed)


func _on_note_hit(note: NoteData) -> void:
	if note.state != NoteData.NoteState.ALIVE:
		return

	var difference: float = Conductor.time - note.time
	if game.strumlines[&"player"].cpu:
		difference = 0.0

	if not game.strumlines[&"player"].cpu:
		difference_label.text = "%.2fms" % [difference * 1000.0]
		difference_label.modulate = Color(0.4, 0.5, 0.8) \
				if difference < 0.0 else Color(0.8, 0.4, 0.5)
	else:
		difference_label.text = "Botplay"
		difference_label.modulate = Color(0.6, 0.62, 0.7)

	if tween and tween.is_running():
		tween.kill()

	var rating := Rating.new()
	if is_instance_valid(rating_calculator):
		rating = rating_calculator.get_rating(absf(difference))
	if rating_textures.has(rating.name):
		rating_sprite.texture = rating_textures[rating.name]

	modulate.a = Settings.get_setting(&"core", "rating_alpha")
	scale = Vector2.ONE * 1.1
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, 'scale', Vector2.ONE, 0.15)
	tween.tween_property(self, 'modulate:a', 0.0, 0.25).set_delay(0.25)

	var combo_str: String = str(game.combo).pad_zeros(3)
	var num_count: int = combo_str.length()
	var combo_spacing: float = 90.0
	if is_instance_valid(hud_skin):
		combo_spacing = hud_skin.combo_spacing

	combo_node.position.x = (-combo_spacing / 4.0) * (num_count - 1)
	while combo_node.get_child_count() < num_count:
		var node: Node = combo_node.get_child(0).duplicate()
		node.name = str(combo_node.get_child_count()+1)
		combo_node.add_child(node)

	for i: int in combo_node.get_child_count():
		var number: Sprite2D = combo_node.get_child(i)
		if i < num_count and is_instance_valid(hud_skin):
			number.texture = hud_skin.get_combo_atlas()
			number.texture_filter = hud_skin.combo_filter
			number.frame = int(combo_str[i])
			number.position.x = combo_spacing * i
			number.visible = true
		else:
			number.visible = false


func _on_note_missed(_note: NoteData) -> void:
	if tween and tween.is_running():
		tween.kill()

	modulate.a = 0.0
