class_name Main
extends Control
## Project Switchboard — conduz o turno: relógio, agenda das ligações, o que a mesa significa para cada
## ligação, fim de ligação e o final. As falas ficam em Conversation; a interface, nas cenas de scenes/ui/.
##
## Laço: ATENDER → ENTENDER → CONSULTAR → CONECTAR/DESPACHAR → REGISTRAR → CONTINUAR

const GAME_MIN_PER_SEC := 0.75          # 360 minutos de turno ≈ 8 minutos reais
const SHIFT_START_HOUR := 18            # o turno vai das 18:00...
const SHIFT_END := 360.0                # ...até 00:00 (minutos depois do início)
const LAST_CALL := 340.0                # 23:40: nada novo toca depois (a desconhecida tem regra própria) e aparece
										# o botão Encerrar turno; quem está na linha à meia-noite é atendido até o fim
const SHADOW_LEAD := 25.0               # minutos antes da ligação desconhecida em que o homem para embaixo do poste (chega andando)...
const SHADOW_LEAVE := 10.0              # ...e em que vai embora andando (para ir ligar): fica 15 minutos
const WEATHERS := ["rain", "fog", "clear"]   # clima sorteado no começo do turno (`-- --weather=fog` força um)
const TALK_LEN := Vector2(34.0, 68.0)   # duração (min de jogo) de uma conversa transferida (≈ 45–90 s reais)
const GIVE_UP_SEC := 60.0               # quem liga desiste se ninguém atende (as do roteiro aguentam 1,5x; retornos, 0,75x)
const SMALLTALK_AFTER := 10.0           # segundos de silêncio esperando a transferência até puxar conversa fiada...
const SMALLTALK_CHANCE := 0.6           # ...às vezes (respostas e limites: Conversation); sem resposta, reclama da demora:
const NAG_AFTER := 22.0                 # segundos de silêncio até reclamar da demora (emergência: EMERGENCY_NAG_AFTER)
const EMERGENCY_NAG_AFTER := 26.0
## Atalhos das ferramentas (Input Map): aba -> ação.
const TAB_KEYS := {"lista": "tab_directory", "despacho": "tab_dispatch", "caderno": "tab_logbook", "registro": "tab_call_log"}
var C: GameContent = GameData.CONTENT

var exchange: Exchange
var night_no := 0                  ## número da noite (1 = primeira); 0 = a salva (`-- --night=N` força uma, sem salvar)
var night: Night                   ## roteiro fixo da noite
var pace_level := 1                ## nível de ritmo desta noite (GameContent.paces)
var force_sectors: Array = []      ## testes: setores atendidos (vazio = os da noite, GameData.SECTOR_NIGHTS)
var pace: Pace                     ## ritmo das ligações sorteadas desta noite
var progress: Progress             ## progresso salvo; nulo quando a noite foi forçada (testes, `--night`)
var flags: StoryFlags:             ## marcadores do roteiro valendo agora: os salvos + os desta noite (mudam a sala)
	set(v):
		flags = v
		flags.changed.connect(func(_n: String, _on: bool): _update_room())
var weather := "rain"
var report := ShiftReport.new()    ## advertências do turno, conferidas pelo supervisor no fim do turno
var minutes := 0.0
var running := false
var sched: Array[PhoneCall] = []   ## ligações ainda por tocar, em ordem de horário (montadas por `Schedule`)
var live: Array[PhoneCall] = []    ## tocando ou em andamento (podem ser várias ao mesmo tempo)
var tut: PhoneCall                 ## primeira ligação: guia passo a passo
var em_call: PhoneCall
var myst_time := "02:13"
var myst_line := 0                 ## entrada por onde veio a ligação desconhecida (sorteada)
var myst_plan := INF               ## horário sorteado da ligação desconhecida (a silhueta segue este, mesmo se ela atrasar)
var after := false                 ## a ligação desconhecida já tocou e caiu
var ending := false
var flick := false

var _dgen := {}                    ## número -> geração do toque (invalida toques quando o cabo sai)
var _sent := {}                    ## último despacho: call, loc, units
var _taught_done := false
var _taught_multi := false
var _taught_ring := false
var _taught_list := false
var _myst_lead := false
var _calling_back := false
var _tick_acc := 0.0
var _taught_midnight := false
var _taught_bank := false
var _hour := 0   ## a última hora cheia em que o relógio bateu (horas desde o começo do turno)
var talk_clock := 0.0              ## segundos de jogo (param na pausa); medem o silêncio na linha (PhoneCall.last_talk)

@onready var background: Background = %Background
@onready var _end_shift: Button = %EndShift
@onready var _shift_hours: Label = %ShiftHours
@onready var board: Switchboard = %Board
@onready var phone: PhonePanel = %Phone
@onready var radio: Radio = phone.radio
@onready var tools: Tools = %Tools
@onready var notebook: Notebook = tools.notebook
@onready var dispatch: Dispatch = tools.dispatch
@onready var conversation: Conversation = %Conversation
@onready var supervisor: Supervisor = %Supervisor
@onready var urgency: Urgency = %Urgency
@onready var _hint: RichTextLabel = %Hint
@onready var _glow: CanvasItem = %Glow
@onready var _intro: Intro = %Intro
@onready var _ending: Ending = %Ending
@onready var _pause: PauseMenu = %PauseMenu


func _init() -> void:
	flags = StoryFlags.new()


## A noite (e os setores dela) vem antes dos filhos ficarem prontos: a lista telefônica monta as páginas no `_ready`.
func _enter_tree() -> void:
	_load_night()


