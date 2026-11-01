extends Node
## O discador da mesa (`Dialer`, na prateleira, e o de perto, o pop-up em cima dele, `DialView`): o operador digita o número
## e liga para ele pelo próprio fone, ligado direto na mesa (sem o FONE). Aqui fica o número digitado, o que o visor
## mostra (`status`) e a ligação feita (`call`, `PhoneCall.Kind.OUTGOING`); a conversa é do `Conversation._outgoing`.
## Enquanto ela dura, é a ligação em foco (`Main._focus`): quem estava com o FONE fica em espera (a linha em HOLD, e
## quem espera demais desiste, `Supervisor.check_hold`), e volta quando ela acaba. A linha do lugar
## chamado fica ocupada (`Exchange`): tocando e depois conectada, como numa transferência (quem pedir o número nesse
## meio-tempo encontra ocupado; o telefone do outro lado da rua toca na vista). Não entra no caderno nem dá advertência;
## a conversa vai para o registro das conversas.

const DialCall := preload("res://scripts/data/dial_call.gd")
const DIGITS := 3   ## os números da cidade (101–399) e das centrais (001–003)

## O que o visor mostra (`TEXT`).
enum Status { IDLE, CALLING, TALK, ENDED, BUSY, NO_ANSWER, NO_NUMBER, NOT_SERVED, TRUNK, DISPATCH }
const TEXT := {Status.CALLING: T.Key.DIAL_CALLING, Status.TALK: T.Key.DIAL_ON_LINE, Status.ENDED: T.Key.DIAL_ENDED,
	Status.BUSY: T.Key.DIAL_BUSY, Status.NO_ANSWER: T.Key.DIAL_NO_ANSWER, Status.NO_NUMBER: T.Key.DIAL_NO_NUMBER,
	Status.NOT_SERVED: T.Key.DIAL_NOT_SERVED, Status.TRUNK: T.Key.DIAL_TRUNK, Status.DISPATCH: T.Key.DIAL_DISPATCH}

var digits := ""   ## o número digitado (ou o da ligação em andamento)
var status := Status.IDLE
var since := 0.0   ## `Main.talk_clock` de quando o `status` mudou (o tempo de conversa no visor)
var call: PhoneCall   ## a ligação feita em andamento (nula = nenhuma)
var last := ""   ## o último número discado: Discar com o visor vazio liga de novo para ele
var key := ""    ## a última tecla apertada ("0"–"9", "DIAL", "END") e quando (`Main.talk_clock`): no discador da
var key_at := -INF   ## prateleira, ela afunda um instante (`Dialer`), mesmo apertada no de perto
var _held: PhoneCall   ## quem estava com o FONE quando o operador ligou: em espera até a ligação feita acabar

@onready var main: Main = get_parent()


## Uma tecla de algarismo: entra no número (o quarto não entra; com a ligação em andamento, nada).
func press(d: String) -> void:
	_key(d)
	if call != null or digits.length() >= DIGITS:
		Sfx.play("dial_full")
		return
	if status != Status.IDLE:   # (o aviso da tentativa anterior some com o número novo)
		digits = ""
		_put(Status.IDLE)
	digits += d
	Sfx.play("dial_key", 0.0, 0.92 + int(d) * 0.02)


## Discar: liga para o número digitado; com o visor vazio, para o último (com ele incompleto, ou já ligando, nada).
func dial() -> void:
	_key("DIAL")
	if call == null and digits == "" and last != "":
		digits = last
	if call != null or digits.length() < DIGITS:
		Sfx.play("dial_full")
		return
	last = digits
	Sfx.play("dial_pulse")
	var e := GameData.entry(digits)
	var story := _story(digits)
	var central := e != null and e in GameData.CONTENT.operators   # (a outra central: fora dos setores)
	if central and e.gone_from > 0 and main.night_no >= e.gone_from:
		_fail(Status.NO_NUMBER)
	elif digits == GameData.OWN:
		_fail(Status.BUSY)
	elif GameData.is_trunk(digits):
		_fail(Status.TRUNK)
	elif e != null and e.dispatch_only:
		_fail(Status.DISPATCH)
	elif not central and not int(digits.left(1)) in GameData.sectors:
		_fail(Status.NOT_SERVED)
	elif e == null and story == null:
		_fail(Status.NO_NUMBER)
	elif main.exchange.has_dest(int(digits)) and main.exchange.dest(int(digits)) != Exchange.Dest.FREE:
		_fail(Status.BUSY)
	else:
		_start(e, story)


## Encerrar: desliga a ligação feita ou apaga o número digitado.
func end() -> void:
	_key("END")
	if call != null:
		hang_up()
	elif digits != "" or status != Status.IDLE:
		digits = ""
		_put(Status.IDLE)
		Sfx.play("dial_key", 0.0, 0.8)


