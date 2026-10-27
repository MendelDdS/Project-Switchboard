extends RefCounted
## O inventário de fitas (`Bureaucracy.tapes`): as virgens da noite, a que está no gravador e as que já saíram dele.
## Com a tecla REC presa (`rec`), a fita no gravador grava a conversa que o operador escuta (a primeira em que ele entra
## assim) e guarda as palavras-chave ouvidas dela (`Clue`, só as ouvidas: a escuta e a desconfiança de sempre valem).
## Tirada do gravador, fica na mesa (`ON_DESK`) até o fim do turno, quando vai para as autoridades (`hand_over`) e vale
## pontos de eficiência pelo valor (`value`), ou até o operador descartá-la (`discard`), e se perde. Qualquer regra pode usar; a B4
## configura (`rule_id`, `per_word`) e grava. As equipamentos da mesa (`scenes/ui/equipment/`) mexem por aqui.

var desk: Node   ## o `Bureaucracy` (o registro de decisões e as advertências)
var rule_id := ""   ## a regra em nome de quem o registro anota
var per_word := 5   ## pontos por palavra-chave numa conversa marcada pelas autoridades
var max_points := 20   ## o máximo de uma fita
var blank := 0   ## fitas virgens no compartimento
var mark_key := ""   ## a marca (`PhoneCall.meta`) das conversas que as autoridades pediram gravadas
var rec := false   ## a tecla REC presa (volta sozinha quando a fita sai)
var inside := {}   ## a fita no gravador: {} vazio; {"call": PhoneCall ou null, "who", "hour", "words": [], "marked": bool}
var done: Array[Dictionary] = []   ## as que saíram nesta noite: {"call", "marked", "who", "hour", "words", "value", "fate"} (`ON_DESK`...)

const ON_DESK := "na mesa"
const DELIVERED := "entregue"
const DISCARDED := "descartada"
const LEFT := "esquecida no gravador"


func _init(d: Node) -> void:
	desk = d


## Começo da noite: `n` virgens; a que ficou no gravador e as que saíram não voltam.
func reset(n: int) -> void:
	blank = n
	rec = false
	inside = {}
	done.clear()


## Uma virgem do compartimento no gravador vazio. Falso se não há fita ou o gravador está ocupado.
func insert() -> bool:
	if blank <= 0 or not inside.is_empty():
		return false
	blank -= 1
	inside = {"call": null, "who": "", "hour": "", "words": [], "marked": false}
	return true


## O gravador está gravando agora: tem fita, a REC presa e o operador escuta a conversa dela (ou, sem conversa ainda,
## qualquer uma).
func recording() -> bool:
	if inside.is_empty() or not rec:
		return false
	var c: PhoneCall = inside["call"]
	var ear = desk.main.eavesdrop
	if c == null:
		return ear.listening(desk.main.board.fone_line())
	return ear.listening(c.line) and ear.call_of(c.line) == c


## A tecla REC: solta, prende; presa, solta. Sem fita, não prende (falso). Presa escutando uma conversa, a fita
## passa a gravá-la.
func press_rec() -> bool:
	if inside.is_empty():
		return false
	rec = not rec
	if recording():
		var c: PhoneCall = desk.main.eavesdrop.call_of(desk.main.board.fone_line())
		if c != null:
			bind(c)
	return true


## A fita grava a conversa `c` (se ainda não gravou outra), da hora de agora.
func bind(c: PhoneCall) -> void:
	if inside.is_empty() or inside["call"] != null:
		return
	inside["call"] = c
	inside["who"] = desk.main.supervisor.who(c)
	inside["hour"] = Main.fmt(desk.main.minutes)
	inside["marked"] = mark_key != "" and c.meta.has(mark_key)


## O valor de informação da fita: as palavras-chave de uma conversa marcada (as outras não interessam).
func value(t: Dictionary) -> int:
	return mini(t["words"].size() * per_word, max_points) if t.get("marked", false) else 0


## A fita no gravador, ainda virgem (sem conversa), volta para o compartimento; a REC solta. Falso se não há fita ou
## ela já gravou.
func put_back() -> bool:
	if inside.is_empty() or inside["call"] != null:
		return false
	inside = {}
	rec = false
	blank += 1
	return true


## O operador tira a fita do gravador: vai para a mesa (`ON_DESK`) e não volta para ele.
func eject() -> void:
	if not inside.is_empty():
		_out(ON_DESK)


## As fitas na mesa, da primeira à última.
func on_desk() -> Array[Dictionary]:
	return done.filter(func(t): return t["fate"] == ON_DESK)


## O operador descarta a fita `t`, da mesa: se perde.
func discard(t: Dictionary) -> void:
	if t.get("fate") != ON_DESK:
		return
	t["fate"] = DISCARDED
	desk.log_decision(rule_id, t["call"], "descartou a fita (%s)" % _words(t), "perdida")


## Fim do turno: as fitas da mesa vão para as autoridades e valem pelo que gravaram. A gravação de uma conversa que
## ninguém pediu vai para o registro como tal (o roteiro pode cobrar).
func hand_over() -> void:
	for t in on_desk():
		t["fate"] = DELIVERED
		t["value"] = value(t)
		if t["value"] > 0:
			desk.main.supervisor.credit("tape", t["value"])
		var result := "gravação não pedida" if t["call"] != null and not t["marked"] else "%d pontos" % t["value"]
		desk.log_decision(rule_id, t["call"], "entregou a fita (%s)" % _words(t), result)


## Fim da noite com fita no gravador: não foi entregue, perdida como a descartada.
func left_behind() -> void:
	if inside.is_empty():
		return
	var t := _out(LEFT)
	desk.log_decision(rule_id, t["call"], "deixou a fita no gravador (%s)" % _words(t), "não entregue")


## A gravada `call` (uma `PhoneCall`) foi entregue nesta noite.
func delivered(call: PhoneCall) -> bool:
	return done.any(func(t): return t["call"] == call and t["fate"] == DELIVERED)


## Tira a fita do gravador para as que saíram, com o destino `fate`, e a devolve; a tecla REC volta.
func _out(fate: String) -> Dictionary:
	var t := inside
	inside = {}
	rec = false
	t["value"] = 0
	t["fate"] = fate
	done.append(t)
	return t


func _words(t: Dictionary) -> String:
	return ", ".join(t["words"]) if not t["words"].is_empty() else "nada"
