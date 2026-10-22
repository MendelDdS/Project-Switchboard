extends BureaucracyRule
## B3. Ligações que exigem código de autorização: transferir para um dos `numbers` pede o código da noite
## (`Bureaucracy.codes`), dito por quem liga logo depois de pedir (`TransferCall.code_line`; o operador vê o aviso de
## que o número exige o código). Sem código ou com o errado, a transferência sai mesmo assim e é infração (gravíssima,
## no `.tres`). Quem pede o próximo código
## (`TransferCall.wants_next_code`) recebe duas opções: revelar (o código da noite seguinte) ou recusar; a escolha vai
## para o registro de decisões e liga um marcador (`revelou_codigo_N` ou `recusou_codigo_N`) para o roteiro.
##
## Roteiro: `activate("b3_codigo")`; `update_params("b3_codigo", {"numbers": PackedStringArray(["390"])})`. O
## supervisor precisa dar o código da noite ao operador (`desk.codes.code(noite)`), no bilhete ou por telefone.

## Os lugares que exigem o código.
@export var numbers := PackedStringArray()
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
	if t == null or not t.wants_next_code or c.meta.has("b3_answered"):
		return []
	return [{"label": T.text(T.Key.CHOICE_REVEAL_CODE), "fn": _answer.bind(c, true)},
		{"label": T.text(T.Key.CHOICE_REFUSE_CODE), "fn": _answer.bind(c, false)}]


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


func debug_info() -> String:
	var next := PackedStringArray()
	for i in range(1, preview_nights + 1):
		next.append("N%d %s" % [desk.night + i, desk.codes.code(desk.night + i)])
	return "código da noite %d: %s\npróximas: %s" % [desk.night, tonight(), ", ".join(next)]
