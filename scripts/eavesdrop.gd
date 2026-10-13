class_name Eavesdrop
extends Node
## A escuta (nó filho de Main). Com o FONE na entrada de uma linha conectada e a chave de escuta dela levantada
## (`Exchange.key`: tecla Escutar, Z, ou clique na alavanca da mesa), o operador ouve a conversa dos dois: as falas
## escritas (`TransferCall.overheard`; a conversa anda ouvindo ou não, e o que ele não ouviu, perdeu) ou o murmúrio das
## vozes, sem texto. A tela da conversa mostra o que ele ouve (`_ears`: uma PhoneCall só para isso, fora do Registro).
## É proibido: ouvindo, a suspeita dos dois sobe (`PhoneCall.suspicion`, em `LISTEN_SEC` chega a 1; cada vez que ele
## entra na linha, pela chave subindo ou pelo FONE encaixando com ela em cima, o estalo soma `CLICK`) e, sem ninguém
## ouvindo, baixa devagar (`COOL_SEC`). Só se nota pela conversa: passando de `HUSH` com ele ouvindo, a conversa
## normal para e o resto anda no tempo (`_react`): terminada a fala, calam-se `HUSH_SEC` (a melhor hora de baixar a
## chave: sem ninguém ouvindo, a conversa segue; os muito desconfiados, `SKEPTIC`, não se calam e, depois de uma pausa,
## `ASK_PAUSE`, perguntam já), um pergunta ao outro se tem alguém na linha (`C.overheard_ask`) e, com ele ainda
## ouvindo, o outro responde e os dois ficam sabendo (`C.overheard_sure`, a resposta da mesma pergunta; `_knows`; sem
## ninguém ouvindo no fim da pergunta, desconversam e a suspeita baixa para `SHRUG` abaixo de `HUSH`); sabendo, mais
## `HUSH_SEC` calados com ele ouvindo e desligam para denunciar a telefonista: a companhia cobra no relatório da noite
## seguinte (`Supervisor.fault_later`, advertência grave `eavesdrop`). Marcadores para o roteiro: `escutou_N` (ouviu
## alguma conversa na noite N), `denunciado_N` e os da ligação ouvida inteira (`TransferCall.overheard_sets`).
## Palavras-chave (`Clue`, `[tipo:texto]` nas falas escritas): ouvida inteira, entra em `clues` (`clue_heard`).

signal clue_heard(clue: Clue)

const LISTEN_SEC := 40.0   # segundos ouvindo até a suspeita chegar a 1 (a conversa toda dura 45–90 s)
const CLICK := 0.08        # o estalo de cada vez que a chave sobe
const HUSH := 0.5          # daqui, com ele ouvindo, eles percebem algo e a conversa normal para (`_react`)
const HUSH_SEC := 3.0      # s calados antes da pergunta e, sabendo, antes da reclamação
const SHRUG := 0.2         # ninguém ouviu a resposta: desconversam e a suspeita fica isto abaixo de `HUSH`
const ASK_PAUSE := 2.0     # s de pausa antes da pergunta dos que não se calam (a de `GAP` incluída)
const SKEPTIC := 1.5       # desconfiados assim (quem ligou vezes o lugar) não se calam: vão direto à pergunta
const COOL_SEC := 45.0     # sem ninguém ouvindo, segundos para a suspeita baixar de 1 a 0
const HEARD_SHARE := 0.75  # quanto de uma fala escrita o operador precisa ouvir para contar como ouvida
const PACE := 1.6          # a conversa deles anda mais devagar que a fala com o operador: dá para ler ouvindo
const GAP := 1.0           # s entre uma fala e a resposta (também a da pergunta da suspeita)
const MURMUR_DB := -7.0    # o murmúrio, mais baixo que uma fala para o operador (eles não falam com ele)

var C: GameContent = GameData.CONTENT
var calls := {}   ## linha -> a PhoneCall conectada nela (a transferência completada)
var _ears := {}   ## linha -> o que o operador ouve dela (a transcrição da tela)
var _knows := {}  ## linhas em que os dois já sabem (ouviram a resposta): da próxima vez, reclamam
var _written := {}  ## linhas cuja conversa ainda tem falas escritas por dizer (`speaking`)
var clues: Array[Clue] = []   ## as palavras-chave ouvidas, desta noite e das anteriores (`Progress.clues`), na ordem

