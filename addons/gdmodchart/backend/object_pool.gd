extends Node
class_name ModchartObjectPool

var pool:Array[ModchartObject] = []

func get_object(origin:Node2D) -> ModchartObject:
	if pool.size() > 0:
		var target = pool[0]
		target.process_mode = Node.ProcessMode.PROCESS_MODE_INHERIT
		target.origin = origin
		pool.erase(target)
		return target
	return ModchartObject.new(origin)

func add_to_pool(object:ModchartObject) -> void:
	object.get_parent().remove_child(object)
	object.process_mode = Node.PROCESS_MODE_DISABLED
	pool.push_back(object)
