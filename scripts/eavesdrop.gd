class_name Eavesdrop
extends Node
## A escuta (nó filho de Main). Com o FONE na entrada de uma linha conectada e a chave de escuta dela levantada
## (`Exchange.key`: tecla Escutar, Z, ou clique na alavanca da mesa), o operador ouve a conversa dos dois: as falas
## escritas (`TransferCall.overheard`; a conversa anda ouvindo ou não, e o que ele não ouviu, perdeu) ou o murmúrio das
## vozes, sem texto. A tela da conversa mostra o que ele ouve (`Talk.ear`: uma PhoneCall só para isso, fora do Registro).
## É proibido: ouvindo, a suspeita dos dois sobe (`PhoneCall.suspicion`, em `LISTEN_SEC` chega a 1; cada vez que ele
## entra na linha, pela chave subindo ou pelo FONE encaixando com ela em cima, o estalo soma `CLICK`) e, sem ninguém
## ouvindo, baixa devagar (`COOL_SEC`). Só se nota pela conversa: passando de `HUSH` com ele ouvindo, a conversa
## normal para e o resto anda no tempo (`_react`): terminada a fala, calam-se `HUSH_SEC` (a melhor hora de baixar a
## chave: sem ninguém ouvindo, a conversa segue; os muito desconfiados, `SKEPTIC`, não se calam e, depois de uma pausa,
## `ASK_PAUSE`, perguntam já), um pergunta ao outro se tem alguém na linha (`C.overheard_ask`) e, com ele ainda
## ouvindo, o outro responde e os dois ficam sabendo (`C.overheard_sure`, a resposta da mesma pergunta; `Talk.knows`; sem
## ninguém ouvindo no fim da pergunta, desconversam e a suspeita baixa para `SHRUG` abaixo de `HUSH`). Sabendo, a
## denúncia é certa (`_denounce`): a companhia cobra no relatório da noite seguinte (`Supervisor.fault_later`,
## advertência grave `eavesdrop`), solte ele a chave ou não; com ele ouvindo, mais `HUSH_SEC` calados, a reclamação e
## os dois desligam (`_caught`). Marcadores para o roteiro: `escutou_N` (ouviu
## alguma conversa na noite N), `denunciado_N` e os da ligação ouvida inteira (`TransferCall.overheard_sets`). No
## silêncio, só o chiado da linha aberta (`SILENT_HISS_DB`). O lugar que denunciou fica mais desconfiado nas noites
## seguintes (`grudges`, `GRUDGE`).
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
const SILENT_HISS_DB := -29.0   ## o chiado da linha no silêncio deles (o de sempre é -36: dá para notar de ouvido)
const GRUDGE := 0.3        # quanto a desconfiança de um lugar sobe a cada vez que ele denunciou a telefonista

var C: GameContent = GameData.CONTENT
var talks := {}   ## linha -> a conversa conectada nela (`Talk`)
var clues: Array[Clue] = []   ## as palavras-chave ouvidas, desta noite e das anteriores (`Progress.clues`), na ordem
var grudges := {}   ## número do lugar -> quantas vezes ele denunciou a telefonista, em todas as noites (`Progress.grudges`)
var silent := -1    ## a linha em que eles estão calados, desconfiados (o chiado sobe: `Main.refresh_hiss`)

@onready var main: Main = get_parent()


## Uma conversa conectada (a transferência completada) e o que a escuta sabe dela.
class Talk:
	var call: PhoneCall
	var ear := PhoneCall.new()   ## o que o operador ouve dela (a transcrição da tela, fora do Registro)
	var knows := false           ## os dois ouviram a resposta: a denúncia está feita e, no próximo silêncio, reclamam
	var written := false         ## ainda tem falas escritas por dizer (`speaking`)


func _ready() -> void:
	if main.progress != null:
		clues.assign(main.progress.clues.map(Clue.from_dict))
		grudges = main.progress.grudges.duplicate()


func _process(delta: float) -> void:
	if main.running:
		tick(delta)


## A transferência `c` completou: os dois começam a conversar (se ninguém ouvir, ninguém fica sabendo). As do
## treinamento não se escutam.
func connected(c: PhoneCall) -> void:
	if c.lesson:
		return
	if talks.has(c.line):
		(talks[c.line] as Talk).ear.ended = true
	var t := Talk.new()
	t.call = c
	t.ear.line = c.line
	t.ear.active = true
	talks[c.line] = t
	_talk(t)


