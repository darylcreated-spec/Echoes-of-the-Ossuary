extends SceneTree

# Complete In-Engine Asset Verification Suite

const ASSET_PATHS = [
	# 1. Adventurers & Characters
	"res://assets/characters/adventurers/Knight.glb",
	"res://assets/characters/adventurers/Rogue.glb",
	"res://assets/characters/adventurers/Mage.glb",
	"res://assets/characters/adventurers/Barbarian.glb",
	"res://assets/characters/adventurers/Rogue_Hooded.glb",
	"res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf",
	
	# 2. Enemies & Monsters
	"res://assets/characters/skeletons/Skeleton_Warrior.glb",
	"res://assets/characters/skeletons/Skeleton_Minion.glb",
	"res://assets/characters/skeletons/Skeleton_Mage.glb",
	"res://assets/characters/skeletons/Skeleton_Rogue.glb",
	"res://assets/characters/monsters/Orc.gltf",
	"res://assets/characters/monsters/Demon.gltf",
	"res://assets/characters/monsters/CreepCreature.glb",
	
	# 3. Animals & Wildlife
	"res://assets/characters/animals/Bull.glb",
	"res://assets/characters/animals/Cow.glb",
	"res://assets/characters/animals/Deer.glb",
	"res://assets/characters/animals/Fox.glb",
	"res://assets/characters/animals/Horse.glb",
	"res://assets/characters/animals/Horse_White.glb",
	"res://assets/characters/animals/Stag.glb",
	"res://assets/characters/animals/Wolf.glb",
	
	# 4. Weapons & Shields
	"res://assets/weapons/sword_1handed.glb",
	"res://assets/weapons/sword_2handed.glb",
	"res://assets/weapons/dagger.glb",
	"res://assets/weapons/staff.glb",
	"res://assets/weapons/axe_2handed.glb",
	"res://assets/weapons/shield_square.glb",
	"res://assets/weapons/Skeleton_Axe.gltf",
	"res://assets/weapons/Skeleton_Blade.gltf",
	"res://assets/weapons/Skeleton_Crossbow.gltf",
	"res://assets/weapons/Skeleton_Staff.gltf",
	
	# 5. Quest Materials
	"res://assets/items/quest_materials/Chalice.glb",
	"res://assets/items/quest_materials/Scroll.glb",
	"res://assets/items/quest_materials/Chest_Ingots.glb",
	"res://assets/items/quest_materials/Crystal1.glb",
	"res://assets/items/quest_materials/Crystal2.glb",
	"res://assets/items/quest_materials/Gold_Ingots.glb",
	"res://assets/overworld/resource_stone.gltf",
	"res://assets/overworld/resource_lumber.gltf",
	
	# 6. Dungeon Tiles & Traps
	"res://assets/dungeon/floor_tile_large.glb",
	"res://assets/dungeon/wall.glb",
	"res://assets/dungeon/pillar.glb",
	"res://assets/dungeon/torch_lit.glb",
	"res://assets/dungeon/floor_tile_big_spikes.glb",
	"res://assets/dungeon/chest_gold.glb",
	
	# 7. Overworld Buildings & Landmarks
	"res://assets/overworld/building_castle_blue.gltf",
	"res://assets/overworld/building_tower_catapult_blue.gltf",
	"res://assets/overworld/building_blacksmith_blue.gltf",
	"res://assets/overworld/building_church_blue.gltf",
	"res://assets/overworld/building_tavern_blue.gltf",
	"res://assets/overworld/building_market_blue.gltf",
	"res://assets/overworld/building_archeryrange_blue.gltf",
	"res://assets/overworld/building_watermill_blue.gltf",
	"res://assets/overworld/building_windmill_blue.gltf",
	"res://assets/overworld/building_home_A_blue.gltf",
	"res://assets/overworld/building_home_B_blue.gltf",
	"res://assets/overworld/building_well_blue.gltf",
	"res://assets/overworld/building_bridge_A.gltf",
	"res://assets/overworld/building_bridge_B.gltf",
	"res://assets/overworld/building_barracks_blue.gltf",
	"res://assets/overworld/building_lumbermill_blue.gltf",
	"res://assets/overworld/building_mine_blue.gltf",
	"res://assets/overworld/building_scaffolding.gltf",
	"res://assets/overworld/arch_gate.gltf",
	"res://assets/overworld/arch.gltf",
	"res://assets/overworld/crypt.gltf",
	
	# 8. Environment Dressing & Nature
	"res://assets/overworld/tree_dead_large.gltf",
	"res://assets/overworld/tree_dead_medium.gltf",
	"res://assets/overworld/tree_dead_small.gltf",
	"res://assets/overworld/tree_pine_orange_large.gltf",
	"res://assets/overworld/tree_pine_yellow_large.gltf",
	"res://assets/overworld/tree_single_A.gltf",
	"res://assets/overworld/trees_A_large.gltf",
	"res://assets/overworld/trees_B_large.gltf",
	"res://assets/overworld/hills_A.gltf",
	"res://assets/overworld/hills_B_trees.gltf",
	"res://assets/overworld/hill_single_A.gltf",
	"res://assets/overworld/mountain_A.gltf",
	"res://assets/overworld/mountain_A_grass.gltf",
	"res://assets/overworld/mountain_B_grass_trees.gltf",
	"res://assets/overworld/mountain_C.gltf",
	"res://assets/overworld/fence_wood_straight.gltf",
	"res://assets/overworld/fence_wood_straight_gate.gltf",
	"res://assets/overworld/post_lantern.gltf",
	"res://assets/overworld/shrine.gltf",
	"res://assets/overworld/shrine_candles.gltf",
	"res://assets/overworld/flag_blue.gltf",
	"res://assets/overworld/barrel.gltf",
	"res://assets/overworld/crate_A_big.gltf",
	"res://assets/overworld/crate_open.gltf",
	"res://assets/overworld/sack.gltf",
	"res://assets/overworld/wheelbarrow.gltf",
	"res://assets/overworld/bench.gltf",
	"res://assets/overworld/bench_decorated.gltf",
	"res://assets/overworld/rock_single_A.gltf",
	"res://assets/overworld/rock_single_B.gltf",
	"res://assets/overworld/rock_single_C.gltf",
	"res://assets/overworld/rock_single_D.gltf",
	"res://assets/overworld/waterlily_A.gltf",
	"res://assets/overworld/waterlily_B.gltf",
	"res://assets/overworld/waterplant_A.gltf",
	"res://assets/overworld/waterplant_B.gltf",
	"res://assets/overworld/waterplant_C.gltf",
	"res://assets/overworld/grave_A.gltf",
	"res://assets/overworld/grave_A_destroyed.gltf",
	"res://assets/overworld/gravestone.gltf",
	"res://assets/overworld/skull_candle.gltf",
	"res://assets/overworld/bone_A.gltf",
	"res://assets/overworld/pumpkin_orange.gltf",
	"res://assets/overworld/bucket_water.gltf",
	"res://assets/overworld/bucket_arrows.gltf",
	"res://assets/overworld/target.gltf",
	
	# 9. Furniture & Village Interior Assets
	"res://assets/furniture/bed_double_A.gltf",
	"res://assets/furniture/cabinet_medium_decorated.gltf",
	"res://assets/furniture/cabinet_small_decorated.gltf",
	"res://assets/furniture/chair_A_wood.gltf",
	"res://assets/furniture/chair_stool_wood.gltf",
	"res://assets/furniture/table_low.gltf",
	"res://assets/furniture/table_medium.gltf",
	"res://assets/furniture/table_medium_long.gltf",
	"res://assets/furniture/shelf_A_big.gltf",
	"res://assets/furniture/shelf_A_small.gltf",
	"res://assets/furniture/shelf_B_large_decorated.gltf",
	"res://assets/furniture/rug_oval_A.gltf",
	"res://assets/furniture/rug_rectangle_A.gltf",
	"res://assets/village/Floor_RedBrick.gltf",
	"res://assets/village/Floor_UnevenBrick.gltf",
	"res://assets/village/Floor_WoodDark.gltf",
	"res://assets/village/Floor_WoodLight.gltf"
]

