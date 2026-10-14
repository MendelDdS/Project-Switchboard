class_name DebugPanel
extends PanelContainer
## Painel de debug (F1; só em build de debug, ou seja, no editor ou num export de debug; no export de release ele
## se apaga): toca ligações na hora, mexe na barra de agravamento, na suspeita da escuta, no relógio, no clima, nas viaturas e no caderno. Cada seção
## tem um "Limpar" que desfaz o que ela mexe, e "Restaurar tudo" faz todos (o relógio fica onde está).
## Limpar não gera advertência nem retorno. Ferramenta de desenvolvimento: textos fixos em português, sem tradução.
## A mesa de som toca cada som do `Sfx.VOL` e ajusta o volume dele na hora (`Sfx.vol`); "Copiar VOL" põe na área de
## transferência a constante pronta para colar em `sfx.gd`. A aba Vozes fala cada letra (pelo nome dela, "bê", "efe")
## ou um texto digitado, na voz escolhida, como numa ligação.

const SPEEDS := [1.0, 2.0, 4.0, 8.0]
const MIX_DB := Vector2(-40.0, 0.0)   ## faixa do controle de volume da mesa de som
const LOOP_PREVIEW := 1.5             ## segundos que um som em loop (o atrito do fio) toca na mesa de som
## O nome de cada letra, como se fala (a aba Vozes fala a letra por ele; vogal fala ela mesma).
const LETTERS := {"a": "a", "b": "bê", "c": "cê", "d": "dê", "e": "é", "f": "efe", "g": "gê", "h": "agá", "i": "i",
	"j": "jota", "k": "cá", "l": "ele", "m": "eme", "n": "ene", "o": "ó", "p": "pê", "q": "quê", "r": "erre", "s": "esse",
	"t": "tê", "u": "u", "v": "vê", "w": "dáblio", "x": "xis", "y": "ípsilon", "z": "zê", "ç": "cê cedilha", "á": "á",
	"â": "â", "ã": "ã", "é": "é", "ê": "ê", "í": "í", "ó": "ó", "ô": "ô", "õ": "õ", "ú": "ú"}
const LETTERS_PER_ROW := 10
const KIND_NAMES := ["transferência", "emergência", "trote", "informação", "desconhecida"]   # PhoneCall.Kind

var C: GameContent = GameData.CONTENT

var _status: Label
var _bar: Label
var _ears: Label   ## a suspeita de cada conversa conectada (escuta)
var _emergency: OptionButton
var _emergencies: Array[EmergencyCall] = []   ## na ordem do seletor: as escritas e depois os moldes
var _freeze: CheckButton
var _mix := {}   ## id do som -> [controle, rótulo do volume]
var _voice: OptionButton   ## a voz da aba Vozes (as chaves de `SfxSynth.VOICE`)
var _say: LineEdit
var _speaking := 0   ## a fala da aba Vozes em andamento (uma nova corta a anterior)
var _weather0 := ""   ## o clima sorteado da noite, antes de o painel trocar (o "Limpar" volta para ele)

