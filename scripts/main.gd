class_name Main
extends Control
## Project Switchboard — conduz o turno: relógio, agenda das ligações, o que a mesa significa para cada
## ligação, fim de ligação e o final. As falas ficam em Conversation; a interface, nas cenas de scenes/ui/.
##
## Laço: ATENDER → ENTENDER → CONSULTAR → CONECTAR/DESPACHAR → REGISTRAR → CONTINUAR

const GAME_MIN_PER_SEC := 0.75          # 360 minutos de turno ≈ 8 minutos reais
const SHIFT_START_HOUR := 18            # o turno vai das 18:00...
const SHIFT_END := 360.0                # ...até 00:00 (minutos depois do início)
const PEAK_CHANCE := 0.05               # chance de a próxima ligação vir logo em seguida (2–6 min): duas linhas juntas
const EMERGENCY_GAP := 60.0             # minutos de jogo entre duas emergências (o despacho cuida de uma por vez)
const STORY_GAP := 8.0                  # as ligações sorteadas ficam a tantos minutos das do roteiro
const SHADOW_LEAD := 15.0               # minutos antes da ligação desconhecida em que a silhueta aparece na janela...
const SHADOW_LEAVE := 10.0              # ...e em que ela sai (para ir ligar)
const WEATHERS := ["rain", "fog", "clear"]   # clima sorteado no começo do turno (`-- --weather=fog` força um)
const TALK_LEN := Vector2(34.0, 68.0)   # duração (min de jogo) de uma conversa transferida (≈ 45–90 s reais)
const TEMPLATE_CHANCE := 0.5            # chance de uma transferência ou emergência vir de um molde e não de um roteiro escrito
const GIVE_UP_SEC := 60.0               # quem liga desiste se ninguém atende (as do roteiro aguentam 1,5x; retornos, 0,75x)
const HOLD_GIVE_UP := 120.0             # minutos de jogo que alguém aguenta em espera antes de desligar
const RETRY_AFTER := Vector2(15.0, 30.0)  # quem teve problema liga de novo depois de tantos minutos de jogo...
const RETRY_WAIT := 20.0                # ...esperando a mesa esvaziar por no máximo tantos minutos
const REDISPATCH_CHANCE := 0.6          # emergência sem socorro que liga de novo: chance de ainda dar para despachar
## Tipo que o supervisor espera ver no caderno para cada ligação.
const TYPE_OF := {
	PhoneCall.Kind.TRANSFER: "Ligação comum", PhoneCall.Kind.INFO: "Ligação comum",
	PhoneCall.Kind.EMERGENCY: "Emergência", PhoneCall.Kind.PRANK: "Trote",
}
var C: GameContent = GameData.CONTENT

var exchange: Exchange
var night_no := 0                  ## número da noite (1 = primeira); 0 = a salva (`-- --night=N` força uma, sem salvar)
var night: Night                   ## agenda e roteiro fixo da noite
var progress: Progress             ## progresso salvo; nulo quando a noite foi forçada (testes, `--night`)
var weather := "rain"
var report := ShiftReport.new()    ## advertências do turno, conferidas pelo supervisor no fim do turno
var minutes := 0.0
var running := false
var sched: Array[PhoneCall] = []   ## ligações ainda por tocar, em ordem de horário
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

@onready var background: Background = %Background
@onready var clock: Label = %Clock
@onready var board: Switchboard = %Board
@onready var phone: PhonePanel = %Phone
@onready var radio: Radio = %Radio
@onready var tools: Tools = %Tools
@onready var notebook: Notebook = tools.notebook
@onready var dispatch: Dispatch = tools.dispatch
@onready var conversation: Conversation = %Conversation
@onready var _hint: RichTextLabel = %Hint
@onready var _glow: CanvasItem = %Glow
@onready var _intro: Intro = %Intro
@onready var _ending: Ending = %Ending


func _ready() -> void:
	_apply_seed()
	_load_night()
	weather = night.weather if night.weather != "" else WEATHERS.pick_random()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--weather=") and a.get_slice("=", 1) in WEATHERS:
			weather = a.get_slice("=", 1)
	background.weather = weather
	exchange = Exchange.new(GameData.board_numbers())
	board.setup(exchange, phone.fone_socket)
	_build_schedule()
	board.end_changed.connect(_on_end_changed)
	board.info_requested.connect(_show_line_info)
	board.warned.connect(warn)
	phone.answer_pressed.connect(answer)
	phone.transfer_pressed.connect(transfer)
	phone.hangup_pressed.connect(hangup)
	_intro.start_pressed.connect(_start_shift)
	tools.tab_changed.connect(_on_tab_changed)
	tools.map_view.location_selected.connect(func(s: String, b: int, l: String):
		dispatch.set_location(s, b, l)
		tools.set_dot("despacho", true))
	tools.map_view.use_pressed.connect(tools.set_tab.bind("despacho"))
	dispatch.open_map_pressed.connect(tools.set_tab.bind("mapa"))
	dispatch.city = tools.map_view.city
	dispatch.radio = radio
	dispatch.sent.connect(_on_dispatched)
	dispatch.arrived.connect(_on_arrived)
	notebook.registered.connect(_on_registered)
	notebook.pending_changed.connect(func(has: bool): tools.set_dot("caderno", has))
	_intro.setup(night_no, night, progress != null and progress.night > 1)
	_refresh_panel()


