class_name Zombie
extends EnemyBase

func _ready() -> void:
	max_hp        = 50
	move_speed    = 50.0
	damage        = 12
	attack_range  = 28.0
	detection_range = 200.0
	attack_cooldown = 1.5
	super._ready()
