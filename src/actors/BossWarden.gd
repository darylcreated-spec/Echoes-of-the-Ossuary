extends "res://src/actors/BaseCharacter3D.gd"
class_name BossWarden

const Projectile3DScript = preload("res://src/combat/Projectile3D.gd")

signal boss_health_updated(current: float, max_val: float, boss_name: String)
signal boss_defeated()

enum BossPhase {
	PHASE_1, # Ground Cleave & 3-way shockwaves
	PHASE_2, # Enrage, Leaping Slam, Minion Summons
	PHASE_3  # Relentless Bone Whirlwind
}

enum BossAction {
	CHASE,
	TELEGRAPH_CLEAVE,
	CLEAVE,
	SHOCKWAVE_3WAY,
	LEAP_PREPARE,
	LEAPING,
	LANDING_SLAM,
	WHIRLWIND,
	STUNNED
}

@export var boss_name: String = "Skeletal Warden, Lich-Architect"

var current_phase: BossPhase = BossPhase.PHASE_1
var current_action: BossAction = BossAction.CHASE
var target_player: Node3D = null

# Timers
var _action_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _summon_cooldown_timer: float = 8.0

# Leap vars
var _leap_start_pos: Vector3 = Vector3.ZERO
var _leap_target_pos: Vector3 = Vector3.ZERO
var _leap_progress: float = 0.0

# Indicators & Nodes
var telegraph_circle: MeshInstance3D = null
var slam_indicator: MeshInstance3D = null
@onready var hitbox = $Hitbox3D if has_node("Hitbox3D") else null

func _ready() -> void:
	max_health = 650.0
	current_health = max_health
	move_speed = 4.2
	attack_damage = 38.0
	defense = 6.0
	super._ready()
	
	_setup_visuals()
	_create_telegraphs()
	
	# Connect to HUD
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
		
	boss_health_updated.emit(current_health, max_health, boss_name)

func _setup_visuals() -> void:
	if visual_model_root and is_instance_valid(visual_model_root):
		visual_model_root.queue_free()

	visual_model_root = AssetLoader.load_or_generate_model("res://assets/characters/skeletons/Skeleton_Warrior.glb", "character", "Boss_Warden")
	visual_model_root.name = "Model"
	visual_model_root.scale = Vector3(2.0, 2.0, 2.0)
	add_child(visual_model_root)
	invalidate_model_cache()
	_cache_model_nodes()

	# Massive Greatsword / Axe
	var sword = AssetLoader.load_or_generate_model("res://assets/weapons/Skeleton_Axe.gltf", "weapon", "axe_2handed")
	AssetLoader.attach_weapon_socket(visual_model_root, sword, "handslot.r")
		
	# Glowing Cyan Crown Light
	var crown_light = OmniLight3D.new()
	crown_light.light_color = Color(0.1, 0.9, 0.85)
	crown_light.light_energy = 3.2
	crown_light.omni_range = 7.0
	crown_light.position = Vector3(0, 3.2, 0)
	visual_model_root.add_child(crown_light)

func _create_telegraphs() -> void:
	# Cleave telegraph
	telegraph_circle = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 4.2
	cyl.bottom_radius = 4.2
	cyl.height = 0.05
	telegraph_circle.mesh = cyl
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.1, 0.1, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.1)
	mat.emission_energy_multiplier = 2.0
	telegraph_circle.material_override = mat
	telegraph_circle.position.y = 0.04
	telegraph_circle.visible = false
	add_child(telegraph_circle)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_knockback(delta)
	
	if is_dead:
		move_and_slide()
		return
		
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta
		
	if _summon_cooldown_timer > 0.0:
		_summon_cooldown_timer -= delta
		
	if not target_player or not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]

	_update_phase()
	_process_action(delta)
	
	move_and_slide()
	update_movement_animation(delta)

func _update_phase() -> void:
	var hp_pct = current_health / max_health
	if hp_pct <= 0.25 and current_phase != BossPhase.PHASE_3:
		current_phase = BossPhase.PHASE_3
		move_speed = 6.2
		CombatJuice.add_trauma(0.5)
		CombatJuice.spawn_hit_spark(global_position + Vector3(0, 2, 0), Color(1.0, 0.1, 0.1))
	elif hp_pct <= 0.60 and current_phase == BossPhase.PHASE_1:
		current_phase = BossPhase.PHASE_2
		move_speed = 5.0
		CombatJuice.add_trauma(0.4)

