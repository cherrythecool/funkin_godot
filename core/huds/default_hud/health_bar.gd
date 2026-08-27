class_name HealthBar
extends Node2D


static var last_song_health: float = -1.0

@onready var bar: ProgressBar = $bar
@onready var icons: Node2D = $icons

var player_icon: CanvasItem = null
var player_color: Color:
	set(value):
		player_color = value
		bar.get(&"theme_override_styles/fill").bg_color = player_color

var opponent_icon: CanvasItem = null
var opponent_color: Color:
	set(value):
		opponent_color = value
		bar.get(&"theme_override_styles/background").bg_color = opponent_color

var rank: StringName = &"N/A"
var lerped_health: float = 0.0

var rating_manager: RatingManager
var tracking_song_health := true


func _ready() -> void:
	if not is_instance_valid(Game.instance):
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	rating_manager = get_tree().get_first_node_in_group(&"RatingManager")

	if rating_manager:
		lerped_health = rating_manager.get_health_percent()
	if last_song_health != -1.0:
		lerped_health = last_song_health

	Game.instance.back_to_menus.connect(func() -> void:
		tracking_song_health = false
		last_song_health = -1.0
	)


func _process(delta: float) -> void:
	if rating_manager:
		lerped_health = lerpf(lerped_health, rating_manager.get_health_percent(), GameUtils.lerp_weight(delta, 5.0))

	if tracking_song_health:
		last_song_health = lerped_health

	bar.value = lerped_health
	icons.scale = Vector2(1.2, 1.2).lerp(Vector2.ONE, icon_lerp())
	position_icons(bar.value)

	_update_icon_animation(player_icon, true)
	_update_icon_animation(opponent_icon, false)


func reload_icons() -> void:
	if player_icon:
		player_icon.queue_free()

	if opponent_icon:
		opponent_icon.queue_free()

	reload_icon_colors()

	opponent_icon = HealthIcon.create_sprite(Game.instance.opponent.icon) if Game.instance.opponent else HealthIcon.create_sprite(HealthIcon.new())
	opponent_icon.position.x = -50.0
	icons.add_child(opponent_icon)

	player_icon = HealthIcon.create_sprite(Game.instance.player.icon) if Game.instance.player else HealthIcon.create_sprite(HealthIcon.new())
	player_icon.position.x = 50.0
	icons.add_child(player_icon)
	player_icon.flip_h = true


func reload_icon_colors() -> void:
	if Game.instance.player:
		player_color = Game.instance.player.icon.color

	if Game.instance.opponent:
		opponent_color = Game.instance.opponent.icon.color


# ease out cubic, taken from easings.net
func icon_ease(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


func icon_lerp() -> float:
	return icon_ease(Conductor.beat - floorf(Conductor.beat))


func position_icons(health: float) -> void:
	icons.position.x = 320.0 - (health * 6.4)


func _update_icon_animation(icon: CanvasItem, is_player: bool) -> void:
	if icon is Sprite2D:
		var frames: int = icon.hframes * icon.vframes
		if lerped_health >= 80.0:
			var target: int = 2 if is_player else 1
			icon.frame = target if frames >= target + 1 else 0
		elif lerped_health <= 20.0:
			var target: int = 1 if is_player else 2
			icon.frame = target if frames >= target + 1 else 0
		else:
			icon.frame = 0
	elif icon is AnimatedSprite2D:
		var target: StringName
		if lerped_health >= 80.0:
			target = &"winning" if is_player else &"losing"
		elif lerped_health <= 20.0:
			target = &"losing" if is_player else &"winning"
		else:
			target = &"default"

		if not icon.sprite_frames.has_animation(target):
			target = &"default"
		if icon.animation != target and icon.sprite_frames.has_animation(target):
			icon.play(target)


func _on_hud_downscroll_changed(downscroll: bool) -> void:
	position.y = 80.0 if downscroll else 720.0 - 80.0


func _on_hud_setup() -> void:
	reload_icons()
