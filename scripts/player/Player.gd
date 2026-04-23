extends CharacterBody2D

var stats: PlayerStats

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _sprinting: bool = false
var _sprint_cooldown: float = 0.0

signal died
signal stats_changed(stats: PlayerStats)

func _ready() -> void:
	add_to_group("player")
	stats = PlayerStats.new()

func _physics_process(delta: float) -> void:
	_handle_sprint_stamina(delta)
	_handle_movement()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_melee_attack()

# ─── Movimentação ──────────────────────────────────────────────────────
func _handle_movement() -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT)  or Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): dir.x += 1
	if Input.is_key_pressed(KEY_UP)    or Input.is_key_pressed(KEY_W): dir.y -= 1
	if Input.is_key_pressed(KEY_DOWN)  or Input.is_key_pressed(KEY_S): dir.y += 1
	dir = dir.normalized()

	_sprinting = Input.is_key_pressed(KEY_SHIFT) and stats.sprint_stamina > 0.0
	velocity = dir * (stats.sprint_speed if _sprinting else stats.walk_speed)

	if dir.x != 0:
		sprite.flip_h = dir.x < 0

	move_and_slide()

func _handle_sprint_stamina(delta: float) -> void:
	if _sprinting:
		stats.sprint_stamina = max(0.0, stats.sprint_stamina - delta)
		_sprint_cooldown = 1.0
	else:
		if _sprint_cooldown > 0.0:
			_sprint_cooldown -= delta
		else:
			stats.sprint_stamina = min(stats.sprint_stamina_max, stats.sprint_stamina + delta * 0.8)

# ─── Combate ───────────────────────────────────────────────────────────
func _melee_attack() -> void:
	var attack_offset := Vector2(32.0 if not sprite.flip_h else -32.0, 0.0)
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + attack_offset
	query.collision_mask = 2  # layer dos inimigos
	for hit in space.intersect_point(query, 4):
		if hit["collider"].has_method("take_damage"):
			hit["collider"].take_damage(stats.melee_damage)

func take_damage(amount: int) -> void:
	if stats.hp <= 0:
		return
	stats.hp = max(0, stats.hp - amount)
	emit_signal("stats_changed", stats)
	if stats.hp <= 0:
		_die()

func _die() -> void:
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	emit_signal("died")
	GameState.on_player_death()
	# TODO: tocar animação de morte, depois mostrar tela com fragmento de lore
