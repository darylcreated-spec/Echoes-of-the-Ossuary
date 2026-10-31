extends RefCounted
class_name BoonSystem

const BOONS: Array[Dictionary] = [
	{
		"id": "vampiric_edge",
		"name": "Vampiric Edge",
		"rarity": "Rare",
		"description": "Slaying a skeletal foe restores 8% of your Max HP.",
		"color": Color(0.9, 0.2, 0.2)
	},
	{
		"id": "lightning_dash",
		"name": "Lightning Dash",
		"rarity": "Epic",
		"description": "Dashing unleashes an electric shockwave, dealing 30 damage to surrounding foes.",
		"color": Color(0.3, 0.7, 1.0)
	},
	{
		"id": "twin_echoes",
		"name": "Twin Echoes",
		"rarity": "Epic",
		"description": "Attacks fire an arcing blade fissure or secondary magical bolt.",
		"color": Color(0.8, 0.4, 1.0)
	},
	{
		"id": "sharpened_bone",
		"name": "Sharpened Bone",
		"rarity": "Common",
		"description": "+20% Attack Damage on all attacks.",
		"color": Color(1.0, 0.8, 0.2)
	},
	{
		"id": "assassin_eye",
		"name": "Death's Precision",
		"rarity": "Rare",
		"description": "+20% Critical Strike Chance on all attacks.",
		"color": Color(1.0, 0.4, 0.2)
	},
	{
		"id": "titan_stride",
		"name": "Titan's Stride",
		"rarity": "Common",
		"description": "+25% Move Speed and complete immunity to floor spike traps.",
		"color": Color(0.4, 0.9, 0.4)
	},
	{
		"id": "soul_siphon",
		"name": "Soul Harvester",
		"rarity": "Rare",
		"description": "Enemies yield +60% more Gold and Soul Echoes.",
		"color": Color(0.2, 0.9, 0.8)
	},
	{
		"id": "thorns_of_bone",
		"name": "Ossuary Thorns",
		"rarity": "Common",
		"description": "Reflect 50% of received damage back to attackers.",
		"color": Color(0.7, 0.7, 0.7)
	},
	{
		"id": "knight_crest",
		"name": "Knight's Royal Crest",
		"rarity": "Legendary",
		"description": "The Crown's blessing grants +15% damage reduction and +30 Max HP.",
		"color": Color(0.95, 0.82, 0.25)
	},
	{
		"id": "tidecaller_compass",
		"name": "Tidecaller's Compass",
		"rarity": "Legendary",
		"description": "Corsair relic of Port Blackwater: +15% Movement Speed and +15% Critical Strike Chance.",
		"color": Color(0.18, 0.75, 0.95)
	},
	{
		"id": "living_heartwood",
		"name": "Living Heartwood",
		"rarity": "Legendary",
		"description": "Ancient Druidic seed of Whisperwood: +40 Max HP and passively regenerates 2 HP every second.",
		"color": Color(0.25, 0.88, 0.35)
	},
	{
		"id": "runebound_core",
		"name": "Runebound Mountain Core",
		"rarity": "Legendary",
		"description": "Ancestral Dwarven relic of Khar-Drakken: +25% Attack Damage and +6 Defense.",
		"color": Color(1.0, 0.55, 0.15)
	},
	{
		"id": "tri_seal_mastery",
		"name": "Tri-Seal of the Realm",
		"rarity": "Mythic",
		"description": "Unites Sea, Forest, and Mountain: +30% to all attributes and unseals the Abyssal Crypts!",
		"color": Color(0.85, 0.35, 1.0)
	}
]

static func get_random_boons(count: int = 3) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for b in BOONS:
		if not GameManager.has_boon(b.id):
			available.append(b)
			
	# If player has collected almost all, allow duplicates/upgrades
	if available.size() < count:
		available = BOONS.duplicate()
		
	available.shuffle()
	var result: Array[Dictionary] = []
	for i in range(mini(count, available.size())):
		result.append(available[i])
	return result