@onready var main: Main = get_parent()
@onready var _box: VBoxContainer = %Box


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_status = _label("")
	_row([["Restaurar tudo", _restore_all]])
	_section("Ligações e mesa", main.drop_all)
	_row([["Transferência", _ring_transfer.bind(false)], ["Molde", _ring_transfer.bind(true)], ["Interurbano", _ring_trunk], ["Informação", func(): _ring(Schedule.info_call())]])
	_row([["Trote", func(): _ring(PhoneCall.from_prank(C.pranks.pick_random()))], ["Desconhecida", func(): _ring(PhoneCall.mystery())], ["Imprimir bilhete", _print_ticket]])
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
	_row([["Próximo estágio", _next_stage], ["Encerrar emergência", main.drop_emergency]])
	_freeze = CheckButton.new()
	_freeze.text = "Congelar a barra"
	_freeze.focus_mode = Control.FOCUS_NONE
	_freeze.toggled.connect(func(on: bool): main.urgency.frozen = on)
	_box.add_child(_freeze)
	_section("Escuta", func(): main.eavesdrop.calm())
	_ears = _label("")
	_row([["Forçar silêncio", func(): main.eavesdrop.force_hush()]])
	_section("Tempo", func(): Engine.time_scale = 1.0)
	var speeds := []
	for s: float in SPEEDS:
		speeds.append(["%d×" % s, func(): Engine.time_scale = s])
	_row(speeds)
	_row([["+30 min", func(): main.minutes = minf(main.minutes + 30.0, Main.SHIFT_END - 1.0)],
		["Ir para 23:50", func(): main.minutes = maxf(main.minutes, Main.SHIFT_END - 10.0)], ["Encerrar turno", func(): main.start_ending()]])
	_section("Clima", func(): if _weather0 != "": main.set_weather(_weather0))
	_row([["Chuva", _set_weather.bind("rain")], ["Névoa", _set_weather.bind("fog")], ["Limpo", _set_weather.bind("clear")]])
	var car := OptionButton.new()   # o modelo do carro que passa lá fora
	car.focus_mode = Control.FOCUS_NONE
	car.add_item("carro sorteado")
	for k: String in Background.CAR_KINDS:
		car.add_item(k)
	_box.add_child(car)
	var kind := func() -> String: return "" if car.selected <= 0 else car.get_item_text(car.selected)
	_row([["Carro na mão de lá", func(): main.background.pass_car(0, kind.call())],
		["Carro na mão de cá", func(): main.background.pass_car(1, kind.call())]])
	_section("Noites", func(): _go_night(1))
	_row([["◀ Noite anterior", func(): _go_night(main.night_no - 1)], ["Próxima noite ▶", func(): _go_night(main.night_no + 1)]])
	_section("Viaturas e caderno", _clear_units_notebook)
	_row([["Viaturas livres", func(): main.dispatch.reset()], ["Registrar pendências", _register_all]])
	_row([["Limpar advertências", func(): main.report.faults.clear()], ["Apagar progresso", Progress.clear]])
	_section("Mesa de som", _reset_mix)
	_row([["Copiar VOL", _copy_mix]])
	for id: String in Sfx.VOL:
		_mixer(id)
	_box = %Voices
	_voices()


## A aba Vozes: a voz, o alfabeto (cada letra fala o nome dela) e uma caixa de texto.
func _voices() -> void:
	_voice = OptionButton.new()
	_voice.focus_mode = Control.FOCUS_NONE
	_voice.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for v: String in SfxSynth.VOICE:
		_voice.add_item("%s · %d Hz" % [v, SfxSynth.VOICE[v]["f0"]])
	_box.add_child(_voice)
	var row := []
	for ch: String in LETTERS:
		row.append([ch.to_upper(), _speak.bind(LETTERS[ch])])
		if row.size() == LETTERS_PER_ROW:
			_row(row)
			row = []
	if not row.is_empty():
		_row(row)
	_say = LineEdit.new()
	_say.placeholder_text = "Texto para falar (Enter)"
	_say.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_say.add_theme_font_size_override("font_size", 11)
	_say.text_submitted.connect(func(t: String): _speak(t))
	_box.add_child(_say)
	_row([["Falar", func(): _speak(_say.text)]])


## Fala `text` na voz escolhida, no ritmo de `Conversation.say` (letra a letra; mais devagar na pontuação).
func _speak(text: String) -> void:
	_speaking += 1
	var me := _speaking
	var voice: String = SfxSynth.VOICE.keys()[_voice.selected]
	var prev := false
	for i in text.length():
		if me != _speaking:
			return
		prev = Sfx.speak_char(voice, text, i, prev, false, -1.0)
		await get_tree().create_timer((0.09 if text[i] in ",." else 0.028), false).timeout


func _set_weather(w: String) -> void:
	if _weather0 == "":
		_weather0 = main.weather
	main.set_weather(w)


## Recomeça o jogo na noite `n` (setores, ritmo e roteiro dela), sem ler nem gravar o progresso salvo (como
## `-- --night=N`). "Limpar" volta para a noite 1.
func _go_night(n: int) -> void:
	var tree := get_tree()
	tree.paused = false
	Sfx.ring_stop()
	Sfx.stop_ambience(0.0)
	var next: Node = load("res://scenes/main.tscn").instantiate()
	next.night_no = clampi(n, 0, C.nights.size())
	# no lugar do Main de agora, no mesmo pai: no jogo ele fica dentro da tela do `GameView` (posto na raiz, saía fora
	# dela, na resolução da janela, e quebrava o layout); sozinho, ele é a cena atual
	main.get_parent().add_child(next)
	if tree.current_scene == main:
		tree.current_scene = next
	main.queue_free()


