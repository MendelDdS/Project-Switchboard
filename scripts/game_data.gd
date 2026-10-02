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


const DIGITS := ["zero", "um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito", "nove"]


## Traduz o molde, preenche as lacunas {x} e põe a primeira letra em maiúscula.
static func fill(template: String, vars: Dictionary) -> String:
	var s := String(TranslationServer.translate(template)).format(vars)
	return s.left(1).to_upper() + s.substr(1)


## Transferência montada a partir de um molde, para um contato fora de `exclude` (números já usados no turno).
static func template_transfer(exclude: Array = []) -> TransferCall:
	var places := CONTENT.directory.filter(func(d: DirectoryEntry):
		return d.spoken != "" and not d.reasons.is_empty() and not d.closed_at_night and not d.dispatch_only)
	var fresh := places.filter(func(d: DirectoryEntry): return not d.number in exclude)
	var e: DirectoryEntry = (fresh if not fresh.is_empty() else places).pick_random()
	var vars := {
		"place": e.spoken, "of_place": "d" + e.spoken, "to_place": "pr" + e.spoken,
		"street": e.address.get_slice(",", 0), "number": e.number,
		"digits": ", ".join(Array(e.number.split("")).map(func(ch: String): return DIGITS[int(ch)])),
		"reason": String(TranslationServer.translate(pick(e.reasons))),
	}
	var tpl: TransferCall = CONTENT.transfer_templates.pick_random()
	var who := pick(CONTENT.callers).split(":")
	var t := TransferCall.new()
	t.group = TransferCall.Group.EXTRA
	t.voice = who[0]
	t.caller = who[1]
	for l in tpl.opening:
		t.opening.append(fill(l, vars))
	t.repeat = fill(tpl.repeat, vars)
	t.target = e.number
	t.destination = e.name
	t.thanks = pick(CONTENT.transfer_thanks)
	return t


## Emergência montada a partir de um molde, numa rua e número sorteados.
static func template_emergency() -> EmergencyCall:
	var tpl: EmergencyCall = CONTENT.emergency_templates.pick_random()
	var st: Street = CONTENT.streets.pick_random()
	var house := randi_range(1, 299)
	var vars := {"street": st.name, "house": house, "address": "%s, %d" % [st.name, house]}
	var who := pick(CONTENT.callers).split(":")
	var e := EmergencyCall.new()
	e.voice = who[0]
	e.caller = who[1]
	e.opening = fill(tpl.opening, vars)
	e.questions = tpl.questions
	for a in tpl.answers:
		e.answers.append(fill(a, vars))
	e.street = st.id
	e.block = floori(house / 100.0)
	e.address = vars["address"]
	e.occurrence = tpl.occurrence
	e.units = tpl.units
	e.after = fill(tpl.after, vars)
	return e


static func transfers(group: int) -> Array:
	return CONTENT.transfers.filter(func(t): return t.group == group)


## Números com tomada na mesa (polícia, bombeiros e hospital vão pelo despacho).
static func board_numbers() -> Array:
	return CONTENT.directory.filter(func(e): return not e.dispatch_only).map(func(e): return int(e.number))


static func is_closed(number: int) -> bool:
	var e := entry(str(number))
	return e != null and e.closed_at_night