func _ready() -> void:
	_apply_seed()
	weather = night.weather if night.weather != "" else WEATHERS.pick_random()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--weather=") and a.get_slice("=", 1) in WEATHERS:
			weather = a.get_slice("=", 1)
	background.weather = weather
	background.night = night_no
	_update_room()
	exchange = Exchange.new(GameData.board_numbers())
	board.setup(exchange, %FoneSocket, %CordTray)
	var plan := Schedule.build(night, pace, LAST_CALL)
	sched = plan.calls
	tut = plan.tut
	myst_plan = plan.mystery_at
	after = night.mystery.is_empty()   # noite sem ligação desconhecida: o turno fecha à meia-noite
	board.end_changed.connect(_on_end_changed)
	board.info_requested.connect(_show_line_info)
	board.warned.connect(warn)
	phone.answer_pressed.connect(answer)
	phone.transfer_pressed.connect(transfer)
	phone.hangup_pressed.connect(hangup)
	_end_shift.pressed.connect(end_shift)
	_intro.start_pressed.connect(_start_shift)
	_intro.settings_pressed.connect(_pause.open_settings)
	_pause.resumed.connect(_update_bell)
	dispatch.radio = radio
	(%Mini as ConsoleMini).phone = phone
	dispatch.sent.connect(_on_dispatched)
	dispatch.arrived.connect(supervisor.on_arrived)
	dispatch.blank_card.connect(func(loc: String): supervisor.fault("dispatch_blank", loc))
	notebook.registered.connect(supervisor.on_registered)
	notebook.pending_changed.connect(func(n: int):
		tools.set_count("caderno", n)
		background.pending = n
		if n > 0:
			_teach("viu_tiras_caderno", T.Key.HINT_DESK_SLIPS))
	tools.call_log.unread_changed.connect(func(on: bool):
		background.unread = on
		if on:
			_teach("viu_folha_registro", T.Key.HINT_DESK_SHEET))
	tools.origin = background.prop_rect   # o papel de cada ferramenta sai do objeto dela na mesa
	background.prop_clicked.connect(func(id: String): if running and not ending: tools.set_tab(id))   # objetos da cena
	_intro.setup(night_no, night, progress != null and progress.night > 1)
	if progress != null and night_no > 1:   # o jornal da manhã, com o que aconteceu na noite anterior
		set_news(progress.news)
	# noite de entrega de um setor: o mapa se abre para o bairro novo na primeira vez que aparece
	var before := GameData.sectors_for(night_no - 1)
	if force_sectors.is_empty() and night_no > 1 and before.size() < GameData.sectors.size():
		dispatch.city.pending_reveal = before
	_refresh_panel()


## Qual noite jogar: `-- --night=N`, a definida antes de entrar na árvore (testes) ou a salva, e em que ritmo: o
## salvo; numa noite forçada, o de quem não tropeçou (`Pace.expected`). `-- --pace=N` força o nível (para medir com o robô).
## `-- --flags=a,b` liga marcadores para testar um ramo do roteiro numa noite forçada.
func _load_night() -> void:
	var forced_pace := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--night="):
			night_no = int(a.get_slice("=", 1))
		elif a.begins_with("--pace="):
			forced_pace = int(a.get_slice("=", 1))
		elif a.begins_with("--flags="):
			for f in a.get_slice("=", 1).split(",", false):
				flags.apply(f)
	pace_level = Pace.expected(night_no)
	if night_no == 0:
		progress = Progress.load_saved()
		night_no = progress.night
		pace_level = progress.pace
		report.severe_before = progress.severe
		for f in progress.flags:
			flags.apply(f)
	night_no = clampi(night_no, 1, C.nights.size())
	night = C.nights[night_no - 1]
	GameData.sectors = GameData.sectors_for(night_no) if force_sectors.is_empty() else force_sectors
	pace_level = clampi(forced_pace if forced_pace > 0 else pace_level, 1, C.paces.size())
	pace = C.paces[pace_level - 1]
	report.night = night_no


## `godot -- --seed=123` repete a mesma agenda de ligações (útil para reproduzir bugs).
func _apply_seed() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed(int(a.get_slice("=", 1)))
			return
	randomize()


static func fmt(m: float) -> String:
	var t := (SHIFT_START_HOUR * 60 + int(floor(m))) % 1440
	if t < 0:
		t += 1440
	return "%02d:%02d" % [t / 60, t % 60]


func hint(t: String) -> void:
	_hint.text = "" if t == "" else "[color=#8a2a1c]%s[/color]  %s" % [T.text(T.Key.HINT_BADGE), t]   # carimbado em vermelho, como o caderno
	_hint.self_modulate.a = 0.0 if t == "" else 1.0   # sem dica, o papel some (o lugar dele fica: nada pula)


## Dica da primeira vez que um sinal da mesa aparece, uma vez no jogo todo: o "já viu" (`flag`) fica nos marcadores,
## salvos entre as noites. Durante o tutorial espera (a dica dele não pode ser atropelada).
func _teach(flag: String, key: T.Key) -> void:
	if flags.has(flag) or (tut != null and not tut.ended):
		return
	flags.apply(flag)
	hint(T.text(key))


func warn(t: String) -> void:
	phone.warn(t)


## Troca o clima na hora (painel de debug): a janela, o ambiente (se a noite já começou) e a conversa fiada.
func set_weather(w: String) -> void:
	weather = w
	background.weather = w
	if running:
		Sfx.set_weather(w, 2.0)


# ================================================================ laço principal

func _start_shift() -> void:
	Sfx.start_ambience(weather)
	running = true
	radio.say(T.text(T.Key.RADIO_PATROL))
	hint(T.text(T.Key.HINT_WAIT_CALLS))


