extends BureaucracyRule
## B1. Identificação obrigatória: quem liga precisa dizer nome e sobrenome. Uns dizem sozinhos logo depois do "alô"
## (`TransferCall.identify` YES, `name_line`); dos outros, o operador pede ([Solicitar identificação]) e eles dizem
## (WHEN_ASKED) ou recusam (`refuse_line`). Recusado, o operador pode insistir ([Insistir no nome]): IF_PRESSED cede e
## diz; NO recusa de novo (`refuse_again_line`) e aí só resta desligar (permitido, vai para o registro) ou transferir
## mesmo assim. Transferir sem identificação (sem pedir ou com a recusa) é infração (média, no `.tres`). Vale para toda
## transferência: o chat mostra `caller` até a pessoa dizer o nome e `caller_name` dali em diante (`PhoneCall.named`).
## Recados (`Bureaucracy.messages`): quem liga pode deixar só um recado (`message`, para `message_to`): com o nome de
## quem se identificou antes de o operador anotar, ou anônimo; o operador anota (quem ligou agradece e desliga) ou
## recusa (reclama, `refused_line`, e desliga). Mais tarde, quando quem é desse número liga e diz quem é
## (`from_number`, identificado), o operador pode dar o recado ou não: a escolha vai para o registro e, se
## `message_penalty` não for "Nenhuma", dar um recado anônimo é advertência.
##
## Roteiro: `activate("b1_identificacao")`; os recados ficam salvos de uma noite para outra.

@export_enum("Nenhuma:-1", "Leve:0", "Média:1", "Grave:2", "Gravíssima:3") var message_penalty := -1
## Das ligações fora do roteiro que diriam o nome sem fala própria (YES sem `name_line`), a parte que só diz quando o
## operador pede (uma das `GameContent.name_lines`): ele precisa cobrar.
@export_range(0.0, 1.0) var ask_share := 0.4


## Estado da identificação em `c.meta["b1"]`: "unasked" (ninguém pediu), "asking" (pedindo agora), "ok", "refused".
func call_started(c: PhoneCall) -> Array:
	var t := c.data as TransferCall
	if t == null:
		return []
	if t.identify == TransferCall.Identify.YES and t.name_line == "" and not c.story and randf() < ask_share:
		c.meta["b1_line"] = GameData.fill(GameData.pick(GameData.CONTENT.name_lines), {"name": t.caller_name})
	if t.identify == TransferCall.Identify.YES and not c.meta.has("b1_line"):
		c.meta["b1"] = "ok"
		return [t.name_line, {"named": t.caller_name}] if t.name_line != "" else []
	c.meta["b1"] = "unasked"
	return []


func before_transfer(c: PhoneCall, d: int) -> Verdict:
	if not c.meta.has("b1") or c.meta["b1"] == "ok":
		return null
	return infraction("sem identificação (%d)" % d)


func choices(c: PhoneCall) -> Array[Dictionary]:
	var t := c.data as TransferCall
	var out: Array[Dictionary] = []
	if t == null:
		return out
	match c.meta.get("b1", ""):
		"unasked":
			out.append({"label": T.text(T.Key.CHOICE_REQUEST_ID), "fn": _ask.bind(c, false)})
		"refused" when not c.meta.has("b1_pressed"):
			out.append({"label": T.text(T.Key.CHOICE_PRESS_NAME), "fn": _ask.bind(c, true)})
	if t.message != "" and not c.meta.has("b1_msg"):
		out.append({"label": T.text(T.Key.CHOICE_TAKE_MESSAGE), "fn": _note.bind(c, true)})
		out.append({"label": T.text(T.Key.CHOICE_REFUSE_MESSAGE), "fn": _note.bind(c, false)})
	var m := _pending(c)
	if not m.is_empty():
		out.append({"label": T.text(T.Key.CHOICE_GIVE_MESSAGE), "fn": _give.bind(c, m, true)})
		out.append({"label": T.text(T.Key.CHOICE_KEEP_MESSAGE), "fn": _give.bind(c, m, false)})
	return out


## O recado deixado para quem liga, depois de saber quem é (vazio se não há).
func _pending(c: PhoneCall) -> Dictionary:
	var t := c.data as TransferCall
	if c.meta.has("b1_given") or c.meta.get("b1", "") != "ok":
		return {}
	var w := desk.messages.waiting(t.from_number)
	return {} if w.is_empty() else w[0]