@onready var main: Main = get_parent()


func _ready() -> void:
	if main.progress != null:
		clues.assign(main.progress.clues.map(Clue.from_dict))


func _process(delta: float) -> void:
	if main.running:
		tick(delta)


## A transferência `c` completou: os dois começam a conversar (se ninguém ouvir, ninguém fica sabendo). As do
## treinamento não se escutam.
func connected(c: PhoneCall) -> void:
	if c.lesson:
		return
	if _ears.has(c.line):
		(_ears[c.line] as PhoneCall).ended = true
	var ear := PhoneCall.new()
	ear.line = c.line
	ear.active = true
	calls[c.line] = c
	_ears[c.line] = ear
	_knows.erase(c.line)
	_talk(c, ear)


## Tecla Escutar ou a alavanca: a chave de escuta da linha `n` sobe ou desce.
func toggle(n: int) -> void:
	main.exchange.set_key(n, not main.exchange.key(n))


## A conversa da linha `n` ainda tem falas escritas por dizer: ela não acaba antes (`Main._update_line_timers`).
func speaking(n: int) -> bool:
	return _written.has(n)


## O operador está ouvindo a linha `n` agora.
func listening(n: int) -> bool:
	return n == main.board.fone_line() and main.exchange.key(n) and calls.has(n)


## Anda `delta` segundos (os testes chamam à mão).
func tick(delta: float) -> void:
	for n in calls.keys():
		var ear: PhoneCall = _ears[n]
		if main.exchange.line(n) != Exchange.Line.CONN:   # acabou ou foi cortada
			ear.ended = true
			calls.erase(n)
			_ears.erase(n)
			_written.erase(n)
			_knows.erase(n)
			continue
		var on := listening(n)
		if on != ear.on_line:
			ear.on_line = on
			if on:
				_heard(n, calls[n], ear)
				_raise(n, CLICK)   # entrou na linha: a chave subindo ou o FONE encaixando com ela em cima estala
		if on:
			_raise(n, delta / LISTEN_SEC)
		else:
			var c: PhoneCall = calls[n]
			c.suspicion = maxf(0.0, c.suspicion - delta / COOL_SEC)


## O operador começou a ouvir a linha `n`: a tela mostra a conversa.
func _heard(n: int, c: PhoneCall, ear: PhoneCall) -> void:
	main.flags.apply("escutou_%d" % main.night_no)
	if ear.transcript.is_empty():
		ear.sys(T.text(T.Key.SYS_LISTENING) % [n, tr(c.caller), _other(c)])
	main.phone.show_call(ear)


## A desconfiança dos dois na conversa `c`: a de quem ligou (`TransferCall.wary`) vezes a de quem atendeu
## (`DirectoryEntry.wary`).
func _wary(c: PhoneCall) -> float:
	var data := c.data as TransferCall
	var place := GameData.entry(str(c.dest_num))
	return (data.wary if data != null else 1.0) * (place.wary if place != null else 1.0)


## Eles desconfiam e o operador está ouvindo: a conversa normal não anda (`_react`).
func _hush(c: PhoneCall) -> bool:
	return c.suspicion >= HUSH and listening(c.line) and calls.has(c.line)


## A suspeita da linha `n` sobe `by` (vezes a desconfiança deles, `_wary`).
func _raise(n: int, by: float) -> void:
	var c: PhoneCall = calls[n]
	c.suspicion = minf(1.0, c.suspicion + by * _wary(c))