func _process(delta: float) -> void:
	talk_clock += delta
	if running:
		# à meia-noite o relógio para, a não ser que ainda haja alguém na linha (o turno se estende até resolver)
		if minutes < SHIFT_END or not live.is_empty():
			minutes += delta * GAME_MIN_PER_SEC
		_tick_acc += delta
		if _tick_acc > 1.0:
			_tick_acc = 0.0
			Sfx.play("tick", -3.0)
		_run_schedule()
		_update_line_timers()
		# o turno fecha depois da meia-noite, da ligação desconhecida, da última ligação e do último registro
		# (com registro pendente, espera o operador registrar ou encerrar pelo botão)
		if minutes >= SHIFT_END and after and live.is_empty():
			if not _unregistered():
				start_ending()
			elif not _taught_midnight:
				_taught_midnight = true
				hint(T.text(T.Key.HINT_MIDNIGHT))
		var can_end := after and minutes >= LAST_CALL and not ending
		if can_end and not _end_shift.visible:   # a campainha da plaqueta: o turno já pode ser encerrado
			Sfx.play_at("shift_bell", _shift_hours.get_global_rect().get_center().x)
		_end_shift.visible = can_end
		_shift_hours.visible = not _end_shift.visible
		var hour := floori(minutes / 60.0)
		if hour > _hour:   # a badalada do relógio a cada hora cheia (vem do relógio de flip da mesa) e o sino da igreja
			Sfx.play_at("chime", background.clock_x)
			background.toll((SHIFT_START_HOUR + hour - 1) % 12 + 1)
		_hour = hour
		background.minutes = SHIFT_START_HOUR * 60 + minutes
		_nag()
		supervisor.check_hold()
	background.flick = flick
	_glow.modulate.a = background.lamp_level


## Quem está na linha esperando o operador: na transferência, às vezes puxa conversa fiada depois de um tempo e,
## se a demora continuar, reclama; na emergência, pede pressa (só antes de a situação piorar).
func _nag() -> void:
	var f := _focus()
	if f == null or not f.active or f.talking or f.closing:
		return
	var quiet := talk_clock - f.last_talk
	if f.kind == PhoneCall.Kind.TRANSFER and f.phase == PhoneCall.Phase.AWAIT:
		if _transferred(f):   # o destino está tocando ou atendeu: ela espera quieta
			return
		if not f.chatted and quiet > SMALLTALK_AFTER:
			f.chatted = true
			if randf() < SMALLTALK_CHANCE:
				f.last_talk = talk_clock
				conversation.smalltalk(f)
		elif quiet > NAG_AFTER:
			f.last_talk = talk_clock
			f.chat = null   # a deixa da conversa passou
			f.chatting = false
			conversation.transfer_choices(f)
			conversation.say(f, GameData.pick(C.waiting))
	# só no estágio inicial: depois, a fala de cada estágio já cobra a demora
	elif f.kind == PhoneCall.Kind.EMERGENCY and not f.dispatched and f.stage == 0 and quiet > EMERGENCY_NAG_AFTER:
		f.last_talk = talk_clock
		conversation.say(f, GameData.pick(C.emergency_waiting))


## Esc: primeiro devolve o plug que está na mão; depois guarda a ferramenta aberta; sem nada disso, pausa o turno.
## 1 a 4 abrem e guardam as ferramentas (só durante o turno; na pausa a árvore está parada). F1 abre o painel de
## debug (só em build de debug).
func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("cancel_plug") and board.held != -1:
		board.go_home(board.held)
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("debug") and OS.is_debug_build():
		get_viewport().set_input_as_handled()
		%Debug.visible = not %Debug.visible
	elif e.is_action_pressed("pause") and running and not ending and tools.open and e is InputEventKey and e.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		tools.close()
	elif e.is_action_pressed("pause") and running and not ending:
		get_viewport().set_input_as_handled()
		pause()
	elif running and not ending:
		for id in TAB_KEYS:
			if e.is_action_pressed(TAB_KEYS[id]):
				get_viewport().set_input_as_handled()
				tools.toggle(id)


func pause() -> void:
	Sfx.ring_stop()   # o Sfx segue tocando na pausa; a campainha volta com _update_bell ao continuar
	_pause.open()


# ================================================================ mesa comutadora

## A ligação em que o operador está: a da entrada onde o FONE está.
func _focus() -> PhoneCall:
	return _call_on_line(board.fone_line())


func _call_on_line(n: int) -> PhoneCall:
	for c in live:
		if c.line == n:
			return c
	return null


func _on_end_changed(e: int, j: int, prev: int) -> void:
	if prev != -1:
		_vacated(prev, e)
	if j != -1:
		_filled(j, e)
	tutorial_step()
	_refresh_panel()


## FONE numa entrada: a ligação dessa linha passa a ser a do operador.
func _filled(j: int, e: int) -> void:
	if e != 0:
		return
	if j == myst_line and after:
		_call_back_mystery()
	var c := _call_on_line(j)
	if c != null and c.active and exchange.line(j) == Exchange.Line.HOLD:
		exchange.set_line(j, Exchange.Line.TALK)


