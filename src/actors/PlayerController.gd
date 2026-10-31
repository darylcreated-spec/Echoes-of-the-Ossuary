extends "res://src/actors/BaseCharacter3D.gd"
class_name PlayerController

const Projectile3DScript = preload("res://src/combat/Projectile3D.gd")
const Hitbox3DScript = preload("res://src/combat/Hitbox3D.gd")

# --- PLAYER PROPERTIES ---
var attack_cooldown: float = 0.4
var attack_range: float = 2.2
var dash_cooldown: float = 1.0
var dash_speed: float = 18.0
var dash_duration: float = 0.22
var is_ranged: bool = false
var crit_chance: float = 0.1

# --- MOUNT SYSTEM (PILLAR 1) ---
var is_mounted: bool = false
var mount_node: Node3D = null
var mount_anim: AnimationPlayer = null
var mount_breed: String = "Horse" # "Horse", "Horse_White", "Stag"
var mount_speed: float = 12.8
var _hoofbeat_timer: float = 0.0
var _trample_cooldown: float = 0.0
var _mount_cooldown: float = 0.0

# --- WEAPON STANCE & SHIELD PARRY (PILLAR 2) ---
enum WeaponStance { MELEE, RANGED }
var current_stance: WeaponStance = WeaponStance.MELEE
var is_blocking: bool = false
var parry_window_timer: float = 0.0
const PARRY_WINDOW: float = 0.22
var has_riposte_crit: bool = false
var primary_weapon_node: Node3D = null
var shield_node: Node3D = null
var crossbow_node: Node3D = null

# Timers & States
var _can_attack: bool = true
var _attack_timer: Timer = null
var _is_dashing: bool = false
var _dash_timer: Timer = null
var _dash_cd_timer: Timer = null
var _dash_direction: Vector3 = Vector3.FORWARD

# 3-Hit Melee Combo System
var combo_step: int = 0
var combo_reset_time: float = 0.85
var _combo_reset_timer: float = 0.0
var _regen_timer: float = 0.0

# Interaction
var current_interactable: Node = null
var is_input_locked: bool = false

# Nodes
@onready var hitbox = $Hitbox3D if has_node("Hitbox3D") else null
@onready var interaction_area: Area3D = $InteractionArea if has_node("InteractionArea") else null
var weapon_mount: Node3D = null

func _ready() -> void:
	super._ready()
	_setup_timers()
	_setup_player_stats()
	_setup_model_and_weapon()
	_setup_interaction()
	
	GameManager.player_stats_changed.connect(_setup_player_stats)
	GameManager.hero_class_changed.connect(_on_hero_class_changed)

func _setup_timers() -> void:
	_attack_timer = Timer.new()
	_attack_timer.one_shot = true
	_attack_timer.timeout.connect(func(): _can_attack = true)
	add_child(_attack_timer)
	
	_dash_timer = Timer.new()
	_dash_timer.one_shot = true
	_dash_timer.timeout.connect(_end_dash)
	add_child(_dash_timer)
	
	_dash_cd_timer = Timer.new()
	_dash_cd_timer.one_shot = true
	add_child(_dash_cd_timer)

func _setup_player_stats() -> void:
	var stats = GameManager.get_base_hero_stats(GameManager.selected_class)
	max_health = stats["max_hp"]
	current_health = min(current_health, max_health)
	if current_health <= 0:
		current_health = max_health
	move_speed = stats["move_speed"]
	attack_damage = stats["attack_damage"]
	attack_cooldown = stats["attack_cooldown"]
	attack_range = stats["attack_range"]
	dash_cooldown = stats["dash_cooldown"]
	dash_speed = stats["dash_speed"]
	dash_duration = stats["dash_duration"]
	is_ranged = stats["is_ranged"]
	crit_chance = stats["crit_chance"]
	defense = stats["defense"]
	health_changed.emit(current_health, max_health)

func _on_hero_class_changed(_new_class: int) -> void:
	_setup_player_stats()
	_setup_model_and_weapon()

