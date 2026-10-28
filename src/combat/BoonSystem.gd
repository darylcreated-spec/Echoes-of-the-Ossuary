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