## Um plug saiu da tomada j.
func _vacated(j: int, e: int) -> void:
	if e == 0:
		# FONE saiu: se o destino já atendeu, a ligação segue pelo cabo de conexão (o agradecimento ficou pela
		# metade); se já foi resolvida, a pessoa termina de falar e desliga; senão fica em espera.
		var c := _call_on_line(j)
		if c != null and c.active and not c.closing:
			if not _try_complete(c):
				exchange.set_line(j, Exchange.Line.HOLD)
				c.hold_since = minutes
				c.sys(T.text(T.Key.SYS_ON_HOLD))
		elif c == null:
			_maybe_free(j)
		return
	var other := board.end_jack(board.mate(e))
	if j <= 20:
		# saiu da SAÍDA da linha n
		var n := j - 10
		var c := _call_on_line(n)
		if c != null and c.active:
			if other > 20:
				_cut_dest(c, other)
		else:
			if exchange.line(n) == Exchange.Line.CONN:
				exchange.set_line(n, Exchange.Line.DONE)   # a conversa foi cortada
				supervisor.fault("cut_call", T.text(T.Key.LINE_N) % n)
				if other > 20 and exchange.dest(other) == Exchange.Dest.CONN:
					exchange.set_dest(other, Exchange.Dest.DONE)
			_maybe_free(n)
		return
	# saiu do destino j
	var st := exchange.dest(j)
	exchange.set_dest(j, Exchange.Dest.FREE)
	cancel_dest_ring(j)
	if st == Exchange.Dest.FREE:
		return
	Sfx.play("sw")
	if other >= 11 and other <= 20:
		var n := other - 10
		var c := _call_on_line(n)
		if c != null and c.active:
			c.sys((T.text(T.Key.SYS_CALL_TO_CANCELLED) if st == Exchange.Dest.RING else T.text(T.Key.SYS_DISCONNECTED)) % j)
			phone.clear_flash()
			conversation.transfer_choices(c)
		elif exchange.line(n) == Exchange.Line.CONN:
			exchange.set_line(n, Exchange.Line.DONE)
			supervisor.fault("cut_call", T.text(T.Key.LINE_N) % n)


## Cabo tirado da SAÍDA no meio de uma transferência: o destino para de tocar ou cai.
func _cut_dest(c: PhoneCall, d: int) -> void:
	if exchange.dest(d) == Exchange.Dest.RING:
		exchange.set_dest(d, Exchange.Dest.FREE)
		cancel_dest_ring(d)
		c.sys(T.text(T.Key.SYS_CALL_TO_CANCELLED) % d)
	elif exchange.dest(d) == Exchange.Dest.CONN:
		exchange.set_dest(d, Exchange.Dest.DONE)
		c.sys(T.text(T.Key.SYS_DISCONNECTED) % d)
	conversation.transfer_choices(c)


## Linha sem ligação e sem plugs volta a ficar livre.
func _maybe_free(n: int) -> void:
	if exchange.line(n) in [Exchange.Line.CONN, Exchange.Line.DONE] and board.cord_at(n) == -1 \
			and board.cord_at(n + 10) == -1 and _call_on_line(n) == null:
		exchange.set_line(n, Exchange.Line.FREE)
		Sfx.play("sw")


## Botão Transferir: chama o destino ligado à SAÍDA da linha em que o FONE está.
func transfer() -> void:
	var c := _focus()
	if c == null or not c.active:
		warn(T.text(T.Key.WARN_FONE_TO_TRANSFER))
		return
	if c.kind != PhoneCall.Kind.TRANSFER:
		warn(T.text(T.Key.WARN_NOT_TRANSFER))
		return
	if c.phase != PhoneCall.Phase.AWAIT:
		warn(T.text(T.Key.WARN_LISTEN_FIRST))
		return
	var d := board.dest_of_output(c.line)
	if d == -1:
		warn(T.text(T.Key.WARN_PLUG_OUTPUT) % c.line)
		return
	if exchange.dest(d) != Exchange.Dest.FREE:
		warn(T.text(T.Key.WARN_DEST_BUSY) % d)
		return
	Sfx.play("key")
	_ring_dest(c, d)


## O destino toca; se o cabo sair da tomada ou a chamada cair, para de tocar.
func _ring_dest(c: PhoneCall, d: int) -> void:
	var g := cancel_dest_ring(d)
	var right := str(d) == c.target
	var closed := right and c.away   # ninguém atende: o operador pode sugerir a alternativa
	exchange.set_dest(d, Exchange.Dest.RING)
	c.set_options([])   # a conversa agora é com o destino; as opções voltam se a transferência for desfeita
	phone.flash(T.text(T.Key.DISPLAY_RINGING) % d, 60000)
	tutorial_step()
	_update_call_ui()
	for i in (4 if closed else (2 if right else 3)):
		if c.on_line:
			Sfx.play("ringback")
		if not await conversation.wait(c, 2.0) or _dgen[d] != g:
			return
	if closed:
		exchange.set_dest(d, Exchange.Dest.FREE)
		phone.flash(T.text(T.Key.DISPLAY_NO_ANSWER) % d, 3000)
		c.sys(T.text(T.Key.SYS_NOBODY_ANSWERS) % d)
		c.no_answer = true
		conversation.transfer_choices(c)
		_update_call_ui()
		return
	exchange.set_dest(d, Exchange.Dest.CONN)
	Sfx.play("sw")
	phone.flash(T.text(T.Key.DISPLAY_CONNECTED) % d, 3000)
	var who := GameData.entry(str(d)).name
	tutorial_step()
	_update_call_ui()
	if not right and c != tut:
		supervisor.fault("wrong_number", supervisor.who(c))
		c.wrong += 1
	if right and c.on_line:   # o operador ouve o agradecimento; a conversa entre os dois ele já não ouve
		c.sys(T.text(T.Key.SYS_ANSWERED) % who)
		await conversation.say(c, (c.data as TransferCall).thanks, 0.4)
	if _try_complete(c) or right:
		return
	# número errado: quem atendeu reclama de ter sido acordado, e o solicitante também
	c.sys(T.text(T.Key.SYS_WRONG_PERSON) % who)
	if not await conversation.say(c, GameData.pick(C.woken_up), 0.4, who, ["m", "f", "w"].pick_random()):
		return
	if c.wrong >= 2:
		if await conversation.say(c, GameData.pick(C.gave_up), 0.5):
			c.sys(T.text(T.Key.SYS_CALLER_HUNG_UP))
			end_call(c, PhoneCall.End.CALLER)
		return
	if await conversation.say(c, GameData.pick(C.wrong_destination)) and tut != null:
		hint(T.text(T.Key.HINT_WRONG_DEST))