func _setup_model_and_weapon() -> void:
	if visual_model_root and is_instance_valid(visual_model_root):
		visual_model_root.queue_free()
		
	var class_name_str = "Knight"
	var weapon_name_str = "sword_1handed"
	
	match GameManager.selected_class:
		GameManager.HeroClass.KNIGHT:
			class_name_str = "Knight"
			weapon_name_str = "sword_1handed"
		GameManager.HeroClass.ROGUE:
			class_name_str = "Rogue"
			weapon_name_str = "dagger"
		GameManager.HeroClass.MAGE:
			class_name_str = "Mage"
			weapon_name_str = "staff"
		GameManager.HeroClass.BARBARIAN:
			class_name_str = "Barbarian"
			weapon_name_str = "axe_2handed"
			
	var asset_path = "res://assets/characters/adventurers/" + class_name_str + ".glb"
	visual_model_root = AssetLoader.load_or_generate_model(asset_path, "character", class_name_str)
	visual_model_root.name = "Model"
	# Proportionate scale: 3.44m base height scaled by 0.55 = 1.89m height (matches 1.8m capsule)
	visual_model_root.scale = Vector3(0.55, 0.55, 0.55)
	add_child(visual_model_root)
	invalidate_model_cache()
	_cache_model_nodes()
	
	# Primary Weapon Attachment
	var weapon_path = "res://assets/weapons/" + weapon_name_str + ".glb"
	primary_weapon_node = AssetLoader.load_or_generate_model(weapon_path, "weapon", weapon_name_str)
	primary_weapon_node.name = "EquippedPrimary"
	AssetLoader.attach_weapon_socket(visual_model_root, primary_weapon_node, "handslot.r")

	# Shield Attachment (Knight gets classic shield_square, other classes get shield_badge_color)
	var shield_file = "res://assets/weapons/shield_square.glb" if GameManager.selected_class == GameManager.HeroClass.KNIGHT else "res://assets/weapons/shield_badge_color.gltf"
	shield_node = AssetLoader.load_or_generate_model(shield_file, "weapon", "shield")
	shield_node.name = "EquippedShield"
	AssetLoader.attach_weapon_socket(visual_model_root, shield_node, "handslot.l")

	# Secondary Crossbow Attachment
	var xbow_file = "res://assets/weapons/crossbow_1handed.gltf"
	crossbow_node = AssetLoader.load_or_generate_model(xbow_file, "weapon", "crossbow_1handed")
	crossbow_node.name = "EquippedCrossbow"
	AssetLoader.attach_weapon_socket(visual_model_root, crossbow_node, "handslot.r")

	_update_weapon_visibility()

func _update_weapon_visibility() -> void:
	if current_stance == WeaponStance.MELEE:
		if primary_weapon_node and is_instance_valid(primary_weapon_node):
			primary_weapon_node.visible = true
		if shield_node and is_instance_valid(shield_node):
			shield_node.visible = true
		if crossbow_node and is_instance_valid(crossbow_node):
			crossbow_node.visible = false
		is_ranged = (GameManager.selected_class == GameManager.HeroClass.MAGE)
	else:
		if primary_weapon_node and is_instance_valid(primary_weapon_node):
			primary_weapon_node.visible = false
		if shield_node and is_instance_valid(shield_node):
			shield_node.visible = false
		if crossbow_node and is_instance_valid(crossbow_node):
			crossbow_node.visible = true
		is_ranged = true

func toggle_weapon_stance() -> void:
	if current_stance == WeaponStance.MELEE:
		current_stance = WeaponStance.RANGED
		is_blocking = false
		_update_weapon_visibility()
		AudioManager.play_sfx("weapon_swap", 0.08, -1.0)
		_show_hud_toast("🏹 Stance: Crossbow (Ranged Piercing)")
	else:
		current_stance = WeaponStance.MELEE
		_update_weapon_visibility()
		AudioManager.play_sfx("weapon_swap", 0.08, -1.0)
		_show_hud_toast("⚔️ Stance: Primary Blade & Shield (Melee / Parry)")

func _setup_interaction() -> void:
	if not interaction_area:
		interaction_area = Area3D.new()
		interaction_area.name = "InteractionArea"
		interaction_area.collision_layer = 0
		interaction_area.collision_mask = 1 << 5 # Layer 6: Interactables
		var shape = SphereShape3D.new()
		shape.radius = 2.4
		var col = CollisionShape3D.new()
		col.shape = shape
		interaction_area.add_child(col)
		add_child(interaction_area)
		
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)