func _process(_delta: float) -> void:
	if not visible:
		return
	var next := ""
	if not main.sched.is_empty():
		next = "\npróxima: %s %s" % [Main.fmt(main.sched[0].at), KIND_NAMES[main.sched[0].kind]]
	_status.text = "%s · noite %d · %s · %.0f×\nligações ativas: %d · advertências: %d%s" % [Main.fmt(main.minutes), main.night_no,
		main.weather, Engine.time_scale, main.live.size(), main.report.faults.size(), next]
	var lines := PackedStringArray()
	for c: PhoneCall in main.in_progress():
		var e: EmergencyCall = c.data
		var total := e.stage_sec.x + e.stage_sec.y + e.stage_sec.z
		lines.append("%s · estágio %d (contado: %d)%s\nbarra: %.0f de %.0f s%s\nexige agora: %s\nreal (sem ouvir): %s" % [
			e.address, c.stage, c.told, " · socorro completo" if c.secured else "", c.urgency, total,
			" · congelada" if main.urgency.frozen else "", _units(main.dispatch.fleet.required(e)), _units(e.required(c.stage))])
	_bar.text = "\n".join(lines) if not lines.is_empty() else "sem emergência em andamento"
	var ears := PackedStringArray()
	for n: int in main.eavesdrop.talks:
		var c := main.eavesdrop.call_of(n)
		ears.append("linha %d → %s · suspeita %.2f%s%s%s" % [n, c.dest_num, c.suspicion,
			" · ouvindo" if main.eavesdrop.listening(n) else "", " · calados" if main.eavesdrop.silent == n else "",
			" · sabem" if main.eavesdrop.knows(n) else ""])
	if not main.eavesdrop.grudges.is_empty():
		ears.append("denúncias: %s" % main.eavesdrop.grudges)
	_ears.text = "\n".join(ears) if not ears.is_empty() else "nenhuma conversa conectada"


func _ring(c: PhoneCall) -> void:
	if not main.running:
		main.warn("Debug: comece o turno primeiro.")
	elif main.free_line() == -1:
		main.warn("Debug: nenhuma entrada livre.")
	else:
		main.ring(c)


func _ring_transfer(template: bool) -> void:
	_ring(PhoneCall.from_transfer(GameData.template_transfer() if template else C.transfers.filter(GameData.serves).pick_random()))


## Um interurbano de molde, num tronco que nenhuma ligação da mesa esteja usando (dois no mesmo travavam um ao outro).
func _ring_trunk() -> void:
	var used := main.live.filter(func(x: PhoneCall): return x.data is TransferCall).map(func(x: PhoneCall): return (x.data as TransferCall).target)
	var t := GameData.trunk_transfer(used)
	if t == null:
		main.warn("Debug: todos os troncos estão em uso.")
	else:
		_ring(PhoneCall.from_transfer(t))


## Só o bilhete, sem ligação: um interurbano de molde que teria falado de 1 a 12 minutos até agora, numa entrada sem
## contador; o calculógrafo imprime como no fim de uma conversa (o som e, da primeira vez, a dica).
func _print_ticket() -> void:
	var free := range(1, Exchange.LINES + 1).filter(func(n: int): return not main.toll.counting(n))
	var t := GameData.trunk_transfer()
	if free.is_empty() or t == null:
		main.warn("Debug: nenhuma entrada sem contador.")
		return
	var n: int = free.pick_random()
	main.toll.start(n, GameData.trunk_city(int(t.target)), t.far_number, maxf(main.minutes - randf_range(1.0, 12.0), 0.0))
	main.print_ticket(n)


func _ring_emergency() -> void:
	if main.in_progress().size() >= Main.MAX_EMERGENCIES:
		main.warn("Debug: já há %d emergências em andamento." % Main.MAX_EMERGENCIES)
		return
	var e := _emergencies[_emergency.selected]
	_ring(PhoneCall.from_emergency(GameData.template_emergency(e) if e in C.emergency_templates else GameData.with_case(e)))