## Destino atendeu: os dois lados seguem conectados pelo cabo de conexão, com ou sem o FONE na entrada.
## Número errado com o FONE na entrada não completa: o operador ouve o engano (`_ring_dest`).
func _try_complete(c: PhoneCall) -> bool:
	if c.ended or c.kind != PhoneCall.Kind.TRANSFER or not c.active:
		return false
	var d := board.dest_of_output(c.line)
	if d == -1 or exchange.dest(d) != Exchange.Dest.CONN:
		return false
	if str(d) != c.target:
		if board.fone_line() == c.line:
			return false
		_wrong_unattended(c, d)
		return true
	exchange.set_line(c.line, Exchange.Line.CONN, minutes + randf_range(TALK_LEN.x, TALK_LEN.y))
	c.connected = true
	c.dest_num = d
	c.sys(T.text(T.Key.SYS_LINES_CONNECTED) % [c.line, d])
	phone.flash("%02d - %d" % [c.line, d], 2600)
	end_call(c, PhoneCall.End.CONNECTED)
	return true


## Destino errado atendeu sem o operador na linha: quem atendeu diz que foi engano e desliga, e o solicitante
## também desliga. Mais tarde ele liga de novo reclamando e pedindo o número certo.
func _wrong_unattended(c: PhoneCall, d: int) -> void:
	exchange.set_dest(d, Exchange.Dest.DONE)
	c.sys(T.text(T.Key.SYS_WRONG_BOTH_HUNG) % GameData.entry(str(d)).name)
	end_call(c, PhoneCall.End.CALLER)
	supervisor.call_again(c, PhoneCall.Retry.WRONG_NUMBER)
	if tut != null:
		hint(T.text(T.Key.HINT_WRONG_UNATTENDED))


## Depois da ligação desconhecida: FONE na entrada dela tenta ligar de volta.
func _call_back_mystery() -> void:
	if _calling_back:
		return
	_calling_back = true
	flags.apply("ligou_de_volta_%d" % night_no)
	phone.flash(T.text(T.Key.DISPLAY_LINE_DOTS) % myst_line, 60000)
	Sfx.play("ringback")
	await get_tree().create_timer(2.2, false).timeout
	Sfx.static_burst(2.0)
	Sfx.play("sit")
	phone.flash(T.text(T.Key.DISPLAY_NO_NUMBER), 3200)
	_calling_back = false


func _show_line_info(n: int) -> void:
	if n > 10 and n <= 20:
		var d := board.dest_of_output(n - 10)
		var what := T.text(T.Key.INFO_FREE) if board.cord_at(n) == -1 else (T.text(T.Key.INFO_TO) % d if d != -1 else T.text(T.Key.INFO_CORD_NO_DEST))
		board.show_info(PackedStringArray([T.text(T.Key.INFO_OUTPUT) % (n - 10), what]), false, n)
		Sfx.play("click")
		return
	if n > 20:
		board.show_info(PackedStringArray([T.text(T.Key.INFO_NUMBER) % n, exchange.dest_label(n).to_upper()]), false, n)
		Sfx.play("click")
		return
	if n == myst_line and after and exchange.line(n) == Exchange.Line.FREE:
		# A linha está livre, mas guarda o registro da última chamada.
		board.show_info(PackedStringArray([T.text(T.Key.INFO_LINE) % n, T.text(T.Key.INFO_FREE), T.text(T.Key.INFO_LAST_ORIGIN), T.text(T.Key.INFO_NUMBER_UNKNOWN), T.text(T.Key.INFO_DURATION) % myst_time]), true, n)
		Sfx.static_burst()
		return
	var a := PackedStringArray([T.text(T.Key.INFO_LINE) % n, exchange.line_label(n).to_upper()])
	if board.fone_line() == n:
		a.append(T.text(T.Key.INFO_FONE_CONNECTED))
	board.show_info(a, false, n)
	Sfx.play("click")


# ================================================================ painel do telefone
# O painel mostra a ligação da entrada com o FONE. As outras continuam tocando ou em espera.

func _refresh_panel() -> void:
	var f := _focus()
	for c in live:
		c.on_line = c == f
	phone.show_call(f if f != null else phone.shown())
	if f != null and f.active:
		Sfx.fade(Sfx.hiss, -26.0 if f.kind == PhoneCall.Kind.MYSTERY else -36.0, 0.3)
	else:
		Sfx.fade(Sfx.hiss, -80.0, 0.2)
	_update_call_ui()


## Já transferida: o destino na ponta do cabo da saída está tocando ou atendeu.
func _transferred(c: PhoneCall) -> bool:
	var d := board.dest_of_output(c.line)
	return d != -1 and exchange.dest(d) != Exchange.Dest.FREE


func _update_call_ui() -> void:
	var f := _focus()
	var can_transfer := f != null and f.active and f.kind == PhoneCall.Kind.TRANSFER and f.phase == PhoneCall.Phase.AWAIT
	can_transfer = can_transfer and not _transferred(f)
	phone.set_buttons(f != null and f.ringing, can_transfer, f != null and f.active)


# ================================================================ agenda das ligações

func free_line() -> int:
	var free := []
	for n in range(1, Exchange.LINES + 1):
		if exchange.line(n) == Exchange.Line.FREE and board.cord_at(n) == -1 and board.cord_at(n + 10) == -1:
			free.append(n)
	return -1 if free.is_empty() else free.pick_random()


