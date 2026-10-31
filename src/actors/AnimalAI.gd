extends "res://src/actors/BaseCharacter3D.gd"
class_name AnimalAI

enum AnimalType {
	STAG,
	DEER,
	WOLF,
	FOX,
	HORSE,
	COW,
	BULL
}

enum AIState {
	IDLE,
	WANDER,
	FLEE,
	CHASE,
	ATTACK,
	DEAD
}

@export var animal_type: AnimalType = AnimalType.STAG

var current_ai_state: AIState = AIState.IDLE
var target_player: Node3D = null
var spawn_origin: Vector3 = Vector3.ZERO
var wander_target: Vector3 = Vector3.ZERO
var _state_timer: float = 0.0
var _attack_cooldown: float = 0.0

func _ready() -> void:
	super._ready()
	spawn_origin = global_position
	_configure_type_stats()
	_setup_collision_and_hurtbox()
	_setup_visuals()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _setup_collision_and_hurtbox() -> void:
	collision_layer = 4 # Enemy/Creature physics
	collision_mask = 1 | 2 # Environment and Player
	
	var col = find_child("CollisionShape3D", true, false)
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape = CapsuleShape3D.new()
		shape.radius = 0.55
		shape.height = 1.3
		col.shape = shape
		col.position.y = 0.65
		add_child(col)
		
	if not hurtbox:
		var hb = Area3D.new()
		hb.name = "Hurtbox3D"
		hb.collision_layer = 4 # Layer 3: Enemy Hurtbox
		hb.collision_mask = 8 # Layer 4: Player Hitbox
		var HurtboxScript = load("res://src/combat/Hurtbox3D.gd")
		if HurtboxScript:
			hb.set_script(HurtboxScript)
			hb.set("owner_character", self)
		var hb_col = CollisionShape3D.new()
		var hb_shape = CapsuleShape3D.new()
		hb_shape.radius = 0.65
		hb_shape.height = 1.4
		hb_col.shape = hb_shape
		hb_col.position.y = 0.7
		hb.add_child(hb_col)
		add_child(hb)
		hurtbox = hb

	# Mount interaction for Horses & Stags
	if animal_type in [AnimalType.HORSE, AnimalType.STAG]:
		var ia = Area3D.new()
		ia.name = "MountInteractArea"
		ia.collision_layer = 1 << 5 # Layer 6: Interactable
		ia.collision_mask = 0
		var ishape = SphereShape3D.new()
		ishape.radius = 2.4
		var icol = CollisionShape3D.new()
		icol.shape = ishape
		icol.position.y = 0.8
		ia.add_child(icol)
		add_child(ia)

func get_prompt_text() -> String:
	if animal_type == AnimalType.STAG:
		return "[E] Mount Elder Stag"
	return "[E] Mount Warhorse"

func interact(player: Node) -> void:
	if player and player.has_method("mount"):
		var breed = "Stag" if animal_type == AnimalType.STAG else "Horse"
		player.mount(breed)
		queue_free()

func _configure_type_stats() -> void:
	match animal_type:
		AnimalType.STAG:
			max_health = 45.0
			move_speed = 7.5
			attack_damage = 0.0
		AnimalType.DEER:
			max_health = 35.0
			move_speed = 7.8
			attack_damage = 0.0
		AnimalType.WOLF:
			max_health = 60.0
			move_speed = 6.2
			attack_damage = 18.0
		AnimalType.FOX:
			max_health = 25.0
			move_speed = 8.2
			attack_damage = 0.0
		AnimalType.HORSE:
			max_health = 80.0
			move_speed = 6.5
			attack_damage = 0.0
		AnimalType.COW, AnimalType.BULL:
			max_health = 90.0
			move_speed = 3.5
			attack_damage = 0.0

	current_health = max_health

func _setup_visuals() -> void:
	if visual_model_root and is_instance_valid(visual_model_root):
		visual_model_root.queue_free()

	var file_name = "Stag"
	var model_scale = Vector3.ONE
	
	match animal_type:
		AnimalType.STAG:
			file_name = "Stag"
			model_scale = Vector3(0.38, 0.38, 0.38) # ~1.85m tall with antlers
		AnimalType.DEER:
			file_name = "Deer"
			model_scale = Vector3(0.30, 0.30, 0.30) # ~1.35m tall
		AnimalType.WOLF:
			file_name = "Wolf"
			model_scale = Vector3(0.18, 0.18, 0.18) # ~0.95m tall
		AnimalType.FOX:
			file_name = "Fox"
			model_scale = Vector3(0.09, 0.09, 0.09) # ~0.50m tall
		AnimalType.HORSE:
			file_name = "Horse"
			model_scale = Vector3(0.30, 0.30, 0.30) # ~1.70m tall
		AnimalType.COW:
			file_name = "Cow"
			model_scale = Vector3(0.20, 0.20, 0.20) # ~1.55m tall
		AnimalType.BULL:
			file_name = "Bull"
			model_scale = Vector3(0.22, 0.22, 0.22) # ~1.70m tall

	var model_path = "res://assets/characters/animals/" + file_name + ".glb"
	visual_model_root = AssetLoader.load_or_generate_model(model_path, "character", file_name)
	visual_model_root.name = "Model"
	visual_model_root.scale = model_scale
	add_child(visual_model_root)
	invalidate_model_cache()
	_cache_model_nodes()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_knockback(delta)
	
	if is_dead:
		move_and_slide()
		return

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
		
	if not target_player or not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]

	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.WANDER:
			_process_wander(delta)
		AIState.FLEE:
			_process_flee(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)

	update_movement_animation(delta)
	move_and_slide()