## Tecla Escutar ou a alavanca: a chave de escuta da linha `n` sobe ou desce.
func toggle(n: int) -> void:
	main.exchange.set_key(n, not main.exchange.key(n))
	main.bureaucracy.listening(n, main.exchange.key(n))


## A conversa da linha `n` ainda tem falas escritas por dizer: ela não acaba antes (`Main._update_line_timers`).
func speaking(n: int) -> bool:
	return talks.has(n) and (talks[n] as Talk).written


## O operador está ouvindo a linha `n` agora.
func listening(n: int) -> bool:
	return n == main.board.fone_line() and main.exchange.key(n) and talks.has(n)


## A ligação conectada na linha `n` (nula se não há conversa que se possa escutar).
func call_of(n: int) -> PhoneCall:
	return (talks[n] as Talk).call if talks.has(n) else null


## Os dois na linha `n` já sabem que alguém escuta (reclamam no próximo silêncio).
func knows(n: int) -> bool:
	return talks.has(n) and (talks[n] as Talk).knows


## Debug: todas as conversas chegam ao ponto em que eles percebem (o silêncio vem no fim da fala de quem estiver
## sendo ouvido).
func force_hush() -> void:
	for t: Talk in talks.values():
		t.call.suspicion = maxf(t.call.suspicion, HUSH)


## Debug: ninguém desconfia de nada, e os lugares esquecem as denúncias.
func calm() -> void:
	for t: Talk in talks.values():
		t.call.suspicion = 0.0
		t.knows = false
	grudges.clear()


## Anda `delta` segundos (os testes chamam à mão).
func tick(delta: float) -> void:
	for n in talks.keys():
		var t: Talk = talks[n]
		if main.exchange.line(n) != Exchange.Line.CONN:   # acabou ou foi cortada
			t.ear.ended = true
			talks.erase(n)
			continue
		var on := listening(n)
		if on != t.ear.on_line:
			t.ear.on_line = on
			if on:
				_heard(t)
				_raise(t.call, CLICK)   # entrou na linha: a chave subindo ou o FONE encaixando com ela em cima estala
		if on:
			_raise(t.call, delta / LISTEN_SEC)
		else:
			t.call.suspicion = maxf(0.0, t.call.suspicion - delta / COOL_SEC)


## O operador começou a ouvir a conversa `t`: a tela mostra o que se ouve.
func _heard(t: Talk) -> void:
	main.flags.apply("escutou_%d" % main.night_no)
	if t.ear.transcript.is_empty():
		t.ear.sys(T.text(T.Key.SYS_LISTENING) % [t.call.line, tr(t.call.caller), _other(t.call)])
	main.phone.show_call(t.ear)


## A desconfiança dos dois na conversa `c`: a de quem ligou (`TransferCall.wary`) vezes a de quem atendeu
## (`DirectoryEntry.wary`, mais `GRUDGE` por denúncia dele).
func _wary(c: PhoneCall) -> float:
	var data := c.data as TransferCall
	var place := GameData.entry(str(c.dest_num))
	var grudge: float = GRUDGE * grudges.get(str(c.dest_num), 0)
	return (data.wary if data != null else 1.0) * ((place.wary if place != null else 1.0) + grudge)


## Eles desconfiam e o operador está ouvindo: a conversa normal não anda (`_react`).
func _hush(t: Talk) -> bool:
	return t.call.suspicion >= HUSH and talks.get(t.call.line) == t and listening(t.call.line)


## A suspeita da conversa `c` sobe `by` (vezes a desconfiança deles, `_wary`).
func _raise(c: PhoneCall, by: float) -> void:
	c.suspicion = minf(1.0, c.suspicion + by * _wary(c))


