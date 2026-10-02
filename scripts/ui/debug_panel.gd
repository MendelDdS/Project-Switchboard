class_name DebugPanel
extends PanelContainer
## Painel de debug (F1; só em build de debug, ou seja, no editor ou num export de debug; no export de release ele
## se apaga): toca ligações na hora, mexe na barra de agravamento, no relógio, nas viaturas e no caderno. Cada seção
## tem um "Limpar" que desfaz o que ela mexe, e "Restaurar tudo" faz todos (o relógio fica onde está).
## Limpar não gera advertência nem retorno. Ferramenta de desenvolvimento: textos fixos em português, sem tradução.

const SPEEDS := [1.0, 2.0, 4.0, 8.0]
const KIND_NAMES := ["transferência", "emergência", "trote", "informação", "desconhecida"]   # PhoneCall.Kind

var C: GameContent = GameData.CONTENT

var _status: Label
var _bar: Label
var _emergency: OptionButton
var _emergencies: Array[EmergencyCall] = []   ## na ordem do seletor: as escritas e depois os moldes
var _freeze: CheckButton

@onready var main: Main = get_parent()
@onready var _box: VBoxContainer = %Box


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_status = _label("")
	_row([["Restaurar tudo", _restore_all]])
	_section("Ligações e mesa", _clear_calls)
	_row([["Transferência", _ring_transfer.bind(false)], ["Molde", _ring_transfer.bind(true)], ["Informação", func(): _ring(Schedule.info_call())]])
	_row([["Trote", func(): _ring(PhoneCall.from_prank(C.pranks.pick_random()))], ["Desconhecida", func(): _ring(PhoneCall.mystery())]])
	_emergency = OptionButton.new()
	_emergency.focus_mode = Control.FOCUS_NONE
	for e in C.emergencies:
		_emergencies.append(e)
		_emergency.add_item(e.resource_path.get_file().get_basename().trim_prefix("emergency_"))
	for e in C.emergency_templates:
		_emergencies.append(e)
		_emergency.add_item("molde: " + e.resource_path.get_file().get_basename().trim_prefix("emergency_"))
	_box.add_child(_emergency)
	_row([["Tocar emergência (caso sorteado)", _ring_emergency]])
	_section("Barra de agravamento", _clear_bar)
	_bar = _label("")
	_row([["Próximo estágio", _next_stage], ["Encerrar emergência", _clear_emergency]])
	_freeze = CheckButton.new()
	_freeze.text = "Congelar a barra"
	_freeze.focus_mode = Control.FOCUS_NONE
	_freeze.toggled.connect(func(on: bool): main.debug_freeze = on)
	_box.add_child(_freeze)
	_section("Tempo", func(): Engine.time_scale = 1.0)
	var speeds := []
	for s: float in SPEEDS:
		speeds.append(["%d×" % s, func(): Engine.time_scale = s])
	_row(speeds)
	_row([["+30 min", func(): main.minutes = minf(main.minutes + 30.0, Main.SHIFT_END - 1.0)],
		["Ir para 23:50", func(): main.minutes = maxf(main.minutes, Main.SHIFT_END - 10.0)], ["Encerrar turno", func(): main._start_ending()]])
	_section("Viaturas e caderno", _clear_units_notebook)
	_row([["Viaturas livres", func(): main.dispatch.reset()], ["Registrar pendências", _register_all]])
	_row([["Limpar advertências", func(): main.report.faults.clear()], ["Apagar progresso", Progress.clear]])


func _process(_delta: float) -> void:
	if not visible:
		return
	var next := ""
	if not main.sched.is_empty():
		next = "\npróxima: %s %s" % [Main.fmt(main.sched[0].at), KIND_NAMES[main.sched[0].kind]]
	_status.text = "%s · noite %d · %s · %.0f×\nligações ativas: %d · advertências: %d%s" % [Main.fmt(main.minutes), main.night_no,
		main.weather, Engine.time_scale, main.live.size(), main.report.faults.size(), next]
	var c: PhoneCall = main.em_call
	if c == null or c.ended and not c.urgent():
		_bar.text = "sem emergência em andamento"
		return
	var e: EmergencyCall = c.data
	var total := e.stage_sec.x + e.stage_sec.y + e.stage_sec.z
	_bar.text = "%s · estágio %d (contado: %d)%s\nbarra: %.0f de %.0f s%s\nexige agora: %s\nreal (sem ouvir): %s" % [
		e.address, c.stage, c.told, " · socorro completo" if c.secured else "", c.urgency, total,
		" · congelada" if main.debug_freeze else "", _units(main.dispatch.required()), _units(e.required(c.stage))]


