extends "res://tests/test_base.gd"
## O núcleo das burocracias (`Bureaucracy`, `BureaucracyRule`) com regras de teste feitas aqui: desligado, nada muda;
## ligado, os ganchos chegam às regras, a infração mais grave da tentativa vira a advertência (todas no registro), o
## número errado não soma outra advertência menor ou igual, e as regras ligam, desligam e mudam na hora.
## O relógio fica parado (`running = false`), como no `test_penalties`.

var m: Main
var b: Switchboard
var C: GameContent = GameData.CONTENT
const LURDES := "res://data/calls/transfer_01_dona_lurdes_farmacia_santa_rita.tres"   # pede a Farmácia Santa Rita (162)


## Regra de teste: toda transferência é infração na gravidade dela; conta os ganchos e oferece uma opção.
class Strict extends BureaucracyRule:
	var started := 0
	var ended := 0
	var done := 0
	var line := ""   ## dita por quem liga no começo, se não vazia

	func call_started(_c: PhoneCall) -> Array:
		started += 1
		return [] if line == "" else [line]

	func choices(_c: PhoneCall) -> Array[Dictionary]:
		return [{"label": "[Teste %s]" % id, "fn": func(): pass}]

	func before_transfer(_c: PhoneCall, d: int) -> Verdict:
		return infraction("destino %d" % d)

	func transfer_done(_c: PhoneCall) -> void:
		done += 1

	func call_ended(_c: PhoneCall, _r: PhoneCall.End) -> void:
		ended += 1


func _rule(id: String, sev: ShiftReport.Severity) -> Strict:
	var r := Strict.new()
	r.id = id
	r.severity = sev
	r.active = true
	m.bureaucracy.register(r)
	return r


func _move(e: int, j: int) -> void:
	if b.ends[e] != -1:
		b.pick_up(e)
	else:
		b.held = e
	if j == -1:
		b.go_home(e)
	else:
		ok(b.place(e, j), "não encaixou %d em %d" % [e, j])


func _clear_board() -> void:
	for e in b.ends.size():
		if b.ends[e] != -1:
			_move(e, -1)


func _faults(id: String) -> int:
	return m.report.faults.filter(func(f): return f["id"] == id).size()


## Uma transferência da Dona Lurdes até o destino `d` atender (ou ela desistir).
func _transfer_to(d: int) -> PhoneCall:
	var c := PhoneCall.from_transfer(load(LURDES))
	m.ring(c)
	_move(0, c.line)
	m.answer()
	ok(await wait_until(func(): return c.phase == PhoneCall.Phase.AWAIT and not c.talking), "pedido")
	_move(1, c.line + 10)
	_move(2, d)
	m.transfer()
	ok(await wait_until(func(): return c.connected or c.wrong > 0), "o destino atendeu")
	return c


## Toca, atende e espera o pedido da ligação de teste `t`.
func _call(t: TransferCall) -> PhoneCall:
	var c := PhoneCall.from_transfer(t)
	m.ring(c)
	_move(0, c.line)
	m.answer()
	ok(await wait_until(func(): return c.phase == PhoneCall.Phase.AWAIT and not c.talking), "pedido: " + t.resource_name)
	return c


## Liga a SAÍDA da ligação `c` ao destino `d`, transfere e espera conectar.
func _connect(c: PhoneCall, d: int) -> void:
	_move(1, c.line + 10)
	_move(2, d)
	m.transfer()
	ok(await wait_until(func(): return c.connected), "conectou %d" % d)


## Liga a SAÍDA ao destino `d`, transfere e espera atender (o certo conecta; o errado conta `wrong`).
func _try(c: PhoneCall, d: int) -> void:
	_move(1, c.line + 10)
	_move(2, d)
	m.transfer()
	ok(await wait_until(func(): return c.connected or c.wrong > 0), "o destino %d atendeu" % d)


