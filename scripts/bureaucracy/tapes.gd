extends RefCounted
## O inventário de fitas (`Bureaucracy.tapes`): as virgens da noite, a que está no gravador e as que já saíram dele.
## A fita no gravador grava a conversa que o operador escuta (a primeira em que ele entra com ela lá) e guarda as
## palavras-chave ouvidas dela (`Clue`, só as ouvidas: a escuta e a desconfiança de sempre valem). Entregue às
## autoridades, vale pontos de eficiência pelo valor (`value`); descartada, se perde. Qualquer regra pode usar; a B4
## configura (`rule_id`, `per_word`) e grava. As equipamentos da mesa (`scenes/ui/equipment/`) mexem por aqui.

var desk: Node   ## o `Bureaucracy` (o registro de decisões e as advertências)
var rule_id := ""   ## a regra em nome de quem o registro anota
var per_word := 10   ## pontos por palavra-chave numa conversa marcada pelas autoridades
var blank := 0   ## fitas virgens no porta-fitas
var inside := {}   ## a fita no gravador: {} vazio; {"call": PhoneCall ou null, "who", "words": [], "marked": bool}
var done: Array[Dictionary] = []   ## as que saíram nesta noite: {"who", "words", "value", "fate"}


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
	return t["words"].size() * per_word if t.get("marked", false) else 0


## O operador entrega a fita às autoridades (`deliver`) ou a descarta: sai do gravador e não volta.
func eject(deliver: bool) -> void:
	if inside.is_empty():
		return
	var t := inside
	inside = {}
	var v := value(t)
	done.append({"who": t["who"], "words": t["words"], "value": v, "fate": "entregue" if deliver else "descartada"})
	if deliver and v > 0:
		desk.main.supervisor.credit("tape", v)
	desk.log_decision(rule_id, t["call"], "%s a fita (%s)" % ["entregou" if deliver else "descartou", ", ".join(t["words"]) if not t["words"].is_empty() else "nada"],
		"%d pontos" % v if deliver else "perdida")
