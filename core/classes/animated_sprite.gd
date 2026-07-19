@tool
class_name AnimatedSprite
extends AnimatedSprite2D


@export var playing: bool = false:
	set(value):
		if value:
			play()
		else:
			pause()
	get:
		return is_playing()