func _on_interaction_area_entered(area: Area3D) -> void:
	if area.has_method("interact"):
		current_interactable = area
	elif area.get_parent() and area.get_parent().has_method("interact"):
		current_interactable = area.get_parent()
	else:
		current_interactable = area
		
	# If it's a descent sigil, descent is instant upon stepping on it, so don't show [E] prompt
	if current_interactable.is_in_group("descent_sigil") or area.is_in_group("descent_sigil") or area.name == "DescentSigil":
		return
		
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and "interact_prompt" in hud and hud.interact_prompt:
		if current_interactable.has_method("get_prompt_text"):
			hud.interact_prompt.text = current_interactable.get_prompt_text()
		else:
			hud.interact_prompt.text = "[E] Interact"
		hud.interact_prompt.visible = true

func _on_interaction_area_exited(area: Area3D) -> void:
	if current_interactable == area or (area.get_parent() and current_interactable == area.get_parent()):
		current_interactable = null
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and "interact_prompt" in hud and hud.interact_prompt:
			hud.interact_prompt.text = "[E] Interact"
			hud.interact_prompt.visible = false

# --- INPUT & PHYSICS ---
func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_knockback(delta)
	
	if parry_window_timer > 0.0:
		parry_window_timer -= delta
	if _mount_cooldown > 0.0:
		_mount_cooldown -= delta
	
	if _combo_reset_timer > 0.0:
		_combo_reset_timer -= delta
		if _combo_reset_timer <= 0.0:
			combo_step = 0
	
	if is_dead:
		move_and_slide()
		return

	if is_input_locked:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		move_and_slide()
		update_movement_animation(delta)
		return
		
	_handle_movement(delta)
	_handle_aiming()
	_handle_actions()
	
	move_and_slide()
	update_movement_animation(delta)
	
	# Clamp vertical position: prevent falling through recessed basins while allowing natural height variation
	if global_position.y < -0.6:
		global_position.y = -0.6
		velocity.y = 0.0

	# Mounted hoofbeats & trample impact
	if is_mounted:
		var horiz_vel = Vector2(velocity.x, velocity.z).length()
		if horiz_vel > 0.5:
			_hoofbeat_timer += delta
			if _hoofbeat_timer >= 0.28:
				_hoofbeat_timer = 0.0
				AudioManager.play_sfx("hoofbeat", 0.08, -5.0)
		_process_trample(delta)

	# Living Heartwood / Tri-Seal Passive Regeneration
	if GameManager.has_boon("living_heartwood") or GameManager.has_boon("tri_seal_mastery"):
		_regen_timer += delta
		if _regen_timer >= 1.0:
			_regen_timer = 0.0
			if current_health < max_health:
				heal(2.0 if not GameManager.has_boon("tri_seal_mastery") else 4.0)

func _handle_movement(_delta: float) -> void:
	if _is_dashing:
		velocity.x = _dash_direction.x * dash_speed
		velocity.z = _dash_direction.z * dash_speed
		return

	var current_move_speed = mount_speed if is_mounted else (move_speed * 0.55 if is_blocking else move_speed)

	var raw_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var cam = get_viewport().get_camera_3d()
	
	if raw_input != Vector2.ZERO and cam:
		# Isometric camera relative movement
		var cam_forward = -cam.global_transform.basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()
		
		var cam_right = cam.global_transform.basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()
		
		var move_dir = (cam_right * raw_input.x + cam_forward * -raw_input.y).normalized()
		velocity.x = move_dir.x * current_move_speed
		velocity.z = move_dir.z * current_move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_move_speed * 0.2)
		velocity.z = move_toward(velocity.z, 0.0, current_move_speed * 0.2)

func _handle_aiming() -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = cam.project_ray_origin(mouse_pos)
	var ray_dir = cam.project_ray_normal(mouse_pos)
	
	# Raycast against ground plane at player's y
	var ground_plane = Plane(Vector3.UP, global_position.y)
	var intersect = ground_plane.intersects_ray(ray_origin, ray_dir)
	
	if intersect:
		var look_target = intersect
		look_target.y = global_position.y
		var dir_to_mouse = (look_target - global_position).normalized()
		if dir_to_mouse.length_squared() > 0.001:
			var target_rot_y = atan2(dir_to_mouse.x, dir_to_mouse.z)
			rotation.y = lerp_angle(rotation.y, target_rot_y, 0.28)

