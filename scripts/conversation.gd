class_name Conversation
extends Node
## As falas de cada ligação. Quem liga fala sílaba por sílaba; o operador escolhe o que responder.
## Quem não está com o FONE na entrada fica em espera e não fala até o operador voltar (`on_line`).
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
	if not await _until_on_line(c):
		return false
	text = tr(text)
	var ghost := c.kind == PhoneCall.Kind.MYSTERY
	var li := c.add_line(who if who != "" else c.caller, "", "ghost" if ghost else "")
	c.set_talking(true)
	var paren := text.begins_with("(")
	voice = "k" if paren else (voice if voice != "" else c.voice)
	var prev_vowel := false
	for i in text.length():
		# em espera, a pessoa para de falar até o operador voltar
		if not c.on_line and not await _until_on_line(c):
			c.set_talking(false)
			return false
		var ch := text[i]
		c.append_text(li, ch)
		prev_vowel = Sfx.speak_char(voice, text, i, prev_vowel, paren)
		var d := 0.062 if ghost else (0.09 if ch in [",", "."] else 0.028)
		await get_tree().create_timer(d).timeout
		if c.ended:
			c.set_talking(false)
			return false
	c.last_talk = Time.get_ticks_msec()
	await get_tree().create_timer(pause).timeout
	c.set_talking(false)
	return not c.ended


## O operador diz `text`.
func op(c: PhoneCall, text: String) -> bool:
	if not await _until_on_line(c):
		return false
	c.add_line("Você", tr(text), "op")
	Sfx.play("click")
	c.last_talk = Time.get_ticks_msec()
	await get_tree().create_timer(0.75).timeout
	return not c.ended


func wait(c: PhoneCall, sec: float) -> bool:
	await get_tree().create_timer(sec).timeout
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
	if randf() < 0.55:
		if not await say(c, GameData.pick(C.smalltalk), 0.45):
			return
	c.phase = PhoneCall.Phase.AWAIT
	c.state_changed.emit()
	main.on_transfer_waiting(c)
	transfer_choices(c)


func transfer_choices(c: PhoneCall) -> void:
	var t: TransferCall = c.data
	var list: Array[Dictionary] = []
	if not c.said_wait:
		list.append({"label": tr("Um momento, vou conectar."), "fn": _transfer_wait.bind(c)})
	list.append({"label": tr("Pode repetir, por favor?"), "fn": _transfer_repeat.bind(c)})
	if c.no_answer and t.alt_target != "" and not c.alt_done:
		list.append({"label": tr(t.alt_ask), "fn": _transfer_alt.bind(c)})
	c.set_options(list)


func _transfer_wait(c: PhoneCall) -> void:
	if c.talking:
		return
	c.said_wait = true
	transfer_choices(c)
	if not await op(c, "Um momento, vou conectar."):
		return
	await say(c, GameData.pick(C.hold_ok))


func _transfer_repeat(c: PhoneCall) -> void:
	if c.talking:
		return
	if not await op(c, "Pode repetir, por favor?"):
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
	var right := ""
	var opts := []
	if c.about != "":
		right = tr("É o %s.") % c.answer
		opts = [right]
		while opts.size() < 3:
			var o := tr("É o %s.") % C.directory.pick_random().number
			if not o in opts:
				opts.append(o)
	else:
		right = tr("São %s.") % Main.fmt(main.minutes)
		opts = [right, tr("São %s.") % Main.fmt(main.minutes + 60.0), tr("São %s.") % Main.fmt(main.minutes - 45.0)]
	opts.shuffle()
	c.phase = PhoneCall.Phase.INFO
	c.state_changed.emit()
	if not _taught_info:
		_taught_info = true
		main.hint(tr("Pedido de informação: confira a lista telefônica (ou o relógio) antes de responder."))
	var i := await choose(c, opts)
	if i < 0 or not await op(c, opts[i]):
		return
	c.info_ok = 1 if opts[i] == right else 0
	if not await say(c, GameData.pick(C.info_thanks if c.info_ok == 1 else C.info_doubt), 0.5):
		return
	c.sys(tr("(O solicitante desligou.)"))
	main.end_call(c, PhoneCall.End.CALLER)


# ---------------------------------------------------------------- emergência

