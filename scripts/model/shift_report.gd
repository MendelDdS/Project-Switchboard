class_name ShiftReport
extends RefCounted
## O que o supervisor confere no fim do turno: as advertências do turno e como terminou cada emergência.
## `SEVERE_LIMIT` advertências graves somadas entre as noites (`severe_before` vem do Progress) significam demissão;
## uma gravíssima conta como `CRITICAL_WEIGHT` graves.

enum Severity { LIGHT, MEDIUM, SEVERE, CRITICAL }
enum Outcome { OK, LATE, BAD }

const SEVERE_LIMIT := 3
const CRITICAL_WEIGHT := 2
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
}

var night := 1
var severe_before := 0               ## advertências graves das noites anteriores
var faults: Array[Dictionary] = []   ## {"id", "time", "detail"}, em ordem
var later: Array = []                ## as que só chegam no relatório da noite seguinte (`Supervisor.fault_later`)
var _incidents := {}                 ## EmergencyCall -> {"trouble": bool, "outcome": Outcome ou -1}
var _picked := {}                    ## EmergencyCall -> [Outcome, molde da manchete]: sorteada uma vez só


func add(id: String, time: String, detail := "") -> void:
	faults.append({"id": id, "time": time, "detail": detail})


static func severity(id: String) -> Severity:
	return FAULTS[id][0]


func count(sev: Severity) -> int:
	return faults.filter(func(f): return severity(f["id"]) == sev).size()


func severe_total() -> int:
	return severe_before + count(Severity.SEVERE) + CRITICAL_WEIGHT * count(Severity.CRITICAL)


## Demitido: graves demais (o treinamento, noite 0, nunca demite).
func fired() -> bool:
	return night > 0 and severe_total() >= SEVERE_LIMIT


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


## 0 = bom turno, 1 = atenção, 2 = turno ruim.
func verdict() -> int:
	if count(Severity.SEVERE) + count(Severity.CRITICAL) > 0:
		return 2
	return 1 if count(Severity.MEDIUM) >= 3 or count(Severity.LIGHT) >= 5 else 0


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
