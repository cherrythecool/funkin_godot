class_name HealthIcon
extends Resource


## Valid animation names are: [code]"default"[/code], [code]"losing"[/code]
## and [code]"winning"[/code].
@export var sprite_frames: SpriteFrames = null
@export var texture: Texture2D = null
@export var texture_frames := Vector2i(2, 1)

@export var color := Color("31b0d1")
@export var filter := CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
@export_custom(PROPERTY_HINT_LINK, "") var scale := Vector2.ONE


static func create_sprite(icon: HealthIcon) -> CanvasItem:
	var sprite: CanvasItem
	if icon.sprite_frames:
		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = icon.sprite_frames
		sprite.play(&"default")
	else:
		sprite = Sprite2D.new()
		sprite.texture = icon.texture

		if not is_instance_valid(sprite.texture):
			sprite.texture = load("uid://dp4wr3woulw3y")
			sprite.hframes = 2
		else:
			sprite.hframes = icon.texture_frames.x
			sprite.vframes = icon.texture_frames.y

	sprite.texture_filter = icon.filter
	sprite.scale = icon.scale
	return sprite
