class_name ShiftReport
extends RefCounted
## O que o supervisor confere no fim do turno: as advertências e os acertos do turno, o conceito que eles dão e como
## terminou cada emergência. `LOW_LIMIT` noites seguidas abaixo do conceito mínimo (`low_before` vem do Progress)
## significam demissão.

enum Severity { LIGHT, MEDIUM, SEVERE, CRITICAL }
enum Outcome { OK, LATE, BAD }

const SEVERITY_NAMES := [T.Key.SEV_LIGHT, T.Key.SEV_MEDIUM, T.Key.SEV_SEVERE, T.Key.SEV_CRITICAL]
## id -> [gravidade, descrição (T.Key)]
const FAULTS := {
	"missed": [Severity.MEDIUM, T.Key.FAULT_MISSED],
	"hold": [Severity.MEDIUM, T.Key.FAULT_HOLD],
	"wrong_number": [Severity.MEDIUM, T.Key.FAULT_WRONG_NUMBER],
	"cut_call": [Severity.MEDIUM, T.Key.FAULT_CUT_CALL],
	"eavesdrop": [Severity.SEVERE, T.Key.FAULT_EAVESDROP],   # a escuta notada: os dois denunciam a telefonista
	"shift_hung_up": [Severity.MEDIUM, T.Key.FAULT_SHIFT_HUNG_UP],
	"wrong_info": [Severity.LIGHT, T.Key.FAULT_WRONG_INFO],
	"register_wrong": [Severity.LIGHT, T.Key.FAULT_REGISTER_WRONG],
	"register_missing": [Severity.LIGHT, T.Key.FAULT_REGISTER_MISSING],
	"toll_unstamped": [Severity.LIGHT, T.Key.FAULT_TOLL_UNSTAMPED],
	"toll_forgotten": [Severity.LIGHT, T.Key.FAULT_TOLL_FORGOTTEN],
	"dispatch_wrong_place": [Severity.SEVERE, T.Key.FAULT_DISPATCH_WRONG_PLACE],
	"dispatch_missing": [Severity.MEDIUM, T.Key.FAULT_DISPATCH_MISSING],
	"dispatch_idle": [Severity.MEDIUM, T.Key.FAULT_DISPATCH_IDLE],
	"dispatch_extra": [Severity.LIGHT, T.Key.FAULT_DISPATCH_EXTRA],
	"dispatch_type": [Severity.LIGHT, T.Key.FAULT_DISPATCH_TYPE],
	"dispatch_blank": [Severity.MEDIUM, T.Key.FAULT_DISPATCH_BLANK],
	"emergency_dropped": [Severity.SEVERE, T.Key.FAULT_EMERGENCY_DROPPED],
	# barra de agravamento: uma por emergência, pelo estágio em que o despacho saiu (a perdida, na hora)
	"emergency_worse": [Severity.MEDIUM, T.Key.FAULT_EMERGENCY_WORSE],
	"emergency_critical": [Severity.SEVERE, T.Key.FAULT_EMERGENCY_CRITICAL],
	"emergency_lost": [Severity.CRITICAL, T.Key.FAULT_EMERGENCY_LOST],
	"authority_ignored": [Severity.MEDIUM, T.Key.FAULT_AUTHORITY_IGNORED],   # a cobrança do supervisor no Dia 12 (`StoryFlags.FAULT`)
}
## Os pontos que cada gravidade tira da eficiência (a gravíssima vale duas graves). A média pesa mais que um acerto: a
## não atendida liga de novo e, com 8, o crédito do retorno a apagava (o robô que deixa tocar 1 em 3 passava sempre).
const POINTS := [3, 15, 30, 60]
## Os acertos: id -> pontos. Só as decisões do operador; registrar e guardar o bilhete já têm a advertência quando faltam.
const CREDITS := {
	"transfer": 10,         # transferência completada
	"trunk": 12,            # interurbano completado (no lugar do "transfer")
	"info": 5,              # informação certa
	"emergency_ok": 20,     # emergência resolvida no estágio inicial
	"emergency_late": 10,   # resolvida com a situação piorando (a média do estágio já desconta); no crítico, nada
	"occurrence": 3,        # tipo de ocorrência perfurado certo
	"prank": 5,             # trote reconhecido
}

