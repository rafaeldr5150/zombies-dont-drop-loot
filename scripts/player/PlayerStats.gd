class_name PlayerStats
extends Resource

@export var character_name: String = "Joey"  # ZeroRespawn online

# Vida
@export var max_hp: int = 100
@export var hp: int = 100

# Munição
@export var max_ammo: int = 12
@export var ammo: int = 12

# Combate
@export var melee_damage: int = 15
@export var ranged_damage: int = 25

# Movimentação
@export var walk_speed: float = 100.0
@export var sprint_speed: float = 180.0
@export var sprint_stamina_max: float = 3.0

var sprint_stamina: float

func _init() -> void:
	sprint_stamina = sprint_stamina_max
