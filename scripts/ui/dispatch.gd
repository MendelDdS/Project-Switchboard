class_name Dispatch
extends Control
## Aba do mapa e despacho: o mapa da cidade ocupa a aba inteira (clicar na rua marca o local) e a ficha de despacho
## fica por cima, à direita, na ordem da decisão: local, ocorrência, unidades (cada uma com o que a justifica, pelo
## protocolo; veja EmergencyCall.units) e Enviar. O tipo não marca unidades: quem decide é a conversa. Cada parte da
## ficha mostra "[ ]" até ser preenchida e Enviar só acende com as três. A ficha abre ao marcar um local ou quando
## chega uma emergência e se recolhe depois do envio (o mapa fica livre; `Open` a reabre); o pedaço do mapa que ela
## cobre continua alcançável arrastando (`CityMap.cover`). Depois do envio, tudo volta limpo para a próxima. Cuida da ida das viaturas, das mensagens de rádio e de
## avaliar se o local e as unidades batem com a emergência em andamento.

## `complete`: tudo o que a emergência precisa agora está a caminho do lugar certo (contando envios anteriores).
signal sent(location: String, units_text: String, complete: bool)
## As unidades chegaram. `result`: "ok" (resolvido), "missing" (faltou unidade), "wrong_place" ou "idle"
## (não havia emergência em andamento). `e` é nulo em "idle". `occurrence` é o tipo marcado no despacho;
## `extra`, as unidades que foram ao local certo sem ser necessárias.
signal arrived(e: EmergencyCall, result: String, occurrence: String, extra: Array)

enum Unit { AVAILABLE, EN_ROUTE, ON_SITE, RETURNING }
const UNIT_IDS := ["pol", "bomb", "amb"]
const UNIT_NAMES := {"pol": T.Key.UNIT_POLICE, "bomb": T.Key.UNIT_FIRE, "amb": T.Key.UNIT_AMBULANCE}
const UNIT_STATUS := [T.Key.UNIT_AVAILABLE, T.Key.UNIT_EN_ROUTE, T.Key.UNIT_ON_SITE, T.Key.UNIT_RETURNING]
const MISSING := Color("8a3a14")   # item da conferência que ainda falta

var radio: Radio

var _location := {}          ## {"street", "block", "label"} marcado no mapa
var _units := {"pol": Unit.AVAILABLE, "bomb": Unit.AVAILABLE, "amb": Unit.AVAILABLE}
var _occ_group := ButtonGroup.new()
var _incident := {}          ## emergência em andamento: call, street, block, req, sent, resolved, addr
var _gen := 0                ## sobe no `reset`: viagens de antes dele não chegam nem voltam mais

@onready var city: CityMap = %City
@onready var _slip: Control = %Slip
@onready var _occurrences: VBoxContainer = %Occurrences
@onready var _send_button: Button = %Send
@onready var _report: Label = %Report
@onready var _unit_buttons := {"pol": %UnitPol as Button, "bomb": %UnitBomb as Button, "amb": %UnitAmb as Button}


func _ready() -> void:
	city.segment_selected.connect(set_location)
	_send_button.pressed.connect(_send)
	%Open.pressed.connect(open_slip.bind(true))
	%Close.pressed.connect(open_slip.bind(false))
	resized.connect(_cover)
	_slip.visible = false   # começa recolhida: o mapa livre até a primeira ocorrência
	%Open.visible = true
	_occ_group.allow_unpress = true
	for o in GameData.CONTENT.occurrences:
		var b := Button.new()
		b.text = o
		b.toggle_mode = true
		b.button_group = _occ_group
		b.theme_type_variation = &"PaperChip"
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size.y = 22
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(Sfx.play.bind("click"))
		b.toggled.connect(_refresh.unbind(1))
		_occurrences.add_child(b)
	for u in UNIT_IDS:
		var ub: Button = _unit_buttons[u]
		ub.pressed.connect(Sfx.play.bind("sw"))
		ub.toggled.connect(_refresh.unbind(1))
	_texts()


## O idioma mudou nas configurações.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_texts()


func _texts() -> void:
	for u in UNIT_IDS:
		(_unit_buttons[u] as Button).text = T.text(UNIT_NAMES[u])
	_refresh()


