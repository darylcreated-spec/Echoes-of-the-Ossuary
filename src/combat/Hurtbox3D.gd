extends Area3D
class_name Hurtbox3D

signal damage_received(amount: float, knockback: Vector3, is_crit: bool, source: Node3D)

const Hitbox3DScript = preload("res://src/combat/Hitbox3D.gd")

@export var i_frame_duration: float = 0.2
@export var owner_character: Node3D = null

var is_invulnerable: bool = false
var _i_timer: Timer = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
	_i_timer = Timer.new()
	_i_timer.one_shot = true
	_i_timer.timeout.connect(_on_i_frame_timeout)
	add_child(_i_timer)

func _on_area_entered(area: Area3D) -> void:
	if is_invulnerable:
		return
	if area is Hitbox3DScript or area.get("damage") != null:
		var hitbox = area
		if hitbox.damage_source == owner_character:
			return # Don't hit self
			
		var kb_dir = (global_position - hitbox.global_position).normalized()
		kb_dir.y = 0.1 # Slight pop-up
		kb_dir = kb_dir.normalized()
		
		var final_damage = hitbox.damage
		var is_crit = hitbox.is_crit if ("is_crit" in hitbox) else false
		var kb_force = hitbox.knockback_force if ("knockback_force" in hitbox) else 6.0
		
		# Trigger i-frames
		start_invulnerability(i_frame_duration)
		
		damage_received.emit(final_damage, kb_dir * kb_force, is_crit, hitbox.damage_source)

func start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	_i_timer.start(duration)

func _on_i_frame_timeout() -> void:
	is_invulnerable = false
