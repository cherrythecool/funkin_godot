extends ModchartModifier

func get_id() -> String:
	return "rotate_x"

func get_sub_modifier_ids() -> Array[String]:
	var sub_mods:Array[String] = ["rotate_y", "rotate_z"]
	var key_count = manager.adapter.get_key_count()
	for i in range(key_count):
		sub_mods.push_back("rotate_x_" + str(i))
		sub_mods.push_back("rotate_y_" + str(i))
		sub_mods.push_back("rotate_z_" + str(i))
	return sub_mods

func get_position(position:Vector3, origin:Variant, type:ModchartManager.ObjectType, visual_time:float, direction:int, player:int) -> Vector3:
	var key_count = manager.adapter.get_key_count()
	var screen_center_y = 360.0

	var col_origin = Vector3(origin.global_position.x, screen_center_y, 0.0)
	var col_pos = position - col_origin
	
	var col_rot_x = get_value(player, "rotate_x_" + str(direction)) * (PI / 180.0)
	var col_rot_y = get_value(player, "rotate_y_" + str(direction)) * (PI / 180.0)
	var col_rot_z = get_value(player, "rotate_z_" + str(direction)) * (PI / 180.0)
	
	if col_rot_x != 0.0:col_pos = col_pos.rotated(Vector3.RIGHT, col_rot_x)
	if col_rot_y != 0.0:col_pos = col_pos.rotated(Vector3.UP, col_rot_y)
	if col_rot_z != 0.0:col_pos = col_pos.rotated(Vector3.FORWARD, col_rot_z)
	
	position = col_pos + col_origin

	var field_origin = Vector3(origin.global_position.x, screen_center_y, 0.0)
	
	var field_pos = position - field_origin
	
	var field_rot_x = (get_value(player) + get_value(player, "rotate_x_" + str(direction))) * (PI / 180.0)
	var field_rot_y = (get_value(player, "rotate_y") + get_value(player, "rotate_y_" + str(direction))) * (PI / 180.0)
	var field_rot_z = (get_value(player, "rotate_z") + get_value(player, "rotate_z_" + str(direction))) * (PI / 180.0)
	
	if field_rot_x != 0.0:field_pos = field_pos.rotated(Vector3.RIGHT, field_rot_x)
	if field_rot_y != 0.0:field_pos = field_pos.rotated(Vector3.UP, field_rot_y)
	if field_rot_z != 0.0:field_pos = field_pos.rotated(Vector3.FORWARD, field_rot_z)
	
	position = field_pos + field_origin
	return position
