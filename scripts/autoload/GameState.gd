extends Node

# ─── Estado da run atual ───────────────────────────────────────────────
var current_run := {
	"character": "",
	"floor": 1,
	"rooms_cleared": 0,
}

# ─── Progressão persistente (entre runs) ───────────────────────────────
var death_count: int = 0
var lore_fragments: Array[String] = []
var unlocked_characters: Array[String] = ["lucas"]

# Emitido para a UI mostrar o fragmento de lore na tela de morte
signal lore_unlocked(fragment: String)

func start_run(character: String) -> void:
	current_run = {
		"character": character,
		"floor": 1,
		"rooms_cleared": 0,
	}

func on_player_death() -> void:
	death_count += 1
	_try_unlock_lore()

func room_cleared() -> void:
	current_run["rooms_cleared"] += 1

# ─── Sistema de lore (estilo Hades: morte revela história) ─────────────
func _try_unlock_lore() -> void:
	var pool: Array[String] = [
		"[%d mortes] Lucas: 'gg wp zumbi. gg wp.'" % death_count,
		"[%d mortes] Ana: 'vc chegou no ponto de encontro?? responde'" % death_count,
		"[%d mortes] Lucas ligou pra vó três vezes. Nenhuma resposta." % death_count,
		"[%d mortes] Renato: 'alguém mais acha estranho que a internet tá ok mas o telefone não?'" % death_count,
		"[%d mortes] A vó não estava no quarto quando Lucas voltou do PC." % death_count,
	]
	if death_count > pool.size():
		return
	var fragment := pool[death_count - 1]
	if lore_fragments.has(fragment):
		return
	lore_fragments.append(fragment)
	emit_signal("lore_unlocked", fragment)
