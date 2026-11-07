class_name Training
extends Node
## O treinamento da noite 0: a telefonista veterana (`Night.teacher`) liga para o operador novo e ensina o serviço como
## uma colega ao lado, pelos passos de `Night.lesson` (`LessonStep`). Ela liga por entradas certas, explica e espera o
## jogador fazer cada coisa na mesa; enquanto espera, a dica do passo fica no papel do manual. Se ela estiver na linha,
## ela mesma comenta o erro ou a demora; senão, fica só a dica. Enquanto corre (`active`), o relógio fica parado (o
## Main não anda o turno) e nada da agenda toca; depois, segue um turno calmo.
## As ligações dela são transferências (`PhoneCall.lesson`): a mesa, os cabos e o Transferir valem como sempre.

signal finished

const TALK_SEC := 8.0   ## a conversa dela com o destino, até a lâmpada ficar vermelha (o relógio está parado)
const SPEECH := 1.6     ## ela fala mais devagar que quem liga (`PhoneCall.speech`)

var active := false
var call: PhoneCall   ## a ligação dela agora (nula antes da primeira)
var _night: Night
var _step: LessonStep   ## o passo esperando o jogador
var drill: EmergencyCall   ## a emergência de treino (nula antes dela; `LessonStep.emergency`)
var drill_call: PhoneCall  ## a ligação dela com a emergência de treino (a ficha leva o local e o cartão)
var _sent := false      ## um cartão entrou no transmissor (passo "sent")
var _arrived := false   ## as unidades chegaram ao lugar certo da emergência de treino (passo "arrived")
var _hint := ""         ## a dica do passo, no papel do manual (`_show`)

@onready var main: Main = get_parent()


func start(night: Night) -> void:
	_night = night
	active = true
	main.notebook.registered.connect(_on_registered)
	main.dispatch.sent.connect(func(_l, _u, _c, _n, _e): _sent = true)
	main.dispatch.blank_card.connect(func(_l): _sent = true)
	main.dispatch.arrived.connect(func(e: EmergencyCall, r: Fleet.Result, _o, _x):
		if e != null and e == drill and r != Fleet.Result.WRONG_PLACE:   # um cartão do endereço errado não conta
			await main.radio.said   # o rádio diz o que encontraram
			_arrived = true)
	for s in night.lesson:
		_step = s
		await _play(s)
	_step = null
	active = false
	# as fichas das últimas ligações dela ficam para o jogador registrar
	_show(T.text(T.Key.HINT_REGISTER) if main.notebook.pending_count() > 0 else "")
	finished.emit()


func _play(s: LessonStep) -> void:
	match s.kind:
		LessonStep.Kind.RING:
			await _ring(s)
		LessonStep.Kind.SAY:
			if _here():
				await _say(s.text)
				if s.seconds > 0.0:
					await _pause(s.seconds)
		LessonStep.Kind.OPERATOR:
			if _here():
				var i := await main.conversation.choose(call, Array(s.options))
				if i >= 0:
					await main.conversation.op(call, s.options[i])
		LessonStep.Kind.WAIT:
			await _wait(s)
		LessonStep.Kind.PAUSE:
			await _pause(s.seconds)
		LessonStep.Kind.HANG_UP:
			if _here():
				Sfx.play("cut")
				call.sys(T.text(T.Key.SYS_OTHER_SIDE_ENDED))
				main.end_call(call, PhoneCall.End.CALLER)


## A ligação dela ainda está de pé (falas e opções só valem nela; se o jogador já completou a transferência, pula).
func _here() -> bool:
	return call != null and not call.ended


## Ela diz `text`; com o FONE fora da linha dela, ela espera em silêncio e o manual diz para voltar.
func _say(text: String) -> bool:
	var away := _here() and not call.on_line and not call.closing
	if away:
		main.hint(T.text(T.Key.HINT_TRAINING_BACK) % [tr(call.caller), call.line])
	var said := await main.conversation.say(call, text, 0.45)
	if away:
		main.hint(_hint)
	return said