## O conceito do turno, pela eficiência (`GRADE_MIN`, o mínimo de cada um, do Ótimo ao Regular).
enum Grade { GREAT, GOOD, FAIR, POOR }
const GRADE_NAMES := [T.Key.GRADE_GREAT, T.Key.GRADE_GOOD, T.Key.GRADE_FAIR, T.Key.GRADE_POOR]
const GRADE_MIN := [0.90, 0.75, 0.60]
const GOAL := Grade.FAIR               ## o conceito mínimo que a companhia exige
## O rigor do supervisor: quanto cada ponto de advertência pesa na eficiência, de `RIGOR.x` na noite 1 a `RIGOR.y` na
## última, em linha reta (1 na noite 9). Nas primeiras ele releva quem ainda está aprendendo; nas últimas cobra mais.
## Calibrado em 28/10/2026 (HISTORICO 447): o desastrado (deixa tocar 1 em 3) fica em Regular até a noite 11 e cai
## para Insuficiente da 12 em diante.
const RIGOR := Vector2(0.6, 1.3)
const LOW_LIMIT := 2                   ## noites seguidas abaixo do mínimo que demitem

var night := 1
var end := 360.0                     ## o fim do turno (minutos depois do início, `Night.shift_end`)
var low_before := 0                  ## noites seguidas abaixo do mínimo antes desta
var faults: Array[Dictionary] = []   ## {"id", "time", "detail"} em ordem; as das burocracias, também "sev" e "text" (`level`, `text_of`)
var credits: Array[Dictionary] = []  ## os acertos, {"id", "time"}, em ordem
var later: Array = []                ## as que só chegam no relatório da noite seguinte (`Supervisor.fault_later`)
var _incidents := {}                 ## EmergencyCall -> {"trouble": bool, "outcome": Outcome ou -1}
var _picked := {}                    ## EmergencyCall -> [Outcome, molde da manchete]: sorteada uma vez só


## Uma advertência; `sev` e `text` (`T.Key`) para as que não estão em `FAULTS` (as das burocracias, `Bureaucracy`).
func add(id: String, time: String, detail := "", sev := -1, text := -1) -> Dictionary:
	var f := {"id": id, "time": time, "detail": detail}
	if sev != -1:
		f["sev"] = sev
		f["text"] = text
	faults.append(f)
	return f


static func severity(id: String) -> Severity:
	return FAULTS[id][0]


## A gravidade da advertência `f` (de `faults`).
static func level(f: Dictionary) -> Severity:
	return f.get("sev", FAULTS[f["id"]][0] if FAULTS.has(f["id"]) else Severity.MEDIUM)


## O texto da advertência `f` no relatório, no idioma atual.
static func text_of(f: Dictionary) -> String:
	return T.text(f.get("text", FAULTS[f["id"]][1] if FAULTS.has(f["id"]) else T.Key.FAULT_BUREAUCRACY))


func count(sev: Severity) -> int:
	return faults.filter(func(f): return level(f) == sev).size()


## Um acerto; `pts` para os que valem conforme o caso (a fita entregue, `Bureaucracy.tapes`), fora de `CREDITS`.
func credit(id: String, time: String, pts := -1) -> void:
	var c := {"id": id, "time": time}
	if pts != -1:
		c["pts"] = pts
	credits.append(c)


func positives() -> int:
	return credits.reduce(func(s, c): return s + c.get("pts", CREDITS.get(c["id"], 0)), 0)


func negatives() -> int:
	return faults.reduce(func(s, f): return s + POINTS[level(f)], 0)


