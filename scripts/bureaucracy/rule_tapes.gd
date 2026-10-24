extends BureaucracyRule
## B4. Gravação de conversas em fitas: as autoridades marcam ligações (`TransferCall.suspicious`; o operador vê o aviso
## no começo dela); o operador põe uma fita do porta-fitas no gravador e escuta a conversa (`Eavesdrop`, com a
## desconfiança de sempre): a fita grava a conversa e as palavras-chave que ele ouvir dela (`Bureaucracy.tapes`).
## Entregue, vale pontos de eficiência pelo valor; descartada, se perde. Os dois notaram a escuta numa ligação marcada:
## advertência na gravidade da regra (trabalho malfeito para as autoridades, que pediram), no lugar da por escuta. `tapes_per_night` virgens por noite. Numa noite
## com pedidos e nenhuma gravação, nada na hora: liga o marcador `authorities_questioning_pending` para o roteiro.
## Equipamentos (`equipment` no `.tres`): o porta-fitas e o gravador chegam na mesa na primeira vez que ela vale e
## ficam (`keep_equipment`), mesmo desligada.
##
## Roteiro: `activate("b4_fitas")` (os equipamentos chegam; `equipment_unlocked` avisa para encenar a chegada).

@export var tapes_per_night := 3
@export var points_per_word := 10

var _asked := 0      ## ligações marcadas nesta noite
var _recorded := 0   ## fitas que gravaram uma delas


func night_started() -> void:
	desk.tapes.rule_id = id
	desk.tapes.per_word = points_per_word
	desk.tapes.reset(tapes_per_night)
	_asked = 0
	_recorded = 0


func call_started(c: PhoneCall) -> Array:
	var t := c.data as TransferCall
	if t != null and t.suspicious:
		_asked += 1
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
	if c.meta.has("b4"):
		_recorded += 1


func caught_listening(c: PhoneCall) -> bool:
	if not c.meta.has("b4"):
		return false
	desk.main.supervisor.fault_later(id, desk.main.supervisor.who(c), severity, T.Key[fault_text])
	desk.log_decision(id, c, "foi pego escutando a ligação marcada", "advertência amanhã")
	return true


func night_ended() -> void:
	if _asked > 0 and _recorded == 0:
		desk.main.flags.apply("authorities_questioning_pending")
		desk.log_decision(id, null, "não gravou nenhuma das %d ligações marcadas" % _asked, "authorities_questioning_pending")


func debug_info() -> String:
	var tp := desk.tapes
	var lines := ["Na prateleira: clique no porta-fitas (fita no gravador), conecte a ligação marcada e escute (Z); "
		+ "depois, Entregar ou Descartar no gravador.", "virgens: %d · no gravador: %s · marcadas na noite: %d, gravadas: %d" % [tp.blank,
		"nada" if tp.inside.is_empty() else "%s %s" % [tp.inside["who"] if tp.inside["who"] != "" else "virgem", tp.inside["words"]], _asked, _recorded]]
	for t in tp.done:
		lines.append("· %s: %s, %d pontos (%s)" % [t["who"], t["words"], t["value"], t["fate"]])
	return "\n".join(lines)


func debug_actions() -> Array:
	return [["Resetar fitas", night_started], ["+1 fita", func(): desk.tapes.blank += 1]]
