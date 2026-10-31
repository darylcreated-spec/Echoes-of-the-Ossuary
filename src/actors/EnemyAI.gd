extends "res://src/actors/BaseCharacter3D.gd"
class_name EnemyAI

const Projectile3DScript = preload("res://src/combat/Projectile3D.gd")

enum EnemyType {
	MINION,
	WARRIOR,
	ROGUE,
	MAGE,
	ORC,
	DEMON,
	CREEP,
	PIRATE,
	BANDIT
}

enum AIState {
	IDLE,
	CHASE,
	TELEGRAPH,
	ATTACK,
	STAGGER,
	DEAD
}

@export var enemy_type: EnemyType = EnemyType.MINION

var current_ai_state: AIState = AIState.CHASE
var target_player: Node3D = null

# AI Parameters
var detection_radius: float = 24.0
var attack_range_threshold: float = 2.0
var telegraph_duration: float = 0.55
var attack_cooldown: float = 1.4
var _cooldown_timer: float = 0.0
var _state_timer: float = 0.0

# Components
@onready var hitbox = $Hitbox3D if has_node("Hitbox3D") else null
var telegraph_indicator: MeshInstance3D = null

func _ready() -> void:
	super._ready()
	add_to_group("enemies")
	_configure_type_stats()
	_setup_visuals()
	_create_telegraph_indicator()
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _configure_type_stats() -> void:
	match enemy_type:
		EnemyType.MINION:
			max_health = 45.0
			move_speed = 5.2
			attack_damage = 14.0
			attack_range_threshold = 1.9
			telegraph_duration = 0.35
			attack_cooldown = 1.1
		EnemyType.WARRIOR:
			max_health = 95.0
			move_speed = 3.8
			attack_damage = 28.0
			attack_range_threshold = 2.4
			telegraph_duration = 0.65
			attack_cooldown = 1.8
			defense = 3.0
		EnemyType.ROGUE:
			max_health = 60.0
			move_speed = 6.4
			attack_damage = 18.0
			attack_range_threshold = 6.5 # Ranged skirmisher
			telegraph_duration = 0.45
			attack_cooldown = 1.5
		EnemyType.MAGE:
			max_health = 55.0
			move_speed = 3.6
			attack_damage = 22.0
			attack_range_threshold = 8.0 # Ranged caster
			telegraph_duration = 0.8
			attack_cooldown = 2.2
		EnemyType.ORC:
			max_health = 130.0
			move_speed = 4.0
			attack_damage = 32.0
			attack_range_threshold = 2.4
			telegraph_duration = 0.6
			attack_cooldown = 1.6
			defense = 4.0
		EnemyType.DEMON:
			max_health = 165.0
			move_speed = 4.4
			attack_damage = 36.0
			attack_range_threshold = 2.5
			telegraph_duration = 0.5
			attack_cooldown = 1.4
			defense = 5.0
		EnemyType.CREEP:
			max_health = 85.0
			move_speed = 6.0
			attack_damage = 24.0
			attack_range_threshold = 2.0
			telegraph_duration = 0.35
			attack_cooldown = 1.1
			defense = 2.0
		EnemyType.PIRATE:
			max_health = 80.0
			move_speed = 6.2
			attack_damage = 22.0
			attack_range_threshold = 2.2
			telegraph_duration = 0.38
			attack_cooldown = 1.2
			defense = 2.0
		EnemyType.BANDIT:
			max_health = 75.0
			move_speed = 6.0
			attack_damage = 20.0
			attack_range_threshold = 2.0
			telegraph_duration = 0.4
			attack_cooldown = 1.3
			defense = 2.0

	current_health = max_health

