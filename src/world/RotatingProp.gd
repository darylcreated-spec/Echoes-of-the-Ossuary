extends Node
class_name RotatingProp

@export var target_node_name: String = ""
@export var rotation_axis: Vector3 = Vector3(0, 0, 1)
@export var rpm: float = 6.0

var _target: Node3D = null

func _ready() -> void:
	if target_node_name != "":
		_target = get_parent().find_child(target_node_name, true, false) as Node3D
	if not _target and get_parent() is Node3D:
		_target = get_parent() as Node3D

func _process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		var rad_per_sec = (rpm * TAU) / 60.0
		_target.rotate_object_local(rotation_axis.normalized(), rad_per_sec * delta)