## O operador pede a identificação (`press`: insiste depois da recusa); quem liga diz o nome ou recusa.
func _ask(c: PhoneCall, press: bool) -> void:
	var t: TransferCall = c.data
	if c.talking:
		return
	c.meta["b1"] = "asking"
	if press:
		c.meta["b1_pressed"] = true
	desk.main.conversation.transfer_choices(c)
	var gives := c.meta.has("b1_line") or t.identify == (TransferCall.Identify.IF_PRESSED if press else TransferCall.Identify.WHEN_ASKED)
	desk.log_decision(id, c, "insistiu no nome" if press else "pediu a identificação",
		"identificou-se: " + t.caller_name if gives else ("recusou de novo" if press else "recusou"))
	if not await desk.main.conversation.op(c, T.text(T.Key.OP_PRESS_NAME if press else T.Key.OP_ASK_NAME)):
		return
	var answer: String = c.meta.get("b1_line", t.name_line) if gives else (t.refuse_again_line if press and t.refuse_again_line != "" else t.refuse_line)
	if await desk.main.conversation.say(c, answer):
		c.meta["b1"] = "ok" if gives else "refused"
		if gives:
			c.named = t.caller_name
		desk.main.conversation.transfer_choices(c)


## Anotou (`take`) ou recusou o recado de quem liga; de um jeito ou de outro, ele desliga (agradecendo ou reclamando).
func _note(c: PhoneCall, take: bool) -> void:
	var t: TransferCall = c.data
	if c.talking:
		return
	c.meta["b1_msg"] = true
	desk.main.conversation.transfer_choices(c)
	var from := t.caller_name if c.meta.get("b1", "") == "ok" else ""
	if take:
		desk.messages.add(t.message_to, t.message, from, desk.night, Main.fmt(desk.main.minutes), t.message_reply)
	desk.log_decision(id, c, ("anotou" if take else "recusou") + " recado %s para %s" % ["anônimo" if from == "" else "de " + from,
		t.message_to], "na fila" if take else "recusado")
	if not await desk.main.conversation.op(c, T.text(T.Key.OP_TAKE_MESSAGE if take else T.Key.OP_REFUSE_MESSAGE)):
		return
	await desk.hang_up_after(c, t.thanks if take else t.refused_line)


## Deu (`give`, o operador diz na hora; quem recebe responde, `TransferCall.message_reply` de quem deixou) ou guardou
## o recado `m`.
func _give(c: PhoneCall, m: Dictionary, give: bool) -> void:
	if c.talking:
		return
	c.meta["b1_given"] = true
	desk.main.conversation.transfer_choices(c)
	if not give:
		desk.log_decision(id, c, "não deu o recado para %s" % m["to"], "o recado continua na fila")
		return
	desk.messages.take(m)
	var who: String = "anônimo" if m["from"] == "" else "de " + m["from"]
	if m["from"] == "" and message_penalty >= 0:
		desk.penalize(self, c, message_penalty as ShiftReport.Severity, "deu recado anônimo para %s" % m["to"], T.Key.FAULT_ANON_MESSAGE)
	else:
		desk.log_decision(id, c, "deu recado %s para %s" % [who, m["to"]], "repassado")
	var line := T.text(T.Key.OP_GIVE_MESSAGE) % tr(m["text"]) if m["from"] == "" else \
		T.text(T.Key.OP_GIVE_MESSAGE_FROM) % [m["from"], tr(m["text"])]
	if await desk.main.conversation.op(c, line) and m.get("reply", "") != "":
		await desk.main.conversation.say(c, m["reply"])


## O operador desligou na cara de quem não se identificou (as três regras registram o "desligou").
func call_ended(c: PhoneCall, reason: PhoneCall.End) -> void:
	if c.meta.get("b1", "ok") != "ok" and reason == PhoneCall.End.OPERATOR and not c.connected:
		desk.log_decision(id, c, "desligou sem transferir (sem identificação)", "permitido")


func debug_info() -> String:
	var items := desk.messages.items
	return "recados na fila: %d%s" % [items.size(), "".join(items.map(func(m): return "\n· para %s (%s, noite %d): %s" % [
		m["to"], m["from"] if m["from"] != "" else "anônimo", m["night"], m["text"]]))]