## A dica do passo no papel do manual.
func _show(h: String) -> void:
	_hint = h
	main.hint(h)


func _pause(sec: float) -> void:
	await get_tree().create_timer(sec, false).timeout


## Ela liga pela entrada `s.line` e espera o jogador atender: primeiro a dica de pôr o FONE nela, depois a tecla
## Atender piscando.
func _ring(s: LessonStep) -> void:
	var c := PhoneCall.new()
	c.lesson = true
	c.speech = SPEECH
	c.voice = _night.teacher_voice
	c.caller = _night.teacher
	c.line = s.line
	if s.call != null:
		c.data = s.call
		c.target = s.call.target
		c.destination = s.call.destination
	call = c
	if s.emergency != null:
		drill = s.emergency
		drill_call = c
		main.dispatch.set_incident(drill)
	main.ring(c)
	var shown := ""
	while c.ringing:
		var on := main.board.fone_line() == c.line
		var h := T.text(T.Key.HINT_TUT_ANSWER) if on else tr(s.hint)
		if h != shown:
			shown = h
			_show(h)
		main.phone.blink_answer(on)
		await get_tree().process_frame
	main.phone.blink_answer(false)
	_show("")
	if s.call != null:
		c.phase = PhoneCall.Phase.AWAIT   # o pedido dela: o Transferir passa a valer


## Espera o jogador fazer `s.until`. Ela comenta o erro (`wrong`) e a demora (`nudges`), uma fala de cada vez, só com
## o operador na linha dela.
func _wait(s: LessonStep) -> void:
	if s.until == "sent":
		_sent = false
		_arrived = false
	var since := 0.0
	var nudge := 0
	var told := -1   # o lugar errado já comentado (não repete enquanto ele não mudar)
	var talked := 0.0
	while not _done(s.until):
		var h := _wait_hint(s)
		if h != _hint:
			_show(h)
		await get_tree().process_frame
		if get_tree().paused:   # o quadro passa na pausa, mas a demora e a conversa dela não contam
			continue
		var dt := get_process_delta_time()
		since += dt
		if s.until == "line_done":   # a conversa dela com o destino acaba sozinha (o relógio está parado)
			talked += dt
			if talked >= TALK_SEC and main.exchange.line(call.line) == Exchange.Line.CONN:
				main.talk_over(call.line)
		var bad := _mistake(s)
		if bad != told and bad != -1 and s.wrong != "" and _listening():
			told = bad
			since = 0.0
			await _say(_line(s.wrong, bad))
		elif bad == -1:
			told = -1
		if s.seconds > 0.0 and since >= s.seconds and nudge < s.nudges.size() and _listening():
			since = 0.0
			nudge += 1
			await _say(s.nudges[nudge - 1])


## A dica do manual no passo `s`: a dele, ou, se as unidades da emergência de treino ainda estão fora (um cartão
## enviado antes da hora), esperar que voltem para perfurá-las.
func _wait_hint(s: LessonStep) -> String:
	if s.until == "punched":
		var d := main.dispatch
		if Array(drill.units).any(func(u): return not u in d.picked() and not d.fleet.is_free(u)):
			return T.text(T.Key.HINT_TRAINING_UNITS_AWAY)
	return tr(s.hint)


## Ela está na linha e calada: pode comentar.
func _listening() -> bool:
	return _here() and call.active and call.on_line and not call.talking


