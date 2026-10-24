class_name Bureaucracy
extends Node
## O gerente das burocracias (nó filho de Main): carrega as regras de `data/bureaucracy/` (`BureaucracyRule`, uma por
## `.tres`), repassa a elas os ganchos do ciclo da ligação e resolve, num lugar só, o que elas dizem de cada tentativa
## de transferência: todas as infrações vão para o registro de decisões (`decisions`), só a maior vira advertência
## (também contra o número errado da mesma tentativa, `wrong_number`). Não conhece nenhuma regra pelo nome.
## Com a chave geral desligada (`enabled`, o padrão), todo gancho volta na primeira linha: o jogo é o de sempre (nem
## o sorteio muda).
##
## Roteiro: `main.bureaucracy.enable(true)` e `activate("id")`; `deactivate`, `update_params`. Uma regra que passa a
## valer com o turno andando começa na hora (`sync`: as fitas da B4, os equipamentos), venha de onde vier o "ligar".

signal decided(entry: Dictionary)   ## uma decisão nova no registro (o painel de debug atualiza)
## Um equipamento chegou na mesa, uma vez só (o gancho para o roteiro encenar a chegada: a fala do supervisor, a
## instalação); `equipment_changed` a cada vez que a lista muda (a mesa redesenha).
signal equipment_unlocked(id: String)
signal equipment_changed

const DIR := "res://data/bureaucracy/"
const AuthCodes := preload("res://scripts/bureaucracy/auth_codes.gd")
const MessageQueue := preload("res://scripts/bureaucracy/message_queue.gd")
const Agreements := preload("res://scripts/bureaucracy/agreements.gd")
const Tapes := preload("res://scripts/bureaucracy/tapes.gd")
const EQUIPMENT := "equipamento_"   ## o marcador (`StoryFlags`, salvo) de cada equipamento liberado: "equipamento_gravador"

## A chave geral. Só o debug liga, por enquanto; o roteiro vai ligar nas noites das burocracias.
static var enabled := false
## As regras desta sessão (cópias dos `.tres`: o que o debug muda vale até fechar o jogo, também na troca de noite).
static var _rules: Array[BureaucracyRule] = []
static var _loaded := false
## Os parâmetros mudados por `update_params` ({id: {campo: valor}}), salvos com o resto (os do debug, que mexe direto
## na regra, não).
static var _params := {}

var night := 0   ## a noite em que as regras se conferem (a do Main; o debug simula outras, `set_night`)
var _begun := {}   ## id -> a regra já começou nesta noite (`night_started`, `sync`)
## O registro de decisões: {"night", "time", "who", "rule", "choice", "result"}, desta noite e das anteriores
## (`Progress.bureaucracy`). Para as consequências do roteiro e o interrogatório das autoridades.
var decisions: Array[Dictionary] = []
## Serviços que qualquer regra pode usar (cada um troca sem mexer nas regras).
var codes: AuthCodes = load("res://data/bureaucracy/services/auth_codes.tres")   ## os códigos de autorização de cada noite
var messages := MessageQueue.new()   ## os recados esperando quem vai recebê-los
var agreements := Agreements.new()   ## os acordos de redirecionamento que o operador aceitou
var tapes := Tapes.new(self)   ## as fitas da noite e a que está no gravador

@onready var main: Main = get_parent()


func _ready() -> void:
	night = main.night_no
	if main.progress != null:
		decisions.assign(main.progress.bureaucracy.get("decisions", []))
		messages.items.assign(main.progress.bureaucracy.get("messages", []))
		agreements.items.assign(main.progress.bureaucracy.get("agreements", []))
	var first := not _loaded
	for r in rules():
		r.desk = self
	if first and main.progress != null:   # o que o roteiro ligou fica de uma sessão para outra; depois, valem as da sessão
		_restore(main.progress.bureaucracy)


## O gerente da cena de `n` (os equipamentos da mesa o acham assim).
static func of(n: Node) -> Bureaucracy:
	while n != null and not n is Main:
		n = n.get_parent()
	return (n as Main).bureaucracy if n != null else null