func _process_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_state_timer -= delta
	
	# Check player proximity
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if animal_type == AnimalType.WOLF:
			if dist < 9.0:
				current_ai_state = AIState.CHASE
				return
		elif animal_type in [AnimalType.HORSE, AnimalType.COW, AnimalType.BULL]:
			# Domestic livestock stay calm around the player
			pass
		else:
			# Wild herbivores flee when player gets too close!
			if dist < 6.5:
				current_ai_state = AIState.FLEE
				_state_timer = randf_range(3.0, 5.0)
				return
				
	if _state_timer <= 0.0:
		# Pick random wander target nearby
		var angle = randf() * TAU
		var dist_w = randf_range(3.0, 7.0)
		wander_target = spawn_origin + Vector3(cos(angle) * dist_w, 0, sin(angle) * dist_w)
		current_ai_state = AIState.WANDER
		_state_timer = randf_range(2.5, 4.5)

func _process_wander(delta: float) -> void:
	_state_timer -= delta
	
	# Check player proximity
	if target_player:
		var dist_p = global_position.distance_to(target_player.global_position)
		if animal_type == AnimalType.WOLF and dist_p < 9.0:
			current_ai_state = AIState.CHASE
			return
		elif animal_type != AnimalType.WOLF and dist_p < 6.5:
			current_ai_state = AIState.FLEE
			_state_timer = randf_range(3.0, 5.0)
			return
			
	var to_target = (wander_target - global_position)
	to_target.y = 0.0
	var dist = to_target.length()
	
	if dist < 0.6 or _state_timer <= 0.0:
		current_ai_state = AIState.IDLE
		_state_timer = randf_range(2.0, 5.0)
		velocity.x = 0.0
		velocity.z = 0.0
		if anim_player:
			if animal_type != AnimalType.WOLF and randf() > 0.4 and anim_player.has_animation("AnimalArmature|Eating"):
				anim_player.play("AnimalArmature|Eating", 0.2, 1.0)
			else:
				play_anim("Idle", 0.2, 1.0)
	else:
		var dir = to_target.normalized()
		velocity.x = dir.x * (move_speed * 0.45) # Walk speed
		velocity.z = dir.z * (move_speed * 0.45)
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 6.0)

func _process_flee(delta: float) -> void:
	_state_timer -= delta
	if not target_player or _state_timer <= 0.0:
		current_ai_state = AIState.IDLE
		_state_timer = randf_range(2.0, 4.0)
		return
		
	# Gallop directly away from player
	var away_dir = (global_position - target_player.global_position).normalized()
	away_dir.y = 0.0
	velocity.x = away_dir.x * move_speed
	velocity.z = away_dir.z * move_speed
	rotation.y = lerp_angle(rotation.y, atan2(away_dir.x, away_dir.z), delta * 8.0)

func _process_chase(delta: float) -> void:
	if not target_player:
		current_ai_state = AIState.IDLE
		return
		
	var to_player = (target_player.global_position - global_position)
	to_player.y = 0.0
	var dist = to_player.length()
	
	if dist > 14.0:
		current_ai_state = AIState.IDLE
		_state_timer = 2.0
		return
		
	if dist < 2.0 and _attack_cooldown <= 0.0:
		_execute_attack()
		return
		
	var dir = to_player.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)

func _execute_attack() -> void:
	current_ai_state = AIState.ATTACK
	_state_timer = 0.4
	velocity.x = 0.0
	velocity.z = 0.0
	
	if anim_player:
		is_attacking = true
		play_anim("Attack", 0.08, 1.5)
		get_tree().create_timer(0.4).timeout.connect(func(): is_attacking = false)
		
	if target_player and target_player.has_method("take_damage"):
		var forward = -transform.basis.z
		target_player.take_damage(attack_damage, forward * 4.0, false, self)
		
	AudioManager.play_sfx("sword_swing", 0.1, 1.2)
	_attack_cooldown = 1.6

func _process_attack(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		current_ai_state = AIState.CHASE

func take_damage(amount: float, knockback: Vector3, is_crit: bool, source: Node3D) -> void:
	super.take_damage(amount, knockback, is_crit, source)
	if not is_dead and anim_player:
		play_anim("Idle_HitReact_Left", 0.05, 1.6)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	character_died.emit()
	
	var drop_name = "Wild Beast Hide"
	var drop_id = "beast_hide"
	match animal_type:
		AnimalType.STAG, AnimalType.DEER:
			drop_name = "Stag Antlers"
			drop_id = "stag_antlers"
		AnimalType.WOLF:
			drop_name = "Wolf Pelt"
			drop_id = "wolf_pelt"
		AnimalType.FOX:
			drop_name = "Fine Fox Fur"
			drop_id = "fine_fur"
		AnimalType.COW, AnimalType.BULL:
			drop_name = "Raw Meat & Hide"
			drop_id = "raw_meat"
		AnimalType.HORSE:
			drop_name = "Tough Leather"
			drop_id = "tough_leather"

	if GameManager.has_method("add_material"):
		GameManager.add_material(drop_id, 1)
	if GameManager.has_method("record_animal_hunted"):
		GameManager.record_animal_hunted(animal_type)
		
	GameManager.add_gold(int(randi_range(6, 16)))
	GameManager.add_echoes(int(randi_range(4, 10)))
	
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 0.8, 0), Color(0.9, 0.6, 0.2))
	AudioManager.play_sfx("sword_swing", 0.1, 1.5)
	if anim_player:
		play_anim("Death", 0.08, 1.2)
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)
		get_tree().create_timer(1.2).timeout.connect(queue_free)
	else:
		queue_free()