func _handle_actions() -> void:
	# Weapon Swap [Q]
	if Input.is_action_just_pressed("swap_weapon") or Input.is_action_just_pressed("ability"):
		toggle_weapon_stance()

	# Mount / Dismount [F]
	if Input.is_action_just_pressed("mount_toggle"):
		toggle_mount()

	# Shield Block & Parry (Hold RMB / C)
	if Input.is_action_pressed("block") and not is_mounted and current_stance == WeaponStance.MELEE:
		if not is_blocking:
			is_blocking = true
			parry_window_timer = PARRY_WINDOW
			if anim_player:
				play_anim("Blocking", 0.06, 1.2)
	elif is_blocking and not Input.is_action_pressed("block"):
		is_blocking = false
		if anim_player:
			play_anim("Idle", 0.1, 1.0)

	# Attack (Primary)
	if (Input.is_action_pressed("attack_primary") or Input.is_action_pressed("attack")) and _can_attack and not _is_dashing:
		_execute_attack()
		
	# Special / Dash (or Leap while mounted)
	if Input.is_action_just_pressed("dash"):
		if is_mounted:
			_mounted_leap()
		elif _dash_cd_timer.is_stopped() and not _is_dashing:
			_start_dash()
		
	# Interact
	if Input.is_action_just_pressed("interact") and current_interactable:
		if anim_player:
			play_anim("Interact", 0.08, 1.6)
		if current_interactable.has_method("interact"):
			current_interactable.interact(self)
		elif current_interactable.has_meta("action"):
			var act = current_interactable.get_meta("action")
			if act == "return_to_sanctuary":
				GameManager.return_to_sanctuary()
				var main = get_tree().get_first_node_in_group("main")
				if main and main.has_method("load_current_floor_room"):
					main.load_current_floor_room()

