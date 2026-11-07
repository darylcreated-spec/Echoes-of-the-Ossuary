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
signal story_act_advanced(new_act: int, act_title: String)
signal world_structure_repaired(structure_id: String)
signal hero_leveled_up(new_level: int, new_title: String)
signal campaign_step_changed(step_index: int, step_data: Dictionary)
signal campaign_step_completed(step_index: int, step_data: Dictionary)
signal story_guide_toggled(enabled: bool)

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
var player_gold: int:
	get:
		return gold
	set(val):
		var diff = val - gold
		gold = val
		gold_changed.emit(gold, diff)
var soul_echoes: int = 150 # Starting echoes for initial altar testing

# Character Development & Hero Progression
var hero_level: int = 1
var hero_xp: int = 0
var xp_to_next_level: int = 100
var hero_title: String = "King's Vanguard Squire"
var bonus_max_hp: float = 0.0
var bonus_attack_damage: float = 0.0
var bonus_armor_defense: float = 0.0
var unlocked_weapon_tier: int = 1
var unlocked_armor_tier: int = 1

# Toggleable Pop-Up Story Guide State
var story_guide_enabled: bool = true
var current_campaign_step: int = 0

var campaign_quests: Array[Dictionary] = [
	{
		"id": "chapter_1_royal_muster",
		"chapter": "Chapter I • The King's Summons",
		"title": "Pledge Fealty & Arm for War",
		"sector": "Sector C2 • Oakhaven Sanctuary",
		"target_pos": Vector3(0.0, 0.0, -3.0),
		"instructions": "1. Use [WASD] to move and press [V] to test the new Top-Down Camera view.\n2. Speak with Captain Vane or Master Blacksmith Torvald in Oakhaven Square [E].\n3. Practice your melee combo [LMB] & Dash [Space], or click [Complete Step] to claim your Royal Muster Arms!",
		"reward_gold": 150,
		"reward_echoes": 60,
		"reward_xp": 120,
		"reward_hp": 25.0,
		"reward_atk": 4.0,
		"reward_def": 2.0,
		"reward_desc": "+150 Gold • +60 Echoes • +25 Max HP • +4 Atk • Steel Arms (Tier II)",
		"completed": false
	},
	{
		"id": "chapter_2_whisperwood_enclave",
		"chapter": "Chapter II • Shadows of Whisperwood",
		"title": "Cleanse Sylva's Enclave & Sun Altar",
		"sector": "Sector B1 • Whisperwood Forest",
		"target_pos": Vector3(-48.0, 0.0, -58.0),
		"instructions": "1. Follow the golden beacon northwest into Sector B1 (Whisperwood Enclave).\n2. Speak with Elder Druid Thorne [E] and defeat the forest bandit raiders.\n3. Restore the Ancient Druidic Sun Altar [E] to earn the Living Heartwood blessing!",
		"reward_gold": 200,
		"reward_echoes": 90,
		"reward_xp": 160,
		"reward_hp": 30.0,
		"reward_atk": 5.0,
		"reward_def": 3.0,
		"reward_desc": "+200 Gold • +90 Echoes • +30 Max HP • +5 Atk • Druid Ward",
		"completed": false
	},
	{
		"id": "chapter_3_port_sea_warfare",
		"chapter": "Chapter III • Seaside Ship Warfare",
		"title": "Defend Port Blackwater from the Sea Armada",
		"sector": "Sector A3/B3 • Port Blackwater Harbor",
		"target_pos": Vector3(-58.0, 0.0, 78.0),
		"instructions": "1. Urgent! An Invading Corsair Armada & Landing Fleet is assaulting Port Blackwater (Sector A3/B3)!\n2. Sound the Port Naval War Horn [E] on the Stone Quay to rally the Port Defenses.\n3. Command the Harbor Cannon Batteries, Quay Bowmen & Marines [Keys 1-5] or helm The Sea Sovereign flagship to crush the sea invasion!",
		"reward_gold": 350,
		"reward_echoes": 150,
		"reward_xp": 240,
		"reward_hp": 40.0,
		"reward_atk": 8.0,
		"reward_def": 4.0,
		"reward_desc": "+350 Gold • +150 Echoes • +40 Max HP • +8 Atk • High Admiral Crest",
		"completed": false
	},
	{
		"id": "chapter_4_dwarven_forge",
		"chapter": "Chapter IV • The Iron Crucible",
		"title": "Reclaim the Khar-Drakken Mithril Forge",
		"sector": "Sector D1 • Khar-Drakken Crags",
		"target_pos": Vector3(62.0, 0.0, -52.0),
		"instructions": "1. Ride northeast to the mountain fortress of Khar-Drakken in Sector D1.\n2. Aid Runesmith Torvald against the Iron-Tusk Orc Warband.\n3. Repair the ancestral Dwarven Bellows [E] to temper your blade with Mithril!",
		"reward_gold": 300,
		"reward_echoes": 140,
		"reward_xp": 250,
		"reward_hp": 35.0,
		"reward_atk": 10.0,
		"reward_def": 4.0,
		"reward_desc": "+300 Gold • +140 Echoes • +35 Max HP • +10 Atk • Mithril Warblade (Tier III)",
		"completed": false
	},
	{
		"id": "chapter_5_massive_land_siege",
		"chapter": "Chapter V • The Great Southern Siege",
		"title": "Lead the King's Combined-Arms Army",
		"sector": "Sector C4 • Southern Siege Battlefield",
		"target_pos": Vector3(24.0, 0.0, 126.0),
		"instructions": "1. March south across the river bridge to the fortified ramparts in Sector C4.\n2. Sound the Royal War Horn [E] to launch the Massive Combined-Arms Land Battle!\n3. Command your Infantry Phalanx, Longbowmen, Mounted Cavalry & Trebuchet Siege Weapons [Keys 1-5] to crush Warlord Malakor's besieging army!",
		"reward_gold": 500,
		"reward_echoes": 250,
		"reward_xp": 350,
		"reward_hp": 55.0,
		"reward_atk": 14.0,
		"reward_def": 6.0,
		"reward_desc": "+500 Gold • +250 Echoes • +55 Max HP • +14 Atk • Royal Marshal Plate (Tier IV)",
		"completed": false
	},
	{
		"id": "chapter_6_weeping_fen",
		"chapter": "Chapter VI • Mists of the Weeping Fen",
		"title": "Purge the Fenland Outlaws & Bog Ward",
		"sector": "Sector D3/D4 • Weeping Fen & Ruined Keep",
		"target_pos": Vector3(58.0, 0.0, 62.0),
		"instructions": "1. Journey southeast into the mist-shrouded Weeping Fen (Sector D3 & D4).\n2. Speak with Witch Morwenna [E] and clear the southern Ruined Watch-Keep.\n3. Claim the Fenland Soul Ward to shield your spirit against abyssal magic!",
		"reward_gold": 350,
		"reward_echoes": 200,
		"reward_xp": 300,
		"reward_hp": 45.0,
		"reward_atk": 10.0,
		"reward_def": 5.0,
		"reward_desc": "+350 Gold • +200 Echoes • +45 Max HP • +10 Atk • Fen-Bane Ward",
		"completed": false
	},
	{
		"id": "chapter_7_tri_seal_gate",
		"chapter": "Chapter VII • Awakening the Tri-Seal",
		"title": "Unseal the Northern Ossuary Gate",
		"sector": "Sector C1 • Northern Crypt Approach",
		"target_pos": Vector3(0.0, 0.0, -28.0),
		"instructions": "1. Return north along the King's Highway to the Ossuary Gate in Sector C1.\n2. Channel your hard-won relics at the Descent Sigil.\n3. Step onto the glowing sigil to descend into Floor 1 of the Ossuary Catacombs!",
		"reward_gold": 400,
		"reward_echoes": 300,
		"reward_xp": 400,
		"reward_hp": 60.0,
		"reward_atk": 15.0,
		"reward_def": 6.0,
		"reward_desc": "+400 Gold • +300 Echoes • +60 Max HP • +15 Atk • Sovereign Relic Blade (Tier V)",
		"completed": false
	},
	{
		"id": "chapter_8_ossuary_warden",
		"chapter": "Chapter VIII • Throne of the Ossuary",
		"title": "Vanquish the Skeletal Warden",
		"sector": "Ossuary Catacombs • Floors 1 to 5",
		"target_pos": Vector3(0.0, 0.0, -29.0),
		"instructions": "1. Fight through the subterranean chambers of the Ossuary Catacombs.\n2. Attune to Relic Boons after each cleared chamber.\n3. Defeat the Skeletal Warden on Floor 5 to become Immortal Savior of Oakhaven!",
		"reward_gold": 1000,
		"reward_echoes": 500,
		"reward_xp": 600,
		"reward_hp": 100.0,
		"reward_atk": 25.0,
		"reward_def": 10.0,
		"reward_desc": "+1000 Gold • +500 Echoes • +100 Max HP • +25 Atk • Immortal Crown",
		"completed": false
	}
]