## Qual noite jogar: `-- --night=N`, a definida antes de entrar na árvore (testes) ou a salva.
func _load_night() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--night="):
			night_no = int(a.get_slice("=", 1))
	if night_no == 0:
		progress = Progress.load_saved()
		night_no = progress.night
		report.severe_before = progress.severe
	night_no = clampi(night_no, 1, C.nights.size())
	night = C.nights[night_no - 1]
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
	_hint.text = "" if t == "" else "[bgcolor=#b8924e][color=#1a150d] %s [/color][/bgcolor]  %s" % [tr("MANUAL"), t]


func warn(t: String) -> void:
	phone.warn(tr(t))


# ================================================================ laço principal

func _start_shift() -> void:
	Sfx.start_ambience(weather)
	running = true
	radio.say("Central, viatura 2 em ronda. Tudo tranquilo.")
	hint(tr("Aguarde as chamadas. A lista, o mapa, o despacho e o caderno ficam nas abas acima."))


func _process(delta: float) -> void:
	if running:
		minutes = minf(SHIFT_END, minutes + delta * GAME_MIN_PER_SEC)
		_tick_acc += delta
		if _tick_acc > 1.0:
			_tick_acc = 0.0
			Sfx.play("tick", -3.0)
		_run_schedule()
		_update_line_timers()
		# o turno só fecha depois da ligação desconhecida ter tocado e caído
		if minutes >= SHIFT_END and after:
			_start_ending()
		clock.text = fmt(minutes)
		_nag()
		_check_hold()
	background.flick = flick
	_glow.modulate.a = background.lamp_level


## Quem está na linha com o operador reclama da demora.
func _nag() -> void:
	var f := _focus()
	if f == null or not f.active or f.talking:
		return
	var now := Time.get_ticks_msec()
	var quiet := now - f.last_talk
	if f.kind == PhoneCall.Kind.TRANSFER and f.phase == PhoneCall.Phase.AWAIT and quiet > 22000:
		f.last_talk = now
		conversation.say(f, GameData.pick(C.waiting))
	elif f.kind == PhoneCall.Kind.EMERGENCY and not f.dispatched and quiet > 26000:
		f.last_talk = now
		conversation.say(f, GameData.pick(C.emergency_waiting))


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("cancel_plug") and board.held != -1:
		board.go_home(board.held)


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
		# FONE saiu: se o destino já atendeu, a ligação segue pelo cabo de conexão; senão fica em espera.
		var c := _call_on_line(j)
		if c != null and c.active:
			if not _try_complete(c):
				exchange.set_line(j, Exchange.Line.HOLD)
				c.hold_since = minutes
				c.sys(tr("(Em espera.)"))
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
				_fault("cut_call", tr("linha %02d") % n)
				if other > 20 and exchange.dest(other) == Exchange.Dest.CONN:
					exchange.set_dest(other, Exchange.Dest.DONE)
			_maybe_free(n)
		return
	# saiu do destino j
	var st := exchange.dest(j)
	exchange.set_dest(j, Exchange.Dest.FREE)
	_dgen[j] = int(_dgen.get(j, 0)) + 1
	if st == Exchange.Dest.FREE:
		return
	Sfx.play("sw")
	if other >= 11 and other <= 20:
		var n := other - 10
		var c := _call_on_line(n)
		if c != null and c.active:
			c.sys((tr("(Chamada para %d cancelada.)") if st == Exchange.Dest.RING else tr("(%d desconectado.)")) % j)
			phone.clear_flash()
			conversation.transfer_choices(c)
		elif exchange.line(n) == Exchange.Line.CONN:
			exchange.set_line(n, Exchange.Line.DONE)
			_fault("cut_call", tr("linha %02d") % n)


