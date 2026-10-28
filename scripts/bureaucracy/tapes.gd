extends RefCounted
## O inventário de fitas (`Bureaucracy.tapes`): as virgens da noite, a que está no gravador e as que já saíram dele.
## Com a tecla REC presa (`rec`), a fita no gravador grava a conversa que o operador escuta (a primeira em que ele entra
## assim) e guarda as palavras-chave ouvidas dela (`Clue`, só as ouvidas: a escuta e a desconfiança de sempre valem).
## Cada virgem tem o lugar dela no compartimento (`slots`); cada fita tirada dele é uma `Tape`. Tirada do gravador,
## fica na mesa (`Tape.Fate.ON_DESK`) até o fim do turno, quando vai para as autoridades (`hand_over`) e vale
## pontos de eficiência pelo valor (`value`), ou até o operador descartá-la (`discard`), e se perde. Qualquer regra pode usar; a B4
## configura (`rule_id`, `per_word`) e grava. As equipamentos da mesa (`scenes/ui/equipment/`) mexem por aqui.

const Tape := preload("res://scripts/bureaucracy/tape.gd")

var desk: Node   ## o `Bureaucracy` (o registro de decisões e as advertências)
var rule_id := ""   ## a regra em nome de quem o registro anota
var per_word := 5   ## pontos por palavra-chave numa conversa marcada pelas autoridades
var max_points := 20   ## o máximo de uma fita
var slots: Array[bool] = []   ## os lugares do compartimento: true com uma virgem (o compartimento desenha estes)
var blank: int:   ## as virgens no compartimento
	get:
		return slots.count(true)
var mark_key := ""   ## a marca (`PhoneCall.meta`) das conversas que as autoridades pediram gravadas
var rec := false   ## a tecla REC presa (volta sozinha quando a fita sai)
var inside: Tape   ## a fita no gravador (null: vazio)
var done: Array[Tape] = []   ## as que saíram nesta noite, com o destino delas


func _init(d: Node) -> void:
	desk = d


## Começo da noite: `n` virgens; a que ficou no gravador e as que saíram não voltam.
func reset(n: int) -> void:
	slots.clear()
	for i in n:
		slots.append(true)
	rec = false
	inside = null
	done.clear()


## Mais uma virgem, no primeiro lugar vazio (o debug).
func add_blank() -> void:
	var i := slots.find(false)
	if i >= 0:
		slots[i] = true
	else:
		slots.append(true)


## A virgem do lugar `i` (sem ele, a da direita) no gravador vazio. Falso se não há fita ou o gravador está ocupado.
func insert(i := -1) -> bool:
	if blank <= 0 or inside != null:
		return false
	if i < 0 or i >= slots.size() or not slots[i]:
		i = slots.rfind(true)
	slots[i] = false
	inside = Tape.new()
	inside.slot = i
	return true


## O gravador está gravando agora: tem fita, a REC presa e o operador escuta a conversa dela (ou, sem conversa ainda,
## qualquer uma).
func recording() -> bool:
	if inside == null or not rec:
		return false
	var ear = desk.main.eavesdrop
	if inside.call == null:
		return ear.listening(desk.main.board.fone_line())
	return ear.listening(inside.call.line) and ear.call_of(inside.call.line) == inside.call


## A tecla REC: solta, prende; presa, solta. Sem fita, não prende (falso). Presa escutando uma conversa, a fita
## passa a gravá-la.
func press_rec() -> bool:
	if inside == null:
		return false
	rec = not rec
	if recording():
		var c: PhoneCall = desk.main.eavesdrop.call_of(desk.main.board.fone_line())
		if c != null:
			bind(c)
	return true


## A fita grava a conversa `c` (se ainda não gravou outra), da hora de agora.
func bind(c: PhoneCall) -> void:
	if inside == null or inside.call != null:
		return
	inside.call = c
	inside.who = desk.main.supervisor.who(c)
	inside.hour = Main.fmt(desk.main.minutes)
	inside.marked = mark_key != "" and c.meta.has(mark_key)


## O valor de informação da fita: as palavras-chave de uma conversa marcada (as outras não interessam).
func value(t: Tape) -> int:
	return mini(t.words.size() * per_word, max_points) if t.marked else 0


## A fita no gravador, ainda virgem (sem conversa), volta para o compartimento, no lugar dela (ou no primeiro vazio);
## a REC solta. Devolve o lugar, ou -1 se não há fita, ela já gravou ou não há lugar.
func put_back() -> int:
	if inside == null or inside.call != null:
		return -1
	var i := inside.slot if inside.slot >= 0 and inside.slot < slots.size() and not slots[inside.slot] else slots.find(false)
	if i < 0:
		return -1
	slots[i] = true
	inside = null
	rec = false
	return i


## O operador tira a fita do gravador: vai para a mesa (`ON_DESK`) e não volta para ele.
func eject() -> void:
	if inside != null:
		_out(Tape.Fate.ON_DESK)


## As fitas na mesa, da primeira à última.
func on_desk() -> Array:
	return done.filter(func(t: Tape): return t.fate == Tape.Fate.ON_DESK)


## O operador descarta a fita `t`, da mesa: se perde.
func discard(t: Tape) -> void:
	if t.fate != Tape.Fate.ON_DESK:
		return
	t.fate = Tape.Fate.DISCARDED
	desk.log_decision(rule_id, t.call, "descartou a fita (%s)" % t.words_text(), "perdida")


## Fim do turno: as fitas da mesa vão para as autoridades e valem pelo que gravaram. A gravação de uma conversa que
## ninguém pediu vai para o registro como tal (o roteiro pode cobrar).
func hand_over() -> void:
	for t: Tape in on_desk():
		t.fate = Tape.Fate.DELIVERED
		t.value = value(t)
		if t.value > 0:
			desk.main.supervisor.credit("tape", t.value)
		var result := "gravação não pedida" if t.call != null and not t.marked else "%d pontos" % t.value
		desk.log_decision(rule_id, t.call, "entregou a fita (%s)" % t.words_text(), result)


## Fim da noite com fita no gravador: não foi entregue, perdida como a descartada.
func left_behind() -> void:
	if inside == null:
		return
	var t := _out(Tape.Fate.LEFT)
	desk.log_decision(rule_id, t.call, "deixou a fita no gravador (%s)" % t.words_text(), "não entregue")


## A gravada `call` (uma `PhoneCall`) foi entregue nesta noite.
func delivered(call: PhoneCall) -> bool:
	return done.any(func(t: Tape): return t.call == call and t.fate == Tape.Fate.DELIVERED)


## Tira a fita do gravador para as que saíram, com o destino `fate`, e a devolve; a tecla REC volta.
func _out(fate: Tape.Fate) -> Tape:
	var t := inside
	inside = null
	rec = false
	t.value = 0
	t.fate = fate
	done.append(t)
	return t
