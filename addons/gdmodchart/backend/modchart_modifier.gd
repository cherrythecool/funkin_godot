extends Object
class_name ModchartModifier

var manager:ModchartManager

func _init(manager:ModchartManager) -> void:
	self.manager = manager

func get_id() -> String:
	return ""

func get_sub_modifier_ids() -> Array[String]:
	return []

func get_position(position:Vector3, object:Node, type:ModchartManager.ObjectType, direction:int, player:int) -> Vector3:
	return position


func get_value(player:int, sub_mod:String = "") -> float:
	var target = sub_mod if sub_mod != "" else get_id()
	return manager.players[player].values.get(target, 0)