# Meta Upgrades (persists across runs)
var upgrade_max_hp_level: int = 0       # +20 Max HP per level (Max 5)
var upgrade_attack_power_level: int = 0 # +12% Attack Power per level (Max 5)
var upgrade_dash_cooldown_level: int = 0 # -12% Dash Cooldown per level (Max 5)

# Story Campaign & Act Progression
var current_story_act: int = 0 # 0: Prologue, 1: Act I, 2: Act II, 3: Act III, 4: Act IV, 5: Epilogue
var world_repairs: Dictionary = {
	"port_crane": false,
	"druid_altar": false,
	"dwarven_bellows": false
}

# Quest & Task States
var quest_chalice_completed: bool = false
var quest_vintage_completed: bool = false
var quest_steel_completed: bool = false
var quest_wolves_completed: bool = false
var quest_port_compass_completed: bool = false
var quest_forest_heartwood_completed: bool = false
var quest_crags_runecore_completed: bool = false
var tri_seal_unlocked: bool = false

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
	},
	{
		"id": "port_corsairs",
		"title": "Corsair Scourge",
		"description": "Defeat 3 Smugglers or Corsairs roaming the Port Blackwater docks.",
		"current": 0,
		"target": 3,
		"reward_gold": 100,
		"reward_echoes": 80,
		"completed": false,
		"claimed": false,
		"icon": "⚓"
	},
	{
		"id": "sea_creeps",
		"title": "Abyssal Shore Lurkers",
		"description": "Slay 2 Deep Sea Creeps crawling along the Blackwater coastline.",
		"current": 0,
		"target": 2,
		"reward_gold": 120,
		"reward_echoes": 90,
		"completed": false,
		"claimed": false,
		"icon": "🦑"
	},
	{
		"id": "forest_bandits",
		"title": "Whisperwood Outlaws",
		"description": "Eliminate 3 Forest Bandits ambushing travelers in Whisperwood.",
		"current": 0,
		"target": 3,
		"reward_gold": 100,
		"reward_echoes": 80,
		"completed": false,
		"claimed": false,
		"icon": "🌲"
	},
	{
		"id": "orc_bastion",
		"title": "Orc Warlords of the Crags",
		"description": "Defeat 2 Orc Berserkers in the Khar-Drakken mountain stronghold.",
		"current": 0,
		"target": 2,
		"reward_gold": 150,
		"reward_echoes": 110,
		"completed": false,
		"claimed": false,
		"icon": "⛰️"
	},
	{
		"id": "tri_seal_quest",
		"title": "The Tri-Seal of Aethelgard",
		"description": "Recover the 3 Relics: Tidecaller's Compass, Living Heartwood, and Runebound Core.",
		"current": 0,
		"target": 3,
		"reward_gold": 350,
		"reward_echoes": 300,
		"completed": false,
		"claimed": false,
		"icon": "✨"
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

	# Apply Storyline & Mission Character Development Bonuses
	stats["max_hp"] += bonus_max_hp + float(hero_level - 1) * 18.0
	stats["attack_damage"] += bonus_attack_damage + float(hero_level - 1) * 3.5
	stats["defense"] += bonus_armor_defense + float(hero_level - 1) * 1.5
	
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
			"knight_crest":
				stats["max_hp"] += 30.0
				stats["defense"] += 4.0
			"tidecaller_compass":
				stats["move_speed"] *= 1.15
				stats["crit_chance"] += 0.15
			"living_heartwood":
				stats["max_hp"] += 40.0
			"runebound_core":
				stats["attack_damage"] *= 1.25
				stats["defense"] += 6.0
			"tri_seal_mastery":
				stats["max_hp"] *= 1.30
				stats["attack_damage"] *= 1.30
				stats["move_speed"] *= 1.20
				stats["defense"] += 8.0
			"paladins_ward":
				stats["defense"] += 6.0
			"titans_cleave":
				stats["attack_damage"] *= 1.15
			"shadowstep":
				stats["crit_chance"] += 0.15
				stats["dash_speed"] *= 1.25
			"venomous_blades":
				stats["attack_damage"] *= 1.15
			"arcane_chain":
				stats["attack_damage"] *= 1.15
			"frost_nova":
				stats["dash_speed"] *= 1.15
			"berserker_rage":
				stats["attack_damage"] *= 1.20
			"unstoppable_juggernaut":
				stats["max_hp"] += 40.0
				stats["defense"] += 4.0
				
	return stats

# --- STORY CAMPAIGN ACTS & CODEX ---
const STORY_ACTS: Array[Dictionary] = [
	{
		"act": 0,
		"title": "Act 0: Shadows in the Courtyard",
		"location": "Oakhaven Sanctuary",
		"synopsis": "Awaken in the royal sanctuary. Meet with King Valerius and Commander Drake to swear fealty, choose your combat class, and undergo trial combat on the castle grounds.",
		"main_objective": "Speak with King Valerius in the Castle Grand Hall and test your blade."
	},
	{
		"act": 1,
		"title": "Act I: Tides of Blackwater",
		"location": "Port Blackwater",
		"synopsis": "Travel south-west to Port Blackwater. Assist Harbormaster Corin and Captain Marlo, repair the collapsed harbor cargo crane, defeat the Deep Sea Creep, and retrieve the Tidecaller's Compass.",
		"main_objective": "Repair the harbor crane and recover the Tidecaller's Compass."
	},
	{
		"act": 2,
		"title": "Act II: The Weeping Canopy",
		"location": "Whisperwood Forest",
		"synopsis": "Journey north-west into the ancient pines of Whisperwood. Meet Elder Thorne at Sylva's Rest, restore the desecrated Druidic Sun Altar, clear the bandit treehouse camp, and recover the Living Heartwood.",
		"main_objective": "Cleanse the Sun Altar and reclaim the Living Heartwood."
	},
	{
		"act": 3,
		"title": "Act III: The Iron Crucible",
		"location": "Khar-Drakken Crags",
		"synopsis": "Scale the jagged mountain pass to the Stonegate Dwarven Outpost. Rebuild the ancestral forge bellows with Runesmith Torvald, storm the high Orc Bastion, and reclaim the Runebound Mountain Core.",
		"main_objective": "Repair the Dwarven Bellows and reclaim the Runebound Core."
	},
	{
		"act": 4,
		"title": "Act IV: The Abyssal Descent",
		"location": "The Ossuary Catacombs",
		"synopsis": "Return to Oakhaven and place the Three Relics upon the Descent Sigil to awaken the Tri-Seal. Delve through the 5 subterranean chambers and vanquish the Bone Titan Skeletal Warden to save the realm.",
		"main_objective": "Step upon the awakened Descent Sigil and defeat the Skeletal Warden."
	},
	{
		"act": 5,
		"title": "Epilogue: Champion of Aethelgard",
		"location": "The Realm Restored",
		"synopsis": "The Ossuary Core is sealed and corruption vanquished. King Valerius names you Protector of Aethelgard. All realms flourish and are open for infinite heroic expeditions.",
		"main_objective": "Explore the restored realm and complete remaining regional bounties."
	}
]

func get_current_act_info() -> Dictionary:
	for a in STORY_ACTS:
		if a["act"] == current_story_act:
			return a
	return STORY_ACTS[0]

func advance_story_act(new_act: int) -> void:
	if new_act > current_story_act:
		current_story_act = new_act
		save_game()
		var act_info = get_current_act_info()
		story_act_advanced.emit(current_story_act, act_info.get("title", ""))
		AudioManager.play_sfx("sfx_victory_fanfare", 0.05, 1.5)

func repair_structure(structure_id: String) -> bool:
	if world_repairs.get(structure_id, false):
		return false
	world_repairs[structure_id] = true
	save_game()
	world_structure_repaired.emit(structure_id)
	AudioManager.play_sfx("anvil_strike", 0.08, 1.2)
	return true

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

func acquire_boon_by_id(boon_id: String) -> void:
	if has_boon(boon_id):
		return
	for b in BoonSystem.BOONS:
		if b.get("id") == boon_id:
			add_boon(b)
			return

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
				bonus_max_hp += 10.0
				bonus_attack_damage += 2.0
				add_hero_xp(80)
				player_stats_changed.emit()
				mission_claimed.emit(m)
				save_game()
				var am = get_node_or_null("/root/AudioManager")
				if am and am.has_method("play_sfx"):
					am.play_sfx("chest_open", 0.05, 1.2)
				return true
	return false

# --- STORYLINE CAMPAIGN & CHARACTER DEVELOPMENT METHODS ---
const HERO_TITLES: Array[String] = [
	"King's Vanguard Squire",
	"Royal Vanguard Knight",
	"Ward of Sylva's Enclave",
	"High Admiral of Blackwater",
	"Mithril Forge Champion",
	"Grand Marshal of the Realm",
	"Fen-Bane Paladin",
	"Sovereign Crypt-Breaker",
	"Arch-Paladin of Aethelgard",
	"Immortal Savior of Oakhaven"
]

func toggle_story_guide() -> bool:
	story_guide_enabled = not story_guide_enabled
	story_guide_toggled.emit(story_guide_enabled)
	return story_guide_enabled

func set_story_guide_enabled(enabled: bool) -> void:
	if story_guide_enabled != enabled:
		story_guide_enabled = enabled
		story_guide_toggled.emit(story_guide_enabled)

func get_current_campaign_quest() -> Dictionary:
	if campaign_quests.is_empty():
		return {}
	var idx = clampi(current_campaign_step, 0, campaign_quests.size() - 1)
	return campaign_quests[idx]

func add_hero_xp(amount: int) -> void:
	hero_xp += amount
	var leveled = false
	while hero_xp >= xp_to_next_level:
		hero_xp -= xp_to_next_level
		hero_level += 1
		xp_to_next_level = int(round(float(xp_to_next_level) * 1.25))
		var t_idx = clampi(hero_level - 1, 0, HERO_TITLES.size() - 1)
		hero_title = HERO_TITLES[t_idx]
		leveled = true
	if leveled:
		player_stats_changed.emit()
		hero_leveled_up.emit(hero_level, hero_title)
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("level_up", 0.05, 2.0)

func complete_current_campaign_step() -> Dictionary:
	if current_campaign_step < 0 or current_campaign_step >= campaign_quests.size():
		return {}
	var q = campaign_quests[current_campaign_step]
	if q.get("completed", false):
		if current_campaign_step < campaign_quests.size() - 1:
			current_campaign_step += 1
			campaign_step_changed.emit(current_campaign_step, get_current_campaign_quest())
		return q

	q["completed"] = true
	var r_gold = int(q.get("reward_gold", 150))
	var r_echoes = int(q.get("reward_echoes", 75))
	var r_xp = int(q.get("reward_xp", 120))
	var r_hp = float(q.get("reward_hp", 25.0))
	var r_atk = float(q.get("reward_atk", 4.0))
	var r_def = float(q.get("reward_def", 2.0))

	add_gold(r_gold)
	add_echoes(r_echoes)
	bonus_max_hp += r_hp
	bonus_attack_damage += r_atk
	bonus_armor_defense += r_def
	unlocked_weapon_tier = max(unlocked_weapon_tier, current_campaign_step + 2)
	unlocked_armor_tier = max(unlocked_armor_tier, current_campaign_step + 2)
	add_hero_xp(r_xp)
	player_stats_changed.emit()

	var completed_idx = current_campaign_step
	campaign_step_completed.emit(completed_idx, q)

	if current_campaign_step < campaign_quests.size() - 1:
		current_campaign_step += 1
	if current_campaign_step <= 5:
		advance_story_act(min(current_campaign_step, 5))

	campaign_step_changed.emit(current_campaign_step, get_current_campaign_quest())
	save_game()
	return q

func complete_campaign_step_by_id(step_id: String) -> bool:
	for i in range(campaign_quests.size()):
		if campaign_quests[i].get("id", "") == step_id:
			if not campaign_quests[i].get("completed", false):
				current_campaign_step = i
				complete_current_campaign_step()
				return true
	return false

func record_enemy_kill(enemy_type_id: int = -1) -> void:
	enemies_defeated += 1
	progress_mission("bone_cleaver", 1)
	match enemy_type_id:
		2: # ROGUE
			progress_mission("port_corsairs", 1)
			progress_mission("forest_bandits", 1)
		4: # ORC
			progress_mission("orc_bastion", 1)
		6: # CREEP
			progress_mission("sea_creeps", 1)
		7: # PIRATE
			progress_mission("port_corsairs", 1)
		8: # BANDIT
			progress_mission("forest_bandits", 1)

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
	if "compass" in mat_id or "heartwood" in mat_id or "runecore" in mat_id or "rune_core" in mat_id:
		progress_mission("tri_seal_quest", 1)

# --- SAVE / LOAD SYSTEM ---
func has_saved_game() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func reset_for_new_campaign(chosen_class: HeroClass = HeroClass.KNIGHT) -> void:
	selected_class = chosen_class
	gold = 100
	soul_echoes = 150
	hero_level = 1
	hero_xp = 0
	xp_to_next_level = 100
	hero_title = "King's Vanguard Squire"
	bonus_max_hp = 0.0
	bonus_attack_damage = 0.0
	bonus_armor_defense = 0.0
	unlocked_weapon_tier = 1
	unlocked_armor_tier = 1
	current_campaign_step = 0
	current_story_act = 0
	current_floor = 0
	for q in campaign_quests:
		q["completed"] = false
	for k in world_repairs.keys():
		world_repairs[k] = false
	set_hero_class(chosen_class)
	gold_changed.emit(gold, 0)
	echoes_changed.emit(soul_echoes, 0)
	player_stats_changed.emit()
	campaign_step_changed.emit(current_campaign_step, get_current_campaign_quest())
	save_game()

func save_game() -> void:
	var missions_data: Array = []
	for m in missions:
		missions_data.append({
			"id": m["id"],
			"current": m["current"],
			"completed": m["completed"],
			"claimed": m["claimed"]
		})

	var campaign_completed: Array = []
	for q in campaign_quests:
		campaign_completed.append(bool(q.get("completed", false)))

	var data: Dictionary = {
		"gold": gold,
		"soul_echoes": soul_echoes,
		"hero_level": hero_level,
		"hero_xp": hero_xp,
		"xp_to_next_level": xp_to_next_level,
		"hero_title": hero_title,
		"bonus_max_hp": bonus_max_hp,
		"bonus_attack_damage": bonus_attack_damage,
		"bonus_armor_defense": bonus_armor_defense,
		"unlocked_weapon_tier": unlocked_weapon_tier,
		"unlocked_armor_tier": unlocked_armor_tier,
		"current_campaign_step": current_campaign_step,
		"story_guide_enabled": story_guide_enabled,
		"campaign_completed": campaign_completed,
		"upgrade_max_hp_level": upgrade_max_hp_level,
		"upgrade_attack_power_level": upgrade_attack_power_level,
		"upgrade_dash_cooldown_level": upgrade_dash_cooldown_level,
		"runs_attempted": runs_attempted,
		"enemies_defeated": enemies_defeated,
		"selected_class": int(selected_class),
		"current_story_act": current_story_act,
		"world_repairs": world_repairs,
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
			gold = int(parsed.get("gold", gold))
			soul_echoes = int(parsed.get("soul_echoes", 150))
			hero_level = int(parsed.get("hero_level", 1))
			hero_xp = int(parsed.get("hero_xp", 0))
			xp_to_next_level = int(parsed.get("xp_to_next_level", 100))
			hero_title = str(parsed.get("hero_title", "King's Vanguard Squire"))
			bonus_max_hp = float(parsed.get("bonus_max_hp", 0.0))
			bonus_attack_damage = float(parsed.get("bonus_attack_damage", 0.0))
			bonus_armor_defense = float(parsed.get("bonus_armor_defense", 0.0))
			unlocked_weapon_tier = int(parsed.get("unlocked_weapon_tier", 1))
			unlocked_armor_tier = int(parsed.get("unlocked_armor_tier", 1))
			current_campaign_step = clampi(int(parsed.get("current_campaign_step", 0)), 0, max(0, campaign_quests.size() - 1))
			story_guide_enabled = bool(parsed.get("story_guide_enabled", true))
			var saved_camp = parsed.get("campaign_completed", [])
			if saved_camp is Array:
				for i in range(min(saved_camp.size(), campaign_quests.size())):
					campaign_quests[i]["completed"] = bool(saved_camp[i])
			upgrade_max_hp_level = parsed.get("upgrade_max_hp_level", 0)
			upgrade_attack_power_level = parsed.get("upgrade_attack_power_level", 0)
			upgrade_dash_cooldown_level = parsed.get("upgrade_dash_cooldown_level", 0)
			runs_attempted = parsed.get("runs_attempted", 0)
			enemies_defeated = parsed.get("enemies_defeated", 0)
			selected_class = parsed.get("selected_class", HeroClass.KNIGHT)
			current_story_act = parsed.get("current_story_act", 0)
			var saved_repairs = parsed.get("world_repairs", {})
			if saved_repairs is Dictionary:
				for k in saved_repairs.keys():
					world_repairs[k] = saved_repairs[k]
			
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
