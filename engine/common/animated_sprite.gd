@tool
class_name AnimatedSprite
extends AnimatedSprite2D
## @deprecated: It's recommended to use [AnimatedSprite2D] instead of this legacy class


@export var playing: bool = false:
	set(value):
		if value:
			play()
		else:
			pause()
	get:
		return is_playing()