## Desconfiados, com o operador ouvindo: calam-se (`HUSH_SEC`; os muito desconfiados não), um (`asker`) pergunta se tem
## alguém na linha e o outro (`other`) responde; já sabendo, calam-se e reclamam. Soltando a chave no meio, a conversa
## volta. Devolve quantas falas foram ditas (a vez da conversa anda), ou -1 se ela acabou.
func _react(t: Talk, asker: String, asker_voice: String, other: String, other_voice: String) -> int:
	var c := t.call
	var ear := t.ear
	if _wary(c) < SKEPTIC or t.knows:
		var kept := await _silence(t)
		if kept < 0.0:
			return -1
		if kept > 0.0:   # soltou a chave no silêncio: a conversa segue
			return 0
	else:
		await _wait(ASK_PAUSE - GAP)
	if ear.ended:
		return -1
	if t.knows:
		_caught(t)
		return -1
	var ask := randi() % C.overheard_ask.size()
	if await _say(ear, C.overheard_ask[ask], asker, asker_voice, true) < 0.0:
		return -1
	if not _hush(t):   # ninguém ouviu o fim da pergunta: o outro desconversa
		c.suspicion = minf(c.suspicion, HUSH - SHRUG)
		return 2   # (a resposta que ninguém ouviu: as falas escritas seguem com quem as diz)
	_denounce(t)
	if await _say(ear, C.overheard_sure[ask], other, other_voice, true) < 0.0:
		return -1
	return 2


## Os dois calados `HUSH_SEC`: na tela, um ponto a cada segundo (dá para ver o tempo passando) e o chiado da linha
## sobe. Devolve o que faltava quando ele soltou a chave (0 se ficou ouvindo até o fim; -1 se a conversa acabou).
func _silence(t: Talk) -> float:
	var li := t.ear.add_line("", T.text(T.Key.SYS_LINE_SILENT) + " ·", "sys")
	silent = t.call.line
	main.refresh_hiss()
	var left := HUSH_SEC
	var dots := 1
	while left > 0.0 and not t.ear.ended and _hush(t):
		await get_tree().process_frame
		if not get_tree().paused:
			left -= get_process_delta_time()
		if dots < ceili(HUSH_SEC) and HUSH_SEC - left >= dots:
			dots += 1
			t.ear.set_line_text(li, T.text(T.Key.SYS_LINE_SILENT) + " ·".repeat(dots))
	if silent == t.call.line:
		silent = -1
		main.refresh_hiss()
	return -1.0 if t.ear.ended else maxf(left, 0.0)


## Eles ouviram a resposta e têm certeza: denunciam a telefonista (amanhã a companhia fica sabendo), ouça ele a
## reclamação ou não, e o lugar fica mais desconfiado (`grudges`). Escuta pedida por uma burocracia (a gravação da
## B4) é cobrada por ela (`Bureaucracy.caught_listening`).
func _denounce(t: Talk) -> void:
	t.knows = true
	if not main.bureaucracy.caught_listening(t.call):
		main.supervisor.fault_later("eavesdrop", main.supervisor.who(t.call))
	main.flags.apply("denunciado_%d" % main.night_no)
	var num := str(t.call.dest_num)
	grudges[num] = grudges.get(num, 0) + 1


## Sabendo, calados com ele ouvindo: ele ouve a reclamação e os dois desligam (a denúncia já está feita).
func _caught(t: Talk) -> void:
	var n := t.call.line
	var c := t.call
	var ear := t.ear
	talks.erase(n)   # a conversa deles acabou: a suspeita não anda mais
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
## eles desligam; sem elas, o cumprimento de quem ligou (se atendeu uma pessoa) e o murmúrio até o fim do `Pace.talk_len`.
## Um fala, o outro responde. Cada fala escrita ouvida liga o marcador dela (`TransferCall.overheard_flags`); ouvidas
## todas, os da ligação (`overheard_sets`).
func _talk(t: Talk) -> void:
	var c := t.call
	var ear := t.ear
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
	t.written = not written.is_empty()
	while not ear.ended:
		if _hush(t):   # desconfiam e ele ouve: a conversa normal para
			var said := await _react(t, who[turn % 2], voices[turn % 2], who[(turn + 1) % 2], voices[(turn + 1) % 2])
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
			t.written = false
			if not written.is_empty() and main.exchange.line(c.line) == Exchange.Line.CONN:
				main.talk_over(c.line)   # despediram-se
				return


## A palavra-chave `word` (`kind`) foi ouvida inteira, acabando na fala `li` da transcrição `ear`: o lápis risca e
## ela fica sublinhada.
func _clue(ear: PhoneCall, li: int, word: String, kind: String) -> void:
	var c := call_of(ear.line)
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
		owe = await _wait(owe + (0.09 if text[i] in [",", "."] else 0.028) * PACE)
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
