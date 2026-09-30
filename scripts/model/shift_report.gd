class_name ShiftReport
extends RefCounted
## O que o supervisor confere às 06:00: as advertências do turno e como terminou cada emergência.
## Pensado para as próximas noites: `night` e as listas podem ser salvas por noite, e `SEVERE_LIMIT`
## advertências graves somadas entre as noites significam demissão.

enum Severity { LIGHT, MEDIUM, SEVERE }
enum Outcome { OK, LATE, BAD }

const SEVERE_LIMIT := 3
const SEVERITY_NAMES := ["leve", "média", "grave"]
## id -> [gravidade, descrição]
const FAULTS := {
	"missed": [Severity.MEDIUM, "Ligação não atendida"],
	"hold": [Severity.MEDIUM, "Solicitante desistiu na espera"],
	"wrong_number": [Severity.MEDIUM, "Conectou o número errado"],
	"cut_call": [Severity.MEDIUM, "Conversa cortada no meio"],
	"wrong_info": [Severity.LIGHT, "Informação errada"],
	"register_wrong": [Severity.LIGHT, "Registro com o tipo errado"],
	"register_missing": [Severity.LIGHT, "Ocorrência sem registro"],
	"dispatch_wrong_place": [Severity.SEVERE, "Unidades enviadas ao endereço errado"],
	"dispatch_missing": [Severity.MEDIUM, "Faltaram unidades no despacho"],
	"dispatch_idle": [Severity.MEDIUM, "Unidades enviadas sem ocorrência"],
	"dispatch_extra": [Severity.LIGHT, "Unidade enviada sem necessidade"],
	"dispatch_type": [Severity.LIGHT, "Ocorrência classificada errado"],
	"emergency_dropped": [Severity.SEVERE, "Emergência encerrada sem despacho"],
}

var night := 1
var faults: Array[Dictionary] = []   ## {"id", "time", "detail"}, em ordem
var _incidents := {}                 ## EmergencyCall -> {"trouble": bool, "outcome": Outcome ou -1}


func add(id: String, time: String, detail := "") -> void:
	faults.append({"id": id, "time": time, "detail": detail})


static func severity(id: String) -> Severity:
	return FAULTS[id][0]


func count(sev: Severity) -> int:
	return faults.filter(func(f): return severity(f["id"]) == sev).size()


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


## 0 = bom turno, 1 = atenção, 2 = turno ruim.
func verdict() -> int:
	if count(Severity.SEVERE) > 0:
		return 2
	return 1 if count(Severity.MEDIUM) >= 3 or count(Severity.LIGHT) >= 5 else 0


func _incident(e: EmergencyCall) -> Dictionary:
	if not _incidents.has(e):
		_incidents[e] = {"trouble": false, "outcome": -1}
	return _incidents[e]