## Cabo tirado da SAÍDA no meio de uma transferência: o destino para de tocar ou cai.
func _cut_dest(c: PhoneCall, d: int) -> void:
	if exchange.dest(d) == Exchange.Dest.RING:
		exchange.set_dest(d, Exchange.Dest.FREE)
		_dgen[d] = int(_dgen.get(d, 0)) + 1
		c.sys(tr("(Chamada para %d cancelada.)") % d)
	elif exchange.dest(d) == Exchange.Dest.CONN:
		exchange.set_dest(d, Exchange.Dest.DONE)
		c.sys(tr("(%d desconectado.)") % d)
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
		warn("Leve o FONE até a entrada da ligação que você quer transferir.")
		return
	if c.kind != PhoneCall.Kind.TRANSFER:
		warn("Esse solicitante não pediu transferência.")
		return
	if c.phase != PhoneCall.Phase.AWAIT:
		warn("Ouça o pedido do solicitante antes de transferir.")
		return
	var d := board.dest_of_output(c.line)
	if d == -1:
		warn(tr("Ligue um cabo de conexão da SAÍDA %02d até o número de destino.") % c.line)
		return
	if exchange.dest(d) != Exchange.Dest.FREE:
		warn(tr("O %d já está tocando ou em conversa.") % d)
		return
	Sfx.play("key")
	_ring_dest(c, d)


## O destino toca; se o cabo sair da tomada ou a chamada cair, para de tocar.
func _ring_dest(c: PhoneCall, d: int) -> void:
	_dgen[d] = int(_dgen.get(d, 0)) + 1
	var g: int = _dgen[d]
	var right := str(d) == c.target
	var closed := GameData.is_closed(d)
	exchange.set_dest(d, Exchange.Dest.RING)
	c.set_options([])   # a conversa agora é com o destino; as opções voltam se a transferência for desfeita
	phone.flash(tr("%d TOCANDO") % d, 60000)
	tutorial_step()
	_update_call_ui()
	for i in (4 if closed else (2 if right else 3)):
		if c.on_line:
			Sfx.play("ringback")
		if not await conversation.wait(c, 2.0) or _dgen[d] != g:
			return
	if closed:
		exchange.set_dest(d, Exchange.Dest.FREE)
		phone.flash(tr("%d SEM RESPOSTA") % d, 3000)
		c.sys(tr("(Ninguém atende no %d.)") % d)
		if right:
			c.no_answer = true
			conversation.transfer_choices(c)
		_update_call_ui()
		return
	exchange.set_dest(d, Exchange.Dest.CONN)
	Sfx.play("sw")
	phone.flash(tr("%d CONECTADO") % d, 3000)
	var who := GameData.display_name(GameData.entry(str(d)))
	tutorial_step()
	_update_call_ui()
	if not right and c != tut:
		_fault("wrong_number", _who(c))
		c.wrong += 1
	if _try_complete(c):
		return
	if right:
		c.sys(tr("(%s atendeu.)") % who)
		await conversation.say(c, (c.data as TransferCall).thanks, 0.4)
		return
	# número errado: quem atendeu reclama de ter sido acordado, e o solicitante também
	c.sys(tr("(Atendeu: %s. Não é quem o solicitante pediu.)") % who)
	if not await conversation.say(c, GameData.pick(C.woken_up), 0.4, who, ["m", "f", "w"].pick_random()):
		return
	if c.wrong >= 2:
		if await conversation.say(c, GameData.pick(C.gave_up), 0.5):
			c.sys(tr("(O solicitante desligou.)"))
			end_call(c, PhoneCall.End.CALLER)
		return
	if await conversation.say(c, GameData.pick(C.wrong_destination)) and tut != null:
		hint(tr("Tire a ponta do cabo desse destino. Confira o nome e o endereço na lista: há nomes parecidos."))


## Destino atendeu e o FONE saiu da entrada: os dois lados seguem conectados pelo cabo de conexão.
func _try_complete(c: PhoneCall) -> bool:
	if c.ended or c.kind != PhoneCall.Kind.TRANSFER or not c.active or board.fone_line() == c.line:
		return false
	var d := board.dest_of_output(c.line)
	if d == -1 or exchange.dest(d) != Exchange.Dest.CONN:
		return false
	if str(d) != c.target:
		_wrong_unattended(c, d)
		return true
	exchange.set_line(c.line, Exchange.Line.CONN, minutes + randf_range(TALK_LEN.x, TALK_LEN.y))
	c.connected = true
	c.dest_num = d
	c.sys(tr("(Você tirou o fone. %02d e %d seguem conectados.)") % [c.line, d])
	phone.flash("%02d - %d" % [c.line, d], 2600)
	end_call(c, PhoneCall.End.CONNECTED)
	return true


## Destino errado atendeu sem o operador na linha: quem atendeu diz que foi engano e desliga, e o solicitante
## também desliga. Mais tarde ele liga de novo reclamando e pedindo o número certo.
func _wrong_unattended(c: PhoneCall, d: int) -> void:
	exchange.set_dest(d, Exchange.Dest.DONE)
	c.sys(tr("(Atendeu: %s. Foi engano, e os dois desligaram.)") % GameData.display_name(GameData.entry(str(d))))
	end_call(c, PhoneCall.End.CALLER)
	_call_again(c, PhoneCall.Retry.WRONG_NUMBER)
	if tut != null:
		hint(tr("Sem o FONE na linha, uma conexão errada cai. A pessoa vai ligar de novo: confira o número na lista antes de transferir."))


