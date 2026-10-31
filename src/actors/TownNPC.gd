extends Node3D
class_name TownNPC

@export var npc_id: String = "blacksmith"
@export var npc_name: String = "Master Torval"
@export var npc_title: String = "Village Blacksmith"
@export var icon: String = "⚒️"
@export_multiline var dialogue_text: String = "Hail, warrior! The forge fires burn night and day. Bring me Soul Echoes from the Ossuary depths and I shall re-temper your blade, fortify your armor, and sharpen your dash reflexes!"
@export var model_path: String = "res://assets/characters/npcs/dwarf_warrior_from_fbx.gltf"
@export var model_scale: Vector3 = Vector3(0.55, 0.55, 0.55)
@export var model_rotation_y: float = 0.0

var _model: Node3D = null
var _label: Label3D = null
var _interact_area: Area3D = null
var _anim_player: AnimationPlayer = null
var _idle_time: float = 0.0
var _spark_timer: float = 0.0
var _target_player: Node3D = null

func _ready() -> void:
	name = "NPC_" + npc_id
	add_to_group("interactable")
	_build_visuals()
	_build_interaction()
	_build_role_effects()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target_player = players[0]

func _process(delta: float) -> void:
	_idle_time += delta
	
	# Procedural idle breathing & weight shift
	if _model and is_instance_valid(_model):
		var breath = sin(_idle_time * 2.4) * 0.015
		_model.position.y = breath
		
		# Smooth player tracking when close
		if not _target_player:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				_target_player = players[0]
				
		var target_rot = model_rotation_y
		if _target_player and is_instance_valid(_target_player):
			var dist = global_position.distance_to(_target_player.global_position)
			if dist < 5.0 and dist > 0.4:
				var look_vec = _target_player.global_position - global_position
				target_rot = rad_to_deg(atan2(look_vec.x, look_vec.z))
				
		_model.rotation_degrees.y = lerp_angle(deg_to_rad(_model.rotation_degrees.y), deg_to_rad(target_rot), delta * 4.5)
		_model.rotation_degrees.y = rad_to_deg(_model.rotation_degrees.y)
		
	# Role-specific timed animations
	if npc_id == "blacksmith":
		_spark_timer += delta
		if _spark_timer >= 3.4:
			_spark_timer = 0.0
			AmbientFX.create_forge_sparks(self, Vector3(0.6, 0.9, 0.4))
			if _target_player and global_position.distance_to(_target_player.global_position) < 18.0:
				AudioManager.play_sfx("anvil_strike", 0.08, -10.0)

func _build_role_effects() -> void:
	if npc_id == "priestess":
		AmbientFX.create_sacred_aura(self, Vector3(0, 0.2, 0))

func _build_visuals() -> void:
	_model = AssetLoader.load_or_generate_model(model_path, "character", npc_name)
	_model.scale = model_scale
	if model_rotation_y != 0.0:
		_model.rotation_degrees.y = model_rotation_y
	add_child(_model)
	
	# Look for AnimationPlayer and start idle
	_anim_player = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim_player:
		_play_default_idle()

func _play_default_idle() -> void:
	if not _anim_player:
		return
	var anims = _anim_player.get_animation_list()
	if anims.size() > 0:
		var idle_anim = anims[0]
		for a in anims:
			if "idle" in a.to_lower():
				idle_anim = a
				break
		_anim_player.play(idle_anim, 0.2, 1.0)
	
	# Floating Name Tag & Prompt
	_label = Label3D.new()
	_label.text = icon + " " + npc_name + "\n[E] Speak"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.0
	_label.font_size = 28
	_label.outline_size = 8
	_label.outline_modulate = Color(0.02, 0.03, 0.05)
	_label.modulate = Color(1.0, 0.90, 0.55)
	add_child(_label)

func _build_interaction() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 1 << 5 # Layer 6: Interactable
	_interact_area.collision_mask = 0
	
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 2.4
	shape.height = 3.0
	col.shape = shape
	col.position.y = 1.5
	_interact_area.add_child(col)
	add_child(_interact_area)

