extends Node

# --- SIGNALS ---
signal gold_changed(new_gold: int, delta: int)
signal echoes_changed(new_echoes: int, delta: int)
signal floor_changed(new_floor: int)
signal hero_class_changed(new_class: int)
signal player_stats_changed()
signal boon_acquired(boon: Dictionary)
signal game_over(victory: bool)
signal room_cleared()
signal room_entered(room_index: int, total_rooms: int)
signal mission_updated(mission: Dictionary)
signal mission_completed(mission: Dictionary)
signal mission_claimed(mission: Dictionary)

# --- ENUMS ---
enum HeroClass {
	KNIGHT,
	ROGUE,
	MAGE,
	BARBARIAN
}

enum GameState {
	SANCTUARY,
	CHAMBER_COMBAT,
	CHAMBER_CLEARED,
	BOSS_COMBAT,
	VICTORY,
	GAME_OVER
}

# --- STATE VARIABLES ---
var current_state: GameState = GameState.SANCTUARY
var current_floor: int = 0 # 0 = Sanctuary, 1..4 = Chambers, 5 = Boss
var current_chamber_index: int = 1
var max_chambers_per_floor: int = 4
var selected_class: HeroClass = HeroClass.KNIGHT

# Currencies
var gold: int = 0
var soul_echoes: int = 150 # Starting echoes for initial altar testing

# Meta Upgrades (persists across runs)
var upgrade_max_hp_level: int = 0       # +20 Max HP per level (Max 5)
var upgrade_attack_power_level: int = 0 # +12% Attack Power per level (Max 5)
var upgrade_dash_cooldown_level: int = 0 # -12% Dash Cooldown per level (Max 5)

# Active Boons in the current descent
var relic_boons: Array[Dictionary] = []

# Lifetime / Run Statistics
var enemies_defeated: int = 0
var rooms_cleared_count: int = 0
var damage_dealt: float = 0.0
var damage_taken: float = 0.0
var runs_attempted: int = 0

# Missions / Bounties
var missions: Array[Dictionary] = [
	{
		"id": "bone_cleaver",
		"title": "Bone Cleaver",
		"description": "Slay 15 skeletal warriors in the catacombs.",
		"current": 0,
		"target": 15,
		"reward_gold": 50,
		"reward_echoes": 40,
		"completed": false,
		"claimed": false,
		"icon": "💀"
	},
	{
		"id": "deep_descent",
		"title": "Into the Abyss",
		"description": "Descend down to Floor 3 of the Ossuary.",
		"current": 0,
		"target": 3,
		"reward_gold": 75,
		"reward_echoes": 60,
		"completed": false,
		"claimed": false,
		"icon": "⚡"
	},
	{
		"id": "relic_attunement",
		"title": "Relic Attunement",
		"description": "Attune to 2 Relic Boons in a single descent.",
		"current": 0,
		"target": 2,
		"reward_gold": 100,
		"reward_echoes": 75,
		"completed": false,
		"claimed": false,
		"icon": "✨"
	},
	{
		"id": "gold_hoarder",
		"title": "Gilded Pockets",
		"description": "Amass 100 Gold during your descent.",
		"current": 0,
		"target": 100,
		"reward_gold": 50,
		"reward_echoes": 70,
		"completed": false,
		"claimed": false,
		"icon": "💰"
	},
	{
		"id": "echo_empowered",
		"title": "Altar Devotion",
		"description": "Purchase an upgrade at the Altar of Souls.",
		"current": 0,
		"target": 1,
		"reward_gold": 60,
		"reward_echoes": 50,
		"completed": false,
		"claimed": false,
		"icon": "🔥"
	},
	{
		"id": "architect_downfall",
		"title": "Architect's Downfall",
		"description": "Defeat the Skeletal Warden on Floor 5.",
		"current": 0,
		"target": 1,
		"reward_gold": 250,
		"reward_echoes": 200,
		"completed": false,
		"claimed": false,
		"icon": "👑"
	},
	{
		"id": "wild_hunt",
		"title": "Wildland Hunter",
		"description": "Hunt 2 wild beasts (Wolves, Stags, or Foxes) in the open world.",
		"current": 0,
		"target": 2,
		"reward_gold": 60,
		"reward_echoes": 45,
		"completed": false,
		"claimed": false,
		"icon": "🐺"
	},
	{
		"id": "mineral_seeker",
		"title": "Mountain Prospector",
		"description": "Gather 2 Arcane Crystals or Gold Veins across the open world.",
		"current": 0,
		"target": 2,
		"reward_gold": 80,
		"reward_echoes": 60,
		"completed": false,
		"claimed": false,
		"icon": "💎"
	},
	{
		"id": "relic_recovery",
		"title": "Relic of the Ancients",
		"description": "Recover the Sacred Chalice or Forgotten Scroll from the ruins.",
		"current": 0,
		"target": 1,
		"reward_gold": 120,
		"reward_echoes": 100,
		"completed": false,
		"claimed": false,
		"icon": "🏆"
	}
]