## Todas as regras registradas, ligadas ou não.
static func rules() -> Array[BureaucracyRule]:
	if not _loaded:
		_loaded = true
		if DirAccess.dir_exists_absolute(DIR):
			for f in ResourceLoader.list_directory(DIR):
				var r := load(DIR + f) as BureaucracyRule if f.ends_with(".tres") else null
				if r != null:
					_rules.append(r.duplicate(true))
	return _rules


## O que fica salvo para as noites seguintes (`Progress.bureaucracy`): o registro, os serviços e o que o roteiro ligou
## (a chave geral, as regras ligadas e os parâmetros de `update_params`).
func state() -> Dictionary:
	return {"decisions": decisions, "messages": messages.items, "agreements": agreements.items, "enabled": enabled,
		"active": rules().filter(func(r: BureaucracyRule): return r.active).map(func(r: BureaucracyRule): return r.id),
		"params": _params}


## Volta o que o roteiro tinha ligado (`state`); regra salva que não existe mais é ignorada. Save sem isso (de antes,
## ou novo): ficam as dos `.tres`.
func _restore(saved: Dictionary) -> void:
	if not saved.has("active"):
		return
	enabled = saved.get("enabled", false)
	var on: Array = saved.get("active", [])
	_params = saved.get("params", {}).duplicate(true)
	for r in rules():
		r.active = r.id in on
		for k: String in _params.get(r.id, {}):
			r.set(k, _params[r.id][k])


## Uma regra a mais nesta sessão (testes; a de mesmo `id` sai).
func register(r: BureaucracyRule) -> void:
	_rules.assign(rules().filter(func(x: BureaucracyRule): return x.id != r.id))
	_rules.append(r)
	r.desk = self


## Debug e testes: as regras voltam a ser as dos `.tres`, desligadas, e a chave geral desliga.
func reset() -> void:
	_rules.clear()
	_loaded = false
	_params = {}
	enabled = false
	_begun.clear()
	for r in rules():
		r.desk = self


func rule(id: String) -> BureaucracyRule:
	for r in rules():
		if r.id == id:
			return r
	push_error("burocracia desconhecida: " + id)
	return null


## A chave geral.
func enable(on: bool) -> void:
	enabled = on
	sync()


## Liga a regra (se valer agora, começa na hora: `sync`).
func activate(id: String) -> void:
	rule(id).active = true
	sync()


## Debug: confere as regras como se fosse a noite `n`.
func set_night(n: int) -> void:
	night = n
	sync()


## As regras que passaram a valer chegam: os equipamentos delas e, com o turno andando, o começo da noite delas (uma
## vez por noite: as fitas da B4).
func sync() -> void:
	arrive()
	if not main.running:
		return
	for r in live():
		if not _begun.has(r.id):
			_begun[r.id] = true
			r.night_started()


func deactivate(id: String) -> void:
	var r := rule(id)
	r.active = false
	if not r.keep_equipment:
		for e in r.equipment:
			lock_equipment(e)


## Os equipamentos das regras que valem agora chegam na mesa (os que já chegaram ficam como estão).
func arrive() -> void:
	for r in live():
		for e in r.equipment:
			unlock_equipment(e)


# ---------------------------------------------------------------- equipamentos da mesa

## Os equipamentos liberados (salvos nos marcadores; a mesa mostra cada um, `Switchboard.set_equipment`).
func equipment() -> PackedStringArray:
	return PackedStringArray(Array(main.flags.names()).filter(func(f: String): return f.begins_with(EQUIPMENT)).map(
		func(f: String): return f.trim_prefix(EQUIPMENT)))


func is_unlocked(id: String) -> bool:
	return main.flags.has(EQUIPMENT + id)


func unlock_equipment(id: String) -> void:
	if is_unlocked(id):
		return
	main.flags.apply(EQUIPMENT + id)
	equipment_unlocked.emit(id)
	equipment_changed.emit()


