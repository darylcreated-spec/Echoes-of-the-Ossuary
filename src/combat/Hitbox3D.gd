extends Area3D
class_name Hitbox3D

@export var damage: float = 20.0
@export var knockback_force: float = 8.0
@export var is_crit: bool = false
@export var damage_source: Node3D = null

func _init() -> void:
	# Default collision monitoring
	monitoring = true
	monitorable = true
