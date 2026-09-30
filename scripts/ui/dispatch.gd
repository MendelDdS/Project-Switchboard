class_name Dispatch
extends VBoxContainer
## Aba do despacho: local (marcado no mapa), tipo de ocorrência e unidades. Cuida da ida das viaturas,
## das mensagens de rádio e de avaliar se o local e as unidades batem com a emergência em andamento.

signal sent(location: String, units_text: String)
signal open_map_pressed

enum Unit { AVAILABLE, EN_ROUTE, ON_SITE, RETURNING }
const UNIT_IDS := ["pol", "bomb", "amb"]
const UNIT_NAMES := {"pol": "Polícia", "bomb": "Bombeiros", "amb": "Ambulância"}
const UNIT_STATUS := ["DISPONÍVEL", "EM DESLOCAMENTO", "NO LOCAL", "RETORNANDO"]

var city: CityMap
var radio: Radio

var _location := {}          ## {"street", "block", "label"} marcado no mapa
var _units := {"pol": Unit.AVAILABLE, "bomb": Unit.AVAILABLE, "amb": Unit.AVAILABLE}
var _incident := {}          ## emergência em andamento: street, block, req, sent, resolved, addr

@onready var _loc_label: Label = %Location
@onready var _occurrences: HFlowContainer = %Occurrences
@onready var _message: Label = %Message
@onready var _report: Label = %Report
@onready var _unit_buttons := {"pol": %UnitPol as Button, "bomb": %UnitBomb as Button, "amb": %UnitAmb as Button}
@onready var _unit_status := {"pol": %StatusPol as Label, "bomb": %StatusBomb as Label, "amb": %StatusAmb as Label}


func _ready() -> void:
	%OpenMap.pressed.connect(open_map_pressed.emit)
	%Send.pressed.connect(_send)
	var group := ButtonGroup.new()
	group.allow_unpress = true
	for o in GameData.CONTENT.occurrences:
		var b := Button.new()
		b.text = o
		b.toggle_mode = true
		b.button_group = group
		b.theme_type_variation = &"PaperToggle"
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(Sfx.play.bind("click"))
		_occurrences.add_child(b)
	for u in UNIT_IDS:
		var b: Button = _unit_buttons[u]
		b.text = "[ %s ]" % tr(UNIT_NAMES[u]).to_upper()
		b.toggled.connect(func(_on): Sfx.play("sw"))
	_refresh()


func set_location(street: String, block: int, label: String) -> void:
	_location = {"street": street, "block": block, "label": label}
	_refresh()


## Uma emergência começou a tocar: guarda onde é e o que precisa, para avaliar o que for enviado.
func set_incident(e: EmergencyCall) -> void:
	_incident = {"street": e.street, "block": e.block, "req": Array(e.units), "sent": [], "resolved": false, "addr": e.address}


func _refresh() -> void:
	var has_loc := not _location.is_empty()
	_loc_label.text = _location["label"] if has_loc else tr("Marque o local no mapa")
	_loc_label.add_theme_color_override("font_color", Pal.INK if has_loc else Pal.INK_SOFT)
	for u in UNIT_IDS:
		var free: bool = _units[u] == Unit.AVAILABLE
		var b: Button = _unit_buttons[u]
		b.disabled = not free
		if not free:
			b.set_pressed_no_signal(false)
		var st: Label = _unit_status[u]
		st.text = tr(UNIT_STATUS[_units[u]])
		st.add_theme_color_override("font_color", Pal.INK if free else Color("8a3a14"))
	var busy := UNIT_IDS.filter(func(u): return _units[u] != Unit.AVAILABLE)
	_report.visible = not busy.is_empty()
	_report.text = ""
	if not busy.is_empty():
		var lines := PackedStringArray([tr("SITUAÇÃO DAS UNIDADES")])
		for u in busy:
			lines.append("%-12s %s" % [tr(UNIT_NAMES[u]), tr(UNIT_STATUS[_units[u]])])
		_report.text = "\n".join(lines)


func _selected_units() -> Array:
	return UNIT_IDS.filter(func(u): return (_unit_buttons[u] as Button).button_pressed)


func _send() -> void:
	var us := _selected_units()
	if _location.is_empty():
		_message.text = tr("Marque o local no mapa antes de enviar.")
		return
	if us.is_empty():
		_message.text = tr("Selecione ao menos uma unidade.")
		return
	_message.text = ""
	var target := _location.duplicate()
	Sfx.play("sw")
	Sfx.static_burst()
	var names := PackedStringArray()
	for u in us:
		_units[u] = Unit.EN_ROUTE
		city.trip(u, target)
		names.append(tr(UNIT_NAMES[u]))
	_refresh()
	sent.emit(String(target["label"]), ", ".join(names))
	await get_tree().create_timer(1.8).timeout
	radio.say(["Central, unidade a caminho.", "Central, recebido. Deslocando."].pick_random())
	await get_tree().create_timer(5.6).timeout
	_arrive(us, target)


func _arrive(us: Array, target: Dictionary) -> void:
	for u in us:
		_units[u] = Unit.ON_SITE
	_refresh()
	var msg := ""
	if _incident.is_empty() or _incident["resolved"]:
		msg = tr("Central, estamos no local. Nada a relatar. Retornando.")
	elif _incident["street"] != target["street"] or _incident["block"] != target["block"]:
		msg = tr("Central, estamos na %s e não há nada aqui. Confirme o endereço.") % String(target["label"]).split(",")[0]
	else:
		for u in us:
			if not u in _incident["sent"]:
				_incident["sent"].append(u)
		var miss := []
		for r in _incident["req"]:
			if not r in _incident["sent"]:
				miss.append(tr(UNIT_NAMES[r]).to_lower())
		if not miss.is_empty():
			msg = tr("Central, precisamos de %s aqui na %s.") % [(" %s " % tr("e")).join(PackedStringArray(miss)), _incident["addr"]]
		else:
			msg = tr("Central, equipe no local. Vítimas atendidas, situação sob controle.")
			_incident["resolved"] = true
	radio.say(msg)
	await get_tree().create_timer(12.0).timeout
	for u in us:
		if _units[u] == Unit.ON_SITE:
			_units[u] = Unit.RETURNING
	_refresh()
	await get_tree().create_timer(7.0).timeout
	for u in us:
		if _units[u] == Unit.RETURNING:
			_units[u] = Unit.AVAILABLE
	city.remove_units(us)
	_refresh()