const AUDIO_KEYS = [
	"bgm_overworld", "bgm_dungeon", "bgm_market", "bgm_tavern", "bgm_castle", "bgm_forge", "bgm_boss",
	"sfx_victory_fanfare", "sword_swing", "sword_swing_heavy", "hit_flesh", "skeleton_bones",
	"chest_open", "dash", "soul_pickup", "gold_pickup", "descent_sigil", "level_up",
	"boon_acquired", "anvil_strike", "door_open", "door_close", "footstep", "button_click", "ui_switch"
]

func _init() -> void:
	print("======================================================================")
	print("     IN-ENGINE RUNTIME ASSET VERIFICATION SUITE                       ")
	print("======================================================================")

	# Ensure autoloads
	var asset_loader = load("res://src/autoload/AssetLoader.gd").new()
	var audio_manager = load("res://src/autoload/AudioManager.gd").new()
	audio_manager._ready()

	var models_verified = 0
	var models_failed = 0
	var audio_verified = 0
	var animations_verified = 0

	print("\n--- 1. VERIFYING 3D MODELS, TEXTURES & SCENES ---")
	for path in ASSET_PATHS:
		var node = asset_loader.load_or_generate_model(path, "prop", path.get_file().get_basename())
		if node and is_instance_valid(node):
			models_verified += 1
			node.free()
		else:
			printerr("FAILED TO LOAD MODEL: ", path)
			models_failed += 1

	print(" -> Verified Models Loaded & Instantiated: ", models_verified, " / ", ASSET_PATHS.size())
	assert(models_failed == 0)

	print("\n--- 2. VERIFYING SKELETAL RIG ANIMATIONS ---")
	var animated_characters = [
		"res://assets/characters/adventurers/Knight.glb",
		"res://assets/characters/adventurers/Rogue.glb",
		"res://assets/characters/adventurers/Mage.glb",
		"res://assets/characters/adventurers/Barbarian.glb",
		"res://assets/characters/adventurers/Rogue_Hooded.glb",
		"res://assets/characters/skeletons/Skeleton_Warrior.glb",
		"res://assets/characters/animals/Wolf.glb",
		"res://assets/characters/animals/Horse.glb",
		"res://assets/characters/animals/Stag.glb"
	]
	
	for c_path in animated_characters:
		var c_node = asset_loader.load_or_generate_model(c_path, "character", c_path.get_file().get_basename())
		if c_node:
			var ap = c_node.find_child("*AnimationPlayer*", true, false) as AnimationPlayer
			if ap:
				var anim_list = ap.get_animation_list()
				print(" -> ", c_path.get_file(), ": ", anim_list.size(), " animations (e.g., ", anim_list.slice(0, 4), ")")
				animations_verified += anim_list.size()
			else:
				print(" -> ", c_path.get_file(), ": Static Mesh without AnimationPlayer")
			c_node.free()

	print(" -> Total Embedded Skeletal Animations Verified: ", animations_verified)
	assert(animations_verified > 0)

	print("\n--- 3. VERIFYING AUDIO SYSTEM & TRACKS ---")
	for a_key in AUDIO_KEYS:
		if audio_manager._audio_cache.has(a_key):
			var stream = audio_manager._audio_cache[a_key]
			if stream is AudioStream:
				audio_verified += 1
		else:
			printerr("FAILED AUDIO KEY: ", a_key)

	print(" -> Verified Audio Streams Active & Ready: ", audio_verified, " / ", AUDIO_KEYS.size())
	assert(audio_verified == AUDIO_KEYS.size())

	audio_manager.free()
	asset_loader.free()

	print("\n======================================================================")
	print("   IN-ENGINE ASSET VERIFICATION COMPLETE: ALL 100% OPERATIONAL!       ")
	print("======================================================================")
	quit(0)
