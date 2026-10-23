extends BureaucracyRule
## B3. Ligações que exigem código de autorização: transferir para um dos `numbers` pede o código da noite
## (`Bureaucracy.codes`), dito por quem liga logo depois de pedir (`TransferCall.code_line`; o operador vê o aviso de
## que o número exige o código). Se ele não diz, o operador pode pedir ([Pedir a autorização]): quem tem lembra e diz
## (`TransferCall.code_when_asked`); quem não tem reage (`refused_line` ou uma das `reactions`, sorteada) e desliga.
## Sem código ou com o errado, a transferência sai mesmo assim e é infração (gravíssima, no `.tres`). Quem pede o
## próximo código
## (`TransferCall.wants_next_code`) recebe duas opções: revelar (o código da noite seguinte) ou recusar; a escolha vai
## para o registro de decisões e liga um marcador (`revelou_codigo_N` ou `recusou_codigo_N`) para o roteiro.
##
## Roteiro: `activate("b3_codigo")`; `update_params("b3_codigo", {"numbers": PackedStringArray(["390"])})`. O
## supervisor precisa dar o código da noite ao operador (`desk.codes.code(noite)`), no bilhete ou por telefone.

## Os lugares que exigem o código.
@export var numbers := PackedStringArray()
## Reações de quem não tem o código quando o operador pede (sem `refused_line`): uma sorteada.
@export var reactions := PackedStringArray()
## Debug: quantas noites seguintes mostrar com o código.
@export var preview_nights := 4


## O código certo desta noite.
func tonight() -> String:
	return desk.codes.code(desk.night)


## Depois do pedido: o aviso de que o número exige o código e o código de quem liga (o certo ou o que tem escrito).
func request_made(c: PhoneCall) -> Array:
	var out := []
	if c.target in numbers:
		out.append({"sys": T.text(T.Key.SYS_NEEDS_CODE) % c.target})
	return out + desk.code_line(c)


func before_transfer(c: PhoneCall, d: int) -> Verdict:
	if not str(d) in numbers or not c.data is TransferCall:
		return null
	match desk.code_of(c):
		-1:
			return infraction("sem código (%d)" % d)
		0:
			return infraction("código errado (%d)" % d)
	return Verdict.allowed("código certo")


func choices(c: PhoneCall) -> Array[Dictionary]:
	var t := c.data as TransferCall
	var out: Array[Dictionary] = []
	if t == null:
		return out
	if c.target in numbers and not c.meta.has("code_said") and not c.meta.has("b3_asked"):
		out.append({"label": T.text(T.Key.CHOICE_ASK_CODE), "fn": _ask.bind(c)})
	if t.wants_next_code and not c.meta.has("b3_answered"):
		out.append({"label": T.text(T.Key.CHOICE_REVEAL_CODE), "fn": _answer.bind(c, true)})
		out.append({"label": T.text(T.Key.CHOICE_REFUSE_CODE), "fn": _answer.bind(c, false)})
	return out


## O operador avisou que o número só passa com o código: quem tem lembra e diz; quem não tem reage e desliga.
func _ask(c: PhoneCall) -> void:
	if c.talking:
		return
	c.meta["b3_asked"] = true
	var code := desk.code_line(c, true)
	desk.main.conversation.transfer_choices(c)
	desk.log_decision(id, c, "pediu o código de autorização", "disse o código" if not code.is_empty() else "não tinha; desistiu")
	if not await desk.main.conversation.op(c, T.text(T.Key.OP_ASK_CODE)):
		return
	if code.is_empty():
		await desk.hang_up_after(c, desk.refusal(c, reactions))
	elif await desk.main.conversation.say(c, code[0]):
		desk.main.conversation.transfer_choices(c)


## O operador revelou (`reveal`) ou recusou o próximo código: decisão de alto peso para o roteiro.
func _answer(c: PhoneCall, reveal: bool) -> void:
	if c.talking:
		return
	c.meta["b3_answered"] = true
	desk.main.conversation.transfer_choices(c)
	var next := desk.codes.code(desk.night + 1)
	desk.log_decision(id, c, "revelou o próximo código (%s)" % next if reveal else "recusou dar o próximo código",
		"alto peso narrativo")
	desk.main.flags.apply(("revelou_codigo_%d" if reveal else "recusou_codigo_%d") % desk.night)
	await desk.main.conversation.op(c, T.text(T.Key.OP_REVEAL_CODE) % next if reveal else T.text(T.Key.OP_REFUSE_CODE))


## O operador desligou sem transferir quem pedia um número com código e não disse o certo.
func call_ended(c: PhoneCall, reason: PhoneCall.End) -> void:
	if c.data is TransferCall and reason == PhoneCall.End.OPERATOR and not c.connected and c.target in numbers \
			and desk.code_of(c) != 1:
		desk.log_decision(id, c, "desligou sem o código certo (%s)" % c.target, "permitido")


func debug_info() -> String:
	var next := PackedStringArray()
	for i in range(1, preview_nights + 1):
		next.append("N%d %s" % [desk.night + i, desk.codes.code(desk.night + i)])
	return "código da noite %d: %s\npróximas: %s" % [desk.night, tonight(), ", ".join(next)]
