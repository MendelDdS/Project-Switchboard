class_name Conversation
extends Node
## As falas de cada ligação. Quem liga fala sílaba por sílaba; o operador escolhe o que responder.
## Quem não está com o FONE na entrada fica em espera e não fala até o operador voltar (`on_line`), a não ser
## que a ligação já esteja resolvida (`closing`): aí a pessoa termina de falar sozinha e desliga, sem som e sem
## aparecer na transcrição (o operador não está ouvindo).
## Os roteiros vêm dos Resources em data/calls/; aqui fica só como cada tipo de ligação se desenrola.

var C: GameContent = GameData.CONTENT

var _taught_info := false

@onready var main: Main = get_parent()


func run(c: PhoneCall) -> void:
	match c.kind:
		PhoneCall.Kind.TRANSFER:
			_transfer(c)
		PhoneCall.Kind.EMERGENCY:
			_emergency(c)
		PhoneCall.Kind.PRANK:
			_prank(c)
		PhoneCall.Kind.INFO:
			_info(c)
		PhoneCall.Kind.MYSTERY:
			_mystery(c)


# ---------------------------------------------------------------- falar e ouvir

## Espera o operador estar na linha dessa ligação. Falso se ela terminar antes.
func _until_on_line(c: PhoneCall) -> bool:
	while not (c.active and c.on_line):
		if c.ended:
			return false
		await get_tree().process_frame
	return true


## Quem ligou diz `text` (ou outra pessoa na linha: `who` com a voz `voice`). Falso se a ligação terminar no meio.
func say(c: PhoneCall, text: String, pause: float = 0.55, who := "", voice := "") -> bool:
	if c.ended or not c.closing and not await _until_on_line(c):
		return false
	text = tr(text)
	var ghost := c.kind == PhoneCall.Kind.MYSTERY
	var li := -1   # a linha da transcrição só aparece enquanto o operador está ouvindo
	c.set_talking(true)
	var paren := text.begins_with("(")
	voice = "k" if paren else (voice if voice != "" else c.voice)
	var prev_vowel := false
	for i in text.length():
		# em espera, a pessoa para de falar até o operador voltar
		if not c.on_line and not c.closing and not await _until_on_line(c):
			c.set_talking(false)
			return false
		var ch := text[i]
		if c.on_line:
			if li == -1:
				li = c.add_line(who if who != "" else c.caller, "", "ghost" if ghost else "")
			c.append_text(li, ch)
			prev_vowel = Sfx.speak_char(voice, text, i, prev_vowel, paren)
		var d := (0.062 if ghost else (0.09 if ch in [",", "."] else 0.028)) * Settings.char_delay()
		await get_tree().create_timer(d, false).timeout
		if c.ended:
			c.set_talking(false)
			return false
	c.last_talk = main.talk_clock
	await get_tree().create_timer(pause, false).timeout
	c.set_talking(false)
	return not c.ended


## O operador diz `text` (numa ligação resolvida, o clique já é a fala, mesmo que ele tenha ido para outra linha).
func op(c: PhoneCall, text: String) -> bool:
	if c.ended or not c.closing and not await _until_on_line(c):
		return false
	c.add_line("", tr(text), "op")
	Sfx.play("click")
	c.last_talk = main.talk_clock
	await get_tree().create_timer(0.75, false).timeout
	return not c.ended


func wait(c: PhoneCall, sec: float) -> bool:
	await get_tree().create_timer(sec, false).timeout
	return not c.ended


## Mostra as opções e espera o operador escolher uma. -1 se a ligação terminar antes.
func choose(c: PhoneCall, opts: Array) -> int:
	var picked := [-1]
	var list: Array[Dictionary] = []
	for i in opts.size():
		var k := i
		var fn := func():
			picked[0] = k
			c.set_options([])
		list.append({"label": tr(opts[i]), "fn": fn})
	c.set_options(list)
	while picked[0] == -1:
		if c.ended:
			return -1
		await get_tree().process_frame
	return picked[0]


## Toda ligação começa igual: o operador não sabe o que vem do outro lado.
## Quem está ligando de novo reclama logo de cara.
func greet(c: PhoneCall) -> bool:
	if not await wait(c, 0.3):
		return false
	if not await op(c, GameData.pick(C.greetings)):
		return false
	match c.retry:
		PhoneCall.Retry.MISSED:
			return await say(c, GameData.pick(C.retry_missed))
		PhoneCall.Retry.WRONG_INFO:
			return await say(c, GameData.pick(C.retry_wrong_info))
		PhoneCall.Retry.WRONG_NUMBER:
			return await say(c, GameData.pick(C.retry_wrong_number))
		PhoneCall.Retry.WORSE:
			return await say(c, GameData.pick(C.retry_too_late if c.too_late else C.retry_worse))
	return true