func _process_action(delta: float) -> void:
	match current_action:
		BossAction.CHASE:
			_process_chase(delta)
		BossAction.TELEGRAPH_CLEAVE:
			_process_telegraph_cleave(delta)
		BossAction.CLEAVE:
			_process_cleave(delta)
		BossAction.LEAP_PREPARE:
			_process_leap_prepare(delta)
		BossAction.LEAPING:
			_process_leaping(delta)
		BossAction.LANDING_SLAM:
			_process_landing_slam(delta)
		BossAction.WHIRLWIND:
			_process_whirlwind(delta)
		BossAction.STUNNED:
			_action_timer -= delta
			if _action_timer <= 0.0:
				current_action = BossAction.CHASE

func _process_chase(delta: float) -> void:
	if not target_player or target_player.is_dead:
		velocity.x = 0.0
		velocity.z = 0.0
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	var dir = (target_player.global_position - global_position).normalized()
	dir.y = 0.0
	
	if dir.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 6.0)
		
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed

	# Minion Summons in Phase 2 & 3
	if current_phase != BossPhase.PHASE_1 and _summon_cooldown_timer <= 0.0:
		_summon_minions()
		_summon_cooldown_timer = 14.0

	# Attack Selection
	if _attack_cooldown_timer <= 0.0:
		if current_phase == BossPhase.PHASE_3 and randf() < 0.4:
			_start_whirlwind()
		elif current_phase != BossPhase.PHASE_1 and dist > 6.0 and randf() < 0.5:
			_start_leap()
		elif dist <= 4.0:
			if randf() < 0.45:
				_start_3way_shockwave()
			else:
				_start_telegraph_cleave()

func _start_telegraph_cleave() -> void:
	current_action = BossAction.TELEGRAPH_CLEAVE
	_action_timer = 0.75
	velocity = Vector3.ZERO
	if telegraph_circle:
		telegraph_circle.visible = true
		telegraph_circle.scale = Vector3(0.2, 1.0, 0.2)
		var tween = telegraph_circle.create_tween()
		tween.tween_property(telegraph_circle, "scale", Vector3(1.0, 1.0, 1.0), 0.75)

func _process_telegraph_cleave(delta: float) -> void:
	_action_timer -= delta
	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		dir.y = 0.0
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 3.0)
		
	if _action_timer <= 0.0:
		_execute_cleave()

func _execute_cleave() -> void:
	current_action = BossAction.CLEAVE
	_action_timer = 0.45
	if telegraph_circle:
		telegraph_circle.visible = false
		
	if anim_player:
		is_attacking = true
		play_anim("2H_Melee_Attack_Chop", 0.05, 1.4)
		get_tree().create_timer(0.45).timeout.connect(func(): is_attacking = false)
		
	AudioManager.play_sfx("sword_swing", 0.05, 3.0)
	CombatJuice.add_trauma(0.25)
	
	if hitbox:
		hitbox.damage = attack_damage * 1.3
		hitbox.damage_source = self
		hitbox.monitoring = true
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(hitbox):
			hitbox.monitoring = false
			
	_attack_cooldown_timer = 1.6

func _process_cleave(delta: float) -> void:
	_action_timer -= delta
	if _action_timer <= 0.0:
		current_action = BossAction.CHASE

func _start_3way_shockwave() -> void:
	current_action = BossAction.CLEAVE
	_action_timer = 0.5
	velocity = Vector3.ZERO
	AudioManager.play_sfx("sword_swing", 0.05, 2.0)
	CombatJuice.add_trauma(0.3)
	
	var forward = -transform.basis.z
	for angle in [-25.0, 0.0, 25.0]:
		var proj = Projectile3DScript.new()
		proj.damage = attack_damage * 0.9
		proj.is_enemy = true
		proj.source_node = self
		proj.direction = forward.rotated(Vector3.UP, deg_to_rad(angle))
		proj.speed = 12.0
		proj.global_position = global_position + Vector3(0, 1.0, 0) + forward * 1.5
		get_tree().current_scene.add_child(proj)
		
	_attack_cooldown_timer = 2.0

