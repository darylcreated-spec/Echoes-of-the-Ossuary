extends CharacterBody3D
class_name BaseCharacter3D

signal health_changed(current: float, max_val: float)
signal character_died()

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var move_speed: float = 6.0
@export var attack_damage: float = 20.0
@export var defense: float = 0.0

var is_dead: bool = false
var is_attacking: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO
var gravity: float = 26.0

@onready var hurtbox = $Hurtbox3D if has_node("Hurtbox3D") else null
var visual_model_root: Node3D = null
var _flash_tween: Tween = null

# --- SKELETAL & PROCEDURAL ANIMATION STATE ---
var anim_player: AnimationPlayer = null
var skeleton_node: Skeleton3D = null
var _walk_time: float = 0.0
var _node_torso: Node3D = null
var _node_head: Node3D = null
var _node_left_leg: Node3D = null
var _node_right_leg: Node3D = null
var _node_left_arm: Node3D = null
var _node_right_arm: Node3D = null
var _base_torso_y: float = 0.9
var _nodes_cached: bool = false

func invalidate_model_cache() -> void:
	_nodes_cached = false
	anim_player = null
	skeleton_node = null
	_node_torso = null
	_node_head = null
	_node_left_leg = null
	_node_right_leg = null
	_node_left_arm = null
	_node_right_arm = null

func _cache_model_nodes() -> void:
	if not visual_model_root:
		visual_model_root = get_node_or_null("Model")
	if visual_model_root:
		anim_player = visual_model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		skeleton_node = visual_model_root.find_child("Skeleton3D", true, false) as Skeleton3D
		_node_torso = visual_model_root.find_child("Torso", true, false)
		_node_head = visual_model_root.find_child("Head", true, false)
		_node_left_leg = visual_model_root.find_child("LeftLeg", true, false)
		_node_right_leg = visual_model_root.find_child("RightLeg", true, false)
		_node_left_arm = visual_model_root.find_child("LeftArm", true, false)
		_node_right_arm = visual_model_root.find_child("RightArm", true, false)
		if _node_torso:
			_base_torso_y = _node_torso.position.y
		_nodes_cached = true

func play_anim(anim_name: String, blend_time: float = 0.12, speed: float = 1.0) -> bool:
	if not anim_player:
		return false
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name, blend_time, speed)
		return true
	
	# Fuzzy match fallback (e.g. "attack" -> "Punch" or "Weapon" or "Bite_Action")
	var anim_list = anim_player.get_animation_list()
	var lower_target = anim_name.to_lower()
	for a in anim_list:
		var la = a.to_lower()
		if lower_target in la or la in lower_target:
			anim_player.play(a, blend_time, speed)
			return true
	return false

func update_movement_animation(delta: float) -> void:
	if is_dead:
		return

	if not _nodes_cached or not visual_model_root:
		_cache_model_nodes()
		if not visual_model_root:
			return

	var horiz_vel = Vector2(velocity.x, velocity.z)
	var speed = horiz_vel.length()

	# --- SKELETAL RIG ANIMATION PLAYBACK ---
	if anim_player:
		if is_attacking:
			return
			
		if speed > 0.35:
			var run_speed = clamp(speed / max(move_speed, 1.0) * 1.3, 0.7, 1.8)
			var move_anim = ""
			var anim_list = anim_player.get_animation_list()
			for candidate in ["running_a", "gallop", "run", "walking_a", "walk", "walk1_action"]:
				for a in anim_list:
					if candidate in a.to_lower():
						move_anim = a
						break
				if move_anim != "":
					break
			if move_anim != "":
				if anim_player.current_animation != move_anim:
					anim_player.play(move_anim, 0.15, run_speed)
				else:
					anim_player.speed_scale = run_speed
		else:
			var idle_anim = ""
			var anim_list = anim_player.get_animation_list()
			for candidate in ["idle", "eating"]:
				for a in anim_list:
					if candidate in a.to_lower():
						idle_anim = a
						break
				if idle_anim != "":
					break
			if idle_anim != "":
				if anim_player.current_animation != idle_anim:
					anim_player.play(idle_anim, 0.2, 1.0)
		return

	# --- PROCEDURAL FALLBACK (FOR NON-RIGGED CSG MODELS) ---
	if speed > 0.35:
		# Moving walk/run cycle
		_walk_time += delta * speed * 2.3
		var leg_swing = sin(_walk_time) * 0.72
		var arm_swing = sin(_walk_time) * 0.52
		
		# Alternating legs and arms
		if _node_left_leg:
			_node_left_leg.rotation.x = leg_swing
		if _node_right_leg:
			_node_right_leg.rotation.x = -leg_swing
		if _node_left_arm:
			_node_left_arm.rotation.x = -arm_swing
		if _node_right_arm and not is_attacking:
			_node_right_arm.rotation.x = arm_swing
			
		# Vertical bobbing (double frequency)
		if _node_torso:
			_node_torso.position.y = _base_torso_y + abs(sin(_walk_time)) * 0.08
			
		# Squash and stretch (volume preservation)
		var scale_mod = cos(_walk_time * 2.0) * 0.035
		visual_model_root.scale = Vector3(1.0 + scale_mod, 1.0 - scale_mod, 1.0 + scale_mod)
		
		# Forward lean & lateral banking
		var forward_tilt = deg_to_rad(6.5)
		visual_model_root.rotation.x = lerp(visual_model_root.rotation.x, forward_tilt, delta * 8.0)
		var bank_target = clamp(-velocity.x / max(move_speed, 1.0) * 0.14, -0.2, 0.2)
		visual_model_root.rotation.z = lerp(visual_model_root.rotation.z, bank_target, delta * 8.0)
	else:
		# Standing still / Idle rest interpolation
		_walk_time = 0.0
		if _node_left_leg:
			_node_left_leg.rotation.x = lerp_angle(_node_left_leg.rotation.x, 0.0, delta * 12.0)
		if _node_right_leg:
			_node_right_leg.rotation.x = lerp_angle(_node_right_leg.rotation.x, 0.0, delta * 12.0)
		if _node_left_arm:
			_node_left_arm.rotation.x = lerp_angle(_node_left_arm.rotation.x, 0.0, delta * 12.0)
		if _node_right_arm and not is_attacking:
			_node_right_arm.rotation.x = lerp_angle(_node_right_arm.rotation.x, 0.0, delta * 12.0)
		if _node_torso:
			_node_torso.position.y = lerp(_node_torso.position.y, _base_torso_y, delta * 10.0)
			# Subtle breathing idle sway
			var breath = sin(Time.get_ticks_msec() * 0.003) * 0.02
			_node_torso.scale = Vector3(1.0 - breath * 0.4, 1.0 + breath, 1.0 - breath * 0.4)
			
		visual_model_root.rotation.x = lerp(visual_model_root.rotation.x, 0.0, delta * 8.0)
		visual_model_root.rotation.z = lerp(visual_model_root.rotation.z, 0.0, delta * 8.0)
		visual_model_root.scale = visual_model_root.scale.lerp(Vector3.ONE, delta * 10.0)

