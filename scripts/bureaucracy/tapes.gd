extends RefCounted
## O inventário de fitas (`Bureaucracy.tapes`): as virgens da noite, a que está no gravador e as que já saíram dele.
## A fita no gravador grava a conversa que o operador escuta (a primeira em que ele entra com ela lá) e guarda as
## palavras-chave ouvidas dela (`Clue`, só as ouvidas: a escuta e a desconfiança de sempre valem). Entregue às
## autoridades, vale pontos de eficiência pelo valor (`value`); descartada, se perde. Qualquer regra pode usar; a B4
## configura (`rule_id`, `per_word`) e grava. As equipamentos da mesa (`scenes/ui/equipment/`) mexem por aqui.

var desk: Node   ## o `Bureaucracy` (o registro de decisões e as advertências)
var rule_id := ""   ## a regra em nome de quem o registro anota
var per_word := 5   ## pontos por palavra-chave numa conversa marcada pelas autoridades
var max_points := 20   ## o máximo de uma fita
var blank := 0   ## fitas virgens no porta-fitas
var inside := {}   ## a fita no gravador: {} vazio; {"call": PhoneCall ou null, "who", "words": [], "marked": bool}
var done: Array[Dictionary] = []   ## as que saíram nesta noite: {"call", "marked", "who", "words", "value", "fate"} (`DELIVERED`...)

const DELIVERED := "entregue"
const DISCARDED := "descartada"
const LEFT := "esquecida no gravador"


func _init(d: Node) -> void:
	desk = d


## Começo da noite: `n` virgens; a que ficou no gravador e as que saíram não voltam.
func reset(n: int) -> void:
	blank = n
	inside = {}
	done.clear()


## Uma virgem do porta-fitas no gravador vazio. Falso se não há fita ou o gravador está ocupado.
func insert() -> bool:
	if blank <= 0 or not inside.is_empty():
		return false
	blank -= 1
	inside = {"call": null, "who": "", "words": [], "marked": false}
	return true


## O gravador está gravando agora: tem fita e o operador escuta a conversa dela (ou, sem conversa ainda, qualquer uma).
func recording() -> bool:
	if inside.is_empty():
		return false
	var c: PhoneCall = inside["call"]
	var ear = desk.main.eavesdrop
	if c == null:
		return ear.listening(desk.main.board.fone_line())
	return ear.listening(c.line) and ear.call_of(c.line) == c


## A fita grava a conversa `c` (se ainda não gravou outra). `marked`: as autoridades pediram.
func bind(c: PhoneCall, marked: bool) -> void:
	if inside.is_empty() or inside["call"] != null:
		return
	inside["call"] = c
	inside["who"] = desk.main.supervisor.who(c)
	inside["marked"] = marked


## O valor de informação da fita: as palavras-chave de uma conversa marcada (as outras não interessam).
func value(t: Dictionary) -> int:
	return mini(t["words"].size() * per_word, max_points) if t.get("marked", false) else 0


## O operador entrega a fita às autoridades (`deliver`) ou a descarta: sai do gravador e não volta. A gravação de uma
## conversa que ninguém pediu entregue vai para o registro como tal (o roteiro pode cobrar).
func eject(deliver: bool) -> void:
	if inside.is_empty():
		return
	var t := _out(DELIVERED if deliver else DISCARDED)
	if deliver and t["value"] > 0:
		desk.main.supervisor.credit("tape", t["value"])
	var result := "perdida"
	if deliver:
		result = "gravação não pedida" if t["call"] != null and not t["marked"] else "%d pontos" % t["value"]
	desk.log_decision(rule_id, t["call"], "%s a fita (%s)" % ["entregou" if deliver else "descartou", _words(t)], result)


## Fim da noite com fita no gravador: não foi entregue, perdida como a descartada.
func left_behind() -> void:
	if inside.is_empty():
		return
	var t := _out(LEFT)
	desk.log_decision(rule_id, t["call"], "deixou a fita no gravador (%s)" % _words(t), "não entregue")


## A gravada `call` (uma `PhoneCall`) foi entregue nesta noite.
func delivered(call: PhoneCall) -> bool:
	return done.any(func(t): return t["call"] == call and t["fate"] == DELIVERED)


## Tira a fita do gravador para as que saíram, com o destino `fate`, e a devolve.
func _out(fate: String) -> Dictionary:
	var t := inside
	inside = {}
	t["value"] = value(t) if fate == DELIVERED else 0
	t["fate"] = fate
	done.append(t)
	return t


func _words(t: Dictionary) -> String:
	return ", ".join(t["words"]) if not t["words"].is_empty() else "nada"
