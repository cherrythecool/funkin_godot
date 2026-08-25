extends Control


var game: Game

var downscroll: bool = false:
	set(value):
		downscroll = value
		set_downscroll(value)

var middlescroll: bool = false:
	set(value):
		middlescroll = value
		set_middlescroll(value)

@export var bumps: bool = false
@export var bump_amount: Vector2 = Vector2(0.03, 0.03)
@export var bump_interval: int = 4
@export var zoom_lerping: bool = true

@export var player_renderer: StrumlineRenderer2D
@export var opponent_renderer: StrumlineRenderer2D

@export var health_bar: HealthBar
@export var countdown_container: CountdownContainer
@export var time_bar: ProgressBar
@export var rating_container: Node2D

@onready var rating_calculator: RatingCalculator:
	get:
		if is_instance_valid(game) and is_instance_valid(game.rating_calculator):
			return game.rating_calculator
		else:
			return null
var rating_tween: Tween

@export var hud_skin: HUDSkin:
	set(v):
		hud_skin = v
		rating_textures = hud_skin.get_rating_textures()

var rating_textures: Dictionary[StringName, Texture2D] = {}
var toggle_visible := true

signal setup
signal downscroll_changed(downscroll: bool)


func _ready() -> void:
	if is_instance_valid(Game.instance):
		game = Game.instance
		game.hud_setup.connect(_on_setup)
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	Conductor.beat_hit.connect(_on_beat_hit)

	downscroll = Settings.get_setting(&"core", "downscroll")
	middlescroll = Settings.get_setting(&"core", "middlescroll")


func _on_setup() -> void:
	if rating_container and not rating_container.hud_skin:
		rating_container.hud_skin = hud_skin

	var strumlines := game.strumlines
	if strumlines.has(&"player"):
		var plr_strums := strumlines[&"player"]
		player_renderer.parent = plr_strums
	else:
		player_renderer.hide()

	if strumlines.has(&"opponent"):
		var opp_strums := strumlines[&"opponent"]
		opp_strums.note_hit.connect(_on_first_opponent_note, CONNECT_ONE_SHOT)
		opponent_renderer.parent = opp_strums
	else:
		opponent_renderer.hide()

	set_downscroll(downscroll)
	setup.emit()


func _on_beat_hit(beat: int) -> void:
	if beat <= 0 or not (game.playing and bumps):
		return

	if beat % bump_interval == 0:
		scale += bump_amount


func _process(delta: float) -> void:
	if not (game.playing and zoom_lerping):
		return

	scale = scale.lerp(Vector2.ONE, delta * 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_game_hud"):
		toggle_visible = not toggle_visible

		if health_bar:
			health_bar.visible = toggle_visible

		if rating_container:
			if not rating_container.visible:
				rating_container.modulate.a = 0.0

			rating_container.visible = toggle_visible

		if countdown_container:
			countdown_container.visible = toggle_visible

		if time_bar:
			time_bar.visible = toggle_visible and Settings.get_setting(&"core", "time_bar_show")


func _on_first_opponent_note(_note: NoteData) -> void:
	bumps = true


func set_downscroll(value: bool) -> void:
	if player_renderer:
		player_renderer.downscroll = value
		player_renderer.position.y = 720.0 - 100.0 if value else 100.0
		player_renderer.splash_alpha = Settings.get_setting(&"core", "note_splash_alpha")
		player_renderer.underlay_alpha = Settings.get_setting(&"core", "note_underlay_alpha")

	if opponent_renderer:
		opponent_renderer.downscroll = value
		opponent_renderer.position.y = 720.0 - 100.0 if value else 100.0
		opponent_renderer.splash_alpha = Settings.get_setting(&"core", "note_splash_alpha")

	downscroll_changed.emit(value)


func set_middlescroll(value: bool) -> void:
	if player_renderer:
		player_renderer.position.x = 640.0 if value else 960.0

	if opponent_renderer:
		opponent_renderer.visible = not value
		opponent_renderer.position.x = 320.0