## Desconfiados, com o operador ouvindo: calam-se (`HUSH_SEC`; os muito desconfiados não), um (`asker`) pergunta se tem
## alguém na linha e o outro (`other`) responde; já sabendo, calam-se e reclamam. Soltando a chave no meio, a conversa
## volta. Devolve quantas falas foram ditas (a vez da conversa anda), ou -1 se ela acabou.
func _react(c: PhoneCall, ear: PhoneCall, asker: String, asker_voice: String, other: String, other_voice: String) -> int:
	if _wary(c) < SKEPTIC or _knows.has(c.line):
		ear.sys(T.text(T.Key.SYS_LINE_SILENT))
		var left := HUSH_SEC
		while left > 0.0:
			if ear.ended:
				return -1
			if not _hush(c):   # soltou a chave no silêncio: a conversa segue
				return 0
			await get_tree().process_frame
			if not get_tree().paused:
				left -= get_process_delta_time()
	else:
		await _wait(ASK_PAUSE - GAP)
	if ear.ended:
		return -1
	if _knows.has(c.line):
		_caught(c.line, c, ear)
		return -1
	var ask := randi() % C.overheard_ask.size()
	if await _say(ear, C.overheard_ask[ask], asker, asker_voice, true) < 0.0:
		return -1
	if not _hush(c):   # ninguém ouviu o fim da pergunta: o outro desconversa
		c.suspicion = minf(c.suspicion, HUSH - SHRUG)
		return 2   # (a resposta que ninguém ouviu: as falas escritas seguem com quem as diz)
	_knows[c.line] = true
	if await _say(ear, C.overheard_sure[ask], other, other_voice, true) < 0.0:
		return -1
	return 2


## Eles têm certeza: quem estiver ouvindo ouve a reclamação, os dois desligam e amanhã a companhia fica sabendo.
func _caught(n: int, c: PhoneCall, ear: PhoneCall) -> void:
	main.supervisor.fault_later("eavesdrop", main.supervisor.who(c))
	main.flags.apply("denunciado_%d" % main.night_no)
	_knows.erase(n)
	calls.erase(n)   # a conversa deles acabou: a suspeita não anda mais
	_written.erase(n)
	ear.ended = true   # a fala de antes para; a reclamação vem a seguir
	var last := PhoneCall.new()
	last.line = n
	last.active = true
	last.on_line = ear.on_line
	last.transcript = ear.transcript
	if ear.on_line:
		main.phone.show_call(last)
	await _say(last, GameData.pick(C.overheard_caught), c.caller, c.voice, true)
	if main.exchange.line(n) == Exchange.Line.CONN:
		last.sys(T.text(T.Key.SYS_BOTH_HUNG_UP))
		main.talk_over(n)


## A conversa dos dois: o "alô" de quem atende e as falas escritas, que fecham com a despedida (`C.overheard_bye`) e
## eles desligam; sem elas, o cumprimento de quem ligou (se atendeu uma pessoa) e o murmúrio até o fim do `TALK_LEN`.
## Um fala, o outro responde. Cada fala escrita ouvida liga o marcador dela (`TransferCall.overheard_flags`); ouvidas
## todas, os da ligação (`overheard_sets`).
func _talk(c: PhoneCall, ear: PhoneCall) -> void:
	var who := [tr(c.caller), _other(c)]
	var place := GameData.entry(str(c.dest_num))
	var voices := [c.voice, GameData.voice_of(place) if place != null else "m"]
	var data: TransferCall = c.data if c.data is TransferCall else null
	var written: PackedStringArray = data.overheard if data != null else PackedStringArray()
	var hello := place.hello if place != null and place.hello != "" else GameData.pick(C.overheard_hello)
	var lines := PackedStringArray([hello]) + written
	if not written.is_empty():
		lines.append_array([GameData.pick(C.overheard_bye), GameData.pick(C.overheard_bye_back)])
	elif place == null or place.hello == "":
		lines.append(GameData.pick(C.overheard_greet))
	var vars := GameData.talk_vars()   # as lacunas, as mesmas na conversa toda
	var k := 0      # a próxima fala do "alô" ou escrita
	var turn := 1   # quem fala: quem atendeu começa
	var heard := 0  # falas escritas ouvidas
	if not written.is_empty():
		_written[c.line] = true
	while not ear.ended:
		if _hush(c):   # desconfiam e ele ouve: a conversa normal para
			var said := await _react(c, ear, who[turn % 2], voices[turn % 2], who[(turn + 1) % 2], voices[(turn + 1) % 2])
			if said < 0:
				return
			turn += said
			continue
		var text := GameData.fill(lines[k], vars) if k < lines.size() else tr((main.conversation.topics().pick_random() as ChatTopic).line)
		var got := await _say(ear, text, who[turn % 2], voices[turn % 2], k < lines.size())
		if got < 0.0:
			return
		turn += 1
		if k >= lines.size():
			continue
		var j := k - 1   # a fala escrita (antes dela, o "alô")
		k += 1
		if j >= 0 and j < written.size() and got >= HEARD_SHARE:
			heard += 1
			if j < data.overheard_flags.size() and data.overheard_flags[j] != "":
				main.flags.apply(data.overheard_flags[j])
			if heard == written.size():
				for f in data.overheard_sets:
					main.flags.apply(f)
		if k == lines.size():
			_written.erase(c.line)
			if not written.is_empty() and main.exchange.line(c.line) == Exchange.Line.CONN:
				main.talk_over(c.line)   # despediram-se
				return