func _setup_visuals() -> void:
	if visual_model_root and is_instance_valid(visual_model_root):
		visual_model_root.queue_free()

	var type_name = "Skeleton_Minion"
	var weapon_name = "Skeleton_Blade"
	var model_path = ""
	var model_scale = Vector3.ONE
	
	match enemy_type:
		EnemyType.MINION:
			type_name = "Skeleton_Minion"
			weapon_name = "Skeleton_Blade"
			model_path = "res://assets/characters/skeletons/" + type_name + ".glb"
		EnemyType.WARRIOR:
			type_name = "Skeleton_Warrior"
			weapon_name = "Skeleton_Axe"
			model_path = "res://assets/characters/skeletons/" + type_name + ".glb"
		EnemyType.ROGUE:
			type_name = "Skeleton_Rogue"
			weapon_name = "dagger"
			model_path = "res://assets/characters/skeletons/" + type_name + ".glb"
		EnemyType.MAGE:
			type_name = "Skeleton_Mage"
			weapon_name = "Skeleton_Staff"
			model_path = "res://assets/characters/skeletons/" + type_name + ".glb"
		EnemyType.ORC:
			type_name = "Orc"
			weapon_name = ""
			model_path = "res://assets/characters/monsters/Orc.gltf"
			model_scale = Vector3(1.15, 1.15, 1.15)
		EnemyType.DEMON:
			type_name = "Demon"
			weapon_name = ""
			model_path = "res://assets/characters/monsters/Demon.gltf"
			model_scale = Vector3(1.25, 1.25, 1.25)
		EnemyType.CREEP:
			type_name = "CreepCreature"
			weapon_name = ""
			model_path = "res://assets/characters/monsters/CreepCreature.glb"
			model_scale = Vector3(1.0, 1.0, 1.0)
		EnemyType.PIRATE:
			type_name = "Rogue_Hooded"
			weapon_name = "sword_1handed"
			model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
			model_scale = Vector3(0.55, 0.55, 0.55)
		EnemyType.BANDIT:
			type_name = "Rogue_Hooded"
			weapon_name = "dagger"
			model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
			model_scale = Vector3(0.55, 0.55, 0.55)

	visual_model_root = AssetLoader.load_or_generate_model(model_path, "character", type_name)
	visual_model_root.name = "Model"
	visual_model_root.scale = model_scale
	add_child(visual_model_root)
	invalidate_model_cache()
	_cache_model_nodes()

	if weapon_name != "":
		var weapon_path = "res://assets/weapons/" + weapon_name + ".gltf"
		var weapon = AssetLoader.load_or_generate_model(weapon_path, "weapon", weapon_name)
		weapon.name = "Weapon"
		AssetLoader.attach_weapon_socket(visual_model_root, weapon, "handslot.r")
		
		# Warrior Shield
		if enemy_type == EnemyType.WARRIOR:
			var shield = AssetLoader.load_or_generate_model("res://assets/weapons/shield_square.glb", "weapon", "shield_square")
			shield.name = "Shield"
			AssetLoader.attach_weapon_socket(visual_model_root, shield, "handslot.l")

	if anim_player:
		if anim_player.has_animation("Spawn_Ground_Skeletons"):
			anim_player.play("Spawn_Ground_Skeletons", 0.05, 1.3)
		elif anim_player.has_animation("Skeletons_Awaken_Floor"):
			anim_player.play("Skeletons_Awaken_Floor", 0.05, 1.3)

func _create_telegraph_indicator() -> void:
	telegraph_indicator = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = attack_range_threshold * 0.95
	cyl.bottom_radius = attack_range_threshold * 0.95
	cyl.height = 0.05
	telegraph_indicator.mesh = cyl
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.15, 0.15, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.1, 0.1)
	mat.emission_energy_multiplier = 1.5
	telegraph_indicator.material_override = mat
	telegraph_indicator.position.y = 0.03
	telegraph_indicator.visible = false
	add_child(telegraph_indicator)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_knockback(delta)
	
	if is_dead:
		move_and_slide()
		return
		
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		
	if not target_player or not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]
			
	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.TELEGRAPH:
			_process_telegraph(delta)
		AIState.ATTACK:
			_process_attack(delta)
		AIState.STAGGER:
			_process_stagger(delta)

	move_and_slide()
	update_movement_animation(delta)

func _process_idle(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if target_player and global_position.distance_to(target_player.global_position) <= detection_radius:
		current_ai_state = AIState.CHASE

func _process_chase(delta: float) -> void:
	if not target_player or target_player.is_dead:
		current_ai_state = AIState.IDLE
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	var dir = (target_player.global_position - global_position).normalized()
	dir.y = 0.0
	
	# Turn to face player
	if dir.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)
		
	if enemy_type in [EnemyType.ROGUE, EnemyType.MAGE]:
		# Ranged spacing logic: back away if too close!
		if dist < 3.2:
			velocity.x = -dir.x * move_speed * 0.9
			velocity.z = -dir.z * move_speed * 0.9
			if enemy_type == EnemyType.MAGE and randf() < 0.015:
				_teleport_away()
		elif dist <= attack_range_threshold:
			velocity.x = 0.0
			velocity.z = 0.0
			if _cooldown_timer <= 0.0:
				_start_telegraph()
		else:
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
	else:
		# Melee behavior
		if dist <= attack_range_threshold:
			velocity.x = 0.0
			velocity.z = 0.0
			if _cooldown_timer <= 0.0:
				_start_telegraph()
		else:
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed

func _start_telegraph() -> void:
	current_ai_state = AIState.TELEGRAPH
	_state_timer = telegraph_duration
	if telegraph_indicator:
		telegraph_indicator.visible = true
		telegraph_indicator.scale = Vector3(0.1, 1.0, 0.1)
		var tween = telegraph_indicator.create_tween()
		tween.tween_property(telegraph_indicator, "scale", Vector3(1.0, 1.0, 1.0), telegraph_duration)

func _process_telegraph(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer -= delta
	
	# Keep tracking player slightly during telegraph
	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		dir.y = 0.0
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 4.0)
		
	if _state_timer <= 0.0:
		_execute_attack()

