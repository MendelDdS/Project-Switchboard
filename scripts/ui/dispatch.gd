class_name Dispatch
extends Control
## Aba do mapa e despacho: o mapa da cidade ocupa a aba inteira (clicar na rua marca o local) e a ficha de despacho
## fica por cima, à direita: marcar o local imprime um cartão perfurado (`PunchCard`), em que o jogador perfura o tipo
## de ocorrência e as unidades (cada uma com o que a justifica, pelo protocolo; veja EmergencyCall.units), e o cartão
## levado ao transmissor envia (ou à trituradora, descarta). O tipo não marca unidades: quem decide é a conversa. O cartão só mostra o que fica aqui
## (`_location`, `_occurrence`, `_picked`). A ficha abre ao marcar um local ou quando chega uma emergência e se
## recolhe depois do envio (`Open` a reabre); abrir ou fechar não mexe no mapa. O transmissor aceita cartão incompleto:
## sem unidade, ninguém sai (`blank_card`, o supervisor pune); sem tipo, as unidades vão e a chegada é avaliada com o
## tipo vazio. Depois do envio, tudo volta limpo para a próxima. Cuida da ida das viaturas, das mensagens de rádio e
## de avaliar se o local e as unidades batem com a emergência em andamento.

## `complete`: tudo o que a emergência precisa agora está a caminho do lugar certo (contando envios anteriores).
signal sent(location: String, units_text: String, complete: bool)
## As unidades chegaram. `result`: "ok" (resolvido), "missing" (faltou unidade), "wrong_place" ou "idle"
## (não havia emergência em andamento). `e` é nulo em "idle". `occurrence` é o tipo marcado no despacho;
## `extra`, as unidades que foram ao local certo sem ser necessárias.
signal arrived(e: EmergencyCall, result: String, occurrence: String, extra: Array)
## Um cartão entrou no transmissor sem nenhuma unidade perfurada: ninguém saiu.
signal blank_card(location: String)

enum Unit { AVAILABLE, EN_ROUTE, ON_SITE, RETURNING }
const UNIT_IDS := ["pol", "bomb", "amb"]
const UNIT_NAMES := {"pol": T.Key.UNIT_POLICE, "bomb": T.Key.UNIT_FIRE, "amb": T.Key.UNIT_AMBULANCE}
const UNIT_STATUS := [T.Key.UNIT_AVAILABLE, T.Key.UNIT_EN_ROUTE, T.Key.UNIT_ON_SITE, T.Key.UNIT_RETURNING]

var radio: Radio

var _location := {}          ## {"street", "block", "label"} marcado no mapa
var _occurrence := ""        ## tipo perfurado no cartão ("" = nenhum)
var _picked: Array = []      ## unidades perfuradas no cartão
var _units := {"pol": Unit.AVAILABLE, "bomb": Unit.AVAILABLE, "amb": Unit.AVAILABLE}
var _incident := {}          ## emergência em andamento: call, street, block, req, sent, resolved, addr
var _gen := 0                ## sobe no `reset`: viagens de antes dele não chegam nem voltam mais
var _open := false           ## a ficha aberta (fechando, ela some só quando as máquinas se recolhem)

@onready var city: CityMap = %City
@onready var card: PunchCard = %Slip
@onready var _slip: Control = %Slip
@onready var _report: Label = %Report


func _ready() -> void:
	city.segment_selected.connect(set_location)
	card.dispatch = self
	card.inserted.connect(_send)
	card.discarded.connect(_discard)
	card.closed.connect(_hide_slip)
	%Open.pressed.connect(open_slip.bind(true))
	%Close.pressed.connect(open_slip.bind(false))
	resized.connect(_block)
	_slip.visible = false   # começa recolhida: o mapa livre até a primeira ocorrência
	%Open.visible = true
	_refresh()


## O idioma mudou nas configurações.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


## Marca o local: sai um cartão novo, em branco (o que estava perfurado fica para trás).
func set_location(street: String, block: int, label: String) -> void:
	_location = {"street": street, "block": block, "label": label}
	_occurrence = ""
	_picked.clear()
	open_slip(true)
	card.print_card(label, GameData.street(street).block_sector(block) if GameData.street(street) != null else 0)
	_refresh()


