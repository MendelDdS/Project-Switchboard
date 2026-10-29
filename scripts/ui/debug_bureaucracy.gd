extends VBoxContainer
## A aba Burocracias do painel de debug (F1): como usar, a chave geral, a noite simulada e o relógio; cada regra registrada
## (`Bureaucracy.rules`) aparece sozinha, com a chave dela, os parâmetros (as `@export` do script dela, editáveis na
## hora), o que ela mostra (`debug_info`), um botão por ligação de teste (`tests`; ele liga a chave geral e a regra) e os
## botões dela
## (`debug_actions`); embaixo, os equipamentos da mesa que as regras trazem (liberar, tirar, simular a chegada), o
## registro de decisões e as advertências da noite. Regra nova não precisa de nada aqui.
## Ferramenta de desenvolvimento: textos fixos em português, sem tradução.

const BASE := ["id", "title", "active", "tests"]   ## campos de toda regra que não viram editor (a chave é o CheckButton)
const LOG_LINES := 14   ## decisões mostradas (as últimas)

var _status: Label
var _log: Label
var _faults: Label
var _infos := {}   ## BureaucracyRule -> Label do `debug_info`
var _equipment: Label
var _switch: CheckButton   ## a chave geral
var _toggles := {}   ## BureaucracyRule -> a chave dela (as duas acompanham o que mudar por fora: os botões de teste, o roteiro)

@onready var main: Main = owner.get_parent()


func _ready() -> void:
	if not OS.is_debug_build():
		return
	_build.call_deferred()   # (o Main ainda não montou o gerente)


func _build() -> void:
	for n in get_children():
		n.queue_free()
	_infos.clear()
	_toggles.clear()
	_label("Como usar: comece o turno e toque uma ligação de teste (o botão liga a chave geral e a regra dela). Atenda "
		+ "com o FONE e siga a ligação; as opções novas aparecem nas respostas.")
	_status = _label("")
	_switch = CheckButton.new()
	_switch.text = "Chave geral"
	_switch.button_pressed = Bureaucracy.enabled
	_switch.toggled.connect(main.bureaucracy.enable)
	_add(_switch)
	var night := _spin(0, GameData.CONTENT.nights.size(), main.bureaucracy.night, func(v: float): main.bureaucracy.set_night(int(v)))
	_pair("Noite simulada", night)
	_row([["−30 min", func(): main.minutes = maxf(main.minutes - 30.0, 0.0)], ["+30 min", func(): main.minutes = minf(main.minutes + 30.0, main.shift_end - 1.0)]])
	_row([["Resetar burocracias", _reset]])
	for r in Bureaucracy.rules():
		_rule(r)
	_title("Equipamentos da mesa")
	_equipment = _label("")
	for id in main.bureaucracy.all_equipment():
		_row([["Liberar " + id, main.bureaucracy.unlock_equipment.bind(id)], ["Tirar", main.bureaucracy.lock_equipment.bind(id)],
			["Chegada", func(): main.bureaucracy.equipment_unlocked.emit(id)]])
	_title("Registro de decisões")
	_log = _label("")
	_title("Advertências da noite")
	_faults = _label("")
	main.bureaucracy.decided.connect(func(_e): _refresh())
	_refresh()


func _process(_delta: float) -> void:
	if _status != null and is_visible_in_tree():
		_status.text = "%s · noite %d (simulada %d) · %s" % [Main.fmt(main.minutes), main.night_no, main.bureaucracy.night,
			"valendo: " + ", ".join(main.bureaucracy.live().map(func(r): return r.id)) if Bureaucracy.enabled else "chave geral desligada"]
		_equipment.text = "na mesa: " + (", ".join(main.bureaucracy.equipment()) if not main.bureaucracy.equipment().is_empty() else "nada (lugar tampado)")
		_switch.set_pressed_no_signal(Bureaucracy.enabled)
		for r: BureaucracyRule in _toggles:
			(_toggles[r] as CheckButton).set_pressed_no_signal(r.active)
		for r: BureaucracyRule in _infos:
			(_infos[r] as Label).text = r.debug_info()
		_faults.text = "\n".join(main.report.faults.map(func(f): return "%s %s · %s%s" % [f["time"],
			T.text(ShiftReport.SEVERITY_NAMES[ShiftReport.level(f)]).to_lower(), f["id"], " (%s)" % f["detail"] if f["detail"] != "" else ""])) if not main.report.faults.is_empty() else "nenhuma"


## Uma regra: a chave, os parâmetros, o que ela mostra e os botões de teste.
func _rule(r: BureaucracyRule) -> void:
	_title("%s (%s)" % [r.title, r.id] if r.title != "" else r.id)
	var on := CheckButton.new()
	on.text = "Ligada"
	on.button_pressed = r.active
	on.toggled.connect(func(v: bool): main.bureaucracy.activate(r.id) if v else main.bureaucracy.deactivate(r.id))
	_add(on)
	_toggles[r] = on
	for p in r.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and p["usage"] & PROPERTY_USAGE_EDITOR and not p["name"] in BASE:
			_param(r, p)
	_infos[r] = _label("")
	var buttons := []
	for t in r.tests:
		buttons.append(["▶ " + (t.resource_name if t.resource_name != "" else t.caller), _ring.bind(t, r)])
	buttons.append_array(r.debug_actions())
	for bt in buttons:   # um por linha: os nomes dos testes são compridos
		_row([bt])