var materials: Dictionary = {}

const SAVE_PATH: String = "user://echoes_save.json"

func _ready() -> void:
	load_game()

# --- HERO DEFINITIONS ---
func get_hero_name(h_class: HeroClass = selected_class) -> String:
	match h_class:
		HeroClass.KNIGHT: return "Iron Warden (Knight)"
		HeroClass.ROGUE: return "Shadow Stalker (Rogue)"
		HeroClass.MAGE: return "Soul Siphon (Mage)"
		HeroClass.BARBARIAN: return "Blood Reaver (Barbarian)"
		_: return "Adventurer"

func get_base_hero_stats(h_class: HeroClass = selected_class) -> Dictionary:
	var stats: Dictionary = {}
	match h_class:
		HeroClass.KNIGHT:
			stats = {
				"max_hp": 120.0,
				"move_speed": 6.2,
				"attack_damage": 26.0,
				"attack_cooldown": 0.45,
				"attack_range": 2.2,
				"dash_cooldown": 1.1,
				"dash_speed": 18.0,
				"dash_duration": 0.22,
				"is_ranged": false,
				"crit_chance": 0.10,
				"defense": 6.0
			}
		HeroClass.ROGUE:
			stats = {
				"max_hp": 85.0,
				"move_speed": 7.8,
				"attack_damage": 18.0,
				"attack_cooldown": 0.28,
				"attack_range": 1.8,
				"dash_cooldown": 0.75,
				"dash_speed": 22.0,
				"dash_duration": 0.25,
				"is_ranged": false,
				"crit_chance": 0.35,
				"defense": 0.0
			}
		HeroClass.MAGE:
			stats = {
				"max_hp": 75.0,
				"move_speed": 5.6,
				"attack_damage": 22.0,
				"attack_cooldown": 0.55,
				"attack_range": 14.0,
				"dash_cooldown": 1.35,
				"dash_speed": 20.0,
				"dash_duration": 0.20,
				"is_ranged": true,
				"crit_chance": 0.15,
				"defense": 0.0
			}
		HeroClass.BARBARIAN:
			stats = {
				"max_hp": 160.0,
				"move_speed": 5.8,
				"attack_damage": 38.0,
				"attack_cooldown": 0.70,
				"attack_range": 2.6,
				"dash_cooldown": 1.6,
				"dash_speed": 16.0,
				"dash_duration": 0.26,
				"is_ranged": false,
				"crit_chance": 0.15,
				"defense": 4.0
			}
	
	# Apply meta upgrades
	stats["max_hp"] += upgrade_max_hp_level * 20.0
	stats["attack_damage"] *= (1.0 + upgrade_attack_power_level * 0.12)
	stats["dash_cooldown"] *= max(0.4, 1.0 - upgrade_dash_cooldown_level * 0.12)
	
	# Apply boons
	for boon in relic_boons:
		match boon.get("id", ""):
			"titan_stride":
				stats["move_speed"] *= 1.25
			"swift_phantom":
				stats["dash_cooldown"] *= 0.75
			"sharpened_bone":
				stats["attack_damage"] *= 1.20
			"assassin_eye":
				stats["crit_chance"] += 0.20
				
	return stats