# --- COMBAT ACTIONS ---
func _execute_attack() -> void:
	_can_attack = false
	_attack_timer.start(attack_cooldown)
	_combo_reset_timer = combo_reset_time
	
	var is_crit = (randf() < crit_chance) or has_riposte_crit
	var forward = -transform.basis.z

	# Ranged Crossbow Stance
	if current_stance == WeaponStance.RANGED:
		var dmg_mult = 2.5 if has_riposte_crit else (1.8 if is_crit else 1.0)
		has_riposte_crit = false
		var final_dmg = attack_damage * 1.5 * dmg_mult
		
		var proj = Projectile3DScript.new()
		proj.damage = final_dmg
		proj.is_crit = is_crit
		proj.is_enemy = false
		proj.source_node = self
		proj.direction = forward
		proj.speed = 24.0
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + Vector3(0, 1.1, 0) + forward * 0.8
		
		# Twin Echoes Boon: extra bolt
		if GameManager.has_boon("twin_echoes"):
			var proj2 = Projectile3DScript.new()
			proj2.damage = final_dmg * 0.7
			proj2.is_crit = is_crit
			proj2.is_enemy = false
			proj2.source_node = self
			proj2.direction = forward.rotated(Vector3.UP, deg_to_rad(12.0))
			proj2.speed = 24.0
			get_tree().current_scene.add_child(proj2)
			proj2.global_position = global_position + Vector3(0, 1.1, 0) + forward * 0.8
			
		AudioManager.play_sfx("crossbow_shoot", 0.08, 0.0)
		CombatJuice.add_trauma(0.08)
		if anim_player:
			is_attacking = true
			play_anim("1H_Ranged_Shoot", 0.04, 2.2)
			get_tree().create_timer(0.22).timeout.connect(func():
				if is_instance_valid(self) and anim_player and not is_dead:
					play_anim("1H_Ranged_Reload", 0.04, 2.0)
					get_tree().create_timer(0.20).timeout.connect(func(): is_attacking = false)
			)
		return
	
	# Mage Arcane Staff Ranged
	if is_ranged and GameManager.selected_class == GameManager.HeroClass.MAGE:
		var dmg_mult = 2.5 if has_riposte_crit else (1.8 if is_crit else 1.0)
		has_riposte_crit = false
		var final_dmg = attack_damage * dmg_mult
		var proj = Projectile3DScript.new()
		proj.damage = final_dmg
		proj.is_crit = is_crit
		proj.is_enemy = false
		proj.source_node = self
		proj.direction = forward
		proj.global_position = global_position + Vector3(0, 1.2, 0) + forward * 0.8
		get_tree().current_scene.add_child(proj)
		
		# Twin Echoes Boon: extra projectile
		if GameManager.has_boon("twin_echoes"):
			var proj2 = Projectile3DScript.new()
			proj2.damage = final_dmg * 0.7
			proj2.is_crit = is_crit
			proj2.is_enemy = false
			proj2.source_node = self
			proj2.direction = forward.rotated(Vector3.UP, deg_to_rad(15.0))
			proj2.global_position = global_position + Vector3(0, 1.2, 0) + forward * 0.8
			get_tree().current_scene.add_child(proj2)
			
		AudioManager.play_sfx("sword_swing", 0.15, -2.0)
		if anim_player:
			is_attacking = true
			play_anim("Spellcast_Shoot", 0.05, 2.2)
			get_tree().create_timer(min(0.32, attack_cooldown)).timeout.connect(func(): is_attacking = false)
	else:
		# 3-Hit Melee Combo: Swing 1 -> Swing 2 -> Spin Cleave (1.5x damage + knockback + lunge)
		var combo_mult = 1.0
		var lunge_force = 3.5
		var kb_mult = 1.0
		
		match combo_step:
			0:
				combo_mult = 1.0
				lunge_force = 3.5
				kb_mult = 1.0
				combo_step = 1
			1:
				combo_mult = 1.15
				lunge_force = 4.2
				kb_mult = 1.2
				combo_step = 2
			2:
				combo_mult = 1.5
				lunge_force = 6.0
				kb_mult = 1.8
				combo_step = 0 # Loop back
				CombatJuice.add_trauma(0.18)
				
		var crit_mult = 2.5 if has_riposte_crit else (1.8 if is_crit else 1.0)
		has_riposte_crit = false
		var final_dmg = attack_damage * combo_mult * crit_mult
		
		# Lunge impulse
		velocity += forward * lunge_force
		
		AudioManager.play_sfx("sword_swing", 0.1, 0.5 if combo_step == 0 else 0.0)
		_animate_melee_combo(combo_step)
		
		if hitbox:
			hitbox.damage = final_dmg
			hitbox.knockback_force = 8.0 * kb_mult
			hitbox.is_crit = is_crit
			hitbox.damage_source = self
			hitbox.monitoring = true
			
			await get_tree().create_timer(0.14).timeout
			if is_instance_valid(hitbox):
				hitbox.monitoring = false
				
		# Twin Echoes Boon for Melee: fire blade shockwave on combo finisher
		if GameManager.has_boon("twin_echoes") and combo_step == 0:
			var wave = Projectile3DScript.new()
			wave.damage = final_dmg * 0.7
			wave.is_crit = is_crit
			wave.is_enemy = false
			wave.source_node = self
			wave.direction = forward
			wave.speed = 15.0
			wave.global_position = global_position + Vector3(0, 0.8, 0) + forward * 0.9
			get_tree().current_scene.add_child(wave)

