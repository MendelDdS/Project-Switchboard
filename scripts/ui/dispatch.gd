class_name Dispatch
extends VBoxContainer
## Aba do despacho: local (marcado no mapa), tipo de ocorrência e unidades. Cuida da ida das viaturas,
## das mensagens de rádio e de avaliar se o local e as unidades batem com a emergência em andamento.

signal sent(location: String, units_text: String)
signal open_map_pressed
## As unidades chegaram. `result`: "ok" (resolvido), "missing" (faltou unidade), "wrong_place" ou "idle"
## (não havia emergência em andamento). `e` é nulo em "idle". `occurrence` é o tipo marcado no despacho;
## `extra`, as unidades que foram ao local certo sem ser necessárias.
signal arrived(e: EmergencyCall, result: String, occurrence: String, extra: Array)

enum Unit { AVAILABLE, EN_ROUTE, ON_SITE, RETURNING }
const UNIT_IDS := ["pol", "bomb", "amb"]
const UNIT_NAMES := {"pol": T.Key.UNIT_POLICE, "bomb": T.Key.UNIT_FIRE, "amb": T.Key.UNIT_AMBULANCE}
const UNIT_STATUS := [T.Key.UNIT_AVAILABLE, T.Key.UNIT_EN_ROUTE, T.Key.UNIT_ON_SITE, T.Key.UNIT_RETURNING]

var city: CityMap
var radio: Radio

var _location := {}          ## {"street", "block", "label"} marcado no mapa
var _units := {"pol": Unit.AVAILABLE, "bomb": Unit.AVAILABLE, "amb": Unit.AVAILABLE}
var _occ_group := ButtonGroup.new()
var _incident := {}          ## emergência em andamento: call, street, block, req, sent, resolved, addr

@onready var _loc_label: Label = %Location
@onready var _occurrences: HFlowContainer = %Occurrences
@onready var _message: Label = %Message
@onready var _report: Label = %Report
@onready var _unit_buttons := {"pol": %UnitPol as Button, "bomb": %UnitBomb as Button, "amb": %UnitAmb as Button}
@onready var _unit_status := {"pol": %StatusPol as Label, "bomb": %StatusBomb as Label, "amb": %StatusAmb as Label}


func _ready() -> void:
	%OpenMap.pressed.connect(open_map_pressed.emit)
	%Send.pressed.connect(_send)
	_occ_group.allow_unpress = true
	for o in GameData.CONTENT.occurrences:
		var b := Button.new()
		b.text = o
		b.toggle_mode = true
		b.button_group = _occ_group
		b.theme_type_variation = &"PaperToggle"
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(Sfx.play.bind("click"))
		_occurrences.add_child(b)
	for u in UNIT_IDS:
		(_unit_buttons[u] as Button).toggled.connect(func(_on): Sfx.play("sw"))
	_texts()


## O idioma mudou nas configurações.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_texts()


func _texts() -> void:
	for u in UNIT_IDS:
		(_unit_buttons[u] as Button).text = "[ %s ]" % T.text(UNIT_NAMES[u]).to_upper()
	_refresh()


func set_location(street: String, block: int, label: String) -> void:
	_location = {"street": street, "block": block, "label": label}
	_refresh()


## Marca o tipo de ocorrência (como clicar no botão).
func set_occurrence(o: String) -> void:
	for b: Button in _occurrences.get_children():
		b.button_pressed = b.text == o


## Uma emergência começou a tocar: guarda onde é e o que precisa, para avaliar o que for enviado.
func set_incident(e: EmergencyCall) -> void:
	_incident = {"call": e, "street": e.street, "block": e.block, "req": Array(e.units), "sent": [], "resolved": false, "addr": e.address}


## Há unidades a caminho (a chegada ainda vai ser avaliada contra a emergência atual).
func en_route() -> bool:
	return _units.values().has(Unit.EN_ROUTE)


func _refresh() -> void:
	var has_loc := not _location.is_empty()
	_loc_label.text = _location["label"] if has_loc else T.text(T.Key.DISPATCH_MARK_MAP)
	_loc_label.add_theme_color_override("font_color", Pal.INK if has_loc else Pal.INK_SOFT)
	for u in UNIT_IDS:
		var free: bool = _units[u] == Unit.AVAILABLE
		var b: Button = _unit_buttons[u]
		b.disabled = not free
		if not free:
			b.set_pressed_no_signal(false)
		var st: Label = _unit_status[u]
		st.text = T.text(UNIT_STATUS[_units[u]])
		st.add_theme_color_override("font_color", Pal.INK if free else Color("8a3a14"))
	var busy := UNIT_IDS.filter(func(u): return _units[u] != Unit.AVAILABLE)
	_report.visible = not busy.is_empty()
	_report.text = ""
	if not busy.is_empty():
		var lines := PackedStringArray([T.text(T.Key.DISPATCH_UNITS_STATUS)])
		for u in busy:
			lines.append("%-12s %s" % [T.text(UNIT_NAMES[u]), T.text(UNIT_STATUS[_units[u]])])
		_report.text = "\n".join(lines)


func _selected_units() -> Array:
	return UNIT_IDS.filter(func(u): return (_unit_buttons[u] as Button).button_pressed)


func _send() -> void:
	var us := _selected_units()
	if _location.is_empty():
		_message.text = T.text(T.Key.DISPATCH_MARK_FIRST)
		return
	var occ := _occ_group.get_pressed_button()
	if occ == null:
		_message.text = T.text(T.Key.CHOOSE_TYPE)
		return
	if us.is_empty():
		_message.text = T.text(T.Key.DISPATCH_SELECT_UNIT)
		return
	_message.text = ""
	var target := _location.duplicate()
	target["occurrence"] = occ.text
	Sfx.play("sw")
	Sfx.static_burst()
	var names := PackedStringArray()
	for u in us:
		_units[u] = Unit.EN_ROUTE
		city.trip(u, target)
		names.append(T.text(UNIT_NAMES[u]))
	_refresh()
	sent.emit(String(target["label"]), ", ".join(names))
	await get_tree().create_timer(1.8, false).timeout
	radio.say(T.text([T.Key.RADIO_ON_WAY, T.Key.RADIO_COPY].pick_random()))
	await get_tree().create_timer(5.6, false).timeout
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
	await get_tree().create_timer(stay, false).timeout
	for u in us:
		if _units[u] == Unit.ON_SITE:
			_units[u] = Unit.RETURNING
	_refresh()
	await get_tree().create_timer(back, false).timeout
	for u in us:
		if _units[u] == Unit.RETURNING:
			_units[u] = Unit.AVAILABLE
	city.remove_units(us)
	_refresh()