func _run_schedule() -> void:
	if sched.is_empty():
		return
	for m in sched:
		if m.kind == PhoneCall.Kind.MYSTERY and not _myst_lead and minutes >= m.at - 20.0:
			_myst_lead = true
			Sfx.hush_nature(true, 20.0)
			Sfx.fade(Sfx.hum, -34.0, 20.0)
	# o homem chega andando, para embaixo do poste lá fora e vai embora antes de a ligação desconhecida tocar
	background.stranger = Vector2(myst_plan - SHADOW_LEAD, myst_plan - SHADOW_LEAVE) + Vector2.ONE * SHIFT_START_HOUR * 60.0   # (na hora do dia)
	var c := sched[0]
	if minutes < c.at:
		return
	# depois da última ligação (LAST_CALL) não toca mais nada, nem retorno nem quem estava esperando a vez
	if minutes >= LAST_CALL and c.kind != PhoneCall.Kind.MYSTERY:
		sched.pop_front()
		return
	# ligação do roteiro cuja condição não bate (os marcadores podem ter mudado durante a noite)
	if not flags.allows(c.requires):
		sched.pop_front()
		return
	# a emergência já foi resolvida (despacho refeito a tempo): ninguém precisa ligar de novo
	if c.kind == PhoneCall.Kind.EMERGENCY and c.retry != PhoneCall.Retry.NONE and report.is_resolved(c.data):
		sched.pop_front()
		return
	# A ligação desconhecida e quem liga de novo só tocam com a mesa em silêncio (até `latest`), para não
	# empilhar ligações sobre quem já está sobrecarregado; as outras esperam uma entrada livre.
	var hush := (c.kind == PhoneCall.Kind.MYSTERY or c.retry != PhoneCall.Retry.NONE) and not live.is_empty() and minutes < c.latest
	# o despacho cuida de uma emergência por vez: a próxima espera a anterior desligar e as unidades chegarem
	if c.kind == PhoneCall.Kind.EMERGENCY and ((em_call != null and (not em_call.ended or em_call.urgent())) or dispatch.fleet.en_route()):
		hush = true
	# não sobrecarregar: com `Pace.max_live` ligações pedindo atenção, a próxima espera (a desconhecida tem regra própria)
	if c.kind != PhoneCall.Kind.MYSTERY and live.size() >= pace.max_live:
		hush = true
	if hush or free_line() == -1:
		c.at = minutes + 3.0
		sched.sort_custom(func(a: PhoneCall, b: PhoneCall): return a.at < b.at)
		return
	sched.pop_front()
	ring(c)


# Conexões completadas duram um tempo; depois alguém desliga e a mesa mostra "desligou".
func _update_line_timers() -> void:
	for n in range(1, Exchange.LINES + 1):
		var until := exchange.line_until(n)
		if exchange.line(n) == Exchange.Line.CONN and until >= 0.0 and minutes >= until:
			exchange.set_line(n, Exchange.Line.DONE)
			var d := board.dest_of_output(n)
			if d != -1 and exchange.dest(d) == Exchange.Dest.CONN:
				exchange.set_dest(d, Exchange.Dest.DONE)
			Sfx.play("sw", -8.0)
			if not _taught_done and live.is_empty():
				_taught_done = true
				hint(T.text(T.Key.HINT_RED_LAMPS))


func _update_bell() -> void:
	var bells := {}   # cada linha chamando toca do lugar da sua tomada
	for c: PhoneCall in live:
		if c.ringing:
			bells[c.line] = board.screen_x(board.jack_rect(c.line).get_center())
	if bells.is_empty():
		Sfx.ring_stop()
	else:
		Sfx.ring_start(bells)


func ring(c: PhoneCall) -> void:
	var busy := not live.is_empty()
	c.line = free_line()
	exchange.set_line(c.line, Exchange.Line.RING)
	c.ringing = true
	c.time = fmt(minutes)
	live.append(c)
	tools.call_log.track(c)
	if c.kind == PhoneCall.Kind.MYSTERY:
		myst_time = c.time
		myst_line = c.line
	if c.kind == PhoneCall.Kind.EMERGENCY:
		em_call = c
		dispatch.set_incident(c.data, c.told)
		phone.urgency.call = c
	_update_bell()
	_refresh_panel()
	if c == tut:
		hint(T.text(T.Key.HINT_TUT_PLUG) % c.line)
	elif busy and not _taught_multi:
		_taught_multi = true
		hint(T.text(T.Key.HINT_ANOTHER_CALL))
	elif tut != null and tut.ended and not _taught_ring:
		_taught_ring = true
		hint(T.text(T.Key.HINT_REMEMBER))
	if c.kind == PhoneCall.Kind.MYSTERY:
		await get_tree().create_timer(9.0, false).timeout
		if c.ringing and not ending:
			warn(T.text(T.Key.WARN_PHONE_RINGING))
	elif c != tut:
		await get_tree().create_timer(GIVE_UP_SEC * (0.75 if c.retry != PhoneCall.Retry.NONE else 1.5 if c.story else 1.0), false).timeout
		if c.ringing:
			end_call(c, PhoneCall.End.MISSED)


