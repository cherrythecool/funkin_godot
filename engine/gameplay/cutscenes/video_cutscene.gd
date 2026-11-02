class_name VideoCutscene
extends BaseCutscene
## Simple cutscene class that plays a video with a
## [VideoStreamPlayer] and then finishes.


signal on_video_ended


@export var video_player: VideoStreamPlayer

## Whether or not to hide the game and its hud
## while the video is playing.
@export var hide_game: bool = true

## Whether or not to allow players to skip the
## cutscene by pressing enter or space (action menu_accept).
@export var allow_skipping: bool = true

## Whether to autoplay the video once its stream is set
@export var autoplay: bool = true


func _ready() -> void:
	super()

	if is_queued_for_deletion():
		return

	if autoplay:
		play()

	if hide_game:
		if asset_loader:
			if asset_loader.characters_parent:
				asset_loader.characters_parent.hide()

			if asset_loader.stage_parent:
				asset_loader.stage_parent.hide()

		if hud:
			hud.hide()


func _unhandled_input(event: InputEvent) -> void:
	if allow_skipping and event.is_action_pressed(&"menu_accept"):
		get_viewport().set_input_as_handled()
		finish()


## Plays the video if it isn't already playing.
## [br][br]
## Use [param force] to force the video to restart if it's already playing.
func play(force: bool = false) -> void:
	if video_player.is_playing():
		if not force:
			return
		else:
			video_player.stop()

	video_player.play()
	video_player.show()


## Frees the cutscene and shows the game again
## if it was previously hidden.
func finish() -> void:
	super()

	video_player.stop()
	video_player.hide()
	on_video_ended.emit()

	if hide_game:
		if asset_loader:
			if asset_loader.characters_parent:
				asset_loader.characters_parent.show()
			if asset_loader.stage_parent:
				asset_loader.stage_parent.show()

		if hud:
			hud.show()
