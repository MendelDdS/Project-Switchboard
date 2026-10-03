class_name GameData
extends RefCounted
## Acesso ao conteúdo do jogo. Os dados ficam em res://data/content.tres (e os roteiros em res://data/calls/),
## editáveis no inspetor do Godot. Veja GameContent.

# static var (e não const + preload): assim o analisador usa os tipos declarados em GameContent.
static var CONTENT: GameContent = load("res://data/content.tres")

## A cidade tem três setores; o de um número é o primeiro dígito (3xx, 1xx, 2xx). O operador começa com o setor 3 e
## recebe os outros em noites fixas: setor -> noite da entrega.
const SECTOR_NIGHTS := {3: 1, 1: 5, 2: 9}
## Setores atendidos no turno atual (Main define ao carregar a noite); a mesa, a lista e as ligações só usam os
## números deles. Polícia, bombeiros e hospital (despacho) valem para a cidade toda.
static var sectors: Array = [1, 2, 3]


static func sectors_for(night: int) -> Array:
	return SECTOR_NIGHTS.keys().filter(func(s): return night >= SECTOR_NIGHTS[s])


static func in_service(number: String) -> bool:
	return number != "" and int(number.left(1)) in sectors


## A transferência pede só números dos setores atendidos (o pedido e a alternativa).
static func serves(t: TransferCall) -> bool:
	return in_service(t.target) and (t.alt_target == "" or in_service(t.alt_target))


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
	if template == "":
		return ""   # traduzir "" devolve o cabeçalho do .po
	var s := String(TranslationServer.translate(template)).format(vars)
	return s.left(1).to_upper() + s.substr(1)


## Transferência montada a partir de um molde, para um contato dos setores atendidos fora de `exclude` (números já
## usados no turno). Nulo se não sobrar nenhum.
static func template_transfer(exclude: Array = []) -> TransferCall:
	var places := CONTENT.directory.filter(func(d: DirectoryEntry):
		return d.spoken != "" and not d.reasons.is_empty() and not d.dispatch_only and in_service(d.number))
	var fresh := places.filter(func(d: DirectoryEntry): return not d.number in exclude)
	if fresh.is_empty():
		return null   # todos os lugares já foram pedidos nesta noite
	var e: DirectoryEntry = fresh.pick_random()
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


## Emergência montada a partir de um molde (`from`, ou um sorteado), numa rua (dos setores atendidos) e número sorteados.
static func template_emergency(from: EmergencyCall = null) -> EmergencyCall:
	var tpl := with_case(from if from != null else CONTENT.emergency_templates.pick_random())
	var spots := []   # [rua, trecho] dos setores atendidos
	for s: Street in CONTENT.streets:
		for b in s.blocks():
			if s.block_sector(b) in sectors:
				spots.append([s, b])
	var spot: Array = spots.pick_random()
	var st: Street = spot[0]
	var house := int(spot[1]) * 100 + randi_range(1 if spot[1] == 0 else 0, 99)
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
	e.stage_sec = tpl.stage_sec
	e.worsening = fill(tpl.worsening, vars)
	e.worsening_units = tpl.worsening_units
	e.critical = fill(tpl.critical, vars)
	e.critical_units = tpl.critical_units
	e.lost = fill(tpl.lost, vars)
	e.worsening_question = tpl.worsening_question
	e.worsening_answer = fill(tpl.worsening_answer, vars)
	e.critical_question = tpl.critical_question
	e.critical_answer = fill(tpl.critical_answer, vars)
	e.lost_answer = fill(tpl.lost_answer, vars)
	e.lost_units = tpl.lost_units
	return e


## Sorteia um dos casos da emergência (`cases`): as respostas do caso trocam as do roteiro e as unidades
## passam a ser as dele. Sem casos, devolve a própria emergência.
static func with_case(e: EmergencyCall) -> EmergencyCall:
	if e.cases.is_empty():
		return e
	var k: EmergencyCase = e.cases.pick_random()
	var out: EmergencyCall = e.duplicate()
	var answers := e.answers.duplicate()
	for i in k.answers.size():
		if k.answers[i] != "":
			answers[i] = k.answers[i]
	out.answers = answers
	out.units = k.units
	out.cases = []
	return out


static func transfers(group: int) -> Array:
	return CONTENT.transfers.filter(func(t): return t.group == group and serves(t))


## Números com tomada na mesa (polícia, bombeiros e hospital vão pelo despacho).
static func board_numbers() -> Array:
	return CONTENT.directory.filter(func(e): return not e.dispatch_only and in_service(e.number)).map(func(e): return int(e.number))
