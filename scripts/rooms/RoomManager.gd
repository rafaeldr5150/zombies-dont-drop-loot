extends Node

const GRID       := 5
const MIN_ROOMS  := 6
const MAX_ROOMS  := 10
const ROOM_SIZE  := Vector2(320.0, 192.0)  # pixels por sala (20 x 12 tiles de 16px)

# Popule conforme criar as salas no editor
const ROOM_SCENES := {
	"start":  "res://scenes/rooms/RoomStart.tscn",
	"normal": "res://scenes/rooms/RoomNormal.tscn",
	"item":   "res://scenes/rooms/RoomItem.tscn",
	"boss":   "res://scenes/rooms/RoomBoss.tscn",
}

var layout: Array    = []          # [x][y] -> tipo (String) ou ""
var instances: Dictionary = {}     # Vector2i -> Room node
var current: Vector2i

@onready var rooms_root: Node2D = $"../World/RoomsContainer"

func _ready() -> void:
	generate_floor()

# ─── Geração procedural ────────────────────────────────────────────────
func generate_floor() -> void:
	_clear()
	_build_layout()
	_spawn_room(Vector2i(GRID / 2, GRID / 2))

func _clear() -> void:
	for child in rooms_root.get_children():
		child.queue_free()
	instances.clear()
	layout = []
	for x in GRID:
		layout.append([])
		for _y in GRID:
			layout[x].append("")

func _build_layout() -> void:
	var start := Vector2i(GRID / 2, GRID / 2)
	layout[start.x][start.y] = "start"

	var placed   := [start]
	var frontier := _neighbors(start)
	var target   := randi_range(MIN_ROOMS, MAX_ROOMS)

	# Random walk para espalhar salas
	while placed.size() < target and not frontier.is_empty():
		var idx: int       = randi() % frontier.size()
		var coord: Vector2i = frontier[idx]
		frontier.remove_at(idx)

		if layout[coord.x][coord.y] != "":
			continue

		layout[coord.x][coord.y] = "normal"
		placed.append(coord)
		for n in _neighbors(coord):
			if layout[n.x][n.y] == "":
				frontier.append(n)

	# Dead ends viram salas especiais
	var dead_ends: Array = []
	for coord in placed:
		if coord == start:
			continue
		var filled := 0
		for n in _neighbors(coord):
			if layout[n.x][n.y] != "":
				filled += 1
		if filled == 1:
			dead_ends.append(coord)

	# A mais distante vira sala do boss; a segunda vira sala de item
	dead_ends.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (Vector2(a) - Vector2(start)).length() > (Vector2(b) - Vector2(start)).length()
	)
	if dead_ends.size() >= 1:
		layout[dead_ends[0].x][dead_ends[0].y] = "boss"
	if dead_ends.size() >= 2:
		layout[dead_ends[1].x][dead_ends[1].y] = "item"

# ─── Instanciação de salas ─────────────────────────────────────────────
func _spawn_room(coord: Vector2i) -> void:
	if instances.has(coord):
		return
	var tipo: String = layout[coord.x][coord.y]
	if tipo == "":
		return
	var path: String = ROOM_SCENES.get(tipo, ROOM_SCENES["normal"])
	if not ResourceLoader.exists(path):
		push_warning("Cena de sala não encontrada: " + path)
		return
	var room: Room = (load(path) as PackedScene).instantiate()
	rooms_root.add_child(room)
	room.position = Vector2(coord.x, coord.y) * ROOM_SIZE
	room.room_cleared.connect(_on_room_cleared.bind(coord))
	instances[coord] = room
	current = coord

func _on_room_cleared(coord: Vector2i) -> void:
	# Pré-carrega salas vizinhas ao limpar a sala atual
	for n in _neighbors(coord):
		if layout[n.x][n.y] != "" and not instances.has(n):
			_spawn_room(n)

func go_to_room(direction: String) -> void:
	var offsets := {
		"north": Vector2i(0, -1),
		"south": Vector2i(0,  1),
		"west":  Vector2i(-1, 0),
		"east":  Vector2i( 1, 0),
	}
	var next := current + offsets.get(direction, Vector2i.ZERO)
	if not instances.has(next):
		_spawn_room(next)
	if instances.has(next):
		current = next
		# TODO: transição de câmera + reposicionar player na porta de entrada

# ─── Utilitário ────────────────────────────────────────────────────────
func _neighbors(c: Vector2i) -> Array:
	var result := []
	for d in [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]:
		var n := c + d
		if n.x >= 0 and n.x < GRID and n.y >= 0 and n.y < GRID:
			result.append(n)
	return result