func _animate_melee_combo(step: int) -> void:
	if not visual_model_root:
		return
	is_attacking = true
	
	# Skeletal rig combat animation
	if anim_player:
		var anim_to_play = "1H_Melee_Attack_Slice_Horizontal"
		var anim_speed = 2.0
		
		if GameManager.selected_class == GameManager.HeroClass.BARBARIAN:
			match step:
				1: anim_to_play = "2H_Melee_Attack_Slice"
				2: anim_to_play = "2H_Melee_Attack_Chop"
				0: 
					anim_to_play = "2H_Melee_Attack_Spin"
					anim_speed = 2.4
		elif GameManager.selected_class == GameManager.HeroClass.MAGE:
			match step:
				1: anim_to_play = "Spellcast_Shoot"
				2: anim_to_play = "Spellcast_Raise"
				0: anim_to_play = "Spellcast_Long"
		elif GameManager.selected_class == GameManager.HeroClass.ROGUE:
			match step:
				1: anim_to_play = "1H_Melee_Attack_Stab"
				2: anim_to_play = "1H_Melee_Attack_Slice_Diagonal"
				0: anim_to_play = "Dualwield_Melee_Attack_Slice"
		else:
			match step:
				1: anim_to_play = "1H_Melee_Attack_Slice_Horizontal"
				2: anim_to_play = "1H_Melee_Attack_Slice_Diagonal"
				0: anim_to_play = "1H_Melee_Attack_Chop"
				
		play_anim(anim_to_play, 0.05, anim_speed)
		var anim_len = 0.32
		if anim_player.has_animation(anim_to_play):
			anim_len = anim_player.get_animation(anim_to_play).length / anim_speed
		get_tree().create_timer(min(anim_len, attack_cooldown * 0.9)).timeout.connect(func():
			is_attacking = false
		)
		return

	# Procedural mesh rotation fallback
	var tween = visual_model_root.create_tween()
	match step:
		1: # Swing 1: Slash Left
			tween.tween_property(visual_model_root, "rotation_degrees:y", 45.0, 0.07).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(visual_model_root, "rotation_degrees:y", -35.0, 0.12).set_trans(Tween.TRANS_BACK)
			tween.tween_property(visual_model_root, "rotation_degrees:y", 0.0, 0.08)
			tween.tween_callback(func(): is_attacking = false)
		2: # Swing 2: Slash Right
			tween.tween_property(visual_model_root, "rotation_degrees:y", -45.0, 0.07).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(visual_model_root, "rotation_degrees:y", 40.0, 0.12).set_trans(Tween.TRANS_BACK)
			tween.tween_property(visual_model_root, "rotation_degrees:y", 0.0, 0.08)
			tween.tween_callback(func(): is_attacking = false)
		0: # Swing 3: 360 Spin Cleave!
			tween.tween_property(visual_model_root, "rotation_degrees:y", 360.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func():
				visual_model_root.rotation_degrees.y = 0.0
				is_attacking = false
			)

func _start_dash() -> void:
	_is_dashing = true
	if anim_player:
		play_anim("Dodge_Forward", 0.05, 2.0)
	var raw_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var cam = get_viewport().get_camera_3d()
	
	if raw_input != Vector2.ZERO and cam:
		var cam_forward = -cam.global_transform.basis.z
		cam_forward.y = 0.0
		var cam_right = cam.global_transform.basis.x
		cam_right.y = 0.0
		_dash_direction = (cam_right.normalized() * raw_input.x + cam_forward.normalized() * -raw_input.y).normalized()
	else:
		_dash_direction = -transform.basis.z
		
	# Invulnerability during dash
	if hurtbox:
		hurtbox.start_invulnerability(dash_duration + 0.05)
		
	AudioManager.play_sfx("dash", 0.08, 0.0)
	CombatJuice.add_trauma(0.08)
	_spawn_dash_ghost()
	
	# Lightning Dash Boon effect
	if GameManager.has_boon("lightning_dash"):
		_trigger_lightning_discharge()
		
	_dash_timer.start(dash_duration)
	_dash_cd_timer.start(dash_cooldown)

func _end_dash() -> void:
	_is_dashing = false

func _spawn_dash_ghost() -> void:
	var ghost = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.45
	cap.height = 1.7
	ghost.mesh = cap
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.85, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.85, 1.0)
	mat.emission_energy_multiplier = 2.0
	ghost.material_override = mat
	
	ghost.global_position = global_position + Vector3(0, 0.85, 0)
	ghost.rotation = rotation
	get_tree().current_scene.add_child(ghost)
	
	var tween = ghost.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.28)
	tween.chain().tween_callback(ghost.queue_free)

