class_name GameData
extends RefCounted
## Acesso ao conteúdo do jogo. Os dados ficam em res://data/content.tres (e os roteiros em res://data/calls/),
## editáveis no inspetor do Godot. Veja GameContent.

# static var (e não const + preload): assim o analisador usa os tipos declarados em GameContent.
static var CONTENT: GameContent = load("res://data/content.tres")


## Um item ao acaso (PackedStringArray não tem pick_random).
static func pick(list: PackedStringArray) -> String:
	return list[randi() % list.size()] if not list.is_empty() else ""


static func street(id: String) -> Street:
	for s in CONTENT.streets:
		if s.id == id:
			return s
	return null


## Contato da lista telefônica pelo número (nulo se não existir).
static func entry(number: String) -> DirectoryEntry:
	for e in CONTENT.directory:
		if e.number == number:
			return e
	return null


static func transfers(group: int) -> Array:
	return CONTENT.transfers.filter(func(t): return t.group == group)


## Números com tomada na mesa (polícia, bombeiros e hospital vão pelo despacho).
static func board_numbers() -> Array:
	return CONTENT.directory.filter(func(e): return not e.dispatch_only).map(func(e): return int(e.number))


static func is_closed(number: int) -> bool:
	var e := entry(str(number))
	return e != null and e.closed_at_night
