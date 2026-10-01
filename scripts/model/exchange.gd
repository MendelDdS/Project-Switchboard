class_name Exchange
extends RefCounted
## Estado das linhas (entradas 01–10) e dos números de destino da central. É o único dono desse estado:
## a mesa só lê para acender as lâmpadas; o fluxo das ligações (Main) muda por aqui.

enum Line { FREE, RING, TALK, HOLD, CONN, DONE }
enum Dest { FREE, RING, CONN, DONE }

const LINES := 10
const LINE_LABEL := [T.Key.EX_LINE_FREE, T.Key.EX_LINE_RING, T.Key.EX_LINE_TALK, T.Key.EX_LINE_HOLD, T.Key.EX_LINE_CONN, T.Key.EX_LINE_DONE]
const DEST_LABEL := [T.Key.EX_DEST_FREE, T.Key.EX_DEST_RING, T.Key.EX_DEST_CONN, T.Key.EX_DEST_DONE]

var _lines: Array[int] = []
var _until: Array[float] = []   ## fim da conversa conectada (minuto de jogo); -1 = sem prazo
var _dests := {}                ## número (int) -> Dest


## `numbers`: números da lista telefônica que têm tomada na mesa.
func _init(numbers: Array) -> void:
	for i in LINES:
		_lines.append(Line.FREE)
		_until.append(-1.0)
	for n in numbers:
		_dests[int(n)] = Dest.FREE


func line(n: int) -> int:
	return _lines[n - 1]


func set_line(n: int, st: int, until := -1.0) -> void:
	_lines[n - 1] = st
	_until[n - 1] = until


func line_until(n: int) -> float:
	return _until[n - 1]


func dest_numbers() -> Array:
	var out := _dests.keys()
	out.sort()
	return out


func has_dest(d: int) -> bool:
	return _dests.has(d)


func dest(d: int) -> int:
	return _dests.get(d, Dest.FREE)


func set_dest(d: int, st: int) -> void:
	_dests[d] = st


func line_label(n: int) -> String:
	return T.text(LINE_LABEL[line(n)])


func dest_label(d: int) -> String:
	return T.text(DEST_LABEL[dest(d)])
