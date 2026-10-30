class_name Conversation
extends Node
## As falas de cada ligação. Quem liga fala sílaba por sílaba; o operador escolhe o que responder.
## Quem não está com o FONE na entrada fica em espera e não fala até o operador voltar (`on_line`), a não ser
## que a ligação já esteja resolvida (`closing`): aí a pessoa termina de falar sozinha e desliga, sem som e sem
## aparecer na transcrição (o operador não está ouvindo).
## Os roteiros vêm dos Resources em data/calls/; aqui fica só como cada tipo de ligação se desenrola.

const SMALLTALK_MAX := 3            ## assuntos de conversa fiada por ligação (puxados por ela ou pelo operador)
const CHAT_WARM_PATIENCE := 10.0    ## resposta simpática: segundos a mais de silêncio antes de ela reclamar
const BUSY_PATIENCE := 40.0         ## ...e esperando, os segundos a mais de silêncio antes de reclamar
const DIAL_RINGS := Vector2i(2, 4)  ## a ligação que o operador faz: quantos toques até atenderem...
const DIAL_NO_ANSWER := 6           ## ...e até a ligação cair, quando ninguém atende
const DIAL_ASKS := 2                ## perguntas oferecidas (sorteadas entre as do atendimento), fora o Encerrar
const DialCall := preload("res://scripts/data/dial_call.gd")

var busy_wait_chance := 0.6   ## todas as linhas ocupadas: a chance de quem liga esperar (senão, liga outra hora)
var C: GameContent = GameData.CONTENT
var heard: Array[ChatTopic] = []    ## novidades da conversa fiada já contadas nesta noite (não se repetem)

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
		PhoneCall.Kind.OUTGOING:
			_outgoing(c)


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
	while c.talking:   # uma fala por vez: a nova espera a anterior terminar (ex.: o agradecimento depois do assunto)
		await get_tree().process_frame
		if c.ended:
			return false
	text = tr(text)
	var ghost := c.kind == PhoneCall.Kind.MYSTERY
	var li := -1   # a linha da transcrição só aparece enquanto o operador está ouvindo
	c.set_talking(true)
	var paren := text.begins_with("(")
	voice = "k" if paren else (voice if voice != "" else c.voice)
	var prev_vowel := false
	var pitch := Sfx.pitch_of(who if who != "" else c.caller)
	for i in text.length():
		# em espera, a pessoa para de falar até o operador voltar
		if not c.on_line and not c.closing and not await _until_on_line(c):
			c.set_talking(false)
			return false
		var ch := text[i]
		if c.on_line:
			if li == -1:
				li = c.add_line(who if who != "" else (c.named if c.named != "" else c.caller), "", "ghost" if ghost else "")
			c.append_text(li, ch)
			prev_vowel = Sfx.speak_char(voice, text, i, prev_vowel, paren, -1.0, pitch, Sfx.agitation(c))
		var d := (0.062 if ghost else (0.09 if ch in [",", "."] else 0.028)) * c.speech
		d *= 1.0 - Sfx.agitation(c) * Sfx.AGITATION["speed"]
		await get_tree().create_timer(d, false).timeout
		if c.ended:
			c.set_talking(false)
			return false
	c.last_talk = main.talk_clock
	await get_tree().create_timer(pause, false).timeout
	c.set_talking(false)
	return not c.ended