func tutorial_step() -> void:
	var c := tut
	if c == null or c.line == 0 or c.ended:
		return
	var n := c.line
	if c.ringing:
		if board.fone_line() == n:
			hint(T.text(T.Key.HINT_TUT_ANSWER))
		return
	if c.phase != PhoneCall.Phase.AWAIT or board.fone_line() != n:
		return
	var dest := c.destination.split(" (")[0]
	var d := board.dest_of_output(n)
	if board.cord_at(n + 10) == -1:
		hint(T.text(T.Key.HINT_TUT_FIND) % [dest, n])
	elif d == -1:
		hint(T.text(T.Key.HINT_TUT_OTHER_END) % dest)
	elif exchange.dest(d) == Exchange.Dest.FREE:
		hint(T.text(T.Key.HINT_TUT_TRANSFER))
	elif exchange.dest(d) == Exchange.Dest.RING:
		hint(T.text(T.Key.HINT_TUT_DEST_RINGING))
	else:
		hint(T.text(T.Key.HINT_TUT_CONNECTED))


## Chamado pela conversa quando o solicitante termina o pedido de transferência.
func on_transfer_waiting(c: PhoneCall) -> void:
	_update_call_ui()
	tutorial_step()
	if board.free_patches() == 0 and board.cord_at(c.line + 10) == -1:
		hint(T.text(T.Key.HINT_NO_CORDS))
	elif not _taught_bank and _new_sector(c.target):
		_taught_bank = true
		var s := int(c.target.left(1))
		hint(T.text(T.Key.HINT_NEW_BANK) % [s, "ABC"[Switchboard.SECTOR_ORDER.find(s)]])
	elif tut != null and c != tut and not _taught_list:
		_taught_list = true
		hint(T.text(T.Key.HINT_CHECK_LIST))


## O número é de um setor entregue nesta noite (o 3, da primeira noite, o tutorial já apresenta)?
func _new_sector(number: String) -> bool:
	var s := int(number.left(1)) if number != "" else 0
	return s != 3 and GameData.SECTOR_NIGHTS.get(s, 0) == night_no


func answer() -> void:
	var c := _focus()
	if c == null or not c.ringing:
		warn(T.text(T.Key.WARN_FONE_TO_BLINK))
		Sfx.play("click")
		return
	c.ringing = false
	c.active = true
	c.last_talk = talk_clock
	_update_bell()
	Sfx.play("sw")
	exchange.set_line(c.line, Exchange.Line.TALK)
	_refresh_panel()
	conversation.run(c)


func hangup() -> void:
	var c := _focus()
	if c == null or not c.active:
		return
	Sfx.play("sw")
	c.add_line("", T.text(T.Key.OP_HANGS_UP), "op")
	if c.kind == PhoneCall.Kind.MYSTERY:
		flags.apply("desligou_desconhecida_%d" % night_no)
	end_call(c, PhoneCall.End.OPERATOR)


## A sala do operador nesta noite: os detalhes do cenário cujos marcadores batem (`GameContent.room`).
func _update_room() -> void:
	if not is_node_ready():   # os marcadores salvos entram antes do cenário existir; o `_ready` chama de novo
		return
	var on := PackedStringArray()
	for r in C.room:
		if night_no >= r.from_night and flags.allows(r.requires):
			on.append(r.detail)
	background.details = on


## Põe na mesa o jornal da manhã com as manchetes `news` (`ShiftReport.news` da noite anterior).
func set_news(news: Array) -> void:
	tools.news.show_news(news, night.weekday)
	background.news = true


# ================================================================ fim de ligação

func end_call(c: PhoneCall, reason: PhoneCall.End) -> void:
	if c.ended:
		return
	c.ended = true
	tools.call_log.filed(c)
	c.active = false
	c.ringing = false
	c.on_line = false
	c.set_talking(false)
	c.set_options([])
	live.erase(c)
	_update_bell()
	if c.kind == PhoneCall.Kind.MYSTERY:
		_mystery_aftermath(c)
	if reason != PhoneCall.End.CONNECTED:
		# Os cabos ficam na mesa: a linha mostra "desligou" até o operador desmontar.
		var d := board.dest_of_output(c.line)
		if d != -1 and exchange.dest(d) == Exchange.Dest.RING:
			exchange.set_dest(d, Exchange.Dest.FREE)
			cancel_dest_ring(d)
		elif d != -1 and exchange.dest(d) == Exchange.Dest.CONN:
			exchange.set_dest(d, Exchange.Dest.DONE)
		if exchange.line(c.line) in [Exchange.Line.TALK, Exchange.Line.HOLD, Exchange.Line.RING]:
			var plugged := board.cord_at(c.line) != -1 or board.cord_at(c.line + 10) != -1
			var keep := plugged and c.kind != PhoneCall.Kind.MYSTERY
			exchange.set_line(c.line, Exchange.Line.DONE if keep else Exchange.Line.FREE)
	if reason == PhoneCall.End.OPERATOR:
		c.sys(T.text(T.Key.SYS_YOU_ENDED))
	elif reason == PhoneCall.End.MISSED:
		c.sys(T.text(T.Key.SYS_NOBODY_ANSWERED))
	elif reason == PhoneCall.End.GAVE_UP:
		c.sys(T.text(T.Key.SYS_TIRED_WAITING))
	_refresh_panel()
	c.record = _record(c, reason)
	notebook.add(c.record)
	supervisor.call_ended(c, reason)
	await get_tree().create_timer(1.5, false).timeout
	if ending or reason == PhoneCall.End.MISSED:   # não atendida já entra registrada
		return
	if live.is_empty():   # a aba mostra quantas faltam; o jogador abre o caderno quando quiser
		hint(T.text(T.Key.HINT_REGISTER))
	else:
		hint(T.text(T.Key.HINT_REGISTER_LATER))