## Depois da ligação desconhecida: FONE na entrada dela tenta ligar de volta.
func _call_back_mystery() -> void:
	if _calling_back:
		return
	_calling_back = true
	phone.flash(tr("LINHA %02d…") % myst_line, 60000)
	Sfx.play("ringback")
	await get_tree().create_timer(2.2).timeout
	Sfx.static_burst(2.0)
	Sfx.play("sit")
	phone.flash(tr("NÚMERO NÃO EXISTE"), 3200)
	_calling_back = false


func _show_line_info(n: int) -> void:
	if n > 10 and n <= 20:
		var d := board.dest_of_output(n - 10)
		var what := tr("LIVRE") if board.cord_at(n) == -1 else (tr("PARA %d") % d if d != -1 else tr("CABO SEM DESTINO"))
		board.show_info(PackedStringArray([tr("SAÍDA %02d") % (n - 10), what]), false, n)
		Sfx.play("click")
		return
	if n > 20:
		board.show_info(PackedStringArray([tr("NÚMERO %d") % n, tr(exchange.dest_label(n)).to_upper()]), false, n)
		Sfx.play("click")
		return
	if n == myst_line and after and exchange.line(n) == Exchange.Line.FREE:
		# A linha está livre, mas guarda o registro da última chamada.
		board.show_info(PackedStringArray([tr("LINHA %02d") % n, tr("LIVRE"), tr("ÚLTIMA ORIGEM: ???"), tr("NÚMERO: ???"), tr("DURAÇÃO: ") + myst_time]), true, n)
		Sfx.static_burst()
		return
	var a := PackedStringArray([tr("LINHA %02d") % n, tr(exchange.line_label(n)).to_upper()])
	if board.fone_line() == n:
		a.append(tr("FONE CONECTADO"))
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


func _update_call_ui() -> void:
	var f := _focus()
	var s := phone.shown()
	var can_transfer := f != null and f.active and f.kind == PhoneCall.Kind.TRANSFER and f.phase == PhoneCall.Phase.AWAIT
	phone.set_buttons(f != null and f.ringing, can_transfer, f != null and f.active)
	var line := tr("Nenhuma chamada")
	var st := ""
	if s != null:
		line = tr("Linha %02d") % s.line
		if s.ended:
			st = tr("encerrada")
		elif s != f:
			st = tr("tocando") if s.ringing else tr("em espera")
		elif s.ringing:
			st = tr("tocando")
		else:
			st = tr("em linha")
			var d := board.dest_of_output(s.line)
			if s.kind == PhoneCall.Kind.TRANSFER and d != -1:
				if exchange.dest(d) == Exchange.Dest.RING:
					st = tr("chamando %d") % d
				elif exchange.dest(d) == Exchange.Dest.CONN:
					st = tr("%d atendeu") % d
	var others := PackedStringArray()
	for c in live:
		if c != s:
			others.append("%02d %s" % [c.line, tr("tocando") if c.ringing else tr("em espera")])
	phone.set_status(line, st, "" if others.is_empty() else tr("Outras linhas: ") + ", ".join(others))


# ================================================================ agenda das ligações

## Agenda da noite: as ligações do roteiro (horário fixo), a ligação desconhecida e as sorteadas.
func _build_schedule() -> void:
	var fixed: Array[PhoneCall] = []
	for st in night.story:
		var c := PhoneCall.from_script(st.call)
		c.at = st.at
		c.story = true
		fixed.append(c)
	if night.mystery.is_empty():
		after = true   # noite sem ligação desconhecida: o turno fecha à meia-noite
	else:
		var myst := PhoneCall.mystery()
		myst.at = randf_range(night.mystery_from, night.mystery_to)
		myst.latest = myst.at + 30.0   # não espera a mesa silenciar para sempre
		myst_plan = myst.at
		fixed.append(myst)
	sched = fixed.duplicate()
	sched.append_array(_random_calls(fixed))
	sched.sort_custom(func(a: PhoneCall, b: PhoneCall): return a.at < b.at)