func _start_leap() -> void:
	current_action = BossAction.LEAP_PREPARE
	_action_timer = 0.5
	velocity = Vector3.ZERO
	_leap_start_pos = global_position
	if target_player:
		_leap_target_pos = target_player.global_position
	else:
		_leap_target_pos = global_position + -transform.basis.z * 8.0

func _process_leap_prepare(delta: float) -> void:
	_action_timer -= delta
	if _action_timer <= 0.0:
		current_action = BossAction.LEAPING
		_leap_progress = 0.0

func _process_leaping(delta: float) -> void:
	_leap_progress += delta * 1.6
	var t = clamp(_leap_progress, 0.0, 1.0)
	var horizontal = _leap_start_pos.lerp(_leap_target_pos, t)
	var height = sin(t * PI) * 6.5
	global_position = Vector3(horizontal.x, _leap_start_pos.y + height, horizontal.z)
	
	if t >= 1.0:
		_execute_landing_slam()

func _execute_landing_slam() -> void:
	current_action = BossAction.LANDING_SLAM
	_action_timer = 0.6
	CombatJuice.add_trauma(0.6)
	CombatJuice.spawn_bone_burst(global_position, 30)
	AudioManager.play_sfx("hit_flesh", 0.05, 4.0)
	
	# Radial 8-way shockwaves
	for i in range(8):
		var angle = i * 45.0
		var proj = Projectile3DScript.new()
		proj.damage = attack_damage * 1.1
		proj.is_enemy = true
		proj.source_node = self
		proj.direction = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(angle))
		proj.speed = 10.0
		proj.global_position = global_position + Vector3(0, 0.8, 0)
		get_tree().current_scene.add_child(proj)
		
	_attack_cooldown_timer = 2.4

func _process_landing_slam(delta: float) -> void:
	_action_timer -= delta
	if _action_timer <= 0.0:
		current_action = BossAction.CHASE

func _start_whirlwind() -> void:
	current_action = BossAction.WHIRLWIND
	_action_timer = 2.4
	if anim_player:
		play_anim("2H_Melee_Attack_Spin", 0.08, 1.8)
	if hitbox:
		hitbox.damage = attack_damage * 0.7
		hitbox.damage_source = self
		hitbox.monitoring = true

func _process_whirlwind(delta: float) -> void:
	_action_timer -= delta
	rotation.y += delta * 15.0
	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		dir.y = 0.0
		velocity.x = dir.x * move_speed * 1.2
		velocity.z = dir.z * move_speed * 1.2
		
	if _action_timer <= 0.0:
		if hitbox:
			hitbox.monitoring = false
		current_action = BossAction.CHASE
		_attack_cooldown_timer = 2.0

func _summon_minions() -> void:
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1.5, 0), Color(0.1, 0.9, 0.8))
	for offset in [Vector3(-3, 0, -2), Vector3(3, 0, -2)]:
		var minion_scene = load("res://scenes/EnemySkeleton.tscn")
		if minion_scene:
			var minion = minion_scene.instantiate()
			minion.global_position = global_position + offset
			get_parent().add_child(minion)

func take_damage(amount: float, knockback: Vector3, is_crit: bool, source: Node3D) -> void:
	# Heavy bosses resist knockback by 80%
	super.take_damage(amount, knockback * 0.2, is_crit, source)
	_update_phase()
	boss_health_updated.emit(current_health, max_health, boss_name)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	boss_health_updated.emit(0.0, max_health, boss_name)
	boss_defeated.emit()
	
	CombatJuice.add_trauma(0.8)
	CombatJuice.freeze_frame(0.2, 0.02)
	CombatJuice.spawn_bone_burst(global_position, 50)
	AudioManager.play_sfx("skeleton_bones", 0.05, 6.0)
	AudioManager.play_sfx("sfx_victory_fanfare", 0.0, 3.0)
	
	if anim_player:
		var death_anim = "Death_C_Skeletons" if anim_player.has_animation("Death_C_Skeletons") else "Death_A"
		play_anim(death_anim, 0.08, 1.0)
	
	GameManager.add_gold(150)
	GameManager.add_echoes(100)
	GameManager.trigger_game_over(true)
	
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	get_tree().create_timer(1.8).timeout.connect(queue_free)