## A linha do caderno já preenchida com o que se sabe da ligação.
func _record(c: PhoneCall, reason: PhoneCall.End) -> Dictionary:
	var where := "—"
	var unit := "—"
	var obs := ""
	var card := 0   # o cartão de despacho enviado (emergência)
	match c.kind:
		PhoneCall.Kind.TRANSFER:
			if c.connected:
				var right := str(c.dest_num) == c.target
				where = tr(c.destination) if right else GameData.entry(str(c.dest_num)).name
				if not right:
					obs = T.text(T.Key.OBS_WRONG_NUMBER)
		PhoneCall.Kind.INFO:
			if c.info_ok >= 0:
				obs = T.text(T.Key.OBS_ASKED_NUMBER) % tr("d" + c.about)
				if c.info_ok == 0:
					obs += " " + T.text(T.Key.OBS_WRONG_INFO)
		PhoneCall.Kind.EMERGENCY:
			var same: bool = not _sent.is_empty() and _sent["call"] == c
			where = String(_sent["loc"]) if same else (c.data as EmergencyCall).address
			unit = String(_sent["units"]) if same else "—"
			card = int(_sent["card"]) if same else 0
		PhoneCall.Kind.PRANK:
			where = (c.data as PrankCall).fake_address
	match reason:
		PhoneCall.End.OPERATOR:
			obs = T.text(T.Key.OBS_OPERATOR_ENDED)
		PhoneCall.End.MISSED:
			obs = T.text(T.Key.OBS_NOT_ANSWERED)
		PhoneCall.End.GAVE_UP:
			obs = T.text(T.Key.OBS_GAVE_UP)
		PhoneCall.End.SHIFT_OVER:
			obs = T.text(T.Key.OBS_SHIFT_ENDED)
		_:
			if c.kind == PhoneCall.Kind.TRANSFER and not c.connected:
				obs = T.text(T.Key.OBS_WRONG_NUMBER) if c.wrong > 0 else T.text(T.Key.OBS_NOT_CONNECTED)
			elif c.kind == PhoneCall.Kind.MYSTERY:
				obs = T.text(T.Key.OBS_CALL_DROPPED)
	var unknown := c.kind == PhoneCall.Kind.MYSTERY or reason == PhoneCall.End.MISSED
	var who := T.text(T.Key.UNKNOWN_CALLER) if unknown else tr(c.caller)
	return {"time": c.time, "who": "%s (%s)" % [who, T.text(T.Key.LINE_N) % c.line], "where": where, "unit": unit, "card": card, "obs": obs,
		"kind": c.kind, "missed": reason == PhoneCall.End.MISSED, "tut": c == tut, "shift": reason == PhoneCall.End.SHIFT_OVER}


## `complete`: com este envio, tudo o que a emergência precisa agora está a caminho do lugar certo.
func _on_dispatched(loc: String, units_text: String, complete: bool, card: int) -> void:
	_sent = {"call": em_call, "loc": loc, "units": units_text, "card": card}
	if em_call == null:
		return
	# o socorro completo saiu: a barra para (e o supervisor vê se demorou)
	if complete and em_call.urgent():
		em_call.secured = true
		supervisor.secured(em_call)
	if not em_call.record.is_empty():
		em_call.record["where"] = loc
		em_call.record["unit"] = units_text
		em_call.record["card"] = card
		notebook.refresh_record(em_call.record)
	conversation.emergency_dispatched(em_call)


## Invalida os toques pendentes do destino `d` (o cabo saiu, ou o debug limpou a mesa); devolve a geração nova.
func cancel_dest_ring(d: int) -> int:
	_dgen[d] = int(_dgen.get(d, 0)) + 1
	return _dgen[d]


## Debug: tira a ligação do turno como se ela nunca tivesse existido (sem caderno, advertência nem retorno).
func drop(c: PhoneCall) -> void:
	c.ended = true   # as falas em andamento param sozinhas
	c.active = false
	c.ringing = false
	c.on_line = false
	c.set_talking(false)
	c.set_options([])
	live.erase(c)
	if c.kind == PhoneCall.Kind.MYSTERY:
		_mystery_aftermath(c)   # o turno pode terminar e a noite volta ao normal
	_update_bell()
	_refresh_panel()


# ================================================================ ligação desconhecida e final

func _mystery_aftermath(c: PhoneCall) -> void:
	Sfx.play("cut")
	Sfx.hum.volume_db = -80.0
	flick = false
	c.sys(T.text(T.Key.SYS_CALL_DROPPED))
	after = true
	get_tree().create_timer(1.8, false).timeout.connect(func(): Sfx.fade(Sfx.hum, -32.0, 3.0))
	get_tree().create_timer(25.0, false).timeout.connect(Sfx.hush_nature.bind(false, 10.0))   # a noite volta aos poucos


func _unregistered() -> bool:
	return notebook.has_pending() or not notebook.queue.is_empty()


## Botão Encerrar turno (a partir de LAST_CALL): quem ainda está na linha ou tocando fica sem resposta, como se o
## operador desligasse (advertência, `Supervisor.call_ended`); o que falta registrar conta como sem registro.
func end_shift() -> void:
	if ending:
		return
	for c in live.duplicate():
		end_call(c, PhoneCall.End.SHIFT_OVER)
	start_ending()


func start_ending() -> void:
	if ending:
		return
	ending = true
	running = false
	Sfx.ring_stop()
	Sfx.stop_ambience(5.0)
	supervisor.shift_over()
	var last := night_no >= C.nights.size()
	if progress != null:
		if report.fired() or last:
			Progress.clear()
		else:
			progress.night = night_no + 1
			progress.pace = Pace.next(pace_level, night_no, report.verdict())
			progress.severe = report.severe_total()
			progress.flags = flags.names()
			progress.news = report.news()
			progress.save()
	await get_tree().create_timer(5.0, false).timeout
	_ending.play(report, not last)
