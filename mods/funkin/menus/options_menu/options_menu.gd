class_name OptionsMenu
extends Node2D


const DEFAULT_TARGET_SCENE := "uid://b7fwxsepnt38j"

static var target_scene := DEFAULT_TARGET_SCENE
static var selected := 0

@export var interface: Control
@export var categories: Control
@export var section: Node2D
@export var options_label: AnimatedSprite2D
@export var scroll_container: ScrollContainer

var active: bool = true
var lerped_vertical_scroll: float = 0.0


func _ready() -> void:
	MenuAudio.music.stream = load("uid://ddoyqrhrcjw1j")
	MenuAudio.music.play()

	Conductor.reset()
	Conductor.tempo = 137.0
	Conductor.target_audio = MenuAudio.music
	Conductor.beat_hit.connect(_on_beat_hit)

	change_selection()

	for child: CategoryIcon in categories.get_children():
		child._ready()


func _process(delta: float) -> void:
	var child: CategoryIcon = categories.get_child(selected)
	var max_scroll := scroll_container.get_v_scroll_bar().max_value - scroll_container.get_rect().size.y
	lerped_vertical_scroll = lerpf(lerped_vertical_scroll, minf(child.position.y, max_scroll), GameUtils.lerp_weight(delta, 6.0))
	scroll_container.scroll_vertical = int(lerped_vertical_scroll)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed(&"menu_left") or event.is_action_pressed(&"menu_right"):
		change_selection(roundi(Input.get_axis(&"menu_left", &"menu_right")))

	if event.is_action_pressed(&"menu_up") or event.is_action_pressed(&"menu_down"):
		change_selection(roundi(Input.get_axis(&"menu_up", &"menu_down")))

	if event.is_action_pressed(&"menu_accept"):
		select_current()

	if event.is_action_pressed(&"menu_cancel"):
		active = false
		MenuAudio.cancel.play()
		SceneManager.transition_to_file(target_scene)
		target_scene = DEFAULT_TARGET_SCENE


func change_selection(amount: int = 0) -> void:
	selected = wrapi(selected + amount, 0, categories.get_child_count())

	if amount != 0:
		MenuAudio.scroll.play()

	for i: int in categories.get_child_count():
		var child: CategoryIcon = categories.get_child(i)
		if i == selected:
			child.target_alpha = 1.0
			child.target_scale = 1.0
		else:
			child.target_alpha = 0.6
			child.target_scale = 0.8


func deselect_current() -> void:
	active = true
	MenuAudio.cancel.play()

	var children: Array[Node] = section.get_children()
	var tween: Tween = create_tween()\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)\
		.set_parallel()

	tween.tween_property(interface, ^"position:x", 0.0, 0.5)
	tween.tween_property(section, ^"position:x", 1920.0, 0.5)
	tween.tween_callback(GameUtils.free_from_array.bind(children)).set_delay(0.5)


func select_current() -> void:
	active = false
	MenuAudio.confirm.play()

	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_parallel()
	tween.tween_property(interface, ^"position:x", -1280.0, 0.5)
	tween.tween_property(section, ^"position:x", 640.0, 0.5)

	var current_selected: CategoryIcon = categories.get_child(selected)
	var options_section: CategoryBase = current_selected.category.instantiate()
	section.add_child(options_section)


func _on_beat_hit(_beat: int) -> void:
	options_label.scale = Vector2(0.65, 0.65)


func _exit_tree() -> void:
	MenuAudio.music.stream = load("uid://dergcpn8f5cju")
	MenuAudio.music.play()
