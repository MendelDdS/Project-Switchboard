class_name GameData
extends RefCounted
## Acesso ao conteúdo do jogo. Os dados ficam em res://data/content.tres (e os roteiros em res://data/calls/),
## editáveis no inspetor do Godot. Veja GameContent.

const CONTENT: GameContent = preload("res://data/content.tres")

# ponytail: formato antigo (dicionários) mantido só até o fluxo passar a usar os Resources direto.
static var CALL_AT: Array = Array(CONTENT.main_call_at)
static var DIR: Array = _dir()
static var CLOSED: Array = _closed()
static var SMALLTALK: Array = Array(CONTENT.smalltalk)
static var WAITING: Array = Array(CONTENT.waiting)
static var EM_WAITING: Array = Array(CONTENT.emergency_waiting)
static var HOLD_OK: Array = Array(CONTENT.hold_ok)
static var WRONG_DEST: Array = Array(CONTENT.wrong_destination)
static var T1: Array = _transfers(TransferCall.Group.ESTABLISHMENT)
static var T2: Array = _transfers(TransferCall.Group.PERSON)
static var FILL: Array = _transfers(TransferCall.Group.EXTRA)
static var INFO_VOICES: Array = Array(CONTENT.info_callers).map(func(s: String): return Array(s.split(":")))
static var INFO_NUM: Array = _info_num()
static var ASK_NUM: Array = Array(CONTENT.ask_number)
static var ASK_TIME: Array = Array(CONTENT.ask_time)
static var INFO_OK: Array = Array(CONTENT.info_thanks)
static var INFO_BAD: Array = Array(CONTENT.info_doubt)
static var EM: Array = _emergencies()
static var TR: Array = _pranks()
static var STREETS: Array = _streets()
static var BLK: Array = Array(CONTENT.block_labels)
static var OCC: Array = Array(CONTENT.occurrences)

const UNAME := {"pol": "Polícia", "bomb": "Bombeiros", "amb": "Ambulância"}
const LINE_LABEL := {"free": "livre", "ring": "chamando", "talk": "em linha", "hold": "em espera", "conn": "conectada", "done": "desligou", "ghost": "DESCONHECIDO"}
const DEST_LABEL := {"free": "livre", "ring": "tocando", "conn": "conectado", "done": "desligou"}


static func street(id: String) -> Dictionary:
	for s in STREETS:
		if s["id"] == id:
			return s
	return {}


static func find_number(num: String) -> Dictionary:
	for d in DIR:
		if d["num"] == num:
			return d
	return {}


static func _dir() -> Array:
	return CONTENT.directory.map(func(e: DirectoryEntry): return {"n": e.name, "s": e.note, "a": e.address, "num": e.number})


static func _closed() -> Array:
	return CONTENT.directory.filter(func(e: DirectoryEntry): return e.closed_at_night).map(func(e: DirectoryEntry): return int(e.number))


static func _info_num() -> Array:
	return CONTENT.directory.filter(func(e: DirectoryEntry): return e.spoken != "").map(func(e: DirectoryEntry): return [e.spoken, e.number])


static func _transfers(g: int) -> Array:
	var out := []
	for t in CONTENT.transfers:
		if t.group != g:
			continue
		var d := {"voice": t.voice, "caller": t.caller, "open": Array(t.opening), "repeat": t.repeat, "target": t.target, "dest": t.destination, "thanks": t.thanks}
		if t.alt_target != "":
			d.merge({"alt": t.alt_target, "alt_dest": t.alt_destination, "alt_ask": t.alt_ask, "alt_yes": t.alt_yes})
		out.append(d)
	return out


static func _emergencies() -> Array:
	var out := []
	for e in CONTENT.emergencies:
		var q := []
		for i in e.questions.size():
			q.append([e.questions[i], e.answers[i]])
		out.append({"voice": e.voice, "caller": e.caller, "open": e.opening, "q": q, "street": e.street, "block": e.block,
			"addr": e.address, "type": e.occurrence, "req": Array(e.units), "after": e.after})
	return out


static func _pranks() -> Array:
	var out := []
	for p in CONTENT.pranks:
		var steps := []
		for st in p.steps:
			match st.kind:
				PrankStep.Kind.CALLER: steps.append(["c", st.text])
				PrankStep.Kind.OPERATOR: steps.append(["o", Array(st.options)])
				PrankStep.Kind.PAUSE: steps.append(["p", st.seconds])
				PrankStep.Kind.END: steps.append(["end"])
		out.append({"voice": p.voice, "caller": p.caller, "fake": p.fake_address, "steps": steps})
	return out


static func _streets() -> Array:
	return CONTENT.streets.map(func(s: Street): return {"id": s.id, "name": s.name, "o": "h" if s.horizontal else "v", ("y" if s.horizontal else "x"): s.pos})
