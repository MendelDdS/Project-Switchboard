extends RefCounted
## O inventário de fitas (`Bureaucracy.tapes`): as virgens do compartimento, a que está no gravador e as que já saíram
## dele. As virgens passam de uma noite para outra (`state`); o compartimento só é reposto quando esvazia ou depois de
## algumas noites incompleto (`restock`).
## Com a tecla REC presa (`rec`), a fita no gravador grava a conversa que o operador escuta (a primeira em que ele entra
## assim) e guarda as palavras-chave ouvidas dela (`Clue`, só as ouvidas: a escuta e a desconfiança de sempre valem).
## Cada virgem tem o lugar dela no compartimento (`slots`); cada fita tirada dele é uma `Tape`. Tirada do gravador,
## fica na mesa (`Tape.Fate.ON_DESK`), onde o operador escolhe para quem vai (`give`): às autoridades (no fim do turno,
## `hand_over`, vale pontos de eficiência pelo valor, `value`) ou a Sebastião, na noite em que ele pediu (`sebastiao_asked`); ou a descarta (`discard`), e se perde. O
## turno só encerra com todas resolvidas (`unresolved`). Qualquer regra pode usar; a B4
## configura (`rule_id`, `per_word`) e grava. As equipamentos da mesa (`scenes/ui/equipment/`) mexem por aqui.

const Tape := preload("res://scripts/bureaucracy/tape.gd")
const ASKED := "sebastiao_pediu_fita_"   ## + a noite: o marcador que a ligação de Sebastião pedindo a fita liga (`sebastiao_asked`)

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
var short_nights := 0   ## noites seguidas terminadas com o compartimento incompleto (`restock`)
var last := {}   ## o resumo da noite anterior (`summary`), para o bilhete do supervisor na abertura


func _init(d: Node) -> void:
	desk = d


## O compartimento cheio: `n` virgens.
func reset(n: int) -> void:
	slots.clear()
	for i in n:
		slots.append(true)


## Começo da noite: as virgens são as que sobraram; a que ficou no gravador e as que saíram não voltam.
func new_night() -> void:
	rec = false
	inside = null
	done.clear()


## Fim da noite: o compartimento vazio, ou incompleto há `after` noites seguidas, volta a ter `full` virgens na noite
## seguinte. Devolve se repôs.
func restock(full: int, after: int) -> bool:
	short_nights = short_nights + 1 if blank < full else 0
	if blank > 0 and short_nights < after:
		return false
	reset(full)
	short_nights = 0
	return true


## O que guardar para a noite seguinte (`Bureaucracy.state`).
func state() -> Dictionary:
	return {"slots": slots, "short": short_nights, "last": last}


func restore(saved: Dictionary) -> void:
	slots.assign(saved.get("slots", []))
	short_nights = saved.get("short", 0)
	last = saved.get("last", {})


## O resumo da noite `n` para o bilhete da seguinte: as fitas usadas, as entregues (com conversa marcada e palavras) e
## quem foi pedido e não chegou gravado (`missed`, o que `Supervisor.who` diz); `restocked`, posto depois (`restock`).
func summary(n: int, missed: Array) -> Dictionary:
	var given := done.filter(func(t: Tape): return t.fate == Tape.Fate.DELIVERED and t.marked and not t.words.is_empty())
	return {"night": n, "used": done.size(), "delivered": given.size(), "missed": missed, "restocked": false}


## O resumo `last` no bilhete do supervisor da noite `n` (vazio se não é da noite anterior ou não há o que dizer).
static func note(last: Dictionary, n: int) -> String:
	if last.is_empty() or last["night"] != n - 1:   # (vazio na noite 0: o -1 do padrão batia com n - 1)
		return ""
	var lines := PackedStringArray()
	if last["used"] > 0:
		lines.append(T.text(T.Key.TAPES_NOTE) % [last["used"], last["delivered"]])
	if not last["missed"].is_empty():
		lines.append(T.text(T.Key.TAPES_NOTE_MISSED) % ", ".join(last["missed"]))
	if last["restocked"]:
		lines.append(T.text(T.Key.TAPES_NOTE_RESTOCK))
	return " ".join(lines)


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


## As fitas da mesa ainda sem destino (o turno espera por elas).
func unresolved() -> Array:
	return on_desk().filter(func(t: Tape): return t.to == Tape.To.NONE)


## Sebastião pediu fita nesta noite (o marcador `ASKED` + a noite, do desfecho da ligação dele): só então a pilha
## oferece dar a ele.
func sebastiao_asked() -> bool:
	return desk.main.flags.has(ASKED + str(desk.main.night_no))


