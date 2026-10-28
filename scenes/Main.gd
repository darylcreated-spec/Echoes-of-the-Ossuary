extends Node3D

@onready var camera: Camera3D = $IsometricCamera
@onready var dungeon_gen: Node3D = $DungeonGenerator
@onready var player: Node3D = $Player
@onready var hud: CanvasLayer = $UI_HUD

# Isometric camera offset
var camera_offset: Vector3 = Vector3(10.0, 14.0, 10.0)
var camera_follow_speed: float = 6.5
var current_room: Node3D = null

func _ready() -> void:
	add_to_group("main")
	
	if camera:
		CombatJuice.register_camera(camera)
		
	# Start background dungeon music
	AudioManager.play_bgm("bgm_dungeon")
	
	# Initial room build (Sanctuary Hub)
	load_current_floor_room()
	
	if camera and player:
		camera.global_position = player.global_position + camera_offset
		camera.look_at(player.global_position + Vector3(0, 0.8, 0), Vector3.UP)

func _physics_process(delta: float) -> void:
	if player and is_instance_valid(player) and camera:
		var target_cam_pos = player.global_position + camera_offset
		camera.global_position = camera.global_position.lerp(target_cam_pos, delta * camera_follow_speed)
		camera.look_at(player.global_position + Vector3(0, 0.8, 0), Vector3.UP)

func load_current_floor_room() -> Node3D:
	current_room = dungeon_gen.build_floor_room(GameManager.current_floor)
	var room = current_room
	
	# Reposition player
	if player and is_instance_valid(player):
		player.global_position = Vector3(0, 0.5, 0 if GameManager.current_floor == 0 else -6.0)
		player.velocity = Vector3.ZERO
		player.current_health = player.max_health
		player.health_changed.emit(player.current_health, player.max_health)
		
	# Connect Boss if Floor 5
	if GameManager.current_floor >= 5 and room:
		for child in room.get_children():
			if child.has_signal("boss_health_updated"):
				child.boss_health_updated.connect(hud.update_boss_health)
				if "boss_name" in child and "current_health" in child and "max_health" in child:
					hud.update_boss_health(child.current_health, child.max_health, child.boss_name)
	return current_room