## O editor de um parâmetro, pelo tipo dele.
func _param(r: BureaucracyRule, p: Dictionary) -> void:
	var key: String = p["name"]
	var v = r.get(key)
	var c: Control
	match p["type"]:
		TYPE_BOOL:
			var b := CheckButton.new()
			b.button_pressed = v
			b.toggled.connect(func(x: bool): r.set(key, x))
			c = b
		TYPE_INT when p["hint"] == PROPERTY_HINT_ENUM:
			var o := OptionButton.new()
			var items := String(p["hint_string"]).split(",")
			for i in items.size():   # o valor no metadado: o id do OptionButton não aceita -1 ("Nenhuma:-1")
				o.add_item(items[i].get_slice(":", 0))
				o.set_item_metadata(i, int(items[i].get_slice(":", 1)) if ":" in items[i] else i)
				if o.get_item_metadata(i) == v:
					o.selected = i
			o.item_selected.connect(func(x: int): r.set(key, o.get_item_metadata(x)))
			c = o
		TYPE_INT, TYPE_FLOAT:
			c = _spin(-9999, 9999, v, func(x: float): r.set(key, int(x) if p["type"] == TYPE_INT else x))
			(c as SpinBox).step = 1.0 if p["type"] == TYPE_INT else 0.1
		TYPE_STRING, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY:
			var e := LineEdit.new()
			e.text = v if p["type"] == TYPE_STRING else ", ".join(Array(v).map(str))
			var apply := func(_t := ""):
				match p["type"]:
					TYPE_STRING:
						r.set(key, e.text)
					TYPE_PACKED_STRING_ARRAY:
						r.set(key, PackedStringArray(Array(e.text.split(",", false)).map(func(s: String): return s.strip_edges())))
					_:
						r.set(key, PackedInt32Array(Array(e.text.split(",", false)).map(func(s: String): return int(s))))
			e.text_submitted.connect(apply)
			e.focus_exited.connect(apply)
			c = e
		_:
			c = _label("(edite no .tres)")
			remove_child(c)
	_pair(key, c)


func _refresh() -> void:
	var d := main.bureaucracy.decisions
	_log.text = "\n".join(d.slice(maxi(d.size() - LOG_LINES, 0)).map(func(e): return "N%d %s %s · %s: %s → %s" % [
		e["night"], e["time"], e["who"], e["rule"], e["choice"], e["result"]])) if not d.is_empty() else "nenhuma decisão"


func _reset() -> void:
	main.bureaucracy.reset()
	main.bureaucracy.decisions.clear()
	_build()


## Toca a ligação de teste `t` da regra `r`, ligando antes a chave geral e a regra (senão tocava como uma comum).
func _ring(t: TransferCall, r: BureaucracyRule) -> void:
	if not main.running:
		main.warn("Debug: comece o turno primeiro.")
	elif main.free_line() == -1:
		main.warn("Debug: nenhuma entrada livre.")
	else:
		if not Bureaucracy.enabled:
			main.bureaucracy.enable(true)
		if not r.active:
			main.bureaucracy.activate(r.id)
		if not r.applies(main.bureaucracy.night):
			main.warn("Debug: %s não vale na noite %d (from_night, to_night)." % [r.id, main.bureaucracy.night])
		main.ring(PhoneCall.from_transfer(t))


# ---------------------------------------------------------------- peças (as do `DebugPanel`, nesta caixa)

func _add(c: Control) -> void:
	c.focus_mode = Control.FOCUS_NONE if not c is LineEdit and not c is SpinBox else Control.FOCUS_CLICK
	c.add_theme_font_size_override("font_size", 11)
	add_child(c)


func _title(text: String) -> void:
	var l := _label(text)
	l.theme_type_variation = &"AmberLabel"


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add(l)
	return l


## Nome à esquerda, controle à direita.
func _pair(name: String, c: Control) -> void:
	var row := HBoxContainer.new()
	add_child(row)
	var l := _label(name)
	l.reparent(row)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size.x = 0.0
	c.add_theme_font_size_override("font_size", 11)
	if c is LineEdit:
		(c as LineEdit).expand_to_text_length = false
	if c.get_parent() != null:
		c.reparent(row)
	else:
		row.add_child(c)


func _spin(lo: float, hi: float, v: float, on: Callable) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.value = v
	s.value_changed.connect(on)
	return s


## Uma linha de botões: cada item é [texto, Callable].
func _row(items: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for it in items:
		var b := Button.new()
		b.text = it[0]
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.focus_mode = Control.FOCUS_NONE
		b.theme_type_variation = &"DarkButton"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true   # (o painel tem 255 px: nome comprido não alarga a coluna)
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(it[1])
		row.add_child(b)
	add_child(row)
