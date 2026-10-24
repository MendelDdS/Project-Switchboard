extends BureaucracyRule
## B2. Números bloqueados: transferir para um dos `blocked` é infração (grave, no `.tres`), também nas ligações
## urgentes; depois do pedido, o operador vê o aviso do bloqueio e pode avisar quem liga (permitido: ele reage,
## `TransferCall.refused_line` ou, sem ela, uma das `reactions` sorteada, e desliga). Bloqueado nunca fica "ninguém
## atende" (`PhoneCall.away`). Cada número pode ter uma janela (`free_until`: liberado até aquela hora, pelo relógio do
## jogo na hora de transferir). Número que passa só com autorização é da B3, não daqui: o roteiro troca a burocracia
## (tira de `blocked`, põe nos `numbers` da B3) e vice-versa. Urgente
## (`TransferCall.urgent`): transferir ou avisar é decisão moral no registro.
## Acordos de redirecionamento (`Bureaucracy.agreements`): quem propõe (`TransferCall.deal_from`, `deal_to`,
## `deal_signal`) pede que as ligações para X vão para Y quando quem liga der o sinal; o operador aceita ou recusa. Com o
## acordo, quem dá o sinal (`secret_signal`) pode ir para Y: permitido (só o registro; o destino passa a ser Y na hora de
## transferir); X segue sendo o pedido, a conversa normal e a advertência do bloqueio. Sem o sinal, tudo segue as regras
## de bloqueio. O sinal `SNAPS` ("estalos") são três estalos de dedo no ritmo da noite (`rhythm`): o mesmo para todos
## naquela noite, outro na noite seguinte; o acordo combina só "estalos".
##
## Roteiro: `activate("b2_bloqueados")`; `update_params("b2_bloqueados", {"blocked": ..., "free_until":
## PackedStringArray(["327 21:00"])})`; `desk.agreements.remove("355")` desfaz um acordo.

## Os números bloqueados.
@export var blocked := PackedStringArray()
## Janelas: "número HH:MM", liberado até essa hora (o bar até as 21:00: "327 21:00").
@export var free_until := PackedStringArray()
## Os ritmos dos três estalos ("tec... tec tec": "..." é a pausa longa depois do estalo); um por noite (`rhythm`).
@export var rhythms := PackedStringArray(["tec tec tec", "tec... tec tec", "tec tec... tec", "tec... tec... tec"])
## Reações de quem é avisado do bloqueio e não tem `refused_line` (as ligações comuns do jogo): uma sorteada.
@export var reactions := PackedStringArray()

const SNAPS := "estalos"   ## o sinal (`secret_signal`, `deal_signal`) dos três estalos no ritmo da noite


## O número está bloqueado agora (fora da janela dele, se tiver).
func is_blocked(number: String) -> bool:
	return number in blocked and not (_window(number) != "" and desk.main.minutes < _at(_window(number)))


## O ritmo dos estalos da noite `night`: sempre o mesmo para a mesma noite, nunca o da noite anterior.
func rhythm(night: int) -> String:
	var k := 0
	for n in range(1, night + 1):
		k = (k + 1 + hash(n) % maxi(rhythms.size() - 1, 1)) % rhythms.size()
	return rhythms[k]


## O número que quem liga pediu (depois de transferir para o do acordo, `c.target` passa a ser o dele).
func _asked(c: PhoneCall) -> String:
	return c.meta.get("b2_redirect", {}).get("from", c.target)


## Até que hora o número fica liberado ("21:00"), ou vazio se não tem janela.
func _window(number: String) -> String:
	for w in free_until:
		if w.get_slice(" ", 0) == number:
			return w.get_slice(" ", 1)
	return ""


## "HH:MM" em minutos do turno (depois da meia-noite, no dia seguinte).
func _at(hhmm: String) -> float:
	var t := int(hhmm.get_slice(":", 0)) * 60 + int(hhmm.get_slice(":", 1)) - Main.SHIFT_START_HOUR * 60
	return t + 1440 if t < 0 else t


## O sinal, logo depois do "alô" (com um acordo para o número pedido, o do acordo também vale, `before_transfer`).
func call_started(c: PhoneCall) -> Array:
	var t := c.data as TransferCall
	if t == null:
		return []
	if c.target in blocked:
		c.away = false   # bloqueado e "ninguém atende" não andam juntos: um exclui o outro
	if t.secret_signal == "":
		return []
	var a := desk.agreements.redirect(c.target, t.secret_signal)
	if not a.is_empty():
		c.meta["b2_redirect"] = a.merged({"name": c.destination})
	return [{"snaps": rhythm(desk.night)} if t.secret_signal == SNAPS else t.secret_signal]


