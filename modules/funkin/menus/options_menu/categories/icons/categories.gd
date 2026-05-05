extends HBoxContainer


static var selected: int = 0

@onready var options_menu: Node2D = $'../..'
@onready var section: Node2D = options_menu.get_node('section')
@onready var section_label: Alphabet = options_menu.get_node('top/section_label')
@onready var starting_position: Vector2 = position
@onready var camera: Camera2D = %camera

var section_label_tween: Tween
var category_tween: Tween
var category_back_tween: Tween
var active: bool = true


func _ready() -> void:
	change_selection()
	_update_items(INF)


func _process(delta: float) -> void:
	_update_items(delta)


func _input(event: InputEvent) -> void:
	if not active:
		return
	if not event.is_pressed():
		return
	if event.is_action('menu_up') or event.is_action('menu_down'):
		change_selection(roundi(Input.get_axis('menu_up', 'menu_down')))
	if event.is_action('menu_left') or event.is_action('menu_right'):
		change_selection(roundi(Input.get_axis('menu_left', 'menu_right')))
	if event.is_action('menu_accept'):
		var selection: CategoryIcon = get_child(selected) as CategoryIcon
		if is_instance_valid(selection.category):
			GlobalAudio.get_player('MENU/CONFIRM').play()
			options_menu.active = false
			active = false
			selection.category.alive = true

			if is_instance_valid(category_tween) and category_tween.is_running():
				category_tween.kill()

			category_tween = create_tween()\
					.set_ease(Tween.EASE_OUT)\
					.set_trans(Tween.TRANS_SINE)\
					.set_parallel()
			category_tween.tween_property(section, 'position:y', 360.0, 0.5)
			# 1005 = 285 + 720
			category_tween.tween_property(self, 'position:y', 1005.0, 0.5)
		else:
			GlobalAudio.get_player('MENU/CANCEL').play()


func change_selection(amount: int = 0) -> void:
	selected = wrapi(selected + amount, 0, get_child_count())
	section_label.text = get_child(selected).name.to_upper()

	if amount != 0:
		GlobalAudio.get_player('MENU/SCROLL').play()

		section_label.modulate.a = 0.75
		section_label.position.y = 40.0

		if is_instance_valid(section_label_tween) and section_label_tween.is_running():
			section_label_tween.kill()

		section_label_tween = create_tween()\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_OUT)\
				.set_parallel()
		section_label_tween.tween_property(section_label, 'modulate:a', 1.0, 0.25)
		section_label_tween.tween_property(section_label, 'position:y', 48.0, 0.25)


func _update_items(delta: float) -> void:
	var instant: bool = is_inf(delta)
	# 0.1 = 1 / 10 = max amount of delta allowed in our lerpfs
	delta = minf(delta, 0.1)

	for i: int in get_child_count():
		var target_alpha: float = 1.0 if i == selected else 0.5
		var target_scale: float = 1.0 if i == selected else 0.75
		var child: Control = get_child(i) as Control
		child.pivot_offset = child.custom_minimum_size * 0.5

		if instant:
			child.modulate.a = target_alpha
			child.scale = Vector2(target_scale, target_scale)
		else:
			child.modulate.a = lerpf(child.modulate.a, target_alpha, delta * 10.0)
			child.scale = child.scale.lerp(Vector2(target_scale, target_scale), delta * 10.0)


func _tween_back(_category: Node2D) -> void:
	category_back_tween = create_tween()\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)\
			.set_parallel()
	category_back_tween.tween_property(section, 'position:y', 1080.0, 0.5)
	category_back_tween.tween_property(self, 'position:y', 285.0, 0.5)
	category_back_tween.tween_property(camera, 'position', Global.game_size / 2.0, 0.5)