## O operador escolhe para quem vai a fita `t` da mesa (`to`): ela é embrulhada e sai no fim do turno. Sem volta.
func give(t: Tape, to: Tape.To) -> void:
	if t.fate != Tape.Fate.ON_DESK or t.to != Tape.To.NONE or to == Tape.To.NONE:
		return
	t.to = to
	desk.log_decision(rule_id, t.call, "embrulhou a fita %s(%s) para %s" % ["pedida " if t.marked else "", t.words_text(),
		"Sebastião" if to == Tape.To.SEBASTIAO else "as autoridades"], "sai no fim do turno")


## Quantas gravadas (com conversa, mesmo sem nada nela) foram entregues às autoridades nesta noite.
func to_authorities() -> int:
	return done.filter(func(t: Tape): return t.fate == Tape.Fate.DELIVERED and t.call != null).size()


## O operador descarta a fita `t`, da mesa: se perde. A de uma conversa marcada é não colaborar de propósito: custa o
## mesmo que não entregar e liga o marcador `b4_descartou_<ligação>` para o roteiro (`call_id`).
func discard(t: Tape) -> void:
	if t.fate != Tape.Fate.ON_DESK:
		return
	t.fate = Tape.Fate.DISCARDED
	if t.marked:
		desk.main.flags.apply("b4_descartou_" + call_id(t.call))
	desk.log_decision(rule_id, t.call, "descartou a fita %s(%s)" % ["pedida " if t.marked else "", t.words_text()], "perdida")


## O nome da ligação nos marcadores: o arquivo do roteiro dela (só as do roteiro vêm marcadas).
static func call_id(c: PhoneCall) -> String:
	return c.data.resource_path.get_file().get_basename() if c != null and c.data != null else ""


## Fim do turno: as fitas da mesa saem para quem o operador escolheu. As das autoridades valem pelo que gravaram (a
## gravação de uma conversa que ninguém pediu vai para o registro como tal; a de uma conversa delas mesmas,
## `StoryCall.authority`, é advertência gravíssima e não vale nada); as de Sebastião ligam os marcadores da
## ligação gravada (`StoryCall.if_sebastiao`); as sem destino (o turno acabou à força) ficam esquecidas.
func hand_over() -> void:
	for t: Tape in on_desk():
		if t.to == Tape.To.NONE:
			t.fate = Tape.Fate.LEFT
			desk.log_decision(rule_id, t.call, "deixou a fita na mesa sem destino (%s)" % t.words_text(), "não entregue")
			continue
		if t.to == Tape.To.SEBASTIAO:
			t.fate = Tape.Fate.SEBASTIAO
			if t.call != null and t.call.beat != null:
				for f in t.call.beat.if_sebastiao:
					desk.main.flags.apply(f)
			desk.log_decision(rule_id, t.call, "deu a fita a Sebastião (%s)" % t.words_text(), "não entregue às autoridades")
			continue
		t.fate = Tape.Fate.DELIVERED
		if t.call != null and t.call.beat != null and t.call.beat.authority:   # gravou as próprias autoridades
			desk.main.supervisor.fault(rule_id, t.who, ShiftReport.Severity.CRITICAL, T.Key.FAULT_TAPE_AUTHORITY)
			desk.log_decision(rule_id, t.call, "entregou às autoridades a fita da conversa delas", "advertência gravíssima")
			continue
		t.value = value(t)
		if t.value > 0:
			desk.main.supervisor.credit("tape", t.value)
		if t.call != null and t.call.beat != null and not t.words.is_empty():
			for f in t.call.beat.if_delivered:
				desk.main.flags.apply(f)
		var result := "gravação não pedida" if t.call != null and not t.marked else (
			"vazia: não conta como entregue" if t.marked and t.words.is_empty() else "%d pontos" % t.value)
		desk.log_decision(rule_id, t.call, "entregou a fita (%s)" % t.words_text(), result)


## Fim da noite com fita no gravador: não foi entregue, perdida como a descartada.
func left_behind() -> void:
	if inside == null:
		return
	var t := _out(Tape.Fate.LEFT)
	desk.log_decision(rule_id, t.call, "deixou a fita no gravador (%s)" % t.words_text(), "não entregue")


## A gravada `call` (uma `PhoneCall`) foi entregue nesta noite, com alguma palavra-chave (a fita vazia, de um segundo
## de escuta, não conta).
func delivered(call: PhoneCall) -> bool:
	return done.any(func(t: Tape): return t.call == call and t.fate == Tape.Fate.DELIVERED and not t.words.is_empty())


## A fita `t` chegou ao máximo que vale (`max_points`): escutar mais só arrisca.
func full(t: Tape) -> bool:
	return t != null and t.marked and t.words.size() * per_word >= max_points


## Tira a fita do gravador para as que saíram, com o destino `fate`, e a devolve; a tecla REC volta.
func _out(fate: Tape.Fate) -> Tape:
	var t := inside
	inside = null
	rec = false
	t.value = 0
	t.fate = fate
	done.append(t)
	return t