## A palavra-chave `word` (`kind`) foi ouvida inteira, acabando na fala `li` da transcrição `ear`: o lápis risca e
## ela fica sublinhada.
func _clue(ear: PhoneCall, li: int, word: String, kind: String) -> void:
	var c: PhoneCall = calls.get(ear.line)
	if c == null or clues.any(func(k: Clue): return k.call == c and k.word == word):
		return
	var k := Clue.new()
	k.word = word
	k.kind = kind
	k.call = c
	k.night = main.night_no
	k.minutes = main.minutes
	k.caller = c.caller
	k.number = str(c.dest_num)
	for old in clues:   # a mesma palavra já anotada: fica com a marca que o operador deu a ela
		if old.kind == k.kind and old.word.to_lower() == k.word.to_lower():
			k.chosen = old.chosen
			k.struck = old.struck
	clues.append(k)
	if li >= 0:
		ear.underline(li, word.length())
	Sfx.play("pencil", -6.0)
	clue_heard.emit(k)


## Um dos dois diz `text` (`shown`: na transcrição; senão, só o som, o murmúrio), letra a letra como na
## `Conversation.say`. Anda com o operador ouvindo ou não (ele ouve e vê só o que pegou; entrando no meio, a fala
## começa com "…"). Devolve quanto dela ele ouviu (0 a 1), ou -1 se a linha cair.
func _say(ear: PhoneCall, text: String, who: String, voice: String, shown: bool) -> float:
	var parsed := Clue.parse(tr(text))   # sem as marcas das palavras-chave
	text = parsed[0]
	text = text.left(1).to_upper() + text.substr(1)   # a fala pode começar por uma palavra-chave
	var li := -1
	var heard := 0
	var missed := -1   # a última letra que o operador não ouviu
	var prev_vowel := false
	var pitch := Sfx.pitch_of(who)
	var owe := 0.0   # tempo de fala que ainda falta esperar (`_wait`)
	for i in text.length():
		if ear.ended:
			return -1.0
		if ear.on_line:
			heard += 1
			if shown:
				if li == -1:
					li = ear.add_line(who, "…" if i > 0 else "")
				ear.append_text(li, text[i])
			prev_vowel = Sfx.speak_char(voice, text, i, prev_vowel, false, -1.0, pitch, 0.0, 0.0 if shown else MURMUR_DB)
		else:
			missed = i
		for s in parsed[1]:
			if s[1] - 1 == i and missed < s[0]:
				_clue(ear, li, text.substr(s[0], s[1] - s[0]), s[2])
		owe = await _wait(owe + (0.09 if text[i] in [",", "."] else 0.028) * PACE * Settings.char_delay())
	await _wait(owe + GAP)
	return -1.0 if ear.ended else heard / float(maxi(1, text.length()))


## Espera `sec` s de jogo, parando na pausa, e devolve o que passou a mais (negativo), para descontar da próxima
## letra: num quadro mais longo que uma letra saem várias no mesmo quadro, e nenhuma cria um timer.
func _wait(sec: float) -> float:
	while sec > 0.0:
		await get_tree().process_frame
		if not get_tree().paused:
			sec -= get_process_delta_time()
	return sec


## Quem atendeu do outro lado da linha de `c`.
func _other(c: PhoneCall) -> String:
	return tr(c.destination) if str(c.dest_num) == c.target else GameData.entry(str(c.dest_num)).name