## Ligações sorteadas pelo turno todo: entre uma e a próxima, `Night.call_gap` minutos (o máximo é o maior
## silêncio possível); de vez em quando (PEAK_CHANCE) a próxima vem logo em seguida. O tipo também é sorteado:
## `Night.emergencies` emergências (espaçadas por EMERGENCY_GAP), `Night.pranks` trotes, e o resto
## transferências ou pedidos de informação. Na noite com tutorial, a primeira é uma transferência guiada.
func _random_calls(fixed: Array[PhoneCall]) -> Array[PhoneCall]:
	var ats := []
	var t := randf_range(3.0, 10.0)
	while t < SHIFT_END - 10.0:
		if not fixed.any(func(f: PhoneCall): return absf(t - f.at) < STORY_GAP):
			ats.append(t)
		t += randf_range(2.0, 6.0) if randf() < PEAK_CHANCE else randf_range(night.call_gap.x, night.call_gap.y)
	var kinds := []
	kinds.resize(ats.size())
	var free := range(1 if night.tutorial else 0, ats.size())
	free.shuffle()
	var em_ats := []
	var em_count := randi_range(night.emergencies.x, night.emergencies.y)
	for i in free.duplicate():
		if em_ats.size() < em_count and em_ats.all(func(x): return absf(ats[i] - x) >= EMERGENCY_GAP):
			kinds[i] = PhoneCall.Kind.EMERGENCY
			em_ats.append(ats[i])
			free.erase(i)
	for i in free.slice(0, randi_range(night.pranks.x, night.pranks.y)):
		kinds[i] = PhoneCall.Kind.PRANK
	var used := fixed.map(func(f: PhoneCall): return f.caller)
	var targets := fixed.map(func(f: PhoneCall): return f.target)
	var transfers := C.transfers.filter(func(x): return not x.caller in used)
	var emergencies := C.emergencies.duplicate()
	var pranks := C.pranks.duplicate()
	for pool in [transfers, emergencies, pranks]:
		pool.shuffle()
	var out: Array[PhoneCall] = []
	for i in ats.size():
		var c: PhoneCall
		if i == 0 and night.tutorial:
			var first: TransferCall = GameData.transfers(TransferCall.Group.ESTABLISHMENT).pick_random()
			transfers.erase(first)
			c = PhoneCall.from_transfer(first)
			targets.append(first.alt_target)
			tut = c
		elif kinds[i] == PhoneCall.Kind.EMERGENCY:
			var written := randf() >= TEMPLATE_CHANCE and not emergencies.is_empty()
			c = PhoneCall.from_emergency(emergencies.pop_back() if written else GameData.template_emergency())
		elif kinds[i] == PhoneCall.Kind.PRANK and not pranks.is_empty():
			c = PhoneCall.from_prank(pranks.pop_back())
		elif randf() < 0.65:
			# um número por noite: duas pessoas pedindo o mesmo destino ficariam esperando uma pela outra
			var fresh := transfers.filter(func(x: TransferCall): return not x.target in targets and not x.alt_target in targets)
			var tc: TransferCall = fresh.back() if randf() >= TEMPLATE_CHANCE and not fresh.is_empty() else GameData.template_transfer(targets)
			transfers.erase(tc)
			c = PhoneCall.from_transfer(tc)
			targets.append(tc.alt_target)
		else:
			c = _info_call()
		targets.append(c.target)
		c.at = ats[i]
		out.append(c)
	return out


func _info_call() -> PhoneCall:
	var who := GameData.pick(C.callers).split(":")
	if randf() < 0.7:
		var e: DirectoryEntry = C.directory.filter(func(d): return d.spoken != "").pick_random()
		return PhoneCall.info(who[0], who[1], tr(GameData.pick(C.ask_number)) % ("d" + e.spoken), e.spoken, e.number)
	return PhoneCall.info(who[0], who[1], GameData.pick(C.ask_time))


func _free_line() -> int:
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
	# alguém para do lado de fora da janela e sai antes de a ligação desconhecida tocar
	background.shadow = minutes >= myst_plan - SHADOW_LEAD and minutes < myst_plan - SHADOW_LEAVE
	var c := sched[0]
	if minutes < c.at:
		return
	# a emergência já foi resolvida (despacho refeito a tempo): ninguém precisa ligar de novo
	if c.kind == PhoneCall.Kind.EMERGENCY and c.retry != PhoneCall.Retry.NONE and report.is_resolved(c.data):
		sched.pop_front()
		return
	# A ligação desconhecida e quem liga de novo só tocam com a mesa em silêncio (até `latest`), para não
	# empilhar ligações sobre quem já está sobrecarregado; as outras esperam uma entrada livre.
	var hush := (c.kind == PhoneCall.Kind.MYSTERY or c.retry != PhoneCall.Retry.NONE) and not live.is_empty() and minutes < c.latest
	# o despacho cuida de uma emergência por vez: a próxima espera a anterior desligar e as unidades chegarem
	if c.kind == PhoneCall.Kind.EMERGENCY and ((em_call != null and not em_call.ended) or dispatch.en_route()):
		hush = true
	if hush or _free_line() == -1:
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
				hint(tr("Lâmpadas vermelhas: a conversa terminou. Tire as duas pontas do cabo de conexão para liberar a linha e o cabo."))