## O equipamento sai da mesa (o roteiro, ou o debug); liberado de novo, chega de novo.
func lock_equipment(id: String) -> void:
	if not is_unlocked(id):
		return
	main.flags.apply("!" + EQUIPMENT + id)
	equipment_changed.emit()


## Todos os equipamentos que as regras registradas trazem.
func all_equipment() -> PackedStringArray:
	var out := PackedStringArray()
	for r in rules():
		for e in r.equipment:
			if not e in out:
				out.append(e)
	return out


## Muda os parâmetros da regra: {"campo": valor} (as `@export` do script dela).
func update_params(id: String, params: Dictionary) -> void:
	var r := rule(id)
	for k: String in params:
		r.set(k, params[k])
	_params[id] = _params.get(id, {}).merged(params, true)


## As regras que valem agora (nenhuma com a chave geral desligada).
func live() -> Array[BureaucracyRule]:
	var out: Array[BureaucracyRule] = []
	if enabled:
		out.assign(rules().filter(func(r: BureaucracyRule): return r.applies(night)))
	return out


## Uma decisão do operador (ou o que o sistema registrou por ele) no registro.
func log_decision(rule_id: String, c: PhoneCall, choice: String, result: String) -> void:
	var e := {"night": night, "time": Main.fmt(main.minutes), "who": main.supervisor.who(c) if c != null else "—",
		"rule": rule_id, "choice": choice, "result": result}
	decisions.append(e)
	decided.emit(e)


## A fala do código de autorização de quem liga (`TransferCall.code_line`, com o da noite no lugar de {code}), uma
## vez por ligação, para a regra que pedir primeiro (`request_made`); vazio se não tem ou já disse. Quem só lembra
## quando o operador pede (`TransferCall.code_when_asked`) só diz com `asked`.
func code_line(c: PhoneCall, asked := false) -> Array:
	var t := c.data as TransferCall
	if t == null or t.code_line == "" or c.meta.has("code_said") or (t.code_when_asked and not asked):
		return []
	c.meta["code_said"] = true
	return [GameData.fill(t.code_line, {"code": codes.code(night)})]


## O código que quem liga disse: 1 o certo desta noite, 0 um errado, -1 nenhum (não tem ou ainda não disse).
func code_of(c: PhoneCall) -> int:
	var t := c.data as TransferCall
	if t == null or not c.meta.has("code_said"):
		return -1
	return 1 if t.code_line.contains("{code}") else 0


## A reação de quem liga ao "não" do operador: a dele (`TransferCall.refused_line`) ou uma de `pool`, sorteada.
func refusal(c: PhoneCall, pool: PackedStringArray) -> String:
	var own: String = c.data.refused_line if c.data is TransferCall else ""
	return own if own != "" or pool.is_empty() else pool[randi() % pool.size()]


## Uma advertência fora da tentativa de transferência (um recado repassado...), com o registro: a regra `r` diz a
## gravidade `sev` e o texto `text` (`T.Key`).
func penalize(r: BureaucracyRule, c: PhoneCall, sev: ShiftReport.Severity, why: String, text: int) -> void:
	log_decision(r.id, c, why, "advertência %s" % T.text(ShiftReport.SEVERITY_NAMES[sev]).to_lower())
	if c == null or not c.lesson:
		main.supervisor.fault(r.id, why, sev, text)


# ---------------------------------------------------------------- ganchos (chamados pelo Main e pela Conversation)

func night_started() -> void:
	arrive()
	for r in live():
		_begun[r.id] = true
		r.night_started()


func night_ended() -> void:
	for r in live():
		r.night_ended()


## Depois do "alô" do operador: as falas que as regras pedem (`BureaucracyRule.call_started`). Falso se a ligação
## acabou no meio.
func call_started(c: PhoneCall) -> bool:
	var lines := []
	for r in live():
		lines.append_array(r.call_started(c))
	return await _speak(c, lines)


