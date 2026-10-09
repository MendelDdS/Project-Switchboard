class_name Fleet
extends RefCounted
## As viaturas e as emergências em andamento (até `Main.MAX_EMERGENCIES` ao mesmo tempo), sem interface nem tempo:
## quem sai, o que a chegada resolve e quando cada uma volta a ficar livre. O `Dispatch` (a tela: cartão, mapa e rádio)
## escolhe de qual emergência é o cartão (`target_of`) e quais viaturas saem (`crew`) e chama na ordem `send` →
## `arrive` → `leave` → `home`, esperando entre eles o tempo de cada viagem. Cada tipo (`IDS`, o que o cartão perfura)
## tem duas viaturas: a de reserva (o id com `SPARE` no fim) só sai com duas emergências em andamento (`spare`); com
## uma, quem errou espera a viatura voltar.

enum Unit { AVAILABLE, EN_ROUTE, ON_SITE, RETURNING }
## Como foi a chegada: resolvida, faltou unidade, endereço errado, ou não havia emergência (ou ela já estava resolvida).
enum Result { OK, MISSING, WRONG_PLACE, IDLE }

const IDS := ["pol", "bomb", "amb"]
const SPARE := "2"   ## o fim do id da viatura de reserva de cada tipo ("pol2")
const NAMES := {"pol": T.Key.UNIT_POLICE, "bomb": T.Key.UNIT_FIRE, "amb": T.Key.UNIT_AMBULANCE}
const STATUS := [T.Key.UNIT_AVAILABLE, T.Key.UNIT_EN_ROUTE, T.Key.UNIT_ON_SITE, T.Key.UNIT_RETURNING]   # por `Unit`

## Uma emergência em andamento: onde é e o que cada unidade já fez por ela.
class Incident:
	var call: EmergencyCall
	var street: String
	var block: int
	var addr: String
	var req: Array = []     ## o que precisa agora
	var going: Array = []   ## já enviadas ao lugar certo
	var sent: Array = []    ## já chegaram lá
	var resolved := false

	func _init(e: EmergencyCall, stage: int) -> void:
		call = e
		street = e.street
		block = e.block
		addr = e.address
		req = Array(e.required(stage))

	func at(target: Dictionary) -> bool:
		return street == target["street"] and block == target["block"]


## Como foi uma chegada (`arrive`).
class Arrival:
	var result := Result.OK
	var missing: Array = []    ## os tipos que ainda faltam
	var extra: Array = []      ## os tipos que foram ao lugar certo sem ser necessários
	var unneeded: Array = []   ## as viaturas que podem voltar logo (todas, se ninguém ali precisava delas; senão, as a mais)


## Viatura -> estado: as de cada tipo de `IDS` e as de reserva.
var units := {"pol": Unit.AVAILABLE, "bomb": Unit.AVAILABLE, "amb": Unit.AVAILABLE,
	"pol2": Unit.AVAILABLE, "bomb2": Unit.AVAILABLE, "amb2": Unit.AVAILABLE}
var spare := false   ## as de reserva podem sair (duas emergências em andamento)
var incidents: Array[Incident] = []   ## as emergências em andamento, na ordem em que tocaram
## Sobe no `reset`: viagens de antes dele não chegam nem voltam mais (quem espera confere).
var gen := 0


## O tipo da viatura `v` ("pol2" -> "pol").
static func kind(v: String) -> String:
	return v.trim_suffix(SPARE)


## A viatura livre do tipo `u` que pode sair agora ("" = nenhuma).
func vehicle(u: String) -> String:
	if units[u] == Unit.AVAILABLE:
		return u
	return u + SPARE if spare and units[u + SPARE] == Unit.AVAILABLE else ""


## Há uma viatura do tipo `u` que pode sair agora.
func is_free(u: String) -> bool:
	return vehicle(u) != ""


## As viaturas fora da base.
func busy() -> Array:
	return units.keys().filter(func(v): return units[v] != Unit.AVAILABLE)


## Há unidades a caminho (a chegada ainda vai ser avaliada).
func en_route() -> bool:
	return units.values().has(Unit.EN_ROUTE)


## A emergência `e` em andamento (nula se não está).
func incident_of(e: EmergencyCall) -> Incident:
	for inc in incidents:
		if inc.call == e:
			return inc
	return null