## Depois do pedido: o aviso do bloqueio do número pedido (ou até que hora está liberado).
func request_made(c: PhoneCall) -> Array:
	var n := _asked(c)
	if not n in blocked:
		return []
	var until := _window(n)
	if until != "" and desk.main.minutes < _at(until):
		_when_closes(c, n)
		return [{"sys": T.text(T.Key.SYS_FREE_UNTIL) % [n, until]}]
	return [{"sys": T.text(T.Key.SYS_BLOCKED) % n}]


## Na hora em que a janela do número `n` fecha, as opções da ligação se refazem (aparece o [Avisar o bloqueio]). Um
## temporizador só, pelo relógio do jogo; se o relógio parou no caminho, ele espera de novo o que falta.
## ponytail: o relógio adiantado pelo debug não adianta o temporizador; o botão aparece quando ele vence.
func _when_closes(c: PhoneCall, n: String) -> void:
	if c.ended or c.connected:
		return
	var left := _at(_window(n)) - desk.main.minutes
	if left > 0:
		desk.get_tree().create_timer(left / Main.GAME_MIN_PER_SEC, false).timeout.connect(_when_closes.bind(c, n))
	elif c.phase == PhoneCall.Phase.AWAIT and not c.options.is_empty():
		desk.main.conversation.transfer_choices(c)


func before_transfer(c: PhoneCall, d: int) -> Verdict:
	var t := c.data as TransferCall
	if t == null:
		return null
	var a: Dictionary = c.meta.get("b2_redirect", {})
	if not a.is_empty() and str(d) in [a["from"], a["to"]]:   # com o sinal, os dois valem: o certo é o tentado agora
		c.target = str(d)
		c.destination = a["name"] if c.target == a["from"] else GameData.entry(a["to"]).name
	if is_blocked(str(d)):
		if t.urgent:
			desk.log_decision(id, c, "aceitou a ligação urgente para o bloqueado %d (%s)" % [d, t.urgency_reason], "decisão moral")
		return infraction("número bloqueado (%d)" % d)
	if not a.is_empty() and str(d) == a["to"]:
		return Verdict.allowed("com o sinal, %s passou para %s (acordo)" % [a["from"], a["to"]])
	if str(d) in blocked:   # bloqueado, mas liberado agora
		return Verdict.allowed("%d liberado (horário)" % d)
	return null


func choices(c: PhoneCall) -> Array[Dictionary]:
	var t := c.data as TransferCall
	var out: Array[Dictionary] = []
	if t == null:
		return out
	if not c.meta.has("b2_warned") and is_blocked(_asked(c)):
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
		desk.log_decision(id, c, "negou a ligação urgente para o bloqueado %s (%s)" % [_asked(c), t.urgency_reason], "permitido; decisão moral")
	else:
		desk.log_decision(id, c, "avisou o bloqueio de %s" % _asked(c), "permitido")
	if await desk.main.conversation.op(c, T.text(T.Key.OP_WARN_BLOCKED)):
		await desk.hang_up_after(c, desk.refusal(c, reactions))


## O operador aceitou ou recusou o acordo proposto por quem liga; ele agradece ou reclama e desliga.
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
	if await desk.main.conversation.op(c, T.text(T.Key.OP_ACCEPT_DEAL if accept else T.Key.OP_REFUSE_DEAL)):
		await desk.hang_up_after(c, t.thanks if accept else t.refused_line)


## O operador desligou a ligação para um bloqueado sem avisar nem transferir (a urgente: decisão moral).
func call_ended(c: PhoneCall, reason: PhoneCall.End) -> void:
	var t := c.data as TransferCall
	if t == null or reason != PhoneCall.End.OPERATOR or c.connected or c.meta.has("b2_warned") or not is_blocked(_asked(c)):
		return
	if t.urgent:
		desk.log_decision(id, c, "desligou a ligação urgente para o bloqueado %s sem avisar (%s)" % [_asked(c), t.urgency_reason], "decisão moral")
	else:
		desk.log_decision(id, c, "desligou sem avisar o bloqueio de %s" % _asked(c), "permitido")


func debug_info() -> String:
	var lines := PackedStringArray(["estalos da noite: " + rhythm(desk.night)])
	for n in blocked:
		lines.append("%s %s: %s" % [n, GameData.entry(n).name if GameData.entry(n) else "?", "bloqueado" if is_blocked(n) else "liberado agora"])
	for a in desk.agreements.items:
		lines.append("acordo: %s → %s com %s (noite %d)" % [a["from"], a["to"], a["signal"], a["night"]])
	return "\n".join(lines)


func debug_actions() -> Array:
	return [["Desfazer acordos", func(): desk.agreements.items.clear()]]