## Quem ligou estala os dedos no ritmo `rhythm` ("tec tec... tec": cada "tec" um estalo; com "...", a pausa longa
## depois dele); a transcrição mostra o ritmo, para o operador comparar. Falso se a ligação terminar no meio.
func snaps(c: PhoneCall, rhythm: String) -> bool:
	if c.ended or not c.closing and not await _until_on_line(c):
		return false
	while c.talking:
		await get_tree().process_frame
		if c.ended:
			return false
	c.set_talking(true)
	var li := c.add_line(c.named if c.named != "" else c.caller, "(")
	var beats := rhythm.split(" ", false)
	for i in beats.size():
		Sfx.play("snap")
		c.append_text(li, beats[i] + (" " if i < beats.size() - 1 else ")"))
		await get_tree().create_timer(0.9 if beats[i].ends_with("...") else 0.3, false).timeout
		if c.ended:
			c.set_talking(false)
			return false
	c.last_talk = main.talk_clock
	c.set_talking(false)
	return true


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
## Quem está ligando de novo reclama logo de cara. Depois, o que as burocracias pedem no começo (`call_started`).
func greet(c: PhoneCall) -> bool:
	if not await wait(c, 0.3):
		return false
	if not await op(c, GameData.pick(C.greetings)):
		return false
	var said := true
	match c.retry:
		PhoneCall.Retry.MISSED:
			said = await say(c, GameData.pick(C.retry_missed))
		PhoneCall.Retry.WRONG_INFO:
			said = await say(c, GameData.pick(C.retry_wrong_info))
		PhoneCall.Retry.WRONG_NUMBER:
			said = await say(c, GameData.pick(C.retry_wrong_number))
		PhoneCall.Retry.BUSY:
			said = await say(c, GameData.pick(C.retry_busy))
		PhoneCall.Retry.WORSE:
			said = await say(c, GameData.pick(C.retry_too_late if c.too_late else C.retry_worse))
	if not said:
		return false
	return await main.bureaucracy.call_started(c)


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
	if not await main.bureaucracy.request_made(c):   # o que as burocracias pedem depois do pedido (o código...)
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
		list.append({"label": T.text(T.Key.CHOICE_CONNECT_WAIT), "fn": _transfer_wait.bind(c)})
	if not c.busy_asked and main.no_cords(c):
		list.append({"label": T.text(T.Key.CHOICE_ALL_BUSY), "fn": _all_busy.bind(c)})
	list.append({"label": T.text(T.Key.CHOICE_REPEAT), "fn": _transfer_repeat.bind(c)})
	if c.no_answer and t.alt_target != "" and not c.alt_done:
		list.append({"label": T.text(T.Key.CHOICE_OFFER_ALT), "fn": _transfer_alt.bind(c)})
	list.append_array(main.bureaucracy.choices(c))
	if c.chat != null:
		for r in c.chat.replies:
			list.append({"label": tr(r.text), "fn": _chat.bind(c, r)})
	elif not c.chat_asked and not c.chatting and c.chats.size() < SMALLTALK_MAX:
		list.append({"label": T.text(T.Key.CHOICE_SMALLTALK), "fn": _ask_chat.bind(c)})
	c.set_options(list)


## Conversa fiada que pode sair agora (`ChatTopic`): os assuntos gerais e as novidades da noite, no clima da noite,
## com os marcadores batendo e sem as novidades já contadas; com `voice`, só os que essa voz pode dizer.
func topics(voice := "") -> Array:
	return (C.smalltalk + main.night.smalltalk).filter(func(t: ChatTopic): return t.weather in ["", main.weather] \
		and (voice == "" or t.voices.is_empty() or voice in t.voices) and main.flags.allows(t.requires) and not t in heard)


## Novidade: assunto da noite ou que depende de marcador. Vem antes dos outros e só uma vez por noite.
func is_news(t: ChatTopic) -> bool:
	return t in main.night.smalltalk or not t.requires.is_empty()


## Quem espera a transferência puxa um assunto (`ChatTopic`); o operador pode responder (as respostas do próprio
## assunto viram opções) enquanto procura na lista. `asked`: o operador perguntou como vai a noite; ela responde
## primeiro (`GameContent.chat_bridge`) e só puxa assunto que caiba como resposta (sem `unprompted_only`).
func smalltalk(c: PhoneCall, asked := false) -> void:
	var pool := topics(c.voice).filter(func(t): return not t in c.chats and not (asked and t.unprompted_only))
	var news := pool.filter(is_news)
	if not news.is_empty():
		pool = news
	if pool.is_empty() or c.chatting:
		return
	var topic: ChatTopic = pool.pick_random()
	if is_news(topic):
		heard.append(topic)
	c.chats.append(topic)
	c.chatting = true
	transfer_choices(c)
	if asked and not await say(c, GameData.pick(C.chat_bridge), 0.35):
		c.chatting = false
		return
	if not await say(c, topic.line, 0.45) or c.options.is_empty():
		c.chatting = false   # sem opções: a transferência já saiu
		return
	c.chat = topic
	transfer_choices(c)


## O operador puxa assunto, uma vez por ligação (para ganhar tempo procurando na lista); quem espera conta alguma coisa.
func _ask_chat(c: PhoneCall) -> void:
	if c.talking or c.chat_asked:
		return
	c.chat_asked = true   # some a opção já no clique
	transfer_choices(c)
	if await op(c, T.text(T.Key.OP_SMALLTALK)):
		await smalltalk(c, true)


## Responder a conversa fiada: ela continua o assunto (a `follow` da resposta) e o silêncio recomeça (adia a
## reclamação da demora). Pelo tom: simpática, ela espera mais um pouco antes de reclamar e depois pode puxar outro
## assunto (`SMALLTALK_MAX`); seca, não puxa mais. A resposta também pode alterar marcadores (`sets`).
func _chat(c: PhoneCall, r: ChatReply) -> void:
	if c.talking or c.chat == null:
		return
	c.chat = null
	c.chatting = false
	for s in r.sets:
		main.flags.apply(s)
	c.chatted = r.tone == ChatReply.Tone.CURT or c.chats.size() >= SMALLTALK_MAX
	c.chat_asked = c.chat_asked or r.tone == ChatReply.Tone.CURT
	transfer_choices(c)
	if await op(c, r.text) and await say(c, r.follow) and r.tone == ChatReply.Tone.WARM:
		c.last_talk += CHAT_WARM_PATIENCE