func _emergency(c: PhoneCall) -> void:
	var e: EmergencyCall = c.data
	if not await greet(c):
		return
	if c.too_late:
		main.report.failed(e)
		c.sys(tr("(O solicitante desligou.)"))
		main.end_call(c, PhoneCall.End.CALLER)
		return
	if not await wait(c, 0.3):
		return
	# quem liga de novo porque piorou já disse o que houve; dá para perguntar e despachar de novo
	if c.retry != PhoneCall.Retry.WORSE and not await say(c, e.opening, 0.3):
		return
	c.phase = PhoneCall.Phase.EMERGENCY
	c.state_changed.emit()
	main.hint(tr("Pergunte o que precisa. Marque o local no mapa, escolha o tipo da ocorrência e envie as unidades pelo despacho."))
	emergency_choices(c)


func emergency_choices(c: PhoneCall) -> void:
	var e: EmergencyCall = c.data
	var list: Array[Dictionary] = []
	for i in e.questions.size():
		if not i in c.asked:
			list.append({"label": tr(e.questions[i]), "fn": _em_ask.bind(c, i)})
	if not c.dispatched:
		list.append({"label": tr("Fique na linha, vou enviar ajuda."), "fn": _em_hold.bind(c)})
	c.set_options(list)


func _em_ask(c: PhoneCall, k: int) -> void:
	var e: EmergencyCall = c.data
	if c.talking or c.ended:
		return
	c.asked.append(k)
	emergency_choices(c)
	if not await op(c, e.questions[k]):
		return
	await say(c, e.answers[k])


func _em_hold(c: PhoneCall) -> void:
	if c.talking:
		return
	if not await op(c, "Fique na linha, vou enviar ajuda."):
		return
	await say(c, ["Rápido, por favor!", "Tá bom... tá bom."].pick_random())


## As unidades saíram: o operador avisa e a pessoa desliga.
func emergency_dispatched(c: PhoneCall) -> void:
	if not c.active or c.dispatched:
		return
	c.dispatched = true
	emergency_choices(c)
	while c.talking:
		if not await wait(c, 0.2):
			return
	if not await op(c, "As unidades estão a caminho."):
		return
	if not await say(c, (c.data as EmergencyCall).after, 0.9):
		return
	c.sys(tr("(O solicitante desligou.)"))
	main.end_call(c, PhoneCall.End.CALLER)


# ---------------------------------------------------------------- trote

func _prank(c: PhoneCall) -> void:
	var p: PrankCall = c.data
	if not await greet(c):
		return
	if not await wait(c, 0.6):
		return
	for st in p.steps:
		match st.kind:
			PrankStep.Kind.CALLER:
				if not await say(c, st.text, 0.45):
					return
			PrankStep.Kind.PAUSE:
				if not await wait(c, st.seconds):
					return
			PrankStep.Kind.OPERATOR:
				var i := await choose(c, Array(st.options))
				if i < 0 or not await op(c, st.options[i]):
					return
			PrankStep.Kind.END:
				Sfx.play("cut")
				c.sys(tr("(A ligação foi encerrada do outro lado.)"))
				if not await wait(c, 0.5):
					return
				main.end_call(c, PhoneCall.End.CALLER)


# ---------------------------------------------------------------- a ligação misteriosa

func _op_line(c: PhoneCall, l: String) -> bool:
	if await choose(c, [l]) < 0:
		return false
	return await op(c, l)


func _mystery(c: PhoneCall) -> void:
	if not await greet(c): return
	if not await wait(c, 2.6): return
	if not await say(c, "...alô?", 0.7): return
	if not await _op_line(c, "Central telefônica. Qual número você está tentando chamar?"): return
	if not await wait(c, 2.2): return
	if not await say(c, "Eu não sei."): return
	if not await _op_line(c, "Qual é o seu nome?"): return
	if not await wait(c, 1.5): return
	if not await say(c, "Eu estou tentando descobrir."): return
	Sfx.static_burst(2.0)
	if not await _op_line(c, "Onde você está?"): return
	if not await wait(c, 1.2): return
	if not await say(c, "Eu não sei."): return
	if not await _op_line(c, "Você consegue me dizer alguma rua?"): return
	if not await wait(c, 3.4): return
	if not await say(c, "Tem uma luz.", 0.6): return
	if not await _op_line(c, "Que luz?"): return
	if not await wait(c, 1.3): return
	main.flick = true
	if not await say(c, "A luz da sua mesa.", 2.6): return
	Sfx.static_burst()
	if not await say(c, "Ela sempre fica acesa?", 0.5): return
	main.end_call(c, PhoneCall.End.MYSTERY)
