class_name Room
extends Node2D

enum Type { START, NORMAL, ITEM, BOSS }

@export var room_type: Type = Type.NORMAL

@onready var enemies_root: Node2D = $Enemies

var enemies_alive: int = 0
var cleared: bool = false

signal room_cleared

func _ready() -> void:
	_count_enemies()
	if room_type == Type.START or enemies_alive == 0:
		_on_all_enemies_dead()

func _count_enemies() -> void:
	if not is_instance_valid(enemies_root):
		return
	for child in enemies_root.get_children():
		if child is EnemyBase:
			enemies_alive += 1
			child.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: EnemyBase) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	if enemies_alive == 0:
		_on_all_enemies_dead()

func _on_all_enemies_dead() -> void:
	if cleared:
		return
	cleared = true
	emit_signal("room_cleared")
	GameState.room_cleared()
	# TODO: abrir portas (chamar Door.set_locked(false))