## O peso das advertências na noite `n` (`RIGOR`).
static func rigor(n: int) -> float:
	return lerpf(RIGOR.x, RIGOR.y, clampf((n - 1) / float(GameData.CONTENT.nights.size() - 1), 0.0, 1.0))


## A parte certa de tudo o que o supervisor anotou, de 0 a 1 (1 sem advertência, também sem acerto nenhum); as
## advertências pesam pelo rigor da noite (`rigor`).
func efficiency() -> float:
	var neg := negatives() * rigor(night)
	return 1.0 if neg == 0.0 else positives() / (positives() + neg)


## O conceito do turno; uma emergência perdida é Insuficiente, seja qual for a eficiência.
func grade() -> Grade:
	if count(Severity.CRITICAL) > 0:
		return Grade.POOR
	var e := efficiency()
	for g in GRADE_MIN.size():
		if e >= GRADE_MIN[g]:
			return g as Grade
	return Grade.POOR


## Noites seguidas abaixo do mínimo, contando esta (uma no mínimo ou acima zera).
func low_nights() -> int:
	return low_before + 1 if grade() > GOAL else 0


## Demitido: noites seguidas demais abaixo do mínimo (o treinamento, noite 0, nunca demite).
func fired() -> bool:
	return night > 0 and low_nights() >= LOW_LIMIT


## Emergência que teve problema (não atendida, sem despacho, endereço errado): se for resolvida, foi com atraso.
func trouble(e: EmergencyCall) -> void:
	_incident(e)["trouble"] = true


func resolved(e: EmergencyCall) -> void:
	var i := _incident(e)
	if i["outcome"] == -1:
		i["outcome"] = Outcome.LATE if i["trouble"] else Outcome.OK


func failed(e: EmergencyCall) -> void:
	_incident(e)["outcome"] = Outcome.BAD


func is_resolved(e: EmergencyCall) -> bool:
	return _incidents.has(e) and _incidents[e]["outcome"] in [Outcome.OK, Outcome.LATE]


## Como terminou cada emergência do turno; a que ficou sem solução conta como BAD.
func outcomes() -> Dictionary:
	var out := {}
	for e in _incidents:
		var o: int = _incidents[e]["outcome"]
		out[e] = Outcome.BAD if o == -1 else o
	return out


## O jornal da manhã: uma manchete por emergência do turno, {"outcome", "template", "occurrence", "address"} (molde e
## ocorrência no original; `headline` traduz na hora de mostrar). Chamado de novo, diz a mesma: o molde é sorteado uma
## vez por desfecho (é o jornal da noite seguinte, na mesa, que o `Progress` guarda).
func news() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var all := outcomes()
	for e: EmergencyCall in all:
		var o: int = all[e]
		if not _picked.has(e) or _picked[e][0] != o:
			var c := GameData.CONTENT
			_picked[e] = [o, GameData.pick([c.news_ok, c.news_late, c.news_bad][o])]
		out.append({"outcome": o, "template": _picked[e][1], "occurrence": e.occurrence, "address": e.address})
	return out


## Uma manchete de `news()`, no idioma atual.
static func headline(d: Dictionary) -> String:
	return GameData.fill(d["template"], {"occurrence": occurrence_name(d["occurrence"]), "address": d["address"]})


## "Invasão / roubo" -> "Invasão"; "Outro" -> "Ocorrência".
static func occurrence_name(o: String) -> String:
	return T.text(T.Key.REPORT_INCIDENT) if o == "Outro" else String(TranslationServer.translate(o)).get_slice(" /", 0)


## Debug: esquece a emergência `e` (ou todas, sem `e`), como se não tivesse acontecido.
func forget(e: EmergencyCall = null) -> void:
	if e == null:
		_incidents.clear()
	else:
		_incidents.erase(e)


func _incident(e: EmergencyCall) -> Dictionary:
	if not _incidents.has(e):
		_incidents[e] = {"trouble": false, "outcome": -1}
	return _incidents[e]