## Unidades que a emergência `e` precisa agora.
func required(e: EmergencyCall) -> Array:
	var inc := incident_of(e)
	return [] if inc == null else inc.req


## Uma emergência começou a tocar: onde é e o que precisa (no estágio de agravamento `stage`). A mesma tocando de
## novo (quem liga de novo) recomeça do zero.
func set_incident(e: EmergencyCall, stage := 0) -> void:
	close(e)
	incidents.append(Incident.new(e, stage))


## A emergência `e` saiu do despacho (deu lugar a outra).
func close(e: EmergencyCall) -> void:
	incidents = incidents.filter(func(inc: Incident): return inc.call != e)


## A situação de `e` piorou antes do despacho: passa a precisar destas unidades.
func require(e: EmergencyCall, us: PackedStringArray) -> void:
	var inc := incident_of(e)
	if inc != null:
		inc.req = Array(us)


## De qual emergência é o cartão marcado em `target`: a daquele lugar (a ainda sem socorro primeiro); fora de todas
## (endereço errado), a de `attending` (a que o operador está atendendo); sem ela, a primeira ainda sem socorro.
func target_of(target: Dictionary, attending: EmergencyCall = null) -> Incident:
	var here := incidents.filter(func(inc: Incident): return inc.at(target))
	here.sort_custom(func(a: Incident, b: Incident): return not a.resolved and b.resolved)
	if not here.is_empty():
		return here[0]
	var mine := incident_of(attending)
	if mine != null:
		return mine
	for inc in incidents:
		if not inc.resolved:
			return inc
	return null if incidents.is_empty() else incidents.back()


## Todas livres na hora (as viagens em andamento não valem mais); `forget` também esquece a emergência.
func reset(forget := false) -> void:
	gen += 1
	for v in units:
		units[v] = Unit.AVAILABLE
	if forget:
		incidents.clear()


## Os tipos de `us` com viatura que pode sair, na ordem de `IDS`.
func available(us: Array) -> Array:
	return IDS.filter(func(u): return u in us and is_free(u))


## As viaturas que saem pelos tipos `us` (uma de cada, dos que podem sair).
func crew(us: Array) -> Array:
	return available(us).map(vehicle)


## Saem para `target` ({"street", "block"}) as viaturas `vs` (`crew`), pela emergência `inc` (`target_of`; nula sem
## emergência). Devolve se, com elas, o socorro completo dela está a caminho do lugar certo (contando envios anteriores).
func send(vs: Array, target: Dictionary, inc: Incident) -> bool:
	for v in vs:
		units[v] = Unit.EN_ROUTE
	if inc == null or not inc.at(target):
		return false
	for v in vs:
		if not kind(v) in inc.going:
			inc.going.append(kind(v))
	return inc.req.all(func(r): return r in inc.going)


## Chegaram a `target` as viaturas `vs`, pela emergência `inc` (a do `send`): o que isso resolveu (`Arrival`).
func arrive(vs: Array, target: Dictionary, inc: Incident) -> Arrival:
	for v in vs:
		units[v] = Unit.ON_SITE
	var out := Arrival.new()
	out.unneeded = vs
	if inc == null or inc.resolved:
		out.result = Result.IDLE
		return out
	if not inc.at(target):
		out.result = Result.WRONG_PLACE
		return out
	out.unneeded = []
	for v in vs:
		if not kind(v) in inc.sent:
			inc.sent.append(kind(v))
		if not kind(v) in inc.req:
			out.extra.append(kind(v))
			out.unneeded.append(v)
	out.missing = inc.req.filter(func(r): return not r in inc.sent)
	if out.missing.is_empty():
		inc.resolved = true
	else:
		out.result = Result.MISSING
	return out


## As viaturas de `vs` que ainda estão no local saem de volta para a base; devolve quais.
func leave(vs: Array) -> Array:
	var going := vs.filter(func(v): return units[v] == Unit.ON_SITE)
	for v in going:
		units[v] = Unit.RETURNING
	return going


## Chegaram à base: livres de novo.
func home(vs: Array) -> void:
	for v in vs:
		if units[v] == Unit.RETURNING:
			units[v] = Unit.AVAILABLE