func _transfer_wait(c: PhoneCall) -> void:
	if c.talking:
		return
	c.said_wait = true
	transfer_choices(c)
	if not await op(c, T.text(T.Key.OP_CONNECT_WAIT)):
		return
	await say(c, GameData.pick(C.hold_ok))


## Todos os cabos de conexão em uso: o operador avisa e pergunta se ela espera. Quem espera aguenta mais o silêncio
## (`Main._nag`) e a espera (`Supervisor.check_hold`); quem não espera desliga sem advertência e liga de novo mais tarde.
func _all_busy(c: PhoneCall) -> void:
	if c.talking:
		return
	c.busy_asked = true
	transfer_choices(c)
	if not await op(c, T.text(T.Key.OP_ALL_BUSY)):
		return
	if randf() < busy_wait_chance:
		if await say(c, GameData.pick(C.busy_wait)):
			c.last_talk = main.talk_clock + BUSY_PATIENCE
		return
	c.busy_later = true
	c.closing = true
	c.set_options([])
	if not await say(c, GameData.pick(C.busy_later)):
		return
	c.sys(T.text(T.Key.SYS_CALLER_HUNG_UP))
	main.supervisor.call_again(c, PhoneCall.Retry.BUSY)
	main.end_call(c, PhoneCall.End.CALLER)


func _transfer_repeat(c: PhoneCall) -> void:
	if c.talking:
		return
	if not await op(c, T.text(T.Key.OP_REPEAT)):
		return
	await say(c, c.repeat)


## O lugar pedido não atendeu: o operador sugere outro (que atende).
func _transfer_alt(c: PhoneCall) -> void:
	var t: TransferCall = c.data
	if c.talking:
		return
	c.alt_done = true
	c.away = false
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
		var o := T.text(T.Key.OP_IT_IS) % str(GameData.board_numbers().pick_random())
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
		list.append({"label": T.text(T.Key.CHOICE_HOLD_EMERGENCY), "fn": _em_hold.bind(c)})
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


## A situação piorou (Urgency.tick): a pessoa conta o que mudou assim que o operador estiver na linha e ela puder
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
		main.urgency.told(c, stage)
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


# ---------------------------------------------------------------- a ligação que o operador faz (o discador)

## Chama alguns toques e atende a do roteiro (`DialCall`) ou o atendimento do lugar (`DirectoryEntry.answers`, um dos
## que valem agora): quem atende diz como atende e o operador faz uma pergunta ou encerra; respondida, só resta
## encerrar (a conversa não se estica). Sem atendimento, ninguém atende e a ligação cai (`Dialing.unanswered`).
func _outgoing(c: PhoneCall) -> void:
	var story := c.data as DialCall
	var e := c.data as DirectoryEntry
	var pool := e.answers.filter(func(t: ChatTopic): return t.weather in ["", main.weather] and main.flags.allows(t.requires)) \
		if e != null else []
	var topic: ChatTopic = null if pool.is_empty() else pool.pick_random()
	for i in randi_range(DIAL_RINGS.x, DIAL_RINGS.y) if story != null or topic != null else DIAL_NO_ANSWER:
		Sfx.play("ringback")
		if not await wait(c, 2.0):
			return
	if story == null and topic == null:
		main.dialing.unanswered(c)
		return
	main.dialing.answered(c)
	if not await wait(c, 0.4):
		return
	if story != null:
		if not await play_steps(c, story.steps):
			return
		for f in story.sets:
			main.flags.apply(f)
		if story.once:
			main.flags.apply(story.done_flag())
		Sfx.play("cut")
		main.dialing.finish(PhoneCall.End.CALLER)
		return
	if not await say(c, topic.line):
		return
	var asks := topic.replies.duplicate()
	asks.shuffle()
	asks = asks.slice(0, DIAL_ASKS)
	var asked := false
	while true:
		var opts: Array = [] if asked else asks.map(func(r: ChatReply): return r.text)
		opts.append(T.text(T.Key.CHOICE_DIAL_BYE))
		var i := await choose(c, opts)
		if i < 0:
			return
		if i == opts.size() - 1:
			break
		var r: ChatReply = asks[i]
		for f in r.sets:
			main.flags.apply(f)
		if not await op(c, r.text) or not await say(c, r.follow):
			return
		asked = true
	if await op(c, T.text(T.Key.OP_DIAL_BYE)) and await say(c, e.bye if e.bye != "" else GameData.pick(C.dial_byes), 0.3):
		main.dialing.finish(PhoneCall.End.OPERATOR)