# --- CLASS SELECTION ---
func set_hero_class(new_class: HeroClass) -> void:
	if selected_class != new_class:
		selected_class = new_class
		hero_class_changed.emit(selected_class)
		player_stats_changed.emit()

# --- ECONOMY & UPGRADES ---
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold, amount)
	set_mission_progress("gold_hoarder", gold)
	if amount > 0:
		AudioManager.play_sfx("chest_open", 0.15, -3.0)

func add_echoes(amount: int) -> void:
	soul_echoes += amount
	echoes_changed.emit(soul_echoes, amount)
	save_game()
	if amount > 0:
		AudioManager.play_sfx("soul_pickup", 0.08, 1.5)

func spend_echoes(amount: int) -> bool:
	if soul_echoes >= amount:
		soul_echoes -= amount
		echoes_changed.emit(soul_echoes, -amount)
		save_game()
		return true
	return false

func get_upgrade_cost(upgrade_type: String) -> int:
	var current_lvl: int = 0
	match upgrade_type:
		"max_hp": current_lvl = upgrade_max_hp_level
		"attack_power": current_lvl = upgrade_attack_power_level
		"dash_cooldown": current_lvl = upgrade_dash_cooldown_level
	if current_lvl >= 5:
		return -1 # Maxed out
	return (current_lvl + 1) * 35

func purchase_upgrade(upgrade_type: String) -> bool:
	var cost: int = get_upgrade_cost(upgrade_type)
	if cost > 0 and spend_echoes(cost):
		match upgrade_type:
			"max_hp": upgrade_max_hp_level += 1
			"attack_power": upgrade_attack_power_level += 1
			"dash_cooldown": upgrade_dash_cooldown_level += 1
		player_stats_changed.emit()
		progress_mission("echo_empowered", 1)
		save_game()
		return true
	return false

# --- BOON MANAGEMENT ---
func add_boon(boon: Dictionary) -> void:
	relic_boons.append(boon)
	boon_acquired.emit(boon)
	player_stats_changed.emit()
	set_mission_progress("relic_attunement", relic_boons.size())
	AudioManager.play_sfx("level_up", 0.05, 2.0)

func has_boon(boon_id: String) -> bool:
	for b in relic_boons:
		if b.get("id") == boon_id:
			return true
	return false

# --- RUN FLOW ---
func start_new_run() -> void:
	runs_attempted += 1
	gold = 0
	relic_boons.clear()
	current_floor = 1
	current_chamber_index = 1
	current_state = GameState.CHAMBER_COMBAT
	floor_changed.emit(current_floor)
	gold_changed.emit(gold, 0)
	player_stats_changed.emit()

func advance_chamber() -> void:
	rooms_cleared_count += 1
	current_chamber_index += 1
	if current_chamber_index > max_chambers_per_floor:
		current_floor += 1
		current_chamber_index = 1
		if current_floor >= 5:
			current_state = GameState.BOSS_COMBAT
		else:
			current_state = GameState.CHAMBER_COMBAT
		floor_changed.emit(current_floor)
	else:
		current_state = GameState.CHAMBER_COMBAT
	set_mission_progress("deep_descent", current_floor)
	room_entered.emit(current_chamber_index, max_chambers_per_floor)

func return_to_sanctuary() -> void:
	current_floor = 0
	current_chamber_index = 0
	relic_boons.clear()
	current_state = GameState.SANCTUARY
	floor_changed.emit(current_floor)
	save_game()

func trigger_game_over(victory: bool) -> void:
	current_state = GameState.VICTORY if victory else GameState.GAME_OVER
	if victory:
		add_echoes(100 + gold / 2)
	else:
		add_echoes(gold / 4)
	game_over.emit(victory)
	save_game()

