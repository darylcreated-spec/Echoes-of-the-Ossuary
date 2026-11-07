extends CharacterBody3D
class_name BattlegroundTroopAI

enum Faction { ROYAL, CRIMSON }
enum Role { KNIGHT, BERSERKER, ARCHER, CAVALRY, COMMANDER }
enum State { FORMATION, MARCH, CHARGE, ENGAGED, SHIELD_WALL, RALLY, RETREAT, DEAD }

signal unit_died(unit: BattlegroundTroopAI)
signal unit_attacked(unit: BattlegroundTroopAI, target: Node3D)

@export var faction: Faction = Faction.ROYAL
@export var role: Role = Role.KNIGHT
@export var unit_name: String = "Royal Vanguard"
@export var max_health: float = 120.0
@export var attack_damage: float = 24.0
@export var move_speed: float = 4.2
@export var attack_range: float = 2.4
@export var attack_cooldown: float = 1.3
@export var custom_royal_group: String = "royal_army"
@export var custom_crimson_group: String = "crimson_army"

var current_health: float = 120.0
var current_state: State = State.FORMATION
var is_shield_wall: bool = false
var formation_offset: Vector3 = Vector3.ZERO
var home_formation_pos: Vector3 = Vector3.ZERO

var target_enemy: Node3D = null
var commander_or_hero: Node3D = null

var _cooldown_timer: float = 0.0
var _anim_player: AnimationPlayer = null
var _mount_anim_player: AnimationPlayer = null
var _mount_model: Node3D = null
var _visual_model: Node3D = null
var _health_bar_mesh: MeshInstance3D = null
var _health_fill_mesh: MeshInstance3D = null
var _overhead_label: Label3D = null
var _attack_windup: float = 0.0
var _is_attacking: bool = false
var _death_timer: float = 0.0
var _scan_timer: float = 0.0

const GRAVITY: float = 9.8

func _ready() -> void:
	add_to_group("battleground_troop")
	if faction == Faction.ROYAL:
		add_to_group(custom_royal_group)
	else:
		add_to_group(custom_crimson_group)

	_apply_role_stats()
	current_health = max_health
	_build_collision()
	_build_visuals()
	_build_overhead_ui()

	_play_anim("Idle")
	_scan_timer = randf_range(0.1, 0.4)

func _apply_role_stats() -> void:
	match role:
		Role.KNIGHT:
			max_health = 135.0
			attack_damage = 22.0
			attack_range = 2.4
			move_speed = 3.8
			attack_cooldown = 1.3
		Role.BERSERKER:
			max_health = 165.0
			attack_damage = 36.0
			attack_range = 2.6
			move_speed = 4.5
			attack_cooldown = 1.6
		Role.ARCHER:
			max_health = 90.0
			attack_damage = 26.0
			attack_range = 24.0
			move_speed = 4.0
			attack_cooldown = 1.75
		Role.CAVALRY:
			max_health = 215.0
			attack_damage = 40.0
			attack_range = 3.2
			move_speed = 7.2
			attack_cooldown = 1.35
		Role.COMMANDER:
			max_health = 340.0
			attack_damage = 48.0
			attack_range = 3.2
			move_speed = 4.0
			attack_cooldown = 1.5

func _build_collision() -> void:
	collision_layer = 1 << 2 # Enemy/Combatant layer
	collision_mask = 1 # Collide with terrain & obstacles

	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.85
	col.shape = cap
	col.position.y = 0.92
	add_child(col)