func _trigger_lightning_discharge() -> void:
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.5, 0), Color(0.2, 0.8, 1.0))
	var shock_hitbox = Hitbox3DScript.new()
	shock_hitbox.damage = 30.0
	shock_hitbox.damage_source = self
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 3.2
	col.shape = sphere
	shock_hitbox.add_child(col)
	shock_hitbox.global_position = global_position
	shock_hitbox.collision_layer = 1 << 3 # PlayerHitbox
	shock_hitbox.collision_mask = 1 << 2  # EnemyHurtbox
	get_tree().current_scene.add_child(shock_hitbox)
	get_tree().create_timer(0.15).timeout.connect(shock_hitbox.queue_free)

# --- MOUNT SYSTEM (PILLAR 1) ---
func toggle_mount() -> void:
	if _mount_cooldown > 0.0:
		return
	_mount_cooldown = 0.4
	
	if is_mounted:
		dismount()
	else:
		if GameManager.current_floor != 0:
			_show_hud_toast("Mounts cannot enter the subterranean catacombs.")
			return
		mount()

func mount(breed: String = "") -> void:
	if breed != "":
		mount_breed = breed
	is_mounted = true
	is_blocking = false
	
	# Spawn or replace mount model
	if mount_node and is_instance_valid(mount_node):
		mount_node.queue_free()
		
	var m_path = "res://assets/characters/animals/" + mount_breed + ".glb"
	mount_node = AssetLoader.load_or_generate_model(m_path, "character", mount_breed)
	var m_scale = Vector3(0.32, 0.32, 0.32)
	if mount_breed == "Stag":
		m_scale = Vector3(0.38, 0.38, 0.38)
	mount_node.scale = m_scale
	mount_node.name = "ActiveMount"
	add_child(mount_node)
	
	mount_anim = mount_node.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if mount_anim:
		mount_anim.play("AnimalArmature|Idle", 0.1)
		
	# Lift player into saddle atop horse back
	if visual_model_root:
		visual_model_root.position.y = 0.95
		visual_model_root.position.z = -0.05
		if anim_player:
			play_anim("Sit_Floor_Idle", 0.1, 1.0)
			
	AudioManager.play_sfx("steed_whistle", 0.05, 0.0)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.3, 0), Color(0.85, 0.75, 0.5))
	_show_hud_toast("🐎 Mounted Warsteed! [Space] Leap | [F] Dismount")

func dismount() -> void:
	if not is_mounted:
		return
	is_mounted = false
	
	if visual_model_root:
		visual_model_root.position = Vector3.ZERO
		if anim_player:
			play_anim("Idle", 0.1, 1.0)
			
	if mount_node and is_instance_valid(mount_node):
		mount_node.queue_free()
		mount_node = null
		mount_anim = null
		
	AudioManager.play_sfx("footstep", 0.05, 0.0)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.2, 0), Color(0.7, 0.65, 0.5))
	_show_hud_toast("Dismounted.")

func _mounted_leap() -> void:
	if not is_on_floor() and velocity.y > 0.0:
		return
	velocity.y = 6.2
	var forward = -transform.basis.z
	velocity += forward * 6.5
	if mount_anim:
		mount_anim.play("AnimalArmature|Gallop_Jump", 0.06, 1.3)
	AudioManager.play_sfx("dash", 0.08, -1.0)
	CombatJuice.add_trauma(0.12)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.3, 0), Color(0.9, 0.8, 0.5))

func _process_trample(delta: float) -> void:
	if _trample_cooldown > 0.0:
		_trample_cooldown -= delta
	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	if horiz_speed < 4.0 or _trample_cooldown > 0.0:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 2.2:
				var forward = -transform.basis.z
				var trample_dir = (enemy.global_position - global_position).normalized()
				trample_dir.y = 0.35
				if enemy.has_method("take_damage"):
					enemy.take_damage(28.0, trample_dir * 12.0, false, self)
				CombatJuice.spawn_hit_spark(enemy.global_position + Vector3(0, 0.8, 0), Color(1.0, 0.75, 0.2))
				CombatJuice.add_trauma(0.12)
				AudioManager.play_sfx("hit_flesh", 0.08, 1.5)
				_trample_cooldown = 0.35
				break

func _show_hud_toast(msg: String) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(msg)

