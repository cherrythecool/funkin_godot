extends Stage


@export var sounds: Array[AudioStream] = []

@onready var background: AnimatedSprite = %background

var lightning_beat: int = 0
var lightning_offset: int = 8


func _ready() -> void:
	game.spectator.offset_camera_position(Vector2(0.0, 75.0))


func _on_beat_hit(beat: int) -> void:
	super(beat)

	if beat == 4 and Game.load_settings[&"song_name"].to_lower() == &"spookeez":
		strike(beat, false)
	if randf_range(0.0, 100.0) >= 90.0 and beat > lightning_beat + lightning_offset:
		strike(beat, true)


func strike(beat: int, play_sound: bool = true) -> void:
	lightning_beat = beat
	lightning_offset = randi_range(8, 24)

	if play_sound:
		var thunder := AudioStreamPlayer.new()
		thunder.stream = sounds.pick_random()
		add_child(thunder)

		thunder.play()
		thunder.finished.connect(thunder.queue_free)

	background.play(&"halloweem bg lightning strike")

	if game.spectator.has_anim(&"scared"):
		game.spectator.play_anim(&"scared", true, true)
	if game.player.has_anim(&"scared"):
		game.player.play_anim(&"scared", true, true)