## O jogador já fez `until` (os valores de `LessonStep.until`).
func _done(until: String) -> bool:
	var target := int(call.target) if call != null and call.target != "" else -1
	match until:
		"directory":
			return main.tools.open and main.tools.tab == Tools.DIRECTORY
		"dispatch":
			return main.tools.open and main.tools.tab == Tools.DISPATCH
		"card":
			return _card_at(_step.street, _step.block)
		"shred":
			return main.dispatch.location().is_empty() and main.dispatch.machines.can_print()
		"punched":
			var d := main.dispatch
			return _card_at("", 0) and d.occurrence() == drill.occurrence and Array(drill.units).all(func(u): return u in d.picked())
		"sent":
			return _sent
		"arrived":
			return _arrived
		"hold":
			return main.exchange.line(call.line) == Exchange.Line.HOLD
		"resume":
			return main.exchange.line(call.line) == Exchange.Line.TALK
		"cord_out":
			return main.board.cord_at(call.line + 10) != -1
		"cord_dest":
			return main.board.dest_of_output(call.line) == target
		"transfer":
			return target != -1 and main.exchange.dest(target) != Exchange.Dest.FREE
		"connected":
			return call.connected
		"line_done":
			return main.exchange.line(call.line) == Exchange.Line.DONE
		"line_free":
			return main.exchange.line(call.line) == Exchange.Line.FREE
		"logbook":
			return _opened(Tools.LOGBOOK, Main.SAW_SLIPS)
		"registered":
			return main.notebook.pending_count() == 0
		"call_log":
			return _opened(Tools.CALL_LOG, Main.SAW_SHEET)
		"diary":
			return _opened(Tools.DIARY, "diario_cecilia")
	push_error("Training: passo com until desconhecido: \"%s\"" % until)
	return true   # (não trava o treinamento)


## A ferramenta `tab` está aberta; o sinal da mesa que ela ensinou (`flag`) já não pede a dica de primeira vez.
func _opened(tab: String, flag: String) -> bool:
	if not (main.tools.open and main.tools.tab == tab):
		return false
	main.flags.apply(flag)
	return true


## Registrou uma ligação dela com um tipo que não é Comum, no passo de registrar: ela comenta, se estiver na linha.
func _on_registered(rec: PhoneCall.Record, type: T.Key) -> void:
	var s := _step
	if rec.tut and type != T.Key.TYPE_COMMON and s != null and s.kind == LessonStep.Kind.WAIT and s.until == "registered" \
			and s.wrong != "" and _listening():
		_say(s.wrong)


## O cartão na mesa é do lugar `street`/`block` (vazio: o da emergência de treino).
func _card_at(street: String, block: int) -> bool:
	var at := main.dispatch.location()
	if street == "":
		street = drill.street
		block = drill.block
	return not at.is_empty() and at["street"] == street and at["block"] == block


## O que o jogador fez de errado neste passo: a tomada errada, ou 0 num erro no cartão (-1 = nada).
func _mistake(s: LessonStep) -> int:
	match s.until:
		"card":
			if not main.dispatch.location().is_empty() and not _card_at(s.street, s.block):
				return 0
		"punched":
			var d := main.dispatch
			if d.occurrence() not in ["", drill.occurrence] or d.picked().any(func(u): return not u in drill.units):
				return 0
		"cord_out":
			for n in range(1, Exchange.LINES + 1):
				if n != call.line and main.board.cord_at(n + 10) != -1:
					return n
		"cord_dest", "transfer":
			var d := main.board.dest_of_output(call.line)
			if d != -1 and str(d) != call.target:
				return d
	return -1


## A fala `text` traduzida, com a tomada `n` no lugar do %d (se houver).
func _line(text: String, n: int) -> String:
	var t := tr(text)
	return t % n if "%d" in t else t


## Transferir com o cabo no número errado: ela avisa antes de tocar lá (`Main.transfer`). A fala é a do erro do passo
## só nos passos de cabo e transferência (nos outros, a fala de erro é de outra coisa: fica o aviso).
func wrong_number(d: int) -> void:
	Sfx.play("click")
	var cable := _step != null and _step.until in ["cord_out", "cord_dest", "transfer"]
	if cable and _step.wrong != "" and _listening():
		_say(_line(_step.wrong, d))
	else:
		main.warn(T.text(T.Key.WARN_TRAINING_WRONG) % d)