## Abre ou recolhe a ficha de despacho: as máquinas entram (ou saem) animadas, e ela some depois (`_hide_slip`).
func open_slip(on: bool) -> void:
	if _open == on:
		return
	_open = on
	if on:
		_slip.visible = true
		%Open.visible = false
	card.set_open(on)
	Sfx.play("page")
	_block()


func _hide_slip() -> void:
	if not _open:
		_slip.visible = false
		%Open.visible = true
		_block()


## Onde há botões por cima do mapa (nenhum nome de rua ali).
func _block() -> void:
	if not is_node_ready():
		return
	var over: Array[Rect2] = []
	for c: Control in [%Open, %Fleet]:
		if c.visible:
			over.append(Rect2(c.get_global_rect().position - city.get_global_rect().position, c.size).grow(4.0))
	city.blocked = over


## Marca o tipo de ocorrência (como perfurar o cartão; "" desmarca, só nos testes e no debug).
func set_occurrence(o: String) -> void:
	_occurrence = o
	_refresh()


## Perfura a unidade no cartão (se estiver disponível).
func punch_unit(u: String) -> void:
	if unit_free(u) and not u in _picked:
		_picked.append(u)
		_refresh()


func occurrence() -> String:
	return _occurrence


func picked() -> Array:
	return _picked


func unit_free(u: String) -> bool:
	return _units[u] == Unit.AVAILABLE


func unit_state(u: String) -> Unit:
	return _units[u]


## Uma emergência começou a tocar: guarda onde é e o que precisa (no estágio de agravamento `stage`), para
## avaliar o que for enviado.
func set_incident(e: EmergencyCall, stage := 0) -> void:
	_incident = {"call": e, "street": e.street, "block": e.block, "req": Array(e.required(stage)), "sent": [], "going": [], "resolved": false, "addr": e.address}
	open_slip(true)


## A situação piorou antes do despacho: passa a precisar destas unidades.
func require(units: PackedStringArray) -> void:
	if not _incident.is_empty():
		_incident["req"] = Array(units)


## Debug: todas as viaturas livres na hora (as que estavam a caminho não chegam mais) e nada marcado no despacho.
## `forget` também esquece a emergência em andamento.
func reset(forget := false) -> void:
	_gen += 1
	for u in UNIT_IDS:
		_units[u] = Unit.AVAILABLE
	city.remove_units(UNIT_IDS)
	_location = {}
	_occurrence = ""
	_picked.clear()
	city.clear_selection()
	card.clear()
	if forget:
		_incident = {}
	_refresh()


## Unidades que a emergência em andamento precisa agora.
func required() -> Array:
	return _incident.get("req", [])


## Há unidades a caminho (a chegada ainda vai ser avaliada contra a emergência atual).
func en_route() -> bool:
	return _units.values().has(Unit.EN_ROUTE)


## Local, tipo e ao menos uma unidade marcados (a luz verde do transmissor; incompleto também entra).
func can_send() -> bool:
	return not _location.is_empty() and _occurrence != "" and not _selected_units().is_empty()


func _refresh() -> void:
	if not is_node_ready():
		return
	card.queue_redraw()
	var busy := UNIT_IDS.filter(func(u): return _units[u] != Unit.AVAILABLE)
	_report.text = "  ·  ".join(PackedStringArray(busy.map(func(u): return "%s: %s" % [T.text(UNIT_NAMES[u]), T.text(UNIT_STATUS[_units[u]])])))
	if %Fleet.visible != not busy.is_empty():
		%Fleet.visible = not busy.is_empty()
		_block.call_deferred()   # a faixa muda de tamanho só no quadro seguinte


func _selected_units() -> Array:
	return UNIT_IDS.filter(func(u): return u in _picked and _units[u] == Unit.AVAILABLE)