func _build_visuals() -> void:
	var model_path = "res://assets/characters/adventurers/Knight.glb"
	var model_scale = Vector3.ONE * 0.88

	match role:
		Role.KNIGHT, Role.CAVALRY:
			model_path = "res://assets/characters/adventurers/Knight.glb"
		Role.BERSERKER:
			model_path = "res://assets/characters/adventurers/Barbarian.glb"
		Role.ARCHER:
			model_path = "res://assets/characters/adventurers/Rogue_Hooded.glb"
		Role.COMMANDER:
			model_path = "res://assets/characters/adventurers/Knight.glb"
			model_scale = Vector3.ONE * 1.15

	var char_name = "Knight"
	if role == Role.BERSERKER: char_name = "Barbarian"
	elif role == Role.ARCHER: char_name = "Rogue"

	if role == Role.CAVALRY:
		var horse_path = "res://assets/characters/animals/Horse_White.glb" if faction == Faction.ROYAL else "res://assets/characters/animals/Horse.glb"
		_mount_model = AssetLoader.load_or_generate_model(horse_path, "animal", "Horse")
		_mount_model.name = "WarhorseMount"
		_mount_model.scale = Vector3.ONE * 0.42
		add_child(_mount_model)
		_mount_anim_player = _mount_model.find_child("AnimationPlayer", true, false) as AnimationPlayer

	_visual_model = AssetLoader.load_or_generate_model(model_path, "character", char_name)
	_visual_model.name = "TroopModel"
	_visual_model.scale = model_scale
	if role == Role.CAVALRY:
		_visual_model.position = Vector3(0.0, 0.72, 0.0)
	add_child(_visual_model)

	_anim_player = _visual_model.find_child("AnimationPlayer", true, false) as AnimationPlayer

	# Attach Weapons & Heraldic Shields
	match role:
		Role.KNIGHT:
			var sword = AssetLoader.load_or_generate_model("res://assets/weapons/sword_1handed.gltf", "weapon", "sword")
			AssetLoader.attach_weapon_socket(_visual_model, sword, "handslot.r")
			var shield_path = "res://assets/weapons/shield_badge.gltf" if faction == Faction.ROYAL else "res://assets/weapons/shield_spikes.gltf"
			var shield = AssetLoader.load_or_generate_model(shield_path, "weapon", "shield")
			AssetLoader.attach_weapon_socket(_visual_model, shield, "handslot.l")
		Role.CAVALRY:
			var lance = AssetLoader.load_or_generate_model("res://assets/weapons/sword_2handed.gltf", "weapon", "greatsword")
			lance.scale = Vector3(1.1, 1.45, 1.1)
			AssetLoader.attach_weapon_socket(_visual_model, lance, "handslot.r")
			var c_shield_path = "res://assets/weapons/shield_badge.gltf" if faction == Faction.ROYAL else "res://assets/weapons/shield_spikes.gltf"
			var c_shield = AssetLoader.load_or_generate_model(c_shield_path, "weapon", "shield")
			AssetLoader.attach_weapon_socket(_visual_model, c_shield, "handslot.l")
		Role.BERSERKER:
			var axe = AssetLoader.load_or_generate_model("res://assets/weapons/axe_2handed.gltf", "weapon", "axe")
			AssetLoader.attach_weapon_socket(_visual_model, axe, "handslot.r")
		Role.ARCHER:
			var bow = AssetLoader.load_or_generate_model("res://assets/weapons/crossbow_2handed.gltf", "weapon", "crossbow")
			AssetLoader.attach_weapon_socket(_visual_model, bow, "handslot.r")
		Role.COMMANDER:
			var gsword = AssetLoader.load_or_generate_model("res://assets/weapons/sword_2handed.gltf", "weapon", "greatsword")
			gsword.scale = Vector3.ONE * 1.3
			AssetLoader.attach_weapon_socket(_visual_model, gsword, "handslot.r")
			# Commander carries the tall Heraldic Faction Standard
			var flag_path = "res://assets/overworld/flag_blue.gltf" if faction == Faction.ROYAL else "res://assets/overworld/flag_red.gltf"
			var banner = AssetLoader.load_or_generate_model(flag_path, "dungeon", "flag")
			banner.scale = Vector3.ONE * 1.5
			banner.position = Vector3(-0.35, 0.0, 0.28)
			_visual_model.add_child(banner)

	# Faction Material Polish
	if faction == Faction.CRIMSON:
		_apply_crimson_tint(_visual_model)