func interact(player: Node3D) -> void:
	if player:
		var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		if look_target.distance_to(global_position) > 0.1:
			look_at(look_target, Vector3.UP)
			rotation.x = 0.0
			rotation.z = 0.0

	# Welcoming gesture / emote
	if _anim_player:
		var gesture = ""
		var anims = _anim_player.get_animation_list()
		for candidate in ["cheer", "interact", "talking", "block"]:
			for a in anims:
				if candidate in a.to_lower():
					gesture = a
					break
			if gesture != "":
				break
		if gesture != "":
			_anim_player.play(gesture, 0.15, 1.2)
			get_tree().create_timer(1.2).timeout.connect(func():
				if is_instance_valid(self) and _anim_player:
					_play_default_idle()
			)

	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		return
		
	var actions: Array[Dictionary] = []
	var active_dialogue = dialogue_text

	match npc_id:
		"steward":
			if GameManager.quest_chalice_completed:
				active_dialogue = "The Sacred Chalice shines upon the imperial altar! You have the eternal gratitude and favor of the Royal Court, champion!"
				actions.append({"id": "open_missions", "label": "📜 Royal Decrees", "color": Color(0.55, 0.22, 0.22), "closes": true})
			elif GameManager.materials.get("sacred_chalice", 0) > 0:
				active_dialogue = "By the King! You have returned the Sacred Chalice of the First Kings! Hand it over to receive the royal bounty and the legendary Knight's Crest!"
				actions.append({"id": "turn_in_chalice", "label": "🏆 Turn in Sacred Chalice", "color": Color(0.85, 0.65, 0.15), "closes": false})
			else:
				active_dialogue = "Welcome to the Grand Throne Room, warrior. The royal chalice was lost to the northern ruins when the catacombs stirred. Bring it back to honor the crown and earn the Knight's Royal Crest (+15% Defense)!"
				actions.append({"id": "open_missions", "label": "📜 Royal Decrees", "color": Color(0.55, 0.22, 0.22), "closes": true})

		"barkeep":
			if GameManager.quest_vintage_completed:
				active_dialogue = "The patrons are cheering and the spiced mead is flowing freely! You're always welcome at the Boar's Tusk, hero!"
				actions.append({"id": "barkeep_ale", "label": "🍺 Buy Flagon (Heal 20 HP - 5 Gold)", "color": Color(0.7, 0.45, 0.15), "closes": false})
			elif GameManager.materials.get("ossuary_codex", 0) > 0:
				active_dialogue = "Sweet Mother of Malt! That's my granddad's secret spiced mead recipe parchment! Hand it over and I'll reward you with gold and my finest invigorating draughts!"
				actions.append({"id": "turn_in_scroll", "label": "📜 Turn in Vintage Scroll", "color": Color(0.85, 0.65, 0.15), "closes": false})
			else:
				active_dialogue = "Welcome to The Boar's Tusk! Rest your boots by the hearth. My granddad's secret spiced mead recipe was lost near the old watchtower cemetery. If you can recover it, I've got gold and rare elixirs for you!"
				actions.append({"id": "barkeep_ale", "label": "🍺 Buy Flagon (Heal 20 HP - 5 Gold)", "color": Color(0.7, 0.45, 0.15), "closes": false})

		"blacksmith":
			var has_metal = GameManager.materials.get("smugglers_chest", 0) > 0 or GameManager.materials.get("gold_vein", 0) > 0 or GameManager.materials.get("iron_ore", 0) > 0
			if GameManager.quest_steel_completed:
				active_dialogue = "Your blade holds a lethal razor edge! What else can I forge or temper for you today, warrior?"
				actions.append({"id": "open_upgrades", "label": "⚒️ Forge Upgrades", "color": Color(0.62, 0.28, 0.12), "closes": true})
			elif has_metal:
				active_dialogue = "By the molten hammer! You brought back refined ingots and raw ore from the ruins! Give them here, and I'll grant you gold and permanently temper your blade!"
				actions.append({"id": "turn_in_ingots", "label": "⚒️ Turn in Ingots (+3 Attack)", "color": Color(0.85, 0.65, 0.15), "closes": false})
				actions.append({"id": "open_upgrades", "label": "⚒️ Forge Upgrades", "color": Color(0.62, 0.28, 0.12), "closes": true})
			else:
				active_dialogue = "Step into the heart of the forge, warrior! My bellows roar day and night. If you scavenge refined ingots or quarry ore from the ruins, I'll temper your blade with razor lethality!"
				actions.append({"id": "open_upgrades", "label": "⚒️ Forge Upgrades", "color": Color(0.62, 0.28, 0.12), "closes": true})

		"farmer":
			var wolves_down = GameManager.get_mission("wild_hunt").get("current", 0) >= 2
			if GameManager.quest_wolves_completed:
				active_dialogue = "The sheep graze quietly on the green slopes thanks to you, champion. The whole hamlet sings your praises!"
				actions.append({"id": "open_missions", "label": "📜 Hamlet Requests", "color": Color(0.25, 0.52, 0.22), "closes": true})
			elif wolves_down:
				active_dialogue = "Bless you, brave warrior! The shepherds tell me the wild wolf pack has been driven back! Take this gold and these soul echoes with our deepest gratitude!"
				actions.append({"id": "turn_in_wolves", "label": "🐺 Report Wolves Hunted", "color": Color(0.85, 0.65, 0.15), "closes": false})
			else:
				active_dialogue = "Good day, traveler. Welcome to our humble home. Ferocious timber wolves have crept out from the eastern woods and stalked our sheep pasture! If you can hunt 2 wild beasts, our hamlet will reward you with gold and soul echoes."
				actions.append({"id": "open_missions", "label": "📜 Hamlet Requests", "color": Color(0.25, 0.52, 0.22), "closes": true})

		"stablemaster":
			active_dialogue = "Hail, cavalier! Welcome to the Royal Stables. Press [F] anytime across the overworld to summon your warsteed with a whistle! Leap over obstacles with [Space], and charge into enemies to trample them underhoof. Which noble steed shall carry you across the realm?"
			actions.append({"id": "select_mount_horse", "label": "🐎 Chestnut Warhorse", "color": Color(0.65, 0.40, 0.20), "closes": false})
			actions.append({"id": "select_mount_horse_white", "label": "🦄 Royal White Courser", "color": Color(0.85, 0.85, 0.95), "closes": false})
			actions.append({"id": "select_mount_stag", "label": "🦌 Elder Antlered Stag", "color": Color(0.40, 0.65, 0.35), "closes": false})
			actions.append({"id": "whistle_steed", "label": "🎺 Mount Up Now [F]", "color": Color(0.85, 0.65, 0.15), "closes": true})

		"bard":
			active_dialogue = "Listen close to the crackling hearth, traveler... 'Beneath the stone, the ossuary sighs, where fallen kings and hollow shadows rise! Steel your heart, brave soul, where glory lies!'"
			actions.append({"id": "bard_song", "label": "🎶 Request Ballad", "color": Color(0.4, 0.25, 0.6), "closes": false})

		"priestess":
			actions.append({"id": "open_missions", "label": "📜 View Bounties", "color": Color(0.18, 0.42, 0.65), "closes": true})

		"guard":
			actions.append({"id": "gate_info", "label": "🛡️ Catacomb Advice", "color": Color(0.24, 0.32, 0.48), "closes": false})

		"commander":
			actions.append({"id": "open_missions", "label": "🛡️ Royal Decrees", "color": Color(0.55, 0.22, 0.22), "closes": true})

		"hermit":
			actions.append({"id": "open_upgrades", "label": "✨ Channel Soul Echoes", "color": Color(0.35, 0.20, 0.58), "closes": true})

		"captain_marlo":
			if not GameManager.world_repairs.get("port_crane", false):
				actions.append({"id": "repair_port_crane", "label": "🔨 Rebuild Cargo Crane (1 Lumber + 1 Iron)", "color": Color(0.95, 0.65, 0.2), "closes": false})
			if GameManager.quest_port_compass_completed:
				active_dialogue = "The seas smile upon us, matey! The Tidecaller's Compass guides our ships through every storm. You're a true brother of the coast!"
				actions.append({"id": "open_missions", "label": "📜 Port Bounties", "color": Color(0.18, 0.55, 0.75), "closes": true})
			elif GameManager.materials.get("tidecaller_compass", 0) > 0:
				active_dialogue = "By the roaring kraken! That's the legendary Tidecaller's Compass recovered from the sunken smuggler's cove! Hand it over and claim the Corsair's Blessing and sea bounty!"
				actions.append({"id": "turn_in_compass", "label": "🧭 Turn in Tidecaller's Compass", "color": Color(0.18, 0.75, 0.95), "closes": false})
			else:
				active_dialogue = "Ahoy, landlubber! Welcome to Port Blackwater. Deep Sea Creeps crawl along our reefs, and corsairs brawl on the piers. At the sunken cove lies the lost Tidecaller's Compass. Retrieve it to master the ocean tides!"
				actions.append({"id": "open_missions", "label": "📜 Port Bounties", "color": Color(0.18, 0.55, 0.75), "closes": true})

		"harbormaster":
			active_dialogue = "Welcome to the Port Blackwater Docks. Keep your weapons drawn—smugglers lurk behind the boathouses, and monstrosities emerge from the salt water. Check the harbor bounty board to assist the port guard!"
			actions.append({"id": "open_missions", "label": "📜 Harbor Bounties", "color": Color(0.2, 0.45, 0.65), "closes": true})

		"druid_thorne":
			if not GameManager.world_repairs.get("druid_altar", false):
				actions.append({"id": "repair_druid_altar", "label": "🌟 Cleanse Sun Altar (1 Arcane + 1 Emerald)", "color": Color(0.3, 0.85, 0.5), "closes": false})
			if GameManager.quest_forest_heartwood_completed:
				active_dialogue = "The great canopy breathes once more. The Living Heartwood pulse revitalizes every root and leaf. Nature's blessing flows in your veins, guardian!"
				actions.append({"id": "druid_blessing", "label": "🌿 Receive Forest Blessing (+Full Heal)", "color": Color(0.25, 0.75, 0.35), "closes": false})
			elif GameManager.materials.get("living_heartwood", 0) > 0:
				active_dialogue = "The sacred seed! You have reclaimed the Living Heartwood from the bandit hollow! Place it upon the shrine to restore the balance and gain permanent health regeneration!"
				actions.append({"id": "turn_in_heartwood", "label": "🌱 Plant Living Heartwood", "color": Color(0.25, 0.88, 0.35), "closes": false})
			else:
				active_dialogue = "Hail, child of the realm. Whisperwood Forest suffers under bandit outlaws who desecrated the sacred grove. Find the Living Heartwood deep in the woodland glade to heal the corrupted forest!"
				actions.append({"id": "open_missions", "label": "📜 Grove Bounties", "color": Color(0.25, 0.65, 0.30), "closes": true})

		"ranger_elora":
			active_dialogue = "Quiet your tread. Highwaymen and timber wolves stalk the shadows of the pines. Keep to the dirt trail unless you're ready for an ambush. What news from the outer world?"
			actions.append({"id": "open_missions", "label": "📜 Ranger Bounties", "color": Color(0.22, 0.52, 0.28), "closes": true})

		"runesmith_torvald":
			if not GameManager.world_repairs.get("smelter_bellows", false):
				actions.append({"id": "repair_smelter_bellows", "label": "🔥 Rebuild Smelter Bellows (1 Gold + 1 Iron)", "color": Color(0.95, 0.45, 0.2), "closes": false})
			if GameManager.quest_crags_runecore_completed:
				active_dialogue = "The ancestral furnace burns red-hot! With the Runebound Core restored, our mountain fortress stands impenetrable! May your hammer strike true, kin!"
				actions.append({"id": "open_upgrades", "label": "⚒️ Masterwork Upgrades", "color": Color(0.75, 0.45, 0.15), "closes": true})
			elif GameManager.materials.get("runebound_core", 0) > 0:
				active_dialogue = "By the fiery blood of the mountain! You shattered the Orc warlords and claimed the Runebound Mountain Core! Give it here, and I shall temper your weapons with ancient dwarven runes!"
				actions.append({"id": "turn_in_runecore", "label": "⛰️ Turn in Runebound Core", "color": Color(0.95, 0.55, 0.15), "closes": false})
			else:
				active_dialogue = "Greetings, warrior! You stand before the Stonegate Mining Outpost. Orc Berserkers and cliff demons have seized the upper crags and stole our Runebound Core! Cleave them in twain and reclaim our heritage!"
				actions.append({"id": "open_upgrades", "label": "⚒️ Mountain Forge", "color": Color(0.75, 0.45, 0.15), "closes": true})

		"signpost_crossroads", "signpost_port", "signpost_forest", "signpost_crags":
			active_dialogue = "Kingdom Crossroad Waystone:\n• South-West: Port Blackwater (Harbor, Ships, and Ocean Coast)\n• North-West: Whisperwood Forest (Sylva's Rest & Ancient Pines)\n• North-East: Khar-Drakken Crags (Dwarven Mines & Orc Stronghold)\n• Central: Oakhaven Sanctuary (Castle Citadel & Catacombs)"
			actions.append({"id": "travel_oakhaven", "label": "🏰 Fast Travel: Oakhaven Town", "color": Color(0.35, 0.45, 0.65), "closes": true})
			actions.append({"id": "travel_port", "label": "⚓ Fast Travel: Port Blackwater", "color": Color(0.18, 0.55, 0.75), "closes": true})
			actions.append({"id": "travel_forest", "label": "🌲 Fast Travel: Whisperwood", "color": Color(0.22, 0.55, 0.28), "closes": true})
			actions.append({"id": "travel_crags", "label": "⛰️ Fast Travel: Khar-Drakken", "color": Color(0.75, 0.45, 0.18), "closes": true})

	if hud.has_method("open_dialogue"):
		hud.open_dialogue(npc_name + " (" + npc_title + ")", icon, active_dialogue, actions)