func _ring(c: PhoneCall) -> void:
	if not main.running:
		main.warn("Debug: comece o turno primeiro.")
	elif main._free_line() == -1:
		main.warn("Debug: nenhuma entrada livre.")
	else:
		main.ring(c)


func _ring_transfer(template: bool) -> void:
	_ring(PhoneCall.from_transfer(GameData.template_transfer() if template else C.transfers.pick_random()))


func _ring_emergency() -> void:
	var e := _emergencies[_emergency.selected]
	_ring(PhoneCall.from_emergency(GameData.template_emergency(e) if e in C.emergency_templates else GameData.with_case(e)))


## Pula para o fim do estágio atual (Main._worsen muda de estágio no próximo quadro, mesmo com a barra congelada).
func _next_stage() -> void:
	var c: PhoneCall = main.em_call
	if c == null or not c.urgent():
		return
	var e: EmergencyCall = c.data
	c.urgency = [e.stage_sec.x, e.stage_sec.x + e.stage_sec.y, e.stage_sec.x + e.stage_sec.y + e.stage_sec.z][c.stage]


# ---------------------------------------------------------------- limpar

func _restore_all() -> void:
	_clear_calls()
	_clear_bar()
	Engine.time_scale = 1.0
	_clear_units_notebook()


## Encerra todas as ligações ativas sem consequência, zera a mesa (linhas e destinos livres antes de tirar os cabos:
## assim nada conta como conversa cortada) e tira da agenda quem ia ligar de novo.
func _clear_calls() -> void:
	_clear_emergency()
	for c in main.live.duplicate():
		_drop(c)
	for c in main.sched.duplicate():
		if c.retry != PhoneCall.Retry.NONE:
			main.sched.erase(c)
	for n in range(1, Exchange.LINES + 1):
		main.exchange.set_line(n, Exchange.Line.FREE)
	for d in GameData.board_numbers():
		main.exchange.set_dest(d, Exchange.Dest.FREE)
		main._dgen[d] = int(main._dgen.get(d, 0)) + 1   # toques de destino pendentes não valem mais
	for e in main.board.ends.size():
		if main.board.ends[e] != -1:
			main.board.pick_up(e)
			main.board.go_home(e)


## A emergência em andamento some sem consequência: a ligação cai, a barra e a luz do rádio apagam, as viaturas
## voltam, o jornal esquece dela e ela não liga de novo.
func _clear_emergency() -> void:
	var c: PhoneCall = main.em_call
	if c == null:
		return
	if c in main.live:
		_drop(c)
		main.exchange.set_line(c.line, Exchange.Line.FREE)
	for r in main.sched.duplicate():
		if r.data == c.data:
			main.sched.erase(r)
	main.em_call = null
	main.dispatch.reset(true)
	main.report._incidents.erase(c.data)


func _clear_bar() -> void:
	_freeze.button_pressed = false
	_clear_emergency()


func _clear_units_notebook() -> void:
	main.dispatch.reset()
	main.notebook.reset()
	main.report.faults.clear()
	main.report._incidents.clear()


## Tira a ligação do turno como se ela nunca tivesse existido (sem caderno, advertência nem retorno).
func _drop(c: PhoneCall) -> void:
	c.ended = true   # as falas em andamento param sozinhas
	c.active = false
	c.ringing = false
	c.on_line = false
	c.set_talking(false)
	c.set_options([])
	main.live.erase(c)
	if c.kind == PhoneCall.Kind.MYSTERY:
		main._mystery_aftermath(c)   # o turno pode terminar e a noite volta ao normal
	main._update_bell()
	main._refresh_panel()


## Registra todas as pendências do caderno com o tipo certo (sem advertência).
func _register_all() -> void:
	while main.notebook.has_pending():
		main.notebook.register(Supervisor.TYPE_OF.get(main.notebook.pending["kind"], T.Key.TYPE_COMMON))


func _units(us: Array) -> String:
	return ", ".join(us.map(func(u): return T.text(Dispatch.UNIT_NAMES[u]).to_lower())) if not us.is_empty() else "—"


## Título da seção e, à direita, o botão que desfaz o que ela mexe.
func _section(title: String, clear: Callable) -> void:
	_row([["Limpar", clear]])
	var row: HBoxContainer = _box.get_child(-1)
	var l := Label.new()
	l.text = title
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.theme_type_variation = &"AmberLabel"
	l.add_theme_font_size_override("font_size", 14)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.move_child(l, 0)
	(row.get_child(1) as Button).size_flags_horizontal = Control.SIZE_SHRINK_END


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 14)
	_box.add_child(l)
	return l


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
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(it[1])
		row.add_child(b)
	_box.add_child(row)