func _apply_crimson_tint(node: Node) -> void:
	if node is MeshInstance3D:
		var mat = node.get_active_material(0)
		if mat is StandardMaterial3D:
			var dup_mat = mat.duplicate() as StandardMaterial3D
			# Blend darker iron armor with crimson red highlight
			dup_mat.albedo_color = dup_mat.albedo_color.lerp(Color(0.85, 0.15, 0.15), 0.35)
			node.material_override = dup_mat
	for child in node.get_children():
		_apply_crimson_tint(child)

func _build_overhead_ui() -> void:
	var ui_root = Node3D.new()
	ui_root.name = "OverheadUI"
	ui_root.position = Vector3(0.0, 2.3 if role != Role.COMMANDER else 2.7, 0.0)
	add_child(ui_root)

	# Unit Title Label
	_overhead_label = Label3D.new()
	_overhead_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_overhead_label.no_depth_test = false
	_overhead_label.pixel_size = 0.0055
	_overhead_label.visibility_range_end = 22.0
	var f_color = Color(0.70, 0.88, 1.0) if faction == Faction.ROYAL else Color(1.0, 0.65, 0.65)
	_overhead_label.modulate = f_color
	_overhead_label.text = unit_name
	_overhead_label.position.y = 0.25
	ui_root.add_child(_overhead_label)

	# 3D Background Bar
	var bg_mesh = MeshInstance3D.new()
	var bg_box = BoxMesh.new()
	bg_box.size = Vector3(1.1, 0.10, 0.05)
	bg_mesh.mesh = bg_box
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.12, 0.12, 0.14, 0.85)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mesh.material_override = bg_mat
	ui_root.add_child(bg_mesh)
	_health_bar_mesh = bg_mesh

	# 3D Health Fill Bar
	var fill_mesh = MeshInstance3D.new()
	var fill_box = BoxMesh.new()
	fill_box.size = Vector3(1.06, 0.08, 0.06)
	fill_mesh.mesh = fill_box
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.8, 0.3) if faction == Faction.ROYAL else Color(0.9, 0.2, 0.2)
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mesh.material_override = fill_mat
	fill_mesh.position.z = 0.01
	ui_root.add_child(fill_mesh)
	_health_fill_mesh = fill_mesh

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		_process_death(delta)
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	_cooldown_timer = max(0.0, _cooldown_timer - delta)
	_scan_timer -= delta

	if _scan_timer <= 0.0:
		_scan_timer = randf_range(0.4, 0.8)
		_find_best_target()

	match current_state:
		State.FORMATION:
			_process_formation(delta)
		State.MARCH:
			_process_march(delta)
		State.CHARGE:
			_process_charge(delta)
		State.ENGAGED:
			_process_engaged(delta)
		State.SHIELD_WALL:
			_process_shield_wall(delta)
		State.RALLY:
			_process_rally(delta)

	move_and_slide()
	_update_overhead_ui()

