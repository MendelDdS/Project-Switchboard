extends BureaucracyRule
## B2. Números bloqueados: transferir para um dos `blocked` é infração (grave, no `.tres`), também nas ligações
## urgentes; o operador pode avisar o bloqueio (permitido). Cada número pode ter uma janela (`free_until`: liberado até
## aquela hora, pelo relógio do jogo) e pode ser liberado pelo código de autorização da noite (`code_frees`, os códigos
## da B3, `Bureaucracy.codes`; sem código ou com o errado, é um bloqueado como os outros). Urgente
## (`TransferCall.urgent`): transferir ou avisar é decisão moral no registro.
## Acordos de redirecionamento (`Bureaucracy.agreements`): quem propõe (`TransferCall.deal_from`, `deal_to`,
## `deal_signal`) pede que as ligações para X vão para Y quando quem liga der o sinal; o operador aceita ou recusa. Com o
## acordo, quem dá o sinal (`secret_signal`) passa a ter Y como destino certo: Y é permitido (só o registro); X é número
## errado (a reclamação, pelo fluxo de sempre) e bloqueado, e vale a maior. Sem o sinal, tudo segue as regras de bloqueio.
##
## Roteiro: `activate("b2_bloqueados")`; `update_params("b2_bloqueados", {"blocked": ..., "free_until":
## PackedStringArray(["327 21:00"])})`; `desk.agreements.remove("355")` desfaz um acordo.

## Os números bloqueados.
@export var blocked := PackedStringArray()
## Janelas: "número HH:MM", liberado até essa hora (o bar até as 21:00: "327 21:00").
@export var free_until := PackedStringArray()
## Os bloqueados que o código de autorização da noite libera.
@export var code_frees := PackedStringArray()


## O número está bloqueado agora para a ligação `c` (com o código dela, se ele liberar).
func is_blocked(number: String, c: PhoneCall = null) -> bool:
	if not number in blocked:
		return false
	for w in free_until:
		if w.get_slice(" ", 0) == number and desk.main.minutes < _at(w.get_slice(" ", 1)):
			return false
	return not (c != null and number in code_frees and desk.code_of(c) == 1)


## "HH:MM" em minutos do turno (depois da meia-noite, no dia seguinte).
func _at(hhmm: String) -> float:
	var t := int(hhmm.get_slice(":", 0)) * 60 + int(hhmm.get_slice(":", 1)) - Main.SHIFT_START_HOUR * 60
	return t + 1440 if t < 0 else t


## O sinal (com um acordo para o número pedido, o destino certo passa a ser o do acordo) e o código, se o número
## pedido se libera com ele.
func call_started(c: PhoneCall) -> Array:
	var t := c.data as TransferCall
	var out := []
	if t == null:
		return out
	if t.secret_signal != "":
		out.append(t.secret_signal)
		var a := desk.agreements.redirect(c.target, t.secret_signal)
		if not a.is_empty():
			c.meta["b2_redirect"] = a
			c.target = a["to"]
			c.destination = GameData.entry(a["to"]).name
	if c.target in code_frees:
		out.append_array(desk.code_line(c))
	return out


func before_transfer(c: PhoneCall, d: int) -> Verdict:
	var t := c.data as TransferCall
	if t == null:
		return null
	var a: Dictionary = c.meta.get("b2_redirect", {})
	if is_blocked(str(d), c):
		if t.urgent:
			desk.log_decision(id, c, "aceitou a ligação urgente para o bloqueado %d (%s)" % [d, t.urgency_reason], "decisão moral")
		return infraction("número bloqueado (%d)" % d)
	if not a.is_empty() and str(d) == a["to"]:
		return Verdict.allowed("com o sinal, %s passou para %s (acordo)" % [a["from"], a["to"]])
	if str(d) in blocked:   # bloqueado, mas liberado agora
		return Verdict.allowed("%d liberado (%s)" % [d, "código" if str(d) in code_frees and desk.code_of(c) == 1 else "horário"])
	return null


func choices(c: PhoneCall) -> Array[Dictionary]:
	var t := c.data as TransferCall
	var out: Array[Dictionary] = []
	if t == null:
		return out
	if not c.meta.has("b2_warned") and is_blocked(c.target, c):
		out.append({"label": T.text(T.Key.CHOICE_WARN_BLOCKED), "fn": _warn.bind(c)})
	if t.deal_from != "" and not c.meta.has("b2_deal"):
		out.append({"label": T.text(T.Key.CHOICE_ACCEPT_DEAL), "fn": _deal.bind(c, true)})
		out.append({"label": T.text(T.Key.CHOICE_REFUSE_DEAL), "fn": _deal.bind(c, false)})
	return out


## O operador avisou que o número está bloqueado (no urgente, negou a ligação).
func _warn(c: PhoneCall) -> void:
	var t: TransferCall = c.data
	if c.talking:
		return
	c.meta["b2_warned"] = true
	desk.main.conversation.transfer_choices(c)
	if t.urgent:
		desk.log_decision(id, c, "negou a ligação urgente para o bloqueado %s (%s)" % [c.target, t.urgency_reason], "permitido; decisão moral")
	else:
		desk.log_decision(id, c, "avisou o bloqueio de %s" % c.target, "permitido")
	await desk.main.conversation.op(c, T.text(T.Key.OP_WARN_BLOCKED))


## O operador aceitou ou recusou o acordo proposto por quem liga.
func _deal(c: PhoneCall, accept: bool) -> void:
	var t: TransferCall = c.data
	if c.talking:
		return
	c.meta["b2_deal"] = true
	desk.main.conversation.transfer_choices(c)
	if accept:
		desk.agreements.add(t.deal_from, t.deal_to, t.deal_signal, desk.night)
	desk.log_decision(id, c, "%s o acordo: %s → %s com %s" % ["aceitou" if accept else "recusou", t.deal_from, t.deal_to, t.deal_signal],
		"acordo valendo" if accept else "sem acordo")
	await desk.main.conversation.op(c, T.text(T.Key.OP_ACCEPT_DEAL if accept else T.Key.OP_REFUSE_DEAL))


func debug_info() -> String:
	var lines := PackedStringArray()
	for n in blocked:
		lines.append("%s %s: %s" % [n, GameData.entry(n).name if GameData.entry(n) else "?", "bloqueado" if is_blocked(n) else "liberado agora"])
	for a in desk.agreements.items:
		lines.append("acordo: %s → %s com %s (noite %d)" % [a["from"], a["to"], a["signal"], a["night"]])
	return "\n".join(lines)


func debug_actions() -> Array:
	return [["Desfazer acordos", func(): desk.agreements.items.clear()]]