# ---------------------------------------------------------------- transferência

func _transfer(c: PhoneCall) -> void:
	var t: TransferCall = c.data
	if not await greet(c):
		return
	if not await wait(c, 0.5):
		return
	for l in t.opening:
		if not await say(c, l):
			return
	# a conversa fiada vem depois, se o operador demorar (Main._nag)
	c.phase = PhoneCall.Phase.AWAIT
	c.state_changed.emit()
	main.on_transfer_waiting(c)
	transfer_choices(c)


func transfer_choices(c: PhoneCall) -> void:
	var t: TransferCall = c.data
	var list: Array[Dictionary] = []
	if not c.said_wait:
		list.append({"label": T.text(T.Key.OP_CONNECT_WAIT), "fn": _transfer_wait.bind(c)})
	list.append({"label": T.text(T.Key.OP_REPEAT), "fn": _transfer_repeat.bind(c)})
	if c.no_answer and t.alt_target != "" and not c.alt_done:
		list.append({"label": tr(t.alt_ask), "fn": _transfer_alt.bind(c)})
	c.set_options(list)


func _transfer_wait(c: PhoneCall) -> void:
	if c.talking:
		return
	c.said_wait = true
	transfer_choices(c)
	if not await op(c, T.text(T.Key.OP_CONNECT_WAIT)):
		return
	await say(c, GameData.pick(C.hold_ok))


func _transfer_repeat(c: PhoneCall) -> void:
	if c.talking:
		return
	if not await op(c, T.text(T.Key.OP_REPEAT)):
		return
	await say(c, c.repeat)


## O lugar pedido não atende à noite: o operador sugere outro.
func _transfer_alt(c: PhoneCall) -> void:
	var t: TransferCall = c.data
	if c.talking:
		return
	c.alt_done = true
	c.target = t.alt_target
	c.destination = t.alt_destination
	c.repeat = t.alt_destination + "."
	transfer_choices(c)
	if not await op(c, t.alt_ask):
		return
	await say(c, t.alt_yes)


# ---------------------------------------------------------------- informação

func _info(c: PhoneCall) -> void:
	if not await greet(c):
		return
	if not await wait(c, 0.4):
		return
	if not await say(c, c.ask):
		return
	var right := T.text(T.Key.OP_IT_IS) % c.answer
	var opts := [right]
	while opts.size() < 3:
		var o := T.text(T.Key.OP_IT_IS) % C.directory.pick_random().number
		if not o in opts:
			opts.append(o)
	opts.shuffle()
	c.phase = PhoneCall.Phase.INFO
	c.state_changed.emit()
	if not _taught_info:
		_taught_info = true
		main.hint(T.text(T.Key.HINT_INFO))
	var i := await choose(c, opts)
	if i < 0:
		return
	c.info_ok = 1 if opts[i] == right else 0
	c.closing = true
	if not await op(c, opts[i]):
		return
	if not await say(c, GameData.pick(C.info_thanks if c.info_ok == 1 else C.info_doubt), 0.5):
		return
	c.sys(T.text(T.Key.SYS_CALLER_HUNG_UP))
	main.end_call(c, PhoneCall.End.CALLER)


# ---------------------------------------------------------------- emergência

func _emergency(c: PhoneCall) -> void:
	var e: EmergencyCall = c.data
	if not await greet(c):
		return
	if c.too_late:
		main.report.failed(e)
		c.sys(T.text(T.Key.SYS_CALLER_HUNG_UP))
		main.end_call(c, PhoneCall.End.CALLER)
		return
	if not await wait(c, 0.3):
		return
	# quem liga de novo porque piorou já disse o que houve; dá para perguntar e despachar de novo
	if c.retry != PhoneCall.Retry.WORSE and not await say(c, e.opening, 0.3):
		return
	c.phase = PhoneCall.Phase.EMERGENCY
	c.state_changed.emit()
	main.hint(T.text(T.Key.HINT_EMERGENCY))
	emergency_choices(c)


## Perguntas que o operador pode fazer: as do roteiro e uma sobre cada estágio que a pessoa já contou (índices
## depois das do roteiro). Perdida: só o endereço (a primeira) e "Tem alguém ferido?".
func emergency_choices(c: PhoneCall) -> void:
	var e: EmergencyCall = c.data
	var n := e.questions.size()
	var ks: Array = [0, n + 2] if c.told >= 3 else range(n + c.told)
	var list: Array[Dictionary] = []
	for k in ks:
		var qa := _qa(e, k)
		if not k in c.asked and qa[0] != "":
			list.append({"label": tr(qa[0]), "fn": _em_ask.bind(c, k)})
	if not c.dispatched:
		list.append({"label": T.text(T.Key.OP_HOLD_EMERGENCY), "fn": _em_hold.bind(c)})
	c.set_options(list)


