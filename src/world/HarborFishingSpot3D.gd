class_name HarborFishingSpot3D
extends Node3D

## HarborFishingSpot3D
## Coastal Pier Fishing Spot with Angler Jonas.
## Offers an interactive fishing reflex mini-game yielding harbor fish,
## lobsters, ocean pearls, and the Sunken Lockbox Key.

enum FishingState { IDLE, WAITING_FOR_BITE, BITE_ACTIVE, REELING }

var _state: FishingState = FishingState.IDLE
var _bite_timer: float = 0.0
var _bite_target_time: float = 2.0
var _bite_reaction_window: float = 1.4

var _bobber: MeshInstance3D = null
var _rod_line: ImmediateMesh = null
var _angler_model: Node3D = null
var _has_caught_key: bool = false

var interact_prompt: String = "[E] Cast Fishing Line"

func _ready() -> void:
	add_to_group("harbor_structures")
	add_to_group("interactable")
	_build_fishing_spot()

func _build_fishing_spot() -> void:
	# 1. Wooden Pier Edge Props: Tackle Box & Bait Tub
	var tackle_box = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.5, 0.35, 0.35)
	tackle_box.mesh = box
	tackle_box.position = Vector3(0.8, 0.18, 0.4)
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.2, 0.4, 0.55)
	tackle_box.material_override = t_mat
	add_child(tackle_box)

	# Bait tub
	var tub = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.18
	cyl.height = 0.35
	tub.mesh = cyl
	tub.position = Vector3(0.8, 0.18, -0.4)
	var tub_mat = StandardMaterial3D.new()
	tub_mat.albedo_color = Color(0.35, 0.25, 0.15)
	tub.material_override = tub_mat
	add_child(tub)

	# 2. Angler Jonas
	var char_path = "res://assets/characters/adventurers/Knight.glb"
	if ResourceLoader.exists(char_path):
		var scene = load(char_path)
		if scene:
			_angler_model = scene.instantiate()
			_angler_model.position = Vector3(-0.6, 0.0, 0.0)
			_angler_model.rotation_degrees.y = 90.0
			add_child(_angler_model)
			
			var ap = _find_animation_player(_angler_model)
			if ap and ap.has_animation("Idle"):
				ap.play("Idle")

	# 3. Floating Fishing Bobber
	_bobber = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.12
	s_mesh.height = 0.24
	_bobber.mesh = s_mesh
	_bobber.position = Vector3(3.5, -0.15, 0.0)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.95, 0.2, 0.15) # bright red float
	_bobber.material_override = b_mat
	_bobber.visible = false
	add_child(_bobber)

func _process(delta: float) -> void:
	match _state:
		FishingState.WAITING_FOR_BITE:
			_bite_timer += delta
			# Bobber gently bobs on water
			if _bobber:
				_bobber.position.y = -0.15 + sin(_bite_timer * 3.0) * 0.04
			
			if _bite_timer >= _bite_target_time:
				_trigger_fish_bite()

		FishingState.BITE_ACTIVE:
			_bite_timer += delta
			# Bobber splashes violently down
			if _bobber:
				_bobber.position.y = -0.35 + sin(_bite_timer * 18.0) * 0.08

			if _bite_timer >= _bite_reaction_window:
				# Fish got away!
				_fish_escaped()

func interact(player: Node) -> void:
	match _state:
		FishingState.IDLE:
			cast_line(player)
		FishingState.WAITING_FOR_BITE:
			HUD.show_notification("Patient, Captain... wait for the bite!")
		FishingState.BITE_ACTIVE:
			reel_in(player)
		FishingState.REELING:
			pass

func cast_line(player: Node = null) -> void:
	_state = FishingState.WAITING_FOR_BITE
	_bite_timer = 0.0
	_bite_target_time = randf_range(1.6, 2.8)
	interact_prompt = "[E] Ready to Hook!"

	if _bobber:
		_bobber.visible = true
		_bobber.position = Vector3(3.5, -0.15, 0.0)

	AudioManager.play_sfx_at_position("reel_splash", global_position + Vector3(3.5, 0.0, 0.0), 30.0, 0.1, -2.0)
	HUD.show_notification("Cast line into the harbor! Watch the red bobber...")

func _trigger_fish_bite() -> void:
	_state = FishingState.BITE_ACTIVE
	_bite_timer = 0.0
	AudioManager.play_sfx_at_position("reel_splash", global_position + Vector3(3.5, 0.0, 0.0), 30.0, 0.2, 2.0)
	interact_prompt = "[E] HOOK NOW!"
	HUD.show_notification("A BITE! Press [E] NOW to set the hook!")
	_spawn_water_splash(global_position + Vector3(3.5, -0.1, 0.0))

func reel_in(player: Node = null) -> void:
	_state = FishingState.IDLE
	interact_prompt = "[E] Cast Fishing Line"
	if _bobber:
		_bobber.visible = false

	AudioManager.play_sfx_at_position("reel_splash", global_position, 30.0, 0.08, 1.0)

	# Determine Catch
	var roll = randf()
	if not _has_caught_key:
		_has_caught_key = true
		HUD.show_notification("Incredible! You reeled in the [Sunken Lockbox Key]! The shipwreck chest can now be unlocked!")
		if player and "inventory" in player:
			player.inventory.append("sunken_lockbox_key")
		if GameManager.has_method("add_echoes"):
			GameManager.add_echoes(15)
	elif roll < 0.45:
		HUD.show_notification("Caught a plump [Blackwater Mackerel]! (+15 HP, +5 Gold)")
		if GameManager.has_method("add_gold"):
			GameManager.add_gold(5)
		if player and player.has_method("heal"):
			player.heal(15)
	elif roll < 0.8:
		HUD.show_notification("Caught a fighting [Harbor Rock Lobster]! (+12 Soul Echoes)")
		if GameManager.has_method("add_echoes"):
			GameManager.add_echoes(12)
	else:
		HUD.show_notification("Rare Catch! Hooked a [Luminescent Bay Oyster with Ocean Pearl]! (+35 Gold)")
		if GameManager.has_method("add_gold"):
			GameManager.add_gold(35)

func _fish_escaped() -> void:
	_state = FishingState.IDLE
	interact_prompt = "[E] Cast Fishing Line"
	if _bobber:
		_bobber.visible = false
	HUD.show_notification("The fish nibbled the bait and slipped away! Try again.")

func _spawn_water_splash(pos: Vector3) -> void:
	for i in range(8):
		var drop = MeshInstance3D.new()
		var s = SphereMesh.new()
		s.radius = 0.08
		s.height = 0.16
		drop.mesh = s
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.95, 1.0, 0.8)
		drop.material_override = mat
		get_tree().current_scene.add_child(drop)
		drop.global_position = pos

		var tw = drop.create_tween()
		var vel = Vector3(randf_range(-0.5, 0.5), randf_range(0.8, 1.6), randf_range(-0.5, 0.5))
		tw.tween_property(drop, "global_position", pos + vel, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(drop, "global_position:y", pos.y, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(drop.queue_free)

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null