func _pick(c: PhoneCall, key: T.Key) -> void:
	var o := c.options.filter(func(x): return x["label"] == T.text(key))
	ok(o.size() == 1, "opção " + T.Key.find_key(key))
	o[0]["fn"].call()
	await wait_until(func(): return not c.talking and c.transcript[-1]["cls"] != "op" or c.ended, 5.0)


## A escuta anda um quadro (o relógio do teste fica parado, `running = false`); sempre verdadeiro, para as esperas.
func _ticked() -> bool:
	m.eavesdrop.tick(1.0 / 60.0)
	return true


func _said(c: PhoneCall, text: String) -> bool:
	return c.transcript.any(func(l): return l["text"] == text or text in l["text"])


func _initialize() -> void:
	Engine.time_scale = 8.0
	m = await load_main([1, 2, 3])
	m.sched.clear()
	m._intro.visible = false
	m.running = false
	b = m.board
	m.bureaucracy.reset()

	# ---- 1. chave geral desligada: a regra ligada não vê nada, e o jogo é o de sempre
	var strict := _rule("teste_media", ShiftReport.Severity.MEDIUM)
	var c1 := await _transfer_to(162)
	ok(c1.connected and m.report.faults.is_empty(), "desligado: transferiu sem advertência")
	ok(strict.started == 0 and strict.done == 0 and m.bureaucracy.decisions.is_empty(), "desligado: nenhum gancho")
	ok(not c1.options.any(func(o): return String(o["label"]).begins_with("[Teste")), "desligado: nenhuma opção a mais")
	_clear_board()
	print("OK 1 desligado")

	# ---- 2. ligado: os ganchos chegam e a maior das infrações vira a advertência; todas no registro
	m.report.faults.clear()   # (desmontar a mesa com a conversa ainda ligada cortou a ligação: `cut_call`)
	Bureaucracy.enabled = true
	var grave := _rule("teste_grave", ShiftReport.Severity.SEVERE)
	grave.line = "Linha de teste da burocracia."
	var c2 := PhoneCall.from_transfer(load(LURDES))
	m.ring(c2)
	_move(0, c2.line)
	m.answer()
	ok(await wait_until(func(): return c2.phase == PhoneCall.Phase.AWAIT and not c2.talking), "pedido 2")
	ok(c2.transcript.any(func(l): return l["text"] == grave.line), "a regra fez quem liga falar no começo")
	ok(c2.options.filter(func(o): return String(o["label"]).begins_with("[Teste")).size() == 2, "uma opção de cada regra")
	_move(1, c2.line + 10)
	_move(2, 162)
	m.transfer()
	ok(await wait_until(func(): return c2.connected), "conectou 2")
	ok(m.report.faults.size() == 1 and _faults("teste_grave") == 1, "só a advertência maior")
	ok(ShiftReport.level(m.report.faults[0]) == ShiftReport.Severity.SEVERE, "na gravidade da regra")
	ok(m.bureaucracy.decisions.size() == 2, "as duas infrações no registro")
	ok(strict.done == 1 and grave.done == 1 and strict.ended == 1, "transferência completa e fim da ligação")
	_clear_board()
	print("OK 2 a maior vale, todas registradas")

	# ---- 3. número errado com uma infração grave na mesma tentativa: fica só a grave
	m.report.faults.clear()
	var c3 := await _transfer_to(142)
	ok(_faults("teste_grave") == 1 and _faults("wrong_number") == 0, "número errado não soma à grave")
	ok(m.bureaucracy.decisions.any(func(e): return e["rule"] == "wrong_number"), "o número errado ficou no registro")
	m.hangup()
	_clear_board()
	print("OK 3 número errado com grave")

	# ---- 4. número errado com só uma infração leve: sai a leve, vale o número errado (o maior)
	m.report.faults.clear()
	m.bureaucracy.deactivate("teste_grave")
	m.bureaucracy.update_params("teste_media", {"severity": ShiftReport.Severity.LIGHT})
	var c4 := await _transfer_to(142)
	ok(_faults("teste_media") == 0 and _faults("wrong_number") == 1, "vale o número errado, maior que a leve")
	m.hangup()
	_clear_board()
	print("OK 4 número errado com leve")

	# ---- 5. noites de vigência
	m.report.faults.clear()
	strict.from_night = 5
	ok(m.bureaucracy.live().is_empty(), "fora das noites dela, não vale")
	m.bureaucracy.night = 6
	ok(m.bureaucracy.live().size() == 1 and m.bureaucracy.live()[0] == strict, "na noite simulada 6, vale")
	strict.to_night = 5
	ok(m.bureaucracy.live().is_empty(), "depois da última noite dela, não vale")

	m.bureaucracy.reset()
	ok(not Bureaucracy.enabled and m.bureaucracy.live().is_empty(), "resetar desliga tudo")
	print("OK 5 vigência e reset")

	# ---- 6. B3, os códigos: um por noite, sem repetir, sempre o mesmo para a mesma noite
	var codes := m.bureaucracy.codes
	var seen := {}
	for n in range(0, 16):
		for i in 3:
			seen[codes.code(n, i)] = true
	ok(seen.size() == 16 * 3, "nenhum código repetido")
	ok(codes.code(1) == "K-07" and codes.code(2) == "M-14" and codes.code(3) == codes.code(3), "o padrão provisório")
	print("OK 6 códigos")

	# ---- 7. B3, as ligações de teste do .tres: certo passa, errado e sem código são gravíssimas
	Bureaucracy.enabled = true
	m.bureaucracy.night = 1
	var b3 := m.bureaucracy.rule("b3_codigo")
	b3.active = true
	for t: TransferCall in b3.tests.slice(0, 3):
		m.report.faults.clear()
		var c := PhoneCall.from_transfer(t)
		m.ring(c)
		_move(0, c.line)
		m.answer()
		ok(await wait_until(func(): return c.phase == PhoneCall.Phase.AWAIT and not c.talking), "pedido " + t.resource_name)
		ok((t.code_line == "") == not c.transcript.any(func(l): return "Autorização" in l["text"]), "disse o código: " + t.resource_name)
		ok(_said(c, T.text(T.Key.SYS_NEEDS_CODE) % t.target), "o aviso de que exige o código: " + t.resource_name)
		_move(1, c.line + 10)
		_move(2, int(t.target))
		m.transfer()
		ok(await wait_until(func(): return c.connected), "conectou " + t.resource_name)
		var right := t.code_line.contains("{code}")
		ok(_faults("b3_codigo") == (0 if right else 1), "advertência: " + t.resource_name)
		ok(right or ShiftReport.level(m.report.faults[-1]) == ShiftReport.Severity.CRITICAL, "gravíssima: " + t.resource_name)
		_clear_board()
	ok(m.report.grade() == ShiftReport.Grade.POOR, "a gravíssima deixa a noite Insuficiente")
	var c7 := PhoneCall.from_transfer(b3.tests[3])
	m.ring(c7)
	_move(0, c7.line)
	m.answer()
	ok(await wait_until(func(): return c7.phase == PhoneCall.Phase.AWAIT and not c7.talking), "pedido do próximo código")
	var reveal := c7.options.filter(func(o): return o["label"] == T.text(T.Key.CHOICE_REVEAL_CODE))
	ok(reveal.size() == 1, "opção de revelar")
	reveal[0]["fn"].call()
	ok(await wait_until(func(): return c7.transcript.any(func(l): return codes.code(2) in l["text"])), "revelou o código da noite 2")
	ok(m.flags.has("revelou_codigo_1") and m.bureaucracy.decisions[-1]["rule"] == "b3_codigo", "marcador e registro")
	ok(not c7.options.any(func(o): return o["label"] == T.text(T.Key.CHOICE_REVEAL_CODE)), "a opção some")
	m.hangup()
	_clear_board()
	m.bureaucracy.reset()
	print("OK 7 B3")

	# ---- 8. B1, identificação e recados
	Bureaucracy.enabled = true
	var b1 := m.bureaucracy.rule("b1_identificacao")
	b1.active = true
	var tests := {}
	for t: TransferCall in b1.tests:
		tests[t.resource_name] = t
	var has := func(c: PhoneCall, key: T.Key) -> bool: return c.options.any(func(o): return o["label"] == T.text(key))
	m.report.faults.clear()
	var alone := await _call(tests["Diz o nome sozinho"])
	ok(_said(alone, tests["Diz o nome sozinho"].name_line) and not _said(alone, T.text(T.Key.OP_ASK_NAME)), "disse o nome sem ninguém pedir")
	ok(not has.call(alone, T.Key.CHOICE_REQUEST_ID), "quem diz sozinho não mostra o botão")
	await _connect(alone, 305)
	ok(_faults("b1_identificacao") == 0, "identificado: sem advertência")
	_clear_board()
	var asked := await _call(tests["Diz quando pedem"])
	ok(not _said(asked, T.text(T.Key.OP_ASK_NAME)) and has.call(asked, T.Key.CHOICE_REQUEST_ID), "ninguém pede sozinho: o botão")
	await _pick(asked, T.Key.CHOICE_REQUEST_ID)
	ok(_said(asked, tests["Diz quando pedem"].name_line) and not has.call(asked, T.Key.CHOICE_REQUEST_ID), "pediu, ele disse")
	await _connect(asked, 305)
	ok(_faults("b1_identificacao") == 0, "pediu e ele disse: sem advertência")
	_clear_board()
	var unasked := await _call(tests["Diz quando pedem"])
	await _connect(unasked, 305)
	ok(_faults("b1_identificacao") == 1, "transferiu sem pedir: média")
	_clear_board()
	var never := await _call(tests["Recusa sempre"])
	await _pick(never, T.Key.CHOICE_REQUEST_ID)
	ok(_said(never, tests["Recusa sempre"].refuse_line) and has.call(never, T.Key.CHOICE_PRESS_NAME), "recusou: o botão de insistir")
	await _pick(never, T.Key.CHOICE_PRESS_NAME)
	ok(_said(never, tests["Recusa sempre"].refuse_again_line), "insistiu e ele recusou de novo")
	ok(not has.call(never, T.Key.CHOICE_PRESS_NAME) and not has.call(never, T.Key.CHOICE_REQUEST_ID), "depois disso, nenhum botão de nome")
	m.hangup()
	ok(m.bureaucracy.decisions[-1]["choice"].begins_with("desligou sem transferir"), "desligou sem transferir: registrado")
	_clear_board()
	var pressed := await _call(tests["Cede se insistir"])
	await _pick(pressed, T.Key.CHOICE_REQUEST_ID)
	await _pick(pressed, T.Key.CHOICE_PRESS_NAME)
	ok(_said(pressed, tests["Cede se insistir"].name_line), "insistiu e ele disse o nome")
	await _connect(pressed, 305)
	ok(_faults("b1_identificacao") == 1, "depois de insistir: sem advertência a mais")
	_clear_board()
	var anon := await _call(tests["Recado anônimo"])
	await _pick(anon, T.Key.CHOICE_REFUSE_MESSAGE)
	ok(await wait_until(func(): return anon.ended) and _said(anon, tests["Recado anônimo"].refused_line), "recado recusado: reclamou e desligou")
	ok(m.bureaucracy.messages.items.is_empty(), "nada na fila")
	_clear_board()
	var anon1 := await _call(tests["Recado anônimo"])
	await _pick(anon1, T.Key.CHOICE_REQUEST_ID)
	await _pick(anon1, T.Key.CHOICE_TAKE_MESSAGE)
	ok(await wait_until(func(): return anon1.ended) and m.bureaucracy.messages.waiting("327").size() == 1, "recado anotado: agradeceu e desligou")
	ok(m.bureaucracy.messages.items[0]["from"] == "", "anônimo (recusou o nome)")
	_clear_board()
	var ze := await _call(tests["Destinatário liga"])
	ok(not has.call(ze, T.Key.CHOICE_GIVE_MESSAGE), "sem saber quem é, nada de recado")
	await _pick(ze, T.Key.CHOICE_REQUEST_ID)
	ok(has.call(ze, T.Key.CHOICE_GIVE_MESSAGE), "é o Zé, do bar: o recado")
	await _pick(ze, T.Key.CHOICE_GIVE_MESSAGE)
	ok(_said(ze, "A encomenda chega amanhã cedo."), "o operador deu o recado a quem liga")
	ok(m.bureaucracy.messages.items.is_empty() and _faults("b1_identificacao") == 1, "saiu da fila, sem advertência (padrão)")
	m.hangup()
	_clear_board()
	b1.message_penalty = ShiftReport.Severity.SEVERE
	var anon2 := await _call(tests["Recado anônimo"])
	await _pick(anon2, T.Key.CHOICE_TAKE_MESSAGE)
	await wait_until(func(): return anon2.ended)
	_clear_board()
	var ze2 := await _call(tests["Destinatário liga"])
	await _pick(ze2, T.Key.CHOICE_REQUEST_ID)
	await _pick(ze2, T.Key.CHOICE_GIVE_MESSAGE)
	ok(m.bureaucracy.messages.items.is_empty(), "deu o segundo recado ao Zé")
	m.hangup()
	ok(m.report.faults.any(func(f): return f["id"] == "b1_identificacao" and ShiftReport.level(f) == ShiftReport.Severity.SEVERE),
		"recado anônimo repassado: a advertência configurada")
	var named_msg := await _call(tests["Recado com nome"])
	await _pick(named_msg, T.Key.CHOICE_TAKE_MESSAGE)
	await wait_until(func(): return named_msg.ended)
	ok(m.bureaucracy.messages.items[0]["from"] == "Teste Remetente", "recado com o nome de quem se identificou")
	_clear_board()
	var faults_before := m.report.faults.size()
	var ze3 := await _call(tests["Destinatário liga"])
	await _pick(ze3, T.Key.CHOICE_REQUEST_ID)
	await _pick(ze3, T.Key.CHOICE_GIVE_MESSAGE)
	ok(_said(ze3, T.text(T.Key.OP_GIVE_MESSAGE_FROM) % ["Teste Remetente", tests["Recado com nome"].message]), "o operador diz de quem é")
	ok(m.report.faults.size() == faults_before, "recado com nome: sem advertência, mesmo com a do anônimo ligada")
	m.hangup()
	_clear_board()
	ok(m.bureaucracy.state()["messages"].is_empty() and m.bureaucracy.state()["decisions"].size() > 5, "o que vai para o save")
	_clear_board()
	m.bureaucracy.reset()
	print("OK 8 B1")

	# ---- 9. B2, números bloqueados, janela, urgente, código e acordos com sinal
	Bureaucracy.enabled = true
	var b2 := m.bureaucracy.rule("b2_bloqueados")
	b2.active = true
	var t2 := {}
	for t: TransferCall in b2.tests:
		t2[t.resource_name] = t
	var severe := func() -> int: return m.report.faults.filter(func(f): return f["id"] == "b2_bloqueados" and ShiftReport.level(f) == ShiftReport.Severity.SEVERE).size()
	m.report.faults.clear()
	var x := await _call(t2["Bloqueado (Bilhar, reação sorteada)"])
	await _try(x, 355)
	ok(severe.call() == 1, "bloqueado: grave")
	_clear_board()
	var w := await _call(t2["Bloqueado (Bilhar, reação sorteada)"])
	await _pick(w, T.Key.CHOICE_WARN_BLOCKED)
	ok(_said(w, T.text(T.Key.SYS_BLOCKED) % "355"), "o aviso do bloqueio depois do pedido")
	ok(_said(w, T.text(T.Key.OP_WARN_BLOCKED)) and m.bureaucracy.decisions[-1]["result"] == "permitido", "avisou o bloqueio: permitido")
	ok(await wait_until(func(): return w.ended) and Array(b2.reactions).any(func(r): return _said(w, r)), "quem ligou reagiu (sorteada) e desligou")
	m.hangup()
	_clear_board()
	var aw := PhoneCall.from_transfer(t2["Bloqueado (Bilhar, reação sorteada)"])
	aw.away = true
	m.ring(aw)
	_move(0, aw.line)
	m.answer()
	ok(await wait_until(func(): return aw.phase == PhoneCall.Phase.AWAIT) and not aw.away, "bloqueado não fica sem atender")
	m.hangup()
	_clear_board()
	m.minutes = 60.0   # 19:00: o bar ainda está liberado
	var bar2 := await _call(t2["Bar (liberado até 21h)"])
	ok(_said(bar2, T.text(T.Key.SYS_FREE_UNTIL) % ["327", "21:00"]), "o aviso: liberado até as 21h")
	await _try(bar2, 327)
	ok(severe.call() == 1 and m.bureaucracy.decisions[-1]["result"].contains("horário"), "bar antes das 21h: liberado")
	_clear_board()
	m.minutes = 179.9   # 20:59: bate 21h com a ligação esperando
	var bar21 := await _call(t2["Bar (liberado até 21h)"])
	ok(not bar21.options.any(func(o): return o["label"] == T.text(T.Key.CHOICE_WARN_BLOCKED)), "20:59: sem o botão de avisar")
	m.minutes = 180.5
	ok(await wait_until(func(): return bar21.options.any(func(o): return o["label"] == T.text(T.Key.CHOICE_WARN_BLOCKED))), "bateu 21h: o botão aparece")
	m.hangup()
	_clear_board()
	m.minutes = 200.0   # 21:20
	var bar3 := await _call(t2["Bar (liberado até 21h)"])
	await _try(bar3, 327)
	ok(severe.call() == 2, "bar depois das 21h: grave")
	_clear_board()
	m.minutes = 0.0
	var urg0 := await _call(t2["Urgente para bloqueado"])
	m.hangup()
	ok(m.bureaucracy.decisions.any(func(e): return e["choice"].begins_with("desligou a ligação urgente")), "urgente desligado sem avisar: decisão moral")
	_clear_board()
	var urg := await _call(t2["Urgente para bloqueado"])
	await _try(urg, 355)
	ok(severe.call() == 3 and m.bureaucracy.decisions.any(func(e): return e["choice"].begins_with("aceitou a ligação urgente")), "urgente aceito: grave e decisão moral")
	_clear_board()
	var cod := await _call(t2["Código certo libera (Funerária)"])
	var at := func(c: PhoneCall, text: String) -> int: return c.transcript.find_custom(func(l): return text in l["text"])
	ok(at.call(cod, m.bureaucracy.codes.code(1)) > at.call(cod, "A Funerária Paz Eterna, por favor"), "pediu e só depois disse o código (a B3 desligada)")
	ok(at.call(cod, T.text(T.Key.SYS_BLOCKED_CODE) % "399") != -1, "o aviso: bloqueado, só com o código")
	ok(not cod.options.any(func(o): return o["label"] == T.text(T.Key.CHOICE_WARN_BLOCKED)), "com o código certo, nada a avisar")
	await _try(cod, 399)
	ok(severe.call() == 3, "código certo libera")
	_clear_board()
	var bad := await _call(t2["Código errado (Funerária)"])
	ok(_said(bad, "Z-99") and bad.options.any(func(o): return o["label"] == T.text(T.Key.CHOICE_WARN_BLOCKED)), "código errado: continua bloqueado")
	await _try(bad, 399)
	ok(severe.call() == 4, "código errado: grave, como bloqueado comum")
	_clear_board()
	var nocod := await _call(t2["Sem código (Funerária)"])
	ok(_said(nocod, T.text(T.Key.SYS_BLOCKED_CODE) % "399"), "sem código: o aviso de que só com autorização")
	await _try(nocod, 399)
	ok(severe.call() == 5, "sem código: bloqueado comum, grave")
	_clear_board()
	# os quatro casos do acordo (X = 355 bloqueado, Y = 336)
	var sig := await _call(t2["Acordo: pede o Bilhar com o sinal"])
	ok(sig.target == "355", "sem acordo, o sinal não muda nada")
	m.hangup()
	_clear_board()
	var no_deal := await _call(t2["Propõe o acordo"])
	await _pick(no_deal, T.Key.CHOICE_REFUSE_DEAL)
	ok(await wait_until(func(): return no_deal.ended) and _said(no_deal, t2["Propõe o acordo"].refused_line), "recusado: reclamou e desligou")
	ok(m.bureaucracy.agreements.items.is_empty(), "recusado: sem acordo")
	_clear_board()
	var deal := await _call(t2["Propõe o acordo"])
	await _pick(deal, T.Key.CHOICE_ACCEPT_DEAL)
	ok(m.bureaucracy.agreements.items.size() == 1, "acordo aceito")
	ok(await wait_until(func(): return deal.ended) and _said(deal, t2["Propõe o acordo"].thanks), "agradeceu e desligou")
	m.hangup()
	_clear_board()
	m.report.faults.clear()
	var sy := await _call(t2["Acordo: pede o Bilhar com o sinal"])
	ok(sy.target == "355", "com o sinal, o pedido continua sendo o Bilhar")
	ok(_said(sy, T.text(T.Key.SYS_BLOCKED) % "355") and sy.options.any(func(o): return o["label"] == T.text(T.Key.CHOICE_WARN_BLOCKED)),
		"com o sinal, o aviso e o botão continuam sendo do número pedido")
	await _try(sy, 336)
	ok(sy.connected and sy.target == "336" and m.report.faults.is_empty(), "X com sinal → Y: permitido, sem advertência")
	_clear_board()
	var sx := await _call(t2["Acordo: pede o Bilhar com o sinal"])
	m.bureaucracy.before_transfer(sx, 336)   # tentou Y antes e desfez: X continua valendo
	await _try(sx, 355)
	ok(sx.connected and sx.wrong == 0 and sx.target == "355" and severe.call() == 1, "X com sinal → X (depois de tentar Y): conversa normal, só a grave")
	m.hangup()
	_clear_board()
	var nx := await _call(t2["Acordo: pede o Bilhar sem o sinal"])
	await _try(nx, 355)
	ok(severe.call() == 2 and _faults("wrong_number") == 0, "X sem sinal → X: grave")
	_clear_board()
	var ny := await _call(t2["Acordo: pede o Bilhar sem o sinal"])
	await _try(ny, 336)
	ok(_faults("wrong_number") == 1 and severe.call() == 2, "X sem sinal → Y: número errado comum")
	m.hangup()
	_clear_board()
	m.bureaucracy.reset()
	print("OK 9 B2")

	# ---- 10. B4, equipamentos e fitas
	ok(b.equipped.is_empty() and m.bureaucracy.equipment().is_empty(), "sem a B4, nada na prateleira")
	var arrivals := []
	m.bureaucracy.equipment_unlocked.connect(func(id: String): arrivals.append(id))
	var tp := m.bureaucracy.tapes
	m.running = true   # com o turno andando: a regra ligada antes da chave geral começa quando a chave liga
	m.bureaucracy.activate("b4_fitas")
	ok(arrivals.is_empty() and tp.blank == 0, "chave geral desligada: nada chega")
	m.bureaucracy.enable(true)
	m.running = false
	ok(arrivals == ["porta_fitas", "gravador"] and b.equipped.size() == 2, "a B4 valendo traz os dois equipamentos")
	ok(tp.blank == 3, "e as três fitas da noite, mesmo ligada no meio do turno")
	m.bureaucracy.deactivate("b4_fitas")
	m.bureaucracy.activate("b4_fitas")
	ok(arrivals.size() == 2 and b.equipped.size() == 2, "desligada e ligada de novo: ficam, e a chegada não se repete")
	var rack: Control = b._equipment["porta_fitas"]
	m.bureaucracy.night_started()
	ok(tp.blank == 3, "três fitas virgens")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	rack._gui_input(click)
	ok(tp.blank == 2 and not tp.inside.is_empty(), "clicar no porta-fitas põe uma no gravador")
	m.report.credits.clear()
	var t4: Array = m.bureaucracy.rule("b4_fitas").tests
	var sus := await _call(t4[0])
	ok(_said(sus, T.text(T.Key.SYS_RECORD_REQUEST)), "o aviso das autoridades")
	await _connect(sus, 312)
	m.listen()
	ok(m.eavesdrop.listening(sus.line) and tp.recording(), "escutando com fita: grava")
	ok(await wait_until(func(): return _ticked() and m.eavesdrop.clues.filter(func(k: Clue): return k.call == sus).size() == 4, 120.0), "ouviu as quatro palavras")
	var words: Array = tp.inside["words"]
	ok(words == ["estação velha", "dez", "pacote", "Ramiro"], "palavras-chave na fita: %s" % [words])
	var recorder: Control = b._equipment["gravador"]
	recorder._hover = 0   # a tecla Entregar
	recorder._gui_input(click)
	ok(tp.inside.is_empty() and tp.done[-1]["value"] == words.size() * 10, "entregue: o valor pelas palavras")
	ok(m.report.credits.any(func(c): return c["id"] == "tape" and c["pts"] == words.size() * 10), "pontos de eficiência pela fita")
	_clear_board()
	tp.insert()
	var calm := await _call(t4[1])
	await _connect(calm, 312)
	m.listen()
	ok(await wait_until(func(): return _ticked() and m.eavesdrop.speaking(calm.line), 20.0), "a conversa sem nada começou")
	ok(await wait_until(func(): return _ticked() and not m.eavesdrop.speaking(calm.line), 120.0), "a conversa sem nada terminou")
	tp.eject(true)
	ok(tp.done[-1]["value"] == 0 and tp.done[-1]["words"].is_empty(), "nada relevante: valor zero")
	_clear_board()
	m.bureaucracy.night_ended()
	ok(not m.flags.has("authorities_questioning_pending"), "gravou: as autoridades não questionam")
	m.bureaucracy.night_started()
	var skip := await _call(t4[1])
	m.hangup()
	_clear_board()
	m.bureaucracy.night_ended()
	ok(m.flags.has("authorities_questioning_pending"), "noite com pedido e sem gravação: o marcador para o roteiro")
	m.bureaucracy.lock_equipment("porta_fitas")
	ok(b.equipped == PackedStringArray(["gravador"]), "o roteiro pode tirar um equipamento")
	m.bureaucracy.reset()
	print("OK 10 B4")

	# ---- 11. a regra de exemplo (feita só pelo guia): desligada por padrão; ligada, a ligação longa leva advertência
	var ex := m.bureaucracy.rule("exemplo_duracao")
	ok(ex != null and not ex.active, "o exemplo existe e vem desligado")
	Bureaucracy.enabled = true
	m.bureaucracy.activate("exemplo_duracao")
	m.bureaucracy.update_params("exemplo_duracao", {"max_minutes": 5.0})
	m.report.faults.clear()
	var long := await _call(ex.tests[0])
	m.minutes += 6.0
	m.hangup()
	ok(_faults("exemplo_duracao") == 1, "passou do limite: advertência")
	_clear_board()
	m.bureaucracy.reset()
	print("OK 11 exemplo")
	finish("bureaucracy")
