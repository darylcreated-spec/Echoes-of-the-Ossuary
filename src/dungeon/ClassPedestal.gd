extends Node3D
class_name ClassPedestal

@export var hero_class: GameManager.HeroClass = GameManager.HeroClass.KNIGHT

func interact(_player: Node3D) -> void:
	AudioManager.play_sfx("sword_swing", 0.05, 1.5)
	CombatJuice.add_trauma(0.1)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1.0, 0), Color(0.2, 0.9, 1.0))
	GameManager.set_hero_class(hero_class)