func set_location(street: String, block: int, label: String) -> void:
	_location = {"street": street, "block": block, "label": label}
	open_slip(true)
	_refresh()


## Abre ou recolhe a ficha de despacho (o mapa ganha a aba toda).
func open_slip(on: bool) -> void:
	if _slip.visible == on:
		return
	_slip.visible = on
	%Open.visible = not on
	Sfx.play("page")
	_cover()


## Quanto do mapa a ficha cobre (ele deixa arrastar esse pedaço para a vista) e onde há botões por cima dele.
func _cover() -> void:
	if not is_node_ready():
		return
	city.cover = city.get_global_rect().end.x - _slip.get_global_rect().position.x + 8.0 if _slip.visible else 0.0
	var over: Array[Rect2] = []
	for c: Control in [%Open, %Fleet]:
		if c.visible:
			over.append(Rect2(c.get_global_rect().position - city.get_global_rect().position, c.size).grow(4.0))
	city.blocked = over


## Marca o tipo de ocorrência (como clicar no botão; "" desmarca).
func set_occurrence(o: String) -> void:
	for b: Button in _occurrences.get_children():
		b.button_pressed = b.text == o


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
	city.clear_selection()
	set_occurrence("")
	if forget:
		_incident = {}
	_refresh()


## Unidades que a emergência em andamento precisa agora.
func required() -> Array:
	return _incident.get("req", [])


## Há unidades a caminho (a chegada ainda vai ser avaliada contra a emergência atual).
func en_route() -> bool:
	return _units.values().has(Unit.EN_ROUTE)


## Local, tipo e ao menos uma unidade marcados.
func can_send() -> bool:
	return not _location.is_empty() and _occ_group.get_pressed_button() != null and not _selected_units().is_empty()


func _refresh() -> void:
	if not is_node_ready():
		return
	for u in UNIT_IDS:
		var b: Button = _unit_buttons[u]
		b.disabled = _units[u] != Unit.AVAILABLE
		if b.disabled:
			b.set_pressed_no_signal(false)
	%Place.text = String(_location["label"]) if not _location.is_empty() else T.text(T.Key.DISPATCH_CLICK_STREET)
	_check(%PlaceHead, not _location.is_empty(), T.text(T.Key.DISPATCH_CHECK_PLACE))
	_check(%TypeHead, _occ_group.get_pressed_button() != null, T.text(T.Key.DISPATCH_CHECK_TYPE))
	_check(%UnitsHead, not _selected_units().is_empty(), T.text(T.Key.DISPATCH_CHECK_UNITS))
	_send_button.disabled = not can_send()
	var busy := UNIT_IDS.filter(func(u): return _units[u] != Unit.AVAILABLE)
	_report.text = "  ·  ".join(PackedStringArray(busy.map(func(u): return "%s: %s" % [T.text(UNIT_NAMES[u]), T.text(UNIT_STATUS[_units[u]])])))
	if %Fleet.visible != not busy.is_empty():
		%Fleet.visible = not busy.is_empty()
		_cover.call_deferred()   # a faixa muda de tamanho só no quadro seguinte


## Título de uma parte da ficha: "[x]" e tinta quando pronta; "[ ]" e vermelho enquanto falta.
func _check(l: Label, done: bool, text: String) -> void:
	l.text = ("[x] " if done else "[ ] ") + text.to_upper()
	l.add_theme_color_override("font_color", Pal.INK if done else MISSING)


func _selected_units() -> Array:
	return UNIT_IDS.filter(func(u): return (_unit_buttons[u] as Button).button_pressed)


func _send() -> void:
	if not can_send():
		return
	var us := _selected_units()
	var target := _location.duplicate()
	target["occurrence"] = _occ_group.get_pressed_button().text
	Sfx.play("sw")
	Sfx.static_burst(0.0, radio.screen_x())
	var names := PackedStringArray()
	var travel := 0.0   # quem vem de mais longe (o Centro fica num canto da cidade) chega por último
	for u in us:
		_units[u] = Unit.EN_ROUTE
		travel = maxf(travel, city.trip(u, target))
		names.append(T.text(UNIT_NAMES[u]))
	# limpo para a próxima emergência (local e tipo não ficam de uma para outra); a ficha se recolhe
	_location = {}
	city.clear_selection()
	set_occurrence("")
	_refresh()
	open_slip(false)
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