## Depois do pedido de transferência (`BureaucracyRule.request_made`).
func request_made(c: PhoneCall) -> bool:
	var lines := []
	for r in live():
		lines.append_array(r.request_made(c))
	return await _speak(c, lines)


## Diz as falas `lines` em ordem: texto de quem liga, {"op"} do operador, {"sys"} aviso, {"named"} o nome que quem
## liga acabou de dizer (`PhoneCall.named`), {"snaps": ritmo} estalos de dedo (`Conversation.snaps`). Falso se a ligação acabou.
func _speak(c: PhoneCall, lines: Array) -> bool:
	for l in lines:
		if l is String:
			if not await main.conversation.say(c, l):
				return false
		elif l.has("op"):
			if not await main.conversation.op(c, l["op"]):
				return false
		elif l.has("named"):
			c.named = l["named"]
		elif l.has("snaps"):
			if not await main.conversation.snaps(c, l["snaps"]):
				return false
		else:
			c.sys(l["sys"])
	return not c.ended


## Quem liga diz `line` (se tiver) e desliga: a resposta a uma decisão do operador (o recado recusado, o acordo).
func hang_up_after(c: PhoneCall, line: String) -> void:
	if line != "" and not await main.conversation.say(c, line):
		return
	if not c.ended:
		c.sys(T.text(T.Key.SYS_CALLER_HUNG_UP))
		main.end_call(c, PhoneCall.End.CALLER)


func choices(c: PhoneCall) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in live():
		out.append_array(r.choices(c))
	return out


## O operador apertou Transferir para `d`: cada regra diz o que acha; todas vão para o registro e a infração mais
## grave vira a advertência desta tentativa (guardada na ligação para o número errado não somar outra, `wrong_number`).
func before_transfer(c: PhoneCall, d: int) -> void:
	c.meta.erase("bureau_fault")
	var worst: BureaucracyRule.Verdict = null
	var by: BureaucracyRule = null
	for r in live():
		var v := r.before_transfer(c, d)
		if v == null:
			continue
		log_decision(r.id, c, "transferiu para %d" % d, _describe(v))
		if v.kind == BureaucracyRule.Verdict.Kind.INFRACTION and (worst == null or v.severity > worst.severity):
			worst = v
			by = r
	if worst != null and not c.lesson:
		c.meta["bureau_fault"] = main.supervisor.fault(by.id, worst.reason, worst.severity, T.Key[by.fault_text])


## O destino errado atendeu nesta tentativa: verdadeiro se a advertência de número errado vale. Se a regra já deu
## uma igual ou maior, ela fica só no registro; se deu uma menor, sai do relatório e vale a de número errado.
func wrong_number(c: PhoneCall) -> bool:
	var f: Dictionary = c.meta.get("bureau_fault", {})
	if f.is_empty():
		return true
	if ShiftReport.level(f) >= ShiftReport.severity("wrong_number"):
		log_decision("wrong_number", c, "transferiu para o número errado", "vale a advertência maior (%s)" % f["id"])
		return false
	main.report.faults.erase(f)
	c.meta.erase("bureau_fault")
	log_decision(f["id"], c, "transferiu para o número errado", "vale o número errado, maior")
	return true


func transfer_done(c: PhoneCall) -> void:
	for r in live():
		r.transfer_done(c)


func call_ended(c: PhoneCall, reason: PhoneCall.End) -> void:
	for r in live():
		r.call_ended(c, reason)


func listening(n: int, on: bool) -> void:
	for r in live():
		r.listening(n, on)


func clue_heard(k: Clue) -> void:
	for r in live():
		r.clue_heard(k)


func _describe(v: BureaucracyRule.Verdict) -> String:
	if v.kind == BureaucracyRule.Verdict.Kind.INFRACTION:
		return "infração %s: %s" % [T.text(ShiftReport.SEVERITY_NAMES[v.severity]).to_lower(), v.reason]
	return "permitido" + (": " + v.reason if v.reason != "" else "")