func _update_bell() -> void:
	if live.any(func(c: PhoneCall): return c.ringing):
		Sfx.ring_start()
	else:
		Sfx.ring_stop()


func ring(c: PhoneCall) -> void:
	var busy := not live.is_empty()
	c.line = _free_line()
	exchange.set_line(c.line, Exchange.Line.RING)
	c.ringing = true
	c.time = fmt(minutes)
	live.append(c)
	if c.kind == PhoneCall.Kind.MYSTERY:
		myst_time = c.time
		myst_line = c.line
	if c.kind == PhoneCall.Kind.EMERGENCY:
		em_call = c
		dispatch.set_incident(c.data)
	_update_bell()
	_refresh_panel()
	if c == tut:
		hint(tr("A lâmpada da entrada %02d está piscando. Arraste o [b]FONE[/b] (cabo vermelho, no telefone) até a tomada dessa entrada.") % c.line)
	elif busy and not _taught_multi:
		_taught_multi = true
		hint(tr("Outra entrada chamando! Leve o [b]FONE[/b] até ela: a ligação atual fica em espera. Para voltar, leve o FONE de volta à entrada dela."))
	elif tut != null and tut.ended and not _taught_ring:
		_taught_ring = true
		hint(tr("Lembre: FONE na entrada que pisca, depois Atender."))
	if c.kind == PhoneCall.Kind.MYSTERY:
		await get_tree().create_timer(9.0).timeout
		if c.ringing and not ending:
			warn("O telefone está tocando.")
	elif c != tut:
		await get_tree().create_timer(GIVE_UP_SEC * (0.75 if c.retry != PhoneCall.Retry.NONE else 1.5 if c.story else 1.0)).timeout
		if c.ringing:
			end_call(c, PhoneCall.End.MISSED)


func tutorial_step() -> void:
	var c := tut
	if c == null or c.line == 0 or c.ended:
		return
	var n := c.line
	if c.ringing:
		if board.fone_line() == n:
			hint(tr("Agora clique em [b]Atender[/b] para falar com quem ligou."))
		return
	if c.phase != PhoneCall.Phase.AWAIT or board.fone_line() != n:
		return
	var dest := c.destination.split(" (")[0]
	var d := board.dest_of_output(n)
	if board.cord_at(n + 10) == -1:
		hint(tr("Procure [b]%s[/b] na lista. Pegue um [b]cabo de conexão[/b] na base e ligue uma ponta na [b]SAÍDA %02d[/b], logo abaixo da entrada.") % [dest, n])
	elif d == -1:
		hint(tr("Leve a outra ponta desse cabo até o número de [b]%s[/b], na fileira de destinos.") % dest)
	elif exchange.dest(d) == Exchange.Dest.FREE:
		hint(tr("Clique em [b]Transferir[/b] para chamar o destino."))
	elif exchange.dest(d) == Exchange.Dest.RING:
		hint(tr("O destino está tocando. Aguarde atender."))
	else:
		hint(tr("O destino atendeu. Tire o [b]FONE[/b] da entrada (devolva ao telefone): a ligação continua pelo cabo de conexão."))


## Chamado pela conversa quando o solicitante termina o pedido de transferência.
func on_transfer_waiting(c: PhoneCall) -> void:
	_update_call_ui()
	tutorial_step()
	if board.free_patches() == 0 and board.cord_at(c.line + 10) == -1:
		hint(tr("Não há cabos de conexão livres. Desmonte uma conexão encerrada (lâmpadas vermelhas)."))
	elif tut != null and c != tut and not _taught_list:
		_taught_list = true
		hint(tr("Consulte a lista. Confira o nome e o endereço."))


func answer() -> void:
	var c := _focus()
	if c == null or not c.ringing:
		warn("Leve o FONE até a entrada que está piscando.")
		Sfx.play("click")
		return
	c.ringing = false
	c.active = true
	c.last_talk = Time.get_ticks_msec()
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
	c.add_line("Você", tr("(desliga)"), "op")
	end_call(c, PhoneCall.End.OPERATOR)


# ================================================================ fim de ligação

