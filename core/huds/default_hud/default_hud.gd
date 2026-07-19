extends Control


var game: Game

var downscroll: bool = false:
	set(value):
		downscroll = value
		set_downscroll(value)

var centered_receptors: bool = false:
	set(value):
		centered_receptors = value
		set_centered_receptors(value)

@export var bumps: bool = false
@export var bump_amount: Vector2 = Vector2(0.03, 0.03)
@export var bump_interval: int = 4
@export var zoom_lerping: bool = true

@export var player_renderer: SkinnedStrumlineRenderer
@export var opponent_renderer: SkinnedStrumlineRenderer

@onready var health_bar: HealthBar = %health_bar
@onready var countdown_container: CountdownContainer = %countdown_container
@onready var time_bar: ProgressBar = %time_bar

@onready var rating_calculator: RatingCalculator:
	get:
		if is_instance_valid(game) and is_instance_valid(game.rating_calculator):
			return game.rating_calculator
		else:
			return null
@onready var rating_container: Node2D = %rating_container
@onready var difference_label: Label = rating_container.get_node('difference_label')
@onready var rating_sprite: Sprite2D = rating_container.get_node('rating')
@onready var combo_node: Node2D = rating_container.get_node('combo')
var rating_tween: Tween

@export var hud_skin: HUDSkin:
	set(v):
		hud_skin = v
		rating_textures = hud_skin.get_rating_textures()

var rating_textures: Dictionary[StringName, Texture2D] = {}

signal setup
signal note_hit(note: NoteData)
signal note_miss(note: NoteData)
signal downscroll_changed(downscroll: bool)


func _ready() -> void:
	if is_instance_valid(Game.instance):
		game = Game.instance
		game.hud_setup.connect(_on_setup)
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	Conductor.beat_hit.connect(_on_beat_hit)

	rating_container.visible = true
	rating_container.modulate.a = 0.0
	downscroll = Settings.get_setting(&"core", "downscroll")
	centered_receptors = Settings.get_setting(&"core", "middlescroll")


func _on_setup() -> void:
	if is_instance_valid(hud_skin):
		combo_node.scale = hud_skin.combo_scale
		combo_node.texture_filter = hud_skin.combo_filter
		rating_sprite.scale = hud_skin.rating_scale
		rating_sprite.texture_filter = hud_skin.rating_filter

	var strumlines := game.strumlines
	if strumlines.has(&"player"):
		var plr_strums := strumlines[&"player"]
		plr_strums.note_hit.connect(_on_note_hit)
		plr_strums.note_missed.connect(_on_note_miss)
		player_renderer.parent = plr_strums
	else:
		player_renderer.hide()

	if strumlines.has(&"opponent"):
		var opp_strums := strumlines[&"opponent"]
		opp_strums.note_hit.connect(_on_opponent_note_hit)
		opp_strums.note_hit.connect(_on_first_opponent_note, CONNECT_ONE_SHOT)
		opponent_renderer.parent = opp_strums
	else:
		opponent_renderer.hide()

	set_downscroll(downscroll)
	setup.emit()


func _on_beat_hit(beat: int) -> void:
	if not (game.playing and bumps):
		return
	if beat <= 0:
		return

	if beat % bump_interval == 0:
		scale += bump_amount


func _process(delta: float) -> void:
	if not (game.playing and zoom_lerping):
		return

	scale = scale.lerp(Vector2.ONE, delta * 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_pressed():
		return
	if event.is_action(&"toggle_game_hud"):
		health_bar.visible = not health_bar.visible
		if not rating_container.visible:
			rating_container.modulate.a = 0.0

		rating_container.visible = health_bar.visible
		countdown_container.visible = health_bar.visible
		time_bar.visible = health_bar.visible and Settings.get_setting(&"core", "time_bar_show")


func _on_first_opponent_note(_note: NoteData) -> void:
	bumps = true


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

	if is_instance_valid(rating_tween) and rating_tween.is_running():
		rating_tween.kill()

	var rating: Rating = Rating.new()
	if is_instance_valid(rating_calculator):
		rating = rating_calculator.get_rating(absf(difference))
	if rating_textures.has(rating.name):
		rating_sprite.texture = rating_textures[rating.name]

	#if rating.name == &'marvelous' or rating.name == &'sick':
	#	spawn_splash(note, player_field.skin, note.field.receptors[note.lane])

	rating_container.modulate.a = Settings.get_setting(&"core", "rating_alpha")
	rating_container.scale = Vector2.ONE * 1.1
	rating_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rating_tween.tween_property(rating_container, 'scale', Vector2.ONE, 0.15)
	rating_tween.tween_property(rating_container, 'modulate:a', 0.0, 0.25).set_delay(0.25)

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

	note_hit.emit(note)


func _on_note_miss(note: NoteData) -> void:
	if is_instance_valid(rating_tween) and rating_tween.is_running():
		rating_tween.kill()

	rating_container.modulate.a = 0.0
	note_miss.emit(note)


func _on_opponent_note_hit(_note: NoteData) -> void:
	#spawn_splash(note, opponent_field.skin, note.field.receptors[note.direction])
	pass


func set_downscroll(value: bool) -> void:
	if is_instance_valid(player_renderer):
		player_renderer.downscroll = value
		player_renderer.position.y = 720.0 - 100.0 if value else 100.0
	if is_instance_valid(opponent_renderer):
		opponent_renderer.downscroll = value
		opponent_renderer.position.y = 720.0 - 100.0 if value else 100.0

	downscroll_changed.emit(value)


func set_centered_receptors(value: bool) -> void:
	if is_instance_valid(opponent_renderer):
		opponent_renderer.visible = not value
		opponent_renderer.position.x = 320.0
	if is_instance_valid(player_renderer):
		player_renderer.position.x = 640.0 if value else 960.0


#func spawn_splash(note: Note, skin: NoteSkin, target: Node2D) -> void:
	#if not is_instance_valid(note.splash):
		#return
#
	#var splash: NoteSplash = note.splash.instantiate()
	#splash.note = note
#
	#if splash.use_skin and is_instance_valid(skin):
		#splash.sprite_frames = skin.get_splash_frames()
		#splash.scale = skin.splash_scale
		#splash.texture_filter = skin.splash_filter
		#splash.colors = skin.splash_shader_colors
		#splash.material = skin.get_splash_material()
#
	##note_fields.add_child(splash)
	#splash.global_position = target.global_position
