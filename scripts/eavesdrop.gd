class_name Eavesdrop
extends Node
## A escuta (nó filho de Main). Com o FONE na entrada de uma linha conectada e a chave de escuta dela levantada
## (`Exchange.key`: tecla Escutar, Z, ou clique na alavanca da mesa), o operador ouve a conversa dos dois: as falas
## escritas (`TransferCall.overheard`; a conversa anda ouvindo ou não, e o que ele não ouviu, perdeu) ou o murmúrio das
## vozes, sem texto. A tela da conversa mostra o que ele ouve (`_ears`: uma PhoneCall só para isso, fora do Registro).
## É proibido: ouvindo, a suspeita dos dois sobe (`PhoneCall.suspicion`, em `LISTEN_SEC` chega a 1; cada vez que ele
## entra na linha, pela chave subindo ou pelo FONE encaixando com ela em cima, o estalo soma `CLICK`) e, sem ninguém
## ouvindo, baixa devagar (`COOL_SEC`). Só se nota pela conversa: eles se calam um instante (`HUSH`), um pergunta se tem
## alguém na linha (`ASK`) e, em 1, desligam para denunciar a telefonista: a companhia cobra no relatório da noite
## seguinte (`Supervisor.fault_later`, advertência grave `eavesdrop`). Marcadores para o roteiro: `escutou_N` (ouviu
## alguma conversa na noite N), `denunciado_N` e os da ligação ouvida inteira (`TransferCall.overheard_sets`).

const LISTEN_SEC := 25.0   # segundos ouvindo até a suspeita chegar a 1 (a conversa toda dura 45–90 s)
const CLICK := 0.08        # o estalo de cada vez que a chave sobe
const HUSH := 0.5          # daqui, eles se calam um instante...
const HUSH_SEC := 3.0
const ASK := 0.8           # ...e daqui, um pergunta se tem alguém na linha
const COOL_SEC := 45.0     # sem ninguém ouvindo, segundos para a suspeita baixar de 1 a 0
const HEARD_SHARE := 0.75  # quanto de uma fala escrita o operador precisa ouvir para contar como ouvida
const MURMUR_DB := -7.0    # o murmúrio, mais baixo que uma fala para o operador (eles não falam com ele)

var C: GameContent = GameData.CONTENT
var calls := {}   ## linha -> a PhoneCall conectada nela (a transferência completada)
var _ears := {}   ## linha -> o que o operador ouve dela (a transcrição da tela)
var _cue := {}    ## linha -> fala que um deles diz na próxima vez (a pergunta da suspeita)
var _quiet := {}  ## linha -> s de silêncio que faltam (`HUSH`)

@onready var main: Main = get_parent()


func _process(delta: float) -> void:
	if main.running:
		tick(delta)


## A transferência `c` completou: os dois começam a conversar (se ninguém ouvir, ninguém fica sabendo).
func connected(c: PhoneCall) -> void:
	if _ears.has(c.line):
		(_ears[c.line] as PhoneCall).ended = true
	var ear := PhoneCall.new()
	ear.line = c.line
	ear.active = true
	calls[c.line] = c
	_ears[c.line] = ear
	_cue.erase(c.line)
	_quiet.erase(c.line)
	_talk(c, ear)


## Tecla Escutar ou a alavanca: a chave de escuta da linha `n` sobe ou desce.
func toggle(n: int) -> void:
	main.exchange.set_key(n, not main.exchange.key(n))


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
			continue
		if _quiet.has(n):
			_quiet[n] -= delta
			if _quiet[n] <= 0.0:
				_quiet.erase(n)
		var on := listening(n)
		if on != ear.on_line:
			ear.on_line = on
			if on:
				_heard(n, calls[n], ear)
				_raise(n, CLICK)   # entrou na linha: a chave subindo ou o FONE encaixando com ela em cima estala
		if not calls.has(n):   # o estalo foi demais: denunciaram
			continue
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