func end_call(c: PhoneCall, reason: PhoneCall.End) -> void:
	if c.ended:
		return
	c.ended = true
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
			_dgen[d] = int(_dgen.get(d, 0)) + 1
		elif d != -1 and exchange.dest(d) == Exchange.Dest.CONN:
			exchange.set_dest(d, Exchange.Dest.DONE)
		if exchange.line(c.line) in [Exchange.Line.TALK, Exchange.Line.HOLD, Exchange.Line.RING]:
			var plugged := board.cord_at(c.line) != -1 or board.cord_at(c.line + 10) != -1
			var keep := plugged and c.kind != PhoneCall.Kind.MYSTERY
			exchange.set_line(c.line, Exchange.Line.DONE if keep else Exchange.Line.FREE)
	if reason == PhoneCall.End.OPERATOR:
		c.sys(tr("(Você encerrou a ligação.)"))
	elif reason == PhoneCall.End.MISSED:
		c.sys(tr("(Ninguém atendeu. A pessoa desistiu.)"))
	elif reason == PhoneCall.End.GAVE_UP:
		c.sys(tr("(Cansou de esperar e desligou.)"))
	_refresh_panel()
	c.record = _record(c, reason)
	notebook.add(c.record)
	_consequences(c, reason)
	await get_tree().create_timer(1.5).timeout
	if ending:
		return
	if live.is_empty():
		tools.set_tab("caderno")
		hint(tr("Registre a ocorrência no caderno."))
	else:
		hint(tr("Há ocorrências para registrar no caderno quando der tempo."))


## A linha do caderno já preenchida com o que se sabe da ligação.
func _record(c: PhoneCall, reason: PhoneCall.End) -> Dictionary:
	var where := "—"
	var unit := "—"
	var obs := ""
	match c.kind:
		PhoneCall.Kind.TRANSFER:
			if c.connected:
				var right := str(c.dest_num) == c.target
				where = c.destination if right else GameData.entry(str(c.dest_num)).name
				if not right:
					obs = tr("Conectada ao número errado.")
		PhoneCall.Kind.INFO:
			if c.info_ok >= 0:
				obs = tr("Pediu o número d%s.") % c.about if c.about != "" else tr("Perguntou as horas.")
				if c.info_ok == 0:
					obs += " " + tr("Informação errada.")
		PhoneCall.Kind.EMERGENCY:
			var same: bool = not _sent.is_empty() and _sent["call"] == c
			where = String(_sent["loc"]) if same else (c.data as EmergencyCall).address
			unit = String(_sent["units"]) if same else "—"
		PhoneCall.Kind.PRANK:
			where = (c.data as PrankCall).fake_address
	match reason:
		PhoneCall.End.OPERATOR:
			obs = tr("Encerrada pelo operador.")
		PhoneCall.End.MISSED:
			obs = tr("Não atendida.")
		PhoneCall.End.GAVE_UP:
			obs = tr("Desistiu na espera.")
		_:
			if c.kind == PhoneCall.Kind.TRANSFER and not c.connected:
				obs = tr("Conectada ao número errado.") if c.wrong > 0 else tr("Não conectada.")
			elif c.kind == PhoneCall.Kind.MYSTERY:
				obs = tr("A ligação caiu.")
	var unknown := c.kind == PhoneCall.Kind.MYSTERY or reason == PhoneCall.End.MISSED
	var who := tr("Desconhecido") if unknown else c.caller
	return {"time": c.time, "who": "%s (%s)" % [who, tr("linha %02d") % c.line], "where": where, "unit": unit, "obs": obs,
		"kind": c.kind, "missed": reason == PhoneCall.End.MISSED, "tut": c == tut}


func _on_dispatched(loc: String, units_text: String) -> void:
	_sent = {"call": em_call, "loc": loc, "units": units_text}
	if em_call == null:
		return
	if not em_call.record.is_empty():
		em_call.record["where"] = loc
		em_call.record["unit"] = units_text
		notebook.refresh_record(em_call.record)
	conversation.emergency_dispatched(em_call)


# ================================================================ advertências (relatório do supervisor)

func _who(c: PhoneCall) -> String:
	return "%s (%s)" % [c.caller, tr("linha %02d") % c.line]


func _fault(id: String, detail := "") -> void:
	report.add(id, fmt(minutes), detail)


## Conversa fiada: as falas gerais e as do clima da noite.
func smalltalk() -> PackedStringArray:
	return C.smalltalk + (C.get("smalltalk_" + weather) as PackedStringArray)


## O que o supervisor vai anotar e quem vai ligar de novo por causa de como a ligação terminou.
## A ligação do tutorial, os trotes e a ligação desconhecida não contam.
func _consequences(c: PhoneCall, reason: PhoneCall.End) -> void:
	if c == tut or c.kind in [PhoneCall.Kind.PRANK, PhoneCall.Kind.MYSTERY]:
		return
	var e: EmergencyCall = c.data if c.kind == PhoneCall.Kind.EMERGENCY else null
	if reason in [PhoneCall.End.MISSED, PhoneCall.End.GAVE_UP]:
		_fault("missed" if reason == PhoneCall.End.MISSED else "hold", String(c.record["who"]))
		if e != null:
			report.trouble(e)
		_call_again(c, PhoneCall.Retry.MISSED)
	elif e != null and not c.dispatched and not c.too_late:
		_fault("emergency_dropped", _who(c))
		report.trouble(e)
		_call_again(c, PhoneCall.Retry.WORSE)
	elif c.kind == PhoneCall.Kind.INFO and c.info_ok == 0:
		_fault("wrong_info", _who(c))
		_call_again(c, PhoneCall.Retry.WRONG_INFO)