func _em_ask(c: PhoneCall, k: int) -> void:
	var e: EmergencyCall = c.data
	if c.talking or c.ended:
		return
	c.asked.append(k)
	emergency_choices(c)
	# a barra de agravamento para enquanto o operador pergunta e a pessoa responde
	var qa := _qa(e, k)
	c.asking = true
	if await op(c, qa[0]):
		await say(c, qa[1])
	c.asking = false


## Pergunta e resposta `k`: as do roteiro e, depois delas, as dos estágios (agravando, agravada, perdida).
func _qa(e: EmergencyCall, k: int) -> Array:
	var n := e.questions.size()
	if k < n:
		return [e.questions[k], e.answers[k]]
	return [[e.worsening_question, e.worsening_answer], [e.critical_question, e.critical_answer],
		[T.text(T.Key.OP_ANYONE_HURT), e.lost_answer]][k - n]


func _em_hold(c: PhoneCall) -> void:
	if c.talking:
		return
	if not await op(c, T.text(T.Key.OP_HOLD_EMERGENCY)):
		return
	await say(c, T.text([T.Key.CALLER_HURRY, T.Key.CALLER_OKAY].pick_random()))


## A situação piorou (Main._worsen): a pessoa conta o que mudou assim que o operador estiver na linha e ela puder
## falar. Depois do despacho, o que ficou por dizer não importa mais.
func emergency_worse(c: PhoneCall, stage: int) -> void:
	var e: EmergencyCall = c.data
	var text: String = [e.worsening, e.critical, e.lost][stage - 1]
	if text == "":
		return
	while not c.on_line or c.talking or c.asking:
		if c.ended or c.dispatched:
			return
		await get_tree().process_frame
	if await say(c, text):
		main.emergency_told(c, stage)
		emergency_choices(c)


## As unidades saíram: o operador avisa e a pessoa desliga.
func emergency_dispatched(c: PhoneCall) -> void:
	if not c.active or c.dispatched:
		return
	c.dispatched = true
	c.closing = true
	emergency_choices(c)
	while c.talking:
		if not await wait(c, 0.2):
			return
	# o operador só avisa se estiver na linha; a pessoa ouve as sirenes de qualquer jeito
	if c.on_line and not await op(c, T.text(T.Key.OP_UNITS_ON_WAY)):
		return
	if not await say(c, (c.data as EmergencyCall).after, 0.9):
		return
	c.sys(T.text(T.Key.SYS_CALLER_HUNG_UP))
	main.end_call(c, PhoneCall.End.CALLER)


# ---------------------------------------------------------------- roteiros falados (trote e ligação desconhecida)

## Segue os passos até o fim ou até um END, pulando os que pedem marcadores que não batem.
## Falso se a ligação terminar no meio.
func play_steps(c: PhoneCall, steps: Array[PrankStep]) -> bool:
	for st in steps:
		if not main.flags.allows(st.requires):
			continue
		match st.kind:
			PrankStep.Kind.CALLER:
				if not await say(c, st.text, st.seconds if st.seconds > 0.0 else 0.45):
					return false
			PrankStep.Kind.PAUSE:
				if not await wait(c, st.seconds):
					return false
			PrankStep.Kind.OPERATOR:
				var i := await choose(c, Array(st.options))
				if i < 0:
					return false
				if i < st.sets.size():
					main.flags.apply(st.sets[i])
				if not await op(c, st.options[i]):
					return false
			PrankStep.Kind.EFFECT:
				match st.effect:
					"static":
						Sfx.static_burst()
					"static_loud":
						Sfx.static_burst(2.0)
					"flick":
						main.flick = true
			PrankStep.Kind.END:
				return true
	return true


func _prank(c: PhoneCall) -> void:
	if not await greet(c):
		return
	if not await wait(c, 0.6):
		return
	if not await play_steps(c, (c.data as PrankCall).steps):
		return
	Sfx.play("cut")
	c.sys(T.text(T.Key.SYS_OTHER_SIDE_ENDED))
	if not await wait(c, 0.5):
		return
	main.end_call(c, PhoneCall.End.CALLER)


## O roteiro muda a cada noite (Night.mystery).
func _mystery(c: PhoneCall) -> void:
	if not await greet(c):
		return
	if not await play_steps(c, main.night.mystery):
		return
	main.end_call(c, PhoneCall.End.MYSTERY)