func _ready() -> void:
	current_health = max_health
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(55.0)
	floor_stop_on_slope = true
	if hurtbox:
		hurtbox.damage_received.connect(take_damage)
	_setup_mesh_flash()

func _setup_mesh_flash() -> void:
	visual_model_root = get_node_or_null("Model")

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5
		
	# Abyss / Void fall safeguard: never allow falling infinitely into the dark void
	if global_position.y < -1.5:
		if is_in_group("player"):
			global_position = Vector3(0, 0.5, 0)
			velocity = Vector3.ZERO
		else:
			take_damage(9999.0, Vector3.ZERO, false, null)

func handle_knockback(delta: float) -> void:
	if knockback_velocity.length() > 0.1:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 12.0)

func take_damage(amount: float, knockback: Vector3, is_crit: bool, source: Node3D) -> void:
	if is_dead:
		return
		
	var actual_damage = max(1.0, amount - defense)
	current_health = max(0.0, current_health - actual_damage)
	knockback_velocity = knockback
	
	health_changed.emit(current_health, max_health)
	
	# Combat Juice feedback
	var is_player = is_in_group("player")
	CombatJuice.spawn_damage_number(global_position, actual_damage, is_crit, is_player)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.8, 0))
	trigger_hit_flash()
	
	if is_player:
		CombatJuice.add_trauma(0.35 if is_crit else 0.2)
		AudioManager.play_sfx("hit_flesh", 0.1, 0.0)
	else:
		CombatJuice.add_trauma(0.15 if is_crit else 0.08)
		AudioManager.play_sfx("skeleton_bones", 0.12, 0.0)
		
	if is_crit:
		CombatJuice.freeze_frame(0.06, 0.05)
		
	if current_health <= 0.0:
		die()
	elif anim_player and not is_attacking:
		play_anim("Hit_A", 0.05, 1.2)

func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	CombatJuice.spawn_damage_number(global_position, amount, false, false, true)

func trigger_hit_flash() -> void:
	if not visual_model_root:
		return
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(visual_model_root, meshes)
	for m in meshes:
		var orig_mat = m.get_surface_override_material(0)
		if orig_mat is StandardMaterial3D:
			orig_mat.emission_enabled = true
			orig_mat.emission = Color(1.0, 1.0, 1.0)
			orig_mat.emission_energy_multiplier = 4.0
	
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_callback(func():
		for m in meshes:
			var orig_mat = m.get_surface_override_material(0)
			if orig_mat is StandardMaterial3D:
				orig_mat.emission_energy_multiplier = 0.0
	).set_delay(0.12)

func _collect_meshes(parent: Node, list: Array[MeshInstance3D]) -> void:
	for c in parent.get_children():
		if c is MeshInstance3D:
			list.append(c)
		_collect_meshes(c, list)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	character_died.emit()
	CombatJuice.spawn_bone_burst(global_position)
	
	if anim_player and anim_player.has_animation("Death_A"):
		collision_layer = 0
		collision_mask = 1 # Keep only floor collision so model doesn't drop through ground
		if hurtbox:
			hurtbox.set_deferred("monitoring", false)
			hurtbox.set_deferred("monitorable", false)
		play_anim("Death_A", 0.08, 1.0)
		var t = create_tween()
		t.tween_interval(0.85)
		t.tween_callback(queue_free)
	else:
		queue_free()