## A mesma pessoa liga de novo mais tarde, irritada e com menos paciência (no máximo uma vez por motivo).
## Vale também para a ligação do tutorial (que só não gera advertência). Nunca fica para depois do fim do turno.
func _call_again(c: PhoneCall, why: PhoneCall.Retry) -> void:
	if why in c.retried:
		return
	var n: PhoneCall
	match c.kind:
		PhoneCall.Kind.TRANSFER:
			n = PhoneCall.from_transfer(c.data)
		PhoneCall.Kind.EMERGENCY:
			n = PhoneCall.from_emergency(c.data)
			n.too_late = why == PhoneCall.Retry.WORSE and randf() >= REDISPATCH_CHANCE
		PhoneCall.Kind.INFO:
			n = PhoneCall.info(c.voice, c.caller, c.ask, c.about, c.answer)
		_:
			return
	n.retry = why
	n.retried = c.retried.duplicate()
	n.retried.append(why)
	n.at = minf(minutes + randf_range(RETRY_AFTER.x, RETRY_AFTER.y), maxf(minutes + 2.0, SHIFT_END - 4.0))
	n.latest = n.at + RETRY_WAIT
	sched.append(n)
	sched.sort_custom(func(a: PhoneCall, b: PhoneCall): return a.at < b.at)


## Quem fica em espera tempo demais desiste.
func _check_hold() -> void:
	for c in live.duplicate():
		if c.active and c != tut and c.kind != PhoneCall.Kind.MYSTERY and exchange.line(c.line) == Exchange.Line.HOLD \
				and minutes - c.hold_since > HOLD_GIVE_UP:
			end_call(c, PhoneCall.End.GAVE_UP)


## As unidades chegaram ao local marcado no despacho.
func _on_arrived(e: EmergencyCall, result: String, occurrence: String, extra: Array) -> void:
	if e != null and occurrence != e.occurrence:
		_fault("dispatch_type", tr("classificada como %s; era %s") % [tr(occurrence), tr(e.occurrence)])
	if not extra.is_empty():
		_fault("dispatch_extra", ", ".join(extra.map(func(u): return tr(Dispatch.UNIT_NAMES[u]))))
	match result:
		"ok":
			report.resolved(e)
		"missing":
			if not report.faults.any(func(f): return f["id"] == "dispatch_missing" and f["detail"] == e.address):
				_fault("dispatch_missing", e.address)
		"idle":
			_fault("dispatch_idle")
		"wrong_place":
			_fault("dispatch_wrong_place", e.address)
			report.trouble(e)
			if em_call != null and em_call.data == e:
				_call_again(em_call, PhoneCall.Retry.WORSE)


## O supervisor confere o tipo registrado (não dá para saber o tipo de quem não foi atendido).
func _on_registered(rec: Dictionary, type: String) -> void:
	if rec["tut"] or rec["missed"] or not TYPE_OF.has(rec["kind"]):
		return
	if type != TYPE_OF[rec["kind"]]:
		report.add("register_wrong", rec["time"], rec["who"])


func _on_tab_changed(id: String) -> void:
	if id == "despacho":
		tools.set_dot("despacho", false)
	if id == "caderno" and not notebook.has_pending():
		tools.set_dot("caderno", false)


# ================================================================ ligação desconhecida e final

func _mystery_aftermath(c: PhoneCall) -> void:
	Sfx.play("cut")
	Sfx.hum.volume_db = -80.0
	flick = false
	c.sys(tr("(A ligação caiu.)"))
	after = true
	get_tree().create_timer(1.8).timeout.connect(func(): Sfx.fade(Sfx.hum, -32.0, 3.0))
	get_tree().create_timer(25.0).timeout.connect(Sfx.hush_nature.bind(false, 10.0))   # a noite volta aos poucos


func _start_ending() -> void:
	if ending:
		return
	ending = true
	running = false
	Sfx.ring_stop()
	Sfx.stop_ambience(5.0)
	var left: Array = notebook.queue.duplicate()
	if notebook.has_pending():
		left.append(notebook.pending)
	for rec in left:
		if not rec["tut"]:
			report.add("register_missing", rec["time"], rec["who"])
	var last := night_no >= C.nights.size()
	if progress != null:
		if report.fired() or last:
			Progress.clear()
		else:
			progress.night = night_no + 1
			progress.severe = report.severe_total()
			progress.save()
	await get_tree().create_timer(5.0).timeout
	_ending.play(report, not last)