func _execute_attack() -> void:
	current_ai_state = AIState.ATTACK
	_state_timer = 0.35
	if telegraph_indicator:
		telegraph_indicator.visible = false
		
	var forward = -transform.basis.z
	
	if anim_player:
		is_attacking = true
		var anim_name = "1H_Melee_Attack_Chop"
		if enemy_type == EnemyType.MAGE:
			anim_name = "Spellcast_Shoot"
		elif enemy_type == EnemyType.ROGUE:
			anim_name = "1H_Melee_Attack_Stab"
		elif enemy_type in [EnemyType.ORC, EnemyType.DEMON]:
			anim_name = "Punch" if randf() < 0.5 else "Weapon"
		elif enemy_type == EnemyType.CREEP:
			anim_name = "Bite_Action"
		play_anim(anim_name, 0.05, 1.8)
		get_tree().create_timer(0.35).timeout.connect(func(): is_attacking = false)
	
	if enemy_type in [EnemyType.ROGUE, EnemyType.MAGE]:
		# Fire bone projectile
		var proj = Projectile3DScript.new()
		proj.damage = attack_damage
		proj.is_enemy = true
		proj.source_node = self
		proj.direction = forward
		proj.speed = 13.0
		proj.global_position = global_position + Vector3(0, 1.0, 0) + forward * 0.7
		get_tree().current_scene.add_child(proj)
		AudioManager.play_sfx("sword_swing", 0.15, -3.0)
	else:
		# Melee strike
		if hitbox:
			hitbox.damage = attack_damage
			hitbox.damage_source = self
			hitbox.monitoring = true
			await get_tree().create_timer(0.15).timeout
			if is_instance_valid(hitbox):
				hitbox.monitoring = false
		AudioManager.play_sfx("sword_swing", 0.1, 1.0)
		
	_cooldown_timer = attack_cooldown

func _process_attack(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer -= delta
	if _state_timer <= 0.0:
		current_ai_state = AIState.CHASE

func _process_stagger(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		current_ai_state = AIState.CHASE

func _teleport_away() -> void:
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1, 0), Color(0.6, 0.2, 0.9))
	var offset = Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
	global_position += offset
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1, 0), Color(0.6, 0.2, 0.9))

func take_damage(amount: float, knockback: Vector3, is_crit: bool, source: Node3D) -> void:
	var final_dmg = amount
	
	# Warrior Frontal Shield Block
	if enemy_type == EnemyType.WARRIOR and source:
		var forward = -transform.basis.z
		var to_source = (source.global_position - global_position).normalized()
		if forward.dot(to_source) > 0.35: # Facing attacker
			final_dmg *= 0.25 # Block 75% damage!
			CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.8, 0) + forward * 0.4, Color(0.9, 0.8, 0.3))
			AudioManager.play_sfx("sword_swing", 0.05, 1.8)
			CombatJuice.add_trauma(0.08)
			
	super.take_damage(final_dmg, knockback, is_crit, source)
	
	if not is_dead and not is_attacking and anim_player:
		play_anim("Hit_A", 0.05, 1.5)

	if current_ai_state == AIState.TELEGRAPH and is_crit:
		# Heavy crit staggers and interrupts telegraph!
		current_ai_state = AIState.STAGGER
		_state_timer = 0.45
		if telegraph_indicator:
			telegraph_indicator.visible = false

func die() -> void:
	if is_dead:
		return
	is_dead = true
	character_died.emit()
	
	# Reward player
	if target_player and target_player.has_method("on_enemy_slain"):
		target_player.on_enemy_slain(self)
		
	var bonus_mult = 1.6 if GameManager.has_boon("soul_siphon") else 1.0
	var gold_drop = int(randi_range(3, 8) * bonus_mult)
	var echo_drop = int(randi_range(2, 5) * bonus_mult)
	GameManager.add_gold(gold_drop)
	GameManager.add_echoes(echo_drop)
	
	if enemy_type in [EnemyType.ORC, EnemyType.DEMON, EnemyType.CREEP, EnemyType.PIRATE, EnemyType.BANDIT]:
		CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1.0, 0), Color(0.9, 0.2, 0.1))
		AudioManager.play_sfx("boss_roar" if enemy_type in [EnemyType.ORC, EnemyType.DEMON] else "hit_flesh", 0.08, 0.5)
	else:
		CombatJuice.spawn_bone_burst(global_position)
		AudioManager.play_sfx("skeleton_bones", 0.1, 2.0)
		
	if anim_player:
		var death_anim = "Death_C_Skeletons" if anim_player.has_animation("Death_C_Skeletons") else "Death_A"
		play_anim(death_anim, 0.08, 1.3)
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)
		get_tree().create_timer(1.2).timeout.connect(queue_free)
	else:
		queue_free()