## Pula para o fim do estágio atual da emergência na linha do FONE (sem ela, da primeira em andamento; Urgency.tick
## muda de estágio no próximo quadro, mesmo com a barra congelada).
func _next_stage() -> void:
	var urgent := main.emergencies.filter(func(x: PhoneCall): return x.urgent())
	if urgent.is_empty():
		return
	var on: Array = urgent.filter(func(x: PhoneCall): return x.on_line)
	var c: PhoneCall = on[0] if not on.is_empty() else urgent[0]
	var e: EmergencyCall = c.data
	c.urgency = [e.stage_sec.x, e.stage_sec.x + e.stage_sec.y, e.stage_sec.x + e.stage_sec.y + e.stage_sec.z][c.stage]


# ---------------------------------------------------------------- limpar

func _restore_all() -> void:
	main.drop_all()
	_clear_bar()
	Engine.time_scale = 1.0
	_clear_units_notebook()


func _clear_bar() -> void:
	_freeze.button_pressed = false
	main.drop_emergency()


func _clear_units_notebook() -> void:
	main.dispatch.reset()
	main.notebook.reset()
	main.report.faults.clear()
	main.report.forget()


## Registra todas as pendências do caderno com o tipo certo (sem advertência).
func _register_all() -> void:
	while main.notebook.has_pending():
		main.notebook.register(Supervisor.TYPE_OF.get(main.notebook.pending.kind, T.Key.TYPE_COMMON))


func _units(us: Array) -> String:
	return ", ".join(us.map(func(u): return T.text(Fleet.NAMES[u]).to_lower())) if not us.is_empty() else "—"


# ---------------------------------------------------------------- mesa de som

## Uma linha: botão que toca o som, controle de volume e o valor (âmbar quando difere do padrão).
func _mixer(id: String) -> void:
	_row([["▶ " + id, _preview.bind(id)]])
	var row: HBoxContainer = _box.get_child(-1)
	var s := HSlider.new()
	s.min_value = MIX_DB.x
	s.max_value = MIX_DB.y
	s.step = 1.0
	s.value = Sfx.vol[id]
	s.focus_mode = Control.FOCUS_NONE
	s.custom_minimum_size.x = 110.0
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(s)
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_size_override("font_size", 11)
	l.custom_minimum_size.x = 33.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(l)
	_mix[id] = [s, l]
	s.value_changed.connect(func(db: float):
		Sfx.vol[id] = db
		_show_db(id))
	s.drag_ended.connect(func(_changed: bool): _preview(id))
	_show_db(id)


func _show_db(id: String) -> void:
	var l: Label = _mix[id][1]
	l.text = "%d" % Sfx.vol[id]
	l.theme_type_variation = &"AmberLabel" if Sfx.vol[id] != Sfx.VOL[id] else &""


## Toca o som como o jogo toca; um loop para sozinho depois de `LOOP_PREVIEW`.
func _preview(id: String) -> void:
	var p := Sfx.play(id)
	if p != null and p.stream is AudioStreamWAV and p.stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		get_tree().create_timer(LOOP_PREVIEW, false).timeout.connect(func(): if p.stream == Sfx.streams[id]: p.stop())


func _reset_mix() -> void:
	for id in _mix:
		(_mix[id][0] as HSlider).value = Sfx.VOL[id]


## A constante `VOL` com os volumes atuais, pronta para colar em `sfx.gd`.
func _copy_mix() -> void:
	var items := PackedStringArray()
	for id: String in Sfx.vol:
		items.append('"%s": %.1f' % [id, Sfx.vol[id]])
	DisplayServer.clipboard_set("const VOL := {\n\t" + ", ".join(items) + ",\n}")
	main.warn("Debug: VOL copiado.")


## Título da seção e, à direita, o botão que desfaz o que ela mexe.
func _section(title: String, clear: Callable) -> void:
	_row([["Limpar", clear]])
	var row: HBoxContainer = _box.get_child(-1)
	var l := Label.new()
	l.text = title
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.theme_type_variation = &"AmberLabel"
	l.add_theme_font_size_override("font_size", 11)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.move_child(l, 0)
	(row.get_child(1) as Button).size_flags_horizontal = Control.SIZE_SHRINK_END


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 11)
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
		b.add_theme_font_size_override("font_size", 11)
		b.pressed.connect(it[1])
		row.add_child(b)
	_box.add_child(row)