## O cartão entrou no transmissor.
func _send() -> void:
	if _location.is_empty():
		return
	var us := _selected_units()
	var target := _location.duplicate()
	target["occurrence"] = _occurrence
	Sfx.static_burst(0.0, radio.screen_x())
	if us.is_empty():   # nenhuma unidade perfurada: a central recebe a ficha e ninguém sai
		_clean()
		blank_card.emit(String(target["label"]))
		await get_tree().create_timer(1.8, false).timeout
		radio.say(T.text(T.Key.RADIO_BLANK_CARD))
		return
	var names := PackedStringArray()
	var travel := 0.0   # quem vem de mais longe (o Centro fica num canto da cidade) chega por último
	for u in us:
		_units[u] = Unit.EN_ROUTE
		travel = maxf(travel, city.trip(u, target))
		names.append(T.text(UNIT_NAMES[u]))
	_clean()
	var complete := false
	if not _incident.is_empty() and _incident["street"] == target["street"] and _incident["block"] == target["block"]:
		for u in us:
			if not u in _incident["going"]:
				_incident["going"].append(u)
		complete = _incident["req"].all(func(r): return r in _incident["going"])
	sent.emit(String(target["label"]), ", ".join(names), complete)
	var gen := _gen
	await get_tree().create_timer(1.8, false).timeout
	if gen != _gen:
		return
	radio.say(T.text([T.Key.RADIO_ON_WAY, T.Key.RADIO_COPY].pick_random()))
	await get_tree().create_timer(maxf(travel - 1.8, 0.5), false).timeout
	if gen == _gen:
		_arrive(us, target)


## O cartão foi para a trituradora: local e furos se perdem, nada sai, e a impressora espera outro local.
func _discard() -> void:
	_location = {}
	_occurrence = ""
	_picked.clear()
	city.clear_selection()
	_refresh()


## Limpo para a próxima emergência (local e tipo não ficam de uma para outra); a ficha se recolhe.
func _clean() -> void:
	_location = {}
	_occurrence = ""
	_picked.clear()
	city.clear_selection()
	card.clear()
	_refresh()
	open_slip(false)


func _arrive(us: Array, target: Dictionary) -> void:
	for u in us:
		_units[u] = Unit.ON_SITE
	_refresh()
	var msg := ""
	var result := "ok"
	var extra := []
	if _incident.is_empty() or _incident["resolved"]:
		msg = T.text(T.Key.RADIO_NOTHING)
		result = "idle"
	elif _incident["street"] != target["street"] or _incident["block"] != target["block"]:
		# endereço errado: não há nada a fazer lá, e as unidades voltam a ficar disponíveis
		msg = T.text(T.Key.RADIO_WRONG_PLACE) % String(target["label"]).split(",")[0]
		result = "wrong_place"
	else:
		for u in us:
			if not u in _incident["sent"]:
				_incident["sent"].append(u)
			if not u in _incident["req"]:
				extra.append(u)
		var miss := []
		for r in _incident["req"]:
			if not r in _incident["sent"]:
				miss.append(T.text(UNIT_NAMES[r]).to_lower())
		if not miss.is_empty():
			msg = T.text(T.Key.RADIO_NEED) % [(" %s " % T.text(T.Key.AND)).join(PackedStringArray(miss)), _incident["addr"]]
			result = "missing"
		else:
			msg = T.text(T.Key.RADIO_UNDER_CONTROL)
			_incident["resolved"] = true
	radio.say(msg)
	if not extra.is_empty():
		var names := PackedStringArray(extra.map(func(u): return T.text(UNIT_NAMES[u]).to_lower()))
		radio.say(T.text(T.Key.RADIO_NOT_NEEDED) % (" %s " % T.text(T.Key.AND)).join(names))
	arrived.emit(null if result == "idle" else _incident["call"], result, target["occurrence"], extra)
	# no endereço errado, e quem não era necessário, voltam logo a ficar disponíveis
	var quick: Array = us if result == "wrong_place" else extra
	_return(quick, 3.0, 1.0)
	_return(us.filter(func(u): return not u in quick), 12.0, 7.0)


func _return(us: Array, stay: float, back: float) -> void:
	if us.is_empty():
		return
	var gen := _gen
	await get_tree().create_timer(stay, false).timeout
	if gen != _gen:
		return
	for u in us:
		if _units[u] == Unit.ON_SITE:
			_units[u] = Unit.RETURNING
	_refresh()
	await get_tree().create_timer(back, false).timeout
	if gen != _gen:
		return
	for u in us:
		if _units[u] == Unit.RETURNING:
			_units[u] = Unit.AVAILABLE
	city.remove_units(us)
	_refresh()