## O operador desliga a ligação feita (a tecla Encerrar, Desligar no console ou o X).
func hang_up() -> void:
	if call == null:
		return
	call.add_line("", T.text(T.Key.OP_HANGS_UP), "op")
	finish(PhoneCall.End.OPERATOR)


## A ligação feita termina: a linha do lugar fica livre, a conversa vai para o registro e o foco volta ao FONE.
func finish(reason: PhoneCall.End) -> void:
	var c := call
	if c == null or c.ended:
		return
	call = null
	c.ended = true
	c.active = false
	c.on_line = false
	c.set_talking(false)
	c.set_options([])
	var d := int(c.target)
	if main.exchange.has_dest(d) and main.exchange.dest(d) != Exchange.Dest.FREE:
		main.exchange.set_dest(d, Exchange.Dest.FREE)
	Sfx.play("sw")
	c.sys(T.text(T.Key.SYS_YOU_ENDED if reason == PhoneCall.End.OPERATOR else T.Key.SYS_OTHER_SIDE_ENDED))
	main.tools.call_log.filed(c)
	if _held != null and not _held.ended and _held.line == main.board.fone_line() \
			and main.exchange.line(_held.line) == Exchange.Line.HOLD:   # quem estava com o FONE volta a falar com o operador
		main.exchange.set_line(_held.line, Exchange.Line.TALK)
	_held = null
	_put(Status.ENDED)
	main._refresh_panel()


## O lugar atendeu: a linha conecta e o visor conta o tempo de conversa. Atendida, a ligação liga o marcador
## `ligou_<número>_<noite>` (uma `StoryCall` pode ligar de volta por ele).
func answered(c: PhoneCall) -> void:
	if c != call:
		return
	c.answered = true
	if main.exchange.has_dest(int(c.target)):
		main.exchange.set_dest(int(c.target), Exchange.Dest.CONN)
	Sfx.play("sw")
	_put(Status.TALK)
	main.flags.apply("ligou_%s_%d" % [c.target, main.night_no])


## Ninguém atendeu: a ligação cai sozinha e o visor avisa.
func unanswered(c: PhoneCall) -> void:
	if c != call:
		return
	c.sys(T.text(T.Key.SYS_NOBODY_ANSWERS) % int(c.target))
	finish(PhoneCall.End.MISSED)
	_put(Status.NO_ANSWER)


## A ligação do roteiro (`DialCall`) que atende neste número agora: as da noite antes das de qualquer noite.
func _story(number: String) -> DialCall:
	for d: DialCall in main.night.dial + main.C.dial:
		if d.number == number and main.minutes >= d.from and main.minutes <= d.to and main.flags.allows(d.requires) \
				and not (d.once and main.flags.allows([d.done_flag()])):
			return d
	return null


func _start(e: DirectoryEntry, story: DialCall) -> void:
	var c := PhoneCall.new()
	c.kind = PhoneCall.Kind.OUTGOING
	c.data = story if story != null else e
	c.caller = story.caller if story != null and story.caller != "" else (e.name if e != null else digits)
	c.voice = story.voice if story != null and story.voice != "" else (GameData.voice_of(e) if e != null else "m")
	c.target = digits
	c.dest_num = int(digits)   # (as palavras-chave das respostas vão para as anotações com este número)
	c.time = Main.fmt(main.minutes)
	c.active = true
	c.on_line = true
	call = c
	var h := main._call_on_line(main.board.fone_line())   # quem está com o FONE fica em espera, como com o FONE fora
	if h != null and h.active and not h.closing and main.exchange.line(h.line) == Exchange.Line.TALK:
		main.exchange.set_line(h.line, Exchange.Line.HOLD)
		h.hold_since = main.minutes
		h.sys(T.text(T.Key.SYS_ON_HOLD))
		_held = h
	if main.exchange.has_dest(int(digits)):
		main.exchange.set_dest(int(digits), Exchange.Dest.RING)
	main.tools.call_log.track(c)
	_put(Status.CALLING)
	c.sys(T.text(T.Key.SYS_DIALING) % digits)
	main._refresh_panel()
	main.conversation.run(c)


## A linha `n` está sendo chamada ou em conversa pelo discador (um cabo solto na tomada dela não a solta).
func seized(n: int) -> bool:
	return call != null and int(call.target) == n


func _key(k: String) -> void:
	key = k
	key_at = main.talk_clock


func _fail(s: Status) -> void:
	Sfx.play("busy" if s in [Status.BUSY, Status.NO_NUMBER] else "dial_full")
	_put(s)


func _put(s: Status) -> void:
	status = s
	since = main.talk_clock
