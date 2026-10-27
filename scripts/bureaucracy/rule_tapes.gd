extends BureaucracyRule
## B4. Gravação de conversas em fitas: as autoridades marcam ligações (`TransferCall.suspicious`; o operador vê o aviso
## no começo dela); o operador põe uma fita do porta-fitas no gravador e escuta a conversa (`Eavesdrop`, com a
## desconfiança de sempre): a fita grava a conversa e as palavras-chave que ele ouvir dela (`Bureaucracy.tapes`).
## Entregue, vale pontos de eficiência pelo valor; descartada (ou esquecida no gravador no fim da noite), se perde. Os
## dois notaram a escuta numa ligação marcada: advertência na gravidade da regra (trabalho malfeito para as autoridades,
## que pediram), no lugar da por escuta. `tapes_per_night` virgens por noite. Ligação marcada sem a fita dela entregue:
## nada na hora (as autoridades não sabem o que ela tinha); `found_after` noites depois descobrem e vem a advertência
## de descuido (`missed_severity`, `missed_text`), e o marcador `authorities_questioning_pending` fica para o roteiro.
## Só as ligações do roteiro vêm marcadas (`TransferCall.suspicious`).
## Equipamentos (`equipment` no `.tres`): o porta-fitas e o gravador chegam na mesa na primeira vez que ela vale e
## ficam (`keep_equipment`), mesmo desligada.
##
## Roteiro: `activate("b4_fitas")` (os equipamentos chegam; `equipment_unlocked` avisa para encenar a chegada).

@export var tapes_per_night := 3
@export var points_per_word := 5   ## (com 10, uma fita de quatro palavras valia mais que uma advertência grave)
@export var max_tape_points := 20   ## o máximo de uma fita, o de uma emergência resolvida a tempo
@export var found_after := 2   ## noites até as autoridades darem pela ligação marcada que não chegou gravada
@export var missed_severity := ShiftReport.Severity.MEDIUM
@export var missed_text := "FAULT_TAPE_MISSED"

var _marked: Array[PhoneCall] = []   ## as ligações marcadas nesta noite


func night_started() -> void:
	desk.tapes.rule_id = id
	desk.tapes.per_word = points_per_word
	desk.tapes.max_points = max_tape_points
	desk.tapes.reset(tapes_per_night)
	_marked.clear()


func call_started(c: PhoneCall) -> Array:
	var t := c.data as TransferCall
	if t != null and t.suspicious:
		_marked.append(c)
		c.meta["b4"] = true
		c.sys(T.text(T.Key.SYS_RECORD_REQUEST))
	return []


## A chave de escuta subiu com fita no gravador: a fita passa a gravar esta conversa.
func listening(n: int, on: bool) -> void:
	var c := desk.main.eavesdrop.call_of(n)
	if on and c != null and desk.tapes.recording():
		_bind(c)


func clue_heard(k: Clue) -> void:
	if desk.tapes.inside.is_empty():
		return
	if desk.tapes.inside["call"] == null and desk.tapes.recording():
		_bind(k.call)
	if desk.tapes.inside["call"] == k.call:
		desk.tapes.inside["words"].append(k.word)


func _bind(c: PhoneCall) -> void:
	if desk.tapes.inside["call"] != null:
		return
	desk.tapes.bind(c, c.meta.has("b4"))


func caught_listening(c: PhoneCall) -> bool:
	if not c.meta.has("b4"):
		return false
	desk.main.supervisor.fault_later(id, desk.main.supervisor.who(c), severity, T.Key[fault_text])
	desk.log_decision(id, c, "foi pego escutando a ligação marcada", "advertência amanhã")
	return true


func night_ended() -> void:
	desk.tapes.left_behind()
	for c in _marked.filter(func(c: PhoneCall): return not desk.tapes.delivered(c)):
		desk.main.supervisor.fault_later(id, desk.main.supervisor.who(c), missed_severity, T.Key[missed_text], found_after)
		desk.main.flags.apply("authorities_questioning_pending")
		desk.log_decision(id, c, "não entregou a gravação da ligação marcada", "advertência daqui a %d noites" % found_after)


func debug_info() -> String:
	var tp := desk.tapes
	var lines := ["Na prateleira: clique no porta-fitas (fita no gravador), conecte a ligação marcada e escute (Z); "
		+ "depois, Entregar ou Descartar no gravador.", "virgens: %d · no gravador: %s · marcadas na noite: %d, entregues: %d" % [tp.blank,
		"nada" if tp.inside.is_empty() else "%s %s" % [tp.inside["who"] if tp.inside["who"] != "" else "virgem", tp.inside["words"]], _marked.size(),
		_marked.filter(func(c: PhoneCall): return tp.delivered(c)).size()]]
	for t in tp.done:
		lines.append("· %s: %s, %d pontos (%s)" % [t["who"], t["words"], t["value"], t["fate"]])
	return "\n".join(lines)


func debug_actions() -> Array:
	return [["Resetar fitas", night_started], ["+1 fita", func(): desk.tapes.blank += 1]]
