class_name EnemyBase
extends CharacterBody2D

@export var max_hp: int = 50
@export var move_speed: float = 55.0
@export var damage: int = 10
@export var attack_range: float = 30.0
@export var detection_range: float = 220.0
@export var attack_cooldown: float = 1.2

var hp: int
var state: String = "idle"
var player: Node2D = null

var _attack_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

signal died(enemy: EnemyBase)

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

func _physics_process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	match state:
		"idle":   _state_idle()
		"chase":  _state_chase()
		"attack": _state_attack()

func _state_idle() -> void:
	velocity = Vector2.ZERO
	if is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= detection_range:
			state = "chase"

func _state_chase() -> void:
	if not is_instance_valid(player):
		state = "idle"
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= attack_range:
		state = "attack"
		return
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	if is_instance_valid(sprite) and dir.x != 0:
		sprite.flip_h = dir.x < 0
	move_and_slide()

func _state_attack() -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(player):
		state = "idle"
		return
	if global_position.distance_to(player.global_position) > attack_range * 1.5:
		state = "chase"
		return
	if _attack_timer <= 0.0:
		_do_attack()
		_attack_timer = attack_cooldown

func _do_attack() -> void:
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(damage)

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		_die()

func _die() -> void:
	emit_signal("died", self)
	# Intencional: zumbis não dão drop de nada.
	# Este é o "Erro Fatal" central do jogo — a realidade não segue as regras dos games.
	queue_free()