# --- MISSION SYSTEM METHODS ---
func get_missions() -> Array[Dictionary]:
	return missions

func get_mission(mission_id: String) -> Dictionary:
	for m in missions:
		if m["id"] == mission_id:
			return m
	return {}

func progress_mission(mission_id: String, amount: int = 1) -> void:
	for m in missions:
		if m["id"] == mission_id:
			if m["completed"]:
				return
			m["current"] = min(m["target"], m["current"] + amount)
			mission_updated.emit(m)
			if m["current"] >= m["target"] and not m["completed"]:
				m["completed"] = true
				mission_completed.emit(m)
				save_game()
			return

func set_mission_progress(mission_id: String, val: int) -> void:
	for m in missions:
		if m["id"] == mission_id:
			if m["completed"]:
				return
			m["current"] = clamp(val, 0, m["target"])
			mission_updated.emit(m)
			if m["current"] >= m["target"] and not m["completed"]:
				m["completed"] = true
				mission_completed.emit(m)
				save_game()
			return

func claim_mission_reward(mission_id: String) -> bool:
	for m in missions:
		if m["id"] == mission_id:
			if m["completed"] and not m["claimed"]:
				m["claimed"] = true
				add_gold(m["reward_gold"])
				add_echoes(m["reward_echoes"])
				mission_claimed.emit(m)
				save_game()
				var am = get_node_or_null("/root/AudioManager")
				if am and am.has_method("play_sfx"):
					am.play_sfx("chest_open", 0.05, 1.2)
				return true
	return false

func record_enemy_kill() -> void:
	enemies_defeated += 1
	progress_mission("bone_cleaver", 1)

func record_boss_slain() -> void:
	progress_mission("architect_downfall", 1)

func add_material(mat_id: String, count: int = 1) -> void:
	if not materials.has(mat_id):
		materials[mat_id] = 0
	materials[mat_id] += count

func record_animal_hunted(_animal_type_val: int) -> void:
	progress_mission("wild_hunt", 1)

func record_material_gathered(mat_id: String) -> void:
	if "crystal" in mat_id or "gold" in mat_id or "stone" in mat_id:
		progress_mission("mineral_seeker", 1)
	if "chalice" in mat_id or "scroll" in mat_id or "key" in mat_id:
		progress_mission("relic_recovery", 1)

# --- SAVE / LOAD SYSTEM ---
func save_game() -> void:
	var missions_data: Array = []
	for m in missions:
		missions_data.append({
			"id": m["id"],
			"current": m["current"],
			"completed": m["completed"],
			"claimed": m["claimed"]
		})

	var data: Dictionary = {
		"soul_echoes": soul_echoes,
		"upgrade_max_hp_level": upgrade_max_hp_level,
		"upgrade_attack_power_level": upgrade_attack_power_level,
		"upgrade_dash_cooldown_level": upgrade_dash_cooldown_level,
		"runs_attempted": runs_attempted,
		"enemies_defeated": enemies_defeated,
		"selected_class": int(selected_class),
		"missions": missions_data
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			soul_echoes = parsed.get("soul_echoes", 150)
			upgrade_max_hp_level = parsed.get("upgrade_max_hp_level", 0)
			upgrade_attack_power_level = parsed.get("upgrade_attack_power_level", 0)
			upgrade_dash_cooldown_level = parsed.get("upgrade_dash_cooldown_level", 0)
			runs_attempted = parsed.get("runs_attempted", 0)
			enemies_defeated = parsed.get("enemies_defeated", 0)
			selected_class = parsed.get("selected_class", HeroClass.KNIGHT)
			
			var saved_missions = parsed.get("missions", [])
			if saved_missions is Array:
				for sm in saved_missions:
					if sm is Dictionary:
						var m_id = sm.get("id", "")
						for m in missions:
							if m["id"] == m_id:
								m["current"] = sm.get("current", 0)
								m["completed"] = sm.get("completed", false)
								m["claimed"] = sm.get("claimed", false)
