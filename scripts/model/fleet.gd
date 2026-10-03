class_name Fleet
extends RefCounted
## As viaturas e a emergência em andamento, sem interface nem tempo: quem sai, o que a chegada resolve e quando
## cada uma volta a ficar livre. O `Dispatch` (a tela: cartão, mapa e rádio) chama na ordem `send` → `arrive` →
## `leave` → `home`, esperando entre eles o tempo de cada viagem.

enum Unit { AVAILABLE, EN_ROUTE, ON_SITE, RETURNING }
## Como foi a chegada: resolvida, faltou unidade, endereço errado, ou não havia emergência (ou ela já estava resolvida).
enum Result { OK, MISSING, WRONG_PLACE, IDLE }

const IDS := ["pol", "bomb", "amb"]
const NAMES := {"pol": T.Key.UNIT_POLICE, "bomb": T.Key.UNIT_FIRE, "amb": T.Key.UNIT_AMBULANCE}
const STATUS := [T.Key.UNIT_AVAILABLE, T.Key.UNIT_EN_ROUTE, T.Key.UNIT_ON_SITE, T.Key.UNIT_RETURNING]   # por `Unit`

var units := {"pol": Unit.AVAILABLE, "bomb": Unit.AVAILABLE, "amb": Unit.AVAILABLE}
## Emergência em andamento: call, street, block, req (o que precisa agora), going (já enviadas ao lugar certo),
## sent (já chegaram lá), resolved, addr.
var incident := {}
## Sobe no `reset`: viagens de antes dele não chegam nem voltam mais (quem espera confere).
var gen := 0


func is_free(u: String) -> bool:
	return units[u] == Unit.AVAILABLE


func busy() -> Array:
	return IDS.filter(func(u): return units[u] != Unit.AVAILABLE)


## Há unidades a caminho (a chegada ainda vai ser avaliada contra a emergência atual).
func en_route() -> bool:
	return units.values().has(Unit.EN_ROUTE)


## Unidades que a emergência em andamento precisa agora.
func required() -> Array:
	return incident.get("req", [])


## Uma emergência começou a tocar: onde é e o que precisa (no estágio de agravamento `stage`).
func set_incident(e: EmergencyCall, stage := 0) -> void:
	incident = {"call": e, "street": e.street, "block": e.block, "req": Array(e.required(stage)), "sent": [], "going": [],
		"resolved": false, "addr": e.address}


## A situação piorou antes do despacho: passa a precisar destas unidades.
func require(us: PackedStringArray) -> void:
	if not incident.is_empty():
		incident["req"] = Array(us)


## Todas livres na hora (as viagens em andamento não valem mais); `forget` também esquece a emergência.
func reset(forget := false) -> void:
	gen += 1
	for u in IDS:
		units[u] = Unit.AVAILABLE
	if forget:
		incident = {}


## As livres de `us`, na ordem de `IDS`.
func available(us: Array) -> Array:
	return IDS.filter(func(u): return u in us and is_free(u))


## Saem para `target` ({"street", "block"}) as unidades `us` (livres). Devolve se, com elas, o socorro completo da
## emergência está a caminho do lugar certo (contando envios anteriores).
func send(us: Array, target: Dictionary) -> bool:
	for u in us:
		units[u] = Unit.EN_ROUTE
	if not _at_incident(target):
		return false
	for u in us:
		if not u in incident["going"]:
			incident["going"].append(u)
	return incident["req"].all(func(r): return r in incident["going"])


## Chegaram a `target`. Devolve {"result": Result, "missing": as que ainda faltam, "extra": as que foram ao lugar certo
## sem ser necessárias, "unneeded": as que podem voltar logo (todas, se ninguém ali precisava delas; senão, as a mais)}.
func arrive(us: Array, target: Dictionary) -> Dictionary:
	for u in us:
		units[u] = Unit.ON_SITE
	var out := {"result": Result.OK, "missing": [], "extra": [], "unneeded": us}
	if incident.is_empty() or incident["resolved"]:
		out["result"] = Result.IDLE
		return out
	if not _at_incident(target):
		out["result"] = Result.WRONG_PLACE
		return out
	for u in us:
		if not u in incident["sent"]:
			incident["sent"].append(u)
		if not u in incident["req"]:
			out["extra"].append(u)
	out["unneeded"] = out["extra"]
	out["missing"] = incident["req"].filter(func(r): return not r in incident["sent"])
	if out["missing"].is_empty():
		incident["resolved"] = true
	else:
		out["result"] = Result.MISSING
	return out


## As que ainda estão no local saem de volta para a base; devolve quais.
func leave(us: Array) -> Array:
	var going := us.filter(func(u): return units[u] == Unit.ON_SITE)
	for u in going:
		units[u] = Unit.RETURNING
	return going


## Chegaram à base: livres de novo.
func home(us: Array) -> void:
	for u in us:
		if units[u] == Unit.RETURNING:
			units[u] = Unit.AVAILABLE


func _at_incident(target: Dictionary) -> bool:
	return not incident.is_empty() and incident["street"] == target["street"] and incident["block"] == target["block"]