## A suspeita da linha `n` sobe `by`; passando de um limite, eles reagem.
func _raise(n: int, by: float) -> void:
	var c: PhoneCall = calls[n]
	var was := c.suspicion
	if was >= 1.0:
		return
	c.suspicion = minf(1.0, was + by)
	if was < HUSH and c.suspicion >= HUSH:
		_quiet[n] = HUSH_SEC
		(_ears[n] as PhoneCall).sys(T.text(T.Key.SYS_LINE_SILENT))
	if was < ASK and c.suspicion >= ASK:
		_cue[n] = GameData.pick(C.overheard_ask)
	if c.suspicion >= 1.0:
		_caught(n, c, _ears[n])


## Eles têm certeza: quem estiver ouvindo ouve a reclamação, os dois desligam e amanhã a companhia fica sabendo.
func _caught(n: int, c: PhoneCall, ear: PhoneCall) -> void:
	main.supervisor.fault_later("eavesdrop", main.supervisor.who(c))
	main.flags.apply("denunciado_%d" % main.night_no)
	_cue.erase(n)
	_quiet.erase(n)
	calls.erase(n)   # a conversa deles acabou: a suspeita não anda mais
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


## A conversa dos dois: as falas escritas, depois o murmúrio, até a linha cair. Um fala, o outro responde. Ouvidas
## todas as escritas, liga os marcadores da ligação (`TransferCall.overheard_sets`).
func _talk(c: PhoneCall, ear: PhoneCall) -> void:
	var who := [tr(c.caller), _other(c)]
	var voices := [c.voice, ["m", "f", "w"][absi(hash(who[1])) % 3]]
	var data: TransferCall = c.data if c.data is TransferCall else null
	var lines: PackedStringArray = data.overheard if data != null else PackedStringArray()
	var k := 0      # a próxima fala escrita
	var turn := 0   # quem fala
	var heard := 0  # falas escritas ouvidas
	while not ear.ended:
		var cue: String = _cue.get(c.line, "")
		_cue.erase(c.line)
		var text := cue if cue != "" else (lines[k] if k < lines.size() else tr((main.conversation.topics().pick_random() as ChatTopic).line))
		var got := await _say(ear, text, who[turn % 2], voices[turn % 2], cue != "" or k < lines.size())
		if got < 0.0:
			return
		turn += 1
		if cue == "" and k < lines.size():
			heard += 1 if got >= HEARD_SHARE else 0
			k += 1
			if k == lines.size() and heard == k:
				for f in data.overheard_sets:
					main.flags.apply(f)


## Um dos dois diz `text` (`shown`: na transcrição; senão, só o som, o murmúrio), letra a letra como na
## `Conversation.say`. Anda com o operador ouvindo ou não (ele ouve e vê só o que pegou; entrando no meio, a fala
## começa com "…") e para no silêncio da suspeita. Devolve quanto dela ele ouviu (0 a 1), ou -1 se a linha cair.
func _say(ear: PhoneCall, text: String, who: String, voice: String, shown: bool) -> float:
	text = tr(text)
	var li := -1
	var heard := 0
	var prev_vowel := false
	var pitch := Sfx.pitch_of(who)
	for i in text.length():
		while _quiet.has(ear.line):
			if ear.ended:
				return -1.0
			await get_tree().process_frame
		if ear.ended:
			return -1.0
		if ear.on_line:
			heard += 1
			if shown:
				if li == -1:
					li = ear.add_line(who, "…" if i > 0 else "")
				ear.append_text(li, text[i])
			prev_vowel = Sfx.speak_char(voice, text, i, prev_vowel, false, -1.0, pitch, 0.0, 0.0 if shown else MURMUR_DB)
		await get_tree().create_timer((0.09 if text[i] in [",", "."] else 0.028) * Settings.char_delay(), false).timeout
	await get_tree().create_timer(0.5, false).timeout
	return -1.0 if ear.ended else heard / float(maxi(1, text.length()))


## Quem atendeu do outro lado da linha de `c`.
func _other(c: PhoneCall) -> String:
	return tr(c.destination) if str(c.dest_num) == c.target else GameData.entry(str(c.dest_num)).name