func _find_best_target() -> void:
	# If engaged or in combat, target nearest opposite faction troop or Hero
	var opp_group = custom_crimson_group if faction == Faction.ROYAL else custom_royal_group
	var candidates = get_tree().get_nodes_in_group(opp_group)

	# Crimson also targets Hero player directly if nearby
	if faction == Faction.CRIMSON:
		var players = get_tree().get_nodes_in_group("player")
		for p in players:
			if is_instance_valid(p) and p is Node3D and global_position.distance_to(p.global_position) < 35.0:
				candidates.append(p)

	var nearest: Node3D = null
	var nearest_dist = 999.0
	for cand in candidates:
		if is_instance_valid(cand) and cand != self:
			if cand is BattlegroundTroopAI and cand.current_state == State.DEAD:
				continue
			var d = global_position.distance_to(cand.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = cand

	if nearest and nearest_dist < (attack_range * 1.6 if role == Role.ARCHER else 32.0):
		target_enemy = nearest
		if current_state in [State.MARCH, State.CHARGE] and nearest_dist <= attack_range:
			current_state = State.ENGAGED

func _process_formation(delta: float) -> void:
	# Stay anchored near formation position
	var desired = home_formation_pos + formation_offset
	var diff = desired - global_position
	diff.y = 0.0
	if diff.length() > 0.6:
		var dir = diff.normalized()
		velocity.x = dir.x * move_speed * 0.7
		velocity.z = dir.z * move_speed * 0.7
		_face_direction(dir, delta)
		_play_anim("Walking_A")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_play_anim("Idle")

func _process_march(delta: float) -> void:
	# Advance toward enemy front line
	var march_dir = Vector3(0.0, 0.0, 1.0) if faction == Faction.ROYAL else Vector3(0.0, 0.0, -1.0)
	if is_instance_valid(target_enemy):
		var diff = target_enemy.global_position - global_position
		diff.y = 0.0
		if diff.length() <= attack_range:
			current_state = State.ENGAGED
			return
		march_dir = diff.normalized()

	velocity.x = march_dir.x * move_speed
	velocity.z = march_dir.z * move_speed
	_face_direction(march_dir, delta)
	_play_anim("Walking_A")

func _process_charge(delta: float) -> void:
	# Aggressive full sprint toward enemy
	var charge_speed = move_speed * 1.35
	var charge_dir = Vector3(0.0, 0.0, 1.0) if faction == Faction.ROYAL else Vector3(0.0, 0.0, -1.0)

	if is_instance_valid(target_enemy):
		var diff = target_enemy.global_position - global_position
		diff.y = 0.0
		var dist = diff.length()
		if dist <= attack_range:
			current_state = State.ENGAGED
			return
		charge_dir = diff.normalized()

	velocity.x = charge_dir.x * charge_speed
	velocity.z = charge_dir.z * charge_speed
	_face_direction(charge_dir, delta)
	_play_anim("Running_A")

func _process_engaged(delta: float) -> void:
	if not is_instance_valid(target_enemy) or (target_enemy is BattlegroundTroopAI and target_enemy.current_state == State.DEAD):
		target_enemy = null
		current_state = State.CHARGE
		return

	var diff = target_enemy.global_position - global_position
	diff.y = 0.0
	var dist = diff.length()

	_face_direction(diff.normalized(), delta)

	if dist > attack_range:
		# Close the distance
		var dir = diff.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		_play_anim("Running_A")
	else:
		# In range, execute melee / ranged strike
		velocity.x = 0.0
		velocity.z = 0.0
		if _cooldown_timer <= 0.0:
			_execute_attack()

func _process_shield_wall(delta: float) -> void:
	# Stationary defensive phalanx, shields raised
	velocity.x = 0.0
	velocity.z = 0.0
	is_shield_wall = true

	if is_instance_valid(target_enemy):
		var diff = target_enemy.global_position - global_position
		diff.y = 0.0
		_face_direction(diff.normalized(), delta)
		if diff.length() <= attack_range and _cooldown_timer <= 0.0:
			_execute_attack()
	else:
		_play_anim("Idle")

func _process_rally(delta: float) -> void:
	# Regroup around Hero or Commander
	var rally_target: Node3D = commander_or_hero
	if not is_instance_valid(rally_target):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			rally_target = players[0]

	if is_instance_valid(rally_target):
		var dest = rally_target.global_position + formation_offset
		var diff = dest - global_position
		diff.y = 0.0
		if diff.length() > 2.0:
			var dir = diff.normalized()
			velocity.x = dir.x * move_speed * 1.2
			velocity.z = dir.z * move_speed * 1.2
			_face_direction(dir, delta)
			_play_anim("Running_A")
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			current_state = State.FORMATION
			_play_anim("Idle")
	else:
		current_state = State.FORMATION

func _execute_attack() -> void:
	_cooldown_timer = attack_cooldown
	unit_attacked.emit(self, target_enemy)

	if role == Role.ARCHER:
		_play_anim("Shoot_Crossbow")
		AudioManager.play_sfx_at_position("crossbow_shoot", global_position, 28.0, 0.08, -2.0)
		_spawn_arrow_projectile()
	elif role == Role.BERSERKER:
		_play_anim("2H_Melee_Attack_Chop")
		AudioManager.play_sfx_at_position("sword_hit", global_position, 26.0, 0.08, 0.0)
		_deal_damage_to_target(attack_damage)
	elif role == Role.CAVALRY:
		_play_anim("2H_Melee_Attack_Chop")
		AudioManager.play_sfx_at_position("sword_hit", global_position, 28.0, 0.08, 1.0)
		_deal_damage_to_target(attack_damage)
	elif role == Role.COMMANDER:
		_play_anim("2H_Melee_Attack_Chop")
		AudioManager.play_sfx_at_position("sword_hit", global_position, 30.0, 0.08, 2.0)
		_deal_damage_to_target(attack_damage)
	else: # KNIGHT
		_play_anim("1H_Melee_Attack_Chop")
		AudioManager.play_sfx_at_position("sword_hit", global_position, 24.0, 0.08, -1.0)
		_deal_damage_to_target(attack_damage)

func _deal_damage_to_target(dmg: float) -> void:
	if not is_instance_valid(target_enemy):
		return

	# Add small damage variance
	var actual_dmg = dmg * randf_range(0.85, 1.15)
	if target_enemy.has_method("take_damage"):
		if target_enemy.is_in_group("player"):
			var kb = (target_enemy.global_position - global_position).normalized() * 2.5
			target_enemy.take_damage(actual_dmg, kb, false, self)
		else:
			target_enemy.take_damage(actual_dmg, self)

func _spawn_arrow_projectile() -> void:
	if not is_inside_tree() or not is_instance_valid(target_enemy) or not get_parent():
		return

	var arrow_inst = MeshInstance3D.new()
	var a_mesh = CylinderMesh.new()
	a_mesh.top_radius = 0.03
	a_mesh.bottom_radius = 0.03
	a_mesh.height = 0.78
	arrow_inst.mesh = a_mesh
	var a_mat = StandardMaterial3D.new()
	a_mat.albedo_color = Color(0.85, 0.68, 0.38) if faction == Faction.ROYAL else Color(0.95, 0.35, 0.22)
	a_mat.emission_enabled = true
	a_mat.emission = a_mat.albedo_color * 0.45
	arrow_inst.material_override = a_mat
	arrow_inst.top_level = true
	get_parent().add_child(arrow_inst)
	arrow_inst.global_position = global_position + Vector3(0.0, 1.45, 0.0)

	var end_pos = target_enemy.global_position + Vector3(0.0, 1.1, 0.0)
	var arrow_wr = weakref(arrow_inst)
	var target_wr = weakref(target_enemy)
	var self_wr = weakref(self)
	var dmg = attack_damage * randf_range(0.85, 1.15)

	var tween = arrow_inst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(arrow_inst, "global_position:x", end_pos.x, 0.44)
	tween.tween_property(arrow_inst, "global_position:z", end_pos.z, 0.44)
	tween.tween_property(arrow_inst, "global_position:y", max(arrow_inst.global_position.y, end_pos.y) + 2.4, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(arrow_inst, "global_position:y", end_pos.y, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		AudioManager.play_sfx_at_position("arrow_impact", end_pos, 24.0, 0.08, -2.0)
		var t = target_wr.get_ref()
		var s = self_wr.get_ref()
		if t and t.has_method("take_damage"):
			if t.is_in_group("player"):
				t.take_damage(dmg, Vector3.ZERO, false, s)
			else:
				t.take_damage(dmg, s)
		var a = arrow_wr.get_ref()
		if a:
			a.queue_free()
	)

func take_damage(amount: float, arg2 = null, _arg3 = false, arg4: Node3D = null) -> void:
	if current_state == State.DEAD:
		return
	var attacker: Node3D = null
	if arg2 is Node3D:
		attacker = arg2
	elif arg4 is Node3D:
		attacker = arg4

	var effective_damage = amount
	if is_shield_wall:
		effective_damage *= 0.25
		AudioManager.play_sfx_at_position("parry_ring", global_position, 28.0, 0.08, 1.0)
		_spawn_hit_spark(Color(0.9, 0.9, 0.3))
	else:
		_spawn_hit_spark(Color(0.9, 0.2, 0.2))

	current_health -= effective_damage

	# Retaliate if not busy
	if attacker and is_instance_valid(attacker) and current_state != State.SHIELD_WALL:
		target_enemy = attacker
		current_state = State.ENGAGED

	if current_health <= 0.0:
		die()

func _spawn_hit_spark(spark_color: Color) -> void:
	var spark = OmniLight3D.new()
	spark.light_color = spark_color
	spark.light_energy = 3.0
	spark.omni_range = 3.5
	spark.position.y = 1.2
	add_child(spark)
	var tw = spark.create_tween()
	tw.tween_property(spark, "light_energy", 0.0, 0.18)
	tw.tween_callback(spark.queue_free)

func die() -> void:
	current_state = State.DEAD
	current_health = 0.0
	velocity = Vector3.ZERO
	is_shield_wall = false
	_play_anim("Death_A")
	AudioManager.play_sfx_at_position("sword_hit", global_position, 28.0, 0.12, 1.0)

	# Disable collision so other troops pass through smoothly
	collision_layer = 0
	collision_mask = 0

	unit_died.emit(self)

func _process_death(delta: float) -> void:
	_death_timer += delta
	if _death_timer > 3.0:
		# Fade out into the ground
		global_position.y -= delta * 0.4
	if _death_timer > 5.0:
		queue_free()

func _update_overhead_ui() -> void:
	if not _health_fill_mesh:
		return
	var ratio = clamp(current_health / max(max_health, 1.0), 0.0, 1.0)
	_health_fill_mesh.scale.x = ratio
	_health_fill_mesh.position.x = -(1.0 - ratio) * 0.53

	if _overhead_label:
		var status_str = ""
		match current_state:
			State.CHARGE: status_str = " [CHARGE]"
			State.SHIELD_WALL: status_str = " [SHIELD WALL]"
			State.RALLY: status_str = " [RALLY]"
			State.ENGAGED: status_str = " [CLASH]"
			State.DEAD: status_str = " [FALLEN]"
		_overhead_label.text = "%s (%d/%d)%s" % [unit_name, int(current_health), int(max_health), status_str]

func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)

func _play_anim(desired: String) -> void:
	if _mount_anim_player and role == Role.CAVALRY:
		var m_anim = "AnimalArmature|Idle"
		if desired in ["Walking_A", "Running_A"]:
			m_anim = "AnimalArmature|Gallop"
		elif desired == "Death_A":
			m_anim = "AnimalArmature|Death"
		if _mount_anim_player.has_animation(m_anim):
			if not _mount_anim_player.is_playing() or _mount_anim_player.current_animation != m_anim:
				_mount_anim_player.play(m_anim, 0.15)

	if not _anim_player:
		return
	var chosen = desired
	if not _anim_player.has_animation(desired):
		# Fallbacks
		if desired == "Running_A": chosen = "Walking_A"
		elif desired == "Shoot_Crossbow": chosen = "1H_Melee_Attack_Chop"
		elif desired == "2H_Melee_Attack_Chop": chosen = "1H_Melee_Attack_Chop"

	if _anim_player.has_animation(chosen):
		if not _anim_player.is_playing() or _anim_player.current_animation != chosen:
			_anim_player.play(chosen, 0.15)

# =========================================================================
# PLAYER TACTICAL COMMAND INTERFACE
# =========================================================================
func command_charge() -> void:
	if current_state == State.DEAD: return
	is_shield_wall = false
	current_state = State.CHARGE
	_find_best_target()

func command_shield_wall() -> void:
	if current_state == State.DEAD: return
	current_state = State.SHIELD_WALL
	is_shield_wall = true

func command_rally(hero_node: Node3D) -> void:
	if current_state == State.DEAD: return
	is_shield_wall = false
	commander_or_hero = hero_node
	current_state = State.RALLY

func command_volley(target_center: Vector3) -> void:
	if current_state == State.DEAD: return
	if role == Role.ARCHER:
		var diff = target_center - global_position
		diff.y = 0.0
		_face_direction(diff.normalized(), 1.0)
		_cooldown_timer = 0.0
		_execute_attack()