func update_movement_animation(delta: float) -> void:
	if is_dead:
		return
	if is_mounted:
		if is_attacking:
			return
		if anim_player:
			if anim_player.current_animation != "Sit_Floor_Idle" and anim_player.current_animation != "Sit_Chair_Idle":
				play_anim("Sit_Floor_Idle", 0.12, 1.0)
		if mount_anim:
			var horiz = Vector2(velocity.x, velocity.z).length()
			if not mount_anim.current_animation.ends_with("Gallop_Jump") or not mount_anim.is_playing():
				if horiz > 0.5:
					mount_anim.play("AnimalArmature|Gallop", 0.12, clamp(horiz / 6.0, 1.0, 2.0))
				else:
					mount_anim.play("AnimalArmature|Idle", 0.2)
		return
	if is_blocking:
		if anim_player and not is_attacking:
			if not anim_player.current_animation.begins_with("Block"):
				play_anim("Blocking", 0.08, 1.0)
		return
	super.update_movement_animation(delta)

# --- OVERRIDES ---
func take_damage(amount: float, knockback: Vector3, is_crit: bool, source: Node3D) -> void:
	var forward = -transform.basis.z
	var is_frontal = true
	if source and source != self:
		var to_source = (source.global_position - global_position).normalized()
		is_frontal = forward.dot(to_source) > 0.05
		
	# Active Shield Block & Perfect Parry (Pillar 2)
	if is_frontal and is_blocking and not is_mounted:
		if parry_window_timer > 0.0:
			# PERFECT PARRY! 100% damage negated + attacker stagger + riposte crit primed
			AudioManager.play_sfx("parry_ring", 0.05, 3.5)
			CombatJuice.freeze_frame(0.08)
			CombatJuice.add_trauma(0.25)
			CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1.0, 0) + forward * 0.7, Color(1.0, 0.9, 0.25))
			if anim_player:
				play_anim("Block_Hit", 0.02, 2.2)
			CombatJuice.spawn_damage_number(global_position + Vector3(0, 1.8, 0), 0.0, true, false)
			has_riposte_crit = true
			if source and "current_ai_state" in source:
				source.current_ai_state = source.AIState.STAGGER
				source.set("_state_timer", 1.8)
				source.velocity = -forward * 7.0
			_show_hud_toast("⚔️ PERFECT PARRY! Riposte Counter Ready (2.5x Crit)!")
			return
		else:
			# REGULAR SHIELD BLOCK: 75% damage absorbed
			amount *= 0.25
			knockback *= 0.15
			AudioManager.play_sfx("anvil_strike", 0.08, -1.0)
			CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.9, 0) + forward * 0.5, Color(0.8, 0.8, 0.9))
			if anim_player:
				play_anim("Block_Hit", 0.04, 1.6)
			CombatJuice.add_trauma(0.08)

	if GameManager.has_boon("knight_crest"):
		amount *= 0.85
	if GameManager.has_boon("paladins_ward"):
		amount *= 0.80 # Paladin absorbs 20% incoming damage
	if GameManager.has_boon("unstoppable_juggernaut"):
		knockback = Vector3.ZERO # Juggernaut cannot be knocked back
	super.take_damage(amount, knockback, is_crit, source)
	if not is_dead and not is_attacking and anim_player:
		var hit_anim = "Hit_A" if randf() > 0.5 else "Hit_B"
		play_anim(hit_anim, 0.05, 1.4)
	# Thorns of Bone Boon: reflect damage
	if GameManager.has_boon("thorns_of_bone") and source and source != self:
		if source.has_method("take_damage"):
			var reflect_amount = amount * 0.5
			source.take_damage(reflect_amount, -knockback * 0.5, false, self)

func on_enemy_slain(enemy: Node3D = null) -> void:
	var enemy_t = -1
	if enemy and "enemy_type" in enemy:
		enemy_t = int(enemy.enemy_type)
	GameManager.record_enemy_kill(enemy_t)
	# Vampiric Edge Boon: heal on kill
	if GameManager.has_boon("vampiric_edge"):
		heal(max_health * 0.08)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	character_died.emit()
	if anim_player:
		play_anim("Death_A", 0.08, 1.0)
	CombatJuice.spawn_bone_burst(global_position, 24)
	AudioManager.play_sfx("skeleton_bones", 0.05, 4.0)
	GameManager.trigger_game_over(false)
