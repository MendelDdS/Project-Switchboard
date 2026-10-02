extends "res://tests/test_base.gd"
## Consequências e relatório do supervisor: ligação perdida e retorno, número errado (duas vezes = desiste),
## registro errado, despacho no endereço errado (retorno e novo despacho), emergência sem despacho (tarde demais),
## espera longa, informação errada e o relatório das 06:00.
## O relógio fica parado (`running = false`): os retornos agendados são tocados à mão.
## `m` e `b` ficam sem tipo: Main e Switchboard usam o autoload Sfx (veja test_flow.gd).

var m   # Main
var b   # Switchboard
var ex: Exchange
var C: GameContent = GameData.CONTENT


func _move(e: int, j: int) -> void:
	if b.ends[e] != -1:
		b.pick_up(e)
	else:
		b.held = e
	if j == -1:
		b.go_home(e)
	else:
		ok(b.place(e, j), "não encaixou %d em %d" % [e, j])


func _faults(id: String) -> int:
	return m.report.faults.filter(func(f): return f["id"] == id).size()


## Tira a ligação agendada para ligar de novo e faz tocar agora.
func _ring_retry(why: PhoneCall.Retry) -> PhoneCall:
	var r: PhoneCall = null
	for c in m.sched:
		if c.retry == why:
			r = c
	ok(r != null, "ninguém agendado para ligar de novo (%d)" % why)
	m.sched.erase(r)
	m.ring(r)
	return r


func _answer(c: PhoneCall) -> void:
	_move(0, c.line)
	m.answer()


func _said(c: PhoneCall, pool: PackedStringArray) -> bool:
	return c.transcript.any(func(l): return l["text"] in pool)


func _clear_board() -> void:
	for e in b.ends.size():
		if b.ends[e] != -1:
			_move(e, -1)


func _initialize() -> void:
	Engine.time_scale = 8.0
	m = await load_main()
	m.sched.clear()
	m._intro.visible = false
	m.running = false
	b = m.board
	ex = m.exchange

	# ---- 1. não atendeu: advertência média e a pessoa liga de novo, reclamando
	var t: TransferCall = GameData.transfers(TransferCall.Group.EXTRA)[0]
	var c1 := PhoneCall.from_transfer(t)
	m.ring(c1)
	ok(await wait_until(func(): return c1.ended, 10.0), "desistiu de esperar")
	ok(_faults("missed") == 1, "advertência: não atendida")
	var r1 := _ring_retry(PhoneCall.Retry.MISSED)
	_answer(r1)
	ok(await wait_until(func(): return _said(r1, C.retry_missed)), "reclamou que ninguém atendeu")
	m.hangup()
	_clear_board()
	print("OK 1 não atendida / liga de novo")

	# ---- 2. número errado: quem atende reclama; na segunda vez o solicitante desiste
	var c2 := PhoneCall.from_transfer(load("res://data/calls/transfer_01_dona_lurdes_farmacia_santa_rita.tres"))
	m.ring(c2)
	_answer(c2)
	ok(await wait_until(func(): return c2.phase == PhoneCall.Phase.AWAIT and not c2.talking), "pedido")
	_move(1, c2.line + 10)
	_move(2, 142)
	m.transfer()
	ok(await wait_until(func(): return _said(c2, C.woken_up)), "quem atendeu no número errado reclamou")
	ok(_faults("wrong_number") == 1, "advertência: número errado")
	ok(await wait_until(func(): return _said(c2, C.wrong_destination) and not c2.talking), "solicitante reclamou")
	_move(2, -1)
	_move(2, 305)
	m.transfer()
	ok(await wait_until(func(): return c2.ended), "desistiu na segunda conexão errada")
	ok(_said(c2, C.gave_up) and not c2.connected and _faults("wrong_number") == 2, "duas advertências, sem conexão")
	_clear_board()
	print("OK 2 número errado / desiste na segunda")

	# ---- 2b. número errado com o FONE fora: foi engano, os dois desligam e o solicitante liga de novo
	var c2b := PhoneCall.from_transfer(load("res://data/calls/transfer_01_dona_lurdes_farmacia_santa_rita.tres"))
	m.ring(c2b)
	_answer(c2b)
	ok(await wait_until(func(): return c2b.phase == PhoneCall.Phase.AWAIT and not c2b.talking), "pedido 2b")
	_move(1, c2b.line + 10)
	_move(2, 142)
	m.transfer()
	_move(0, -1)              # tira o FONE com o destino errado ainda tocando
	ok(await wait_until(func(): return c2b.ended), "desligaram")
	ok(not c2b.connected and ex.dest(142) == Exchange.Dest.DONE and _faults("wrong_number") == 3, "não completa com o número errado")
	ok(c2b.record["obs"] == T.text(T.Key.OBS_WRONG_NUMBER), "caderno: número errado")
	var r2b := _ring_retry(PhoneCall.Retry.WRONG_NUMBER)
	_clear_board()
	_answer(r2b)
	ok(await wait_until(func(): return r2b.phase == PhoneCall.Phase.AWAIT and not r2b.talking), "ligou de novo e pediu de novo")
	ok(_said(r2b, C.retry_wrong_number), "reclamou do número errado")
	m.hangup()
	_clear_board()
	print("OK 2b número errado com o FONE fora / liga de novo")

	# ---- 2c. o mesmo fluxo liga de novo também na ligação do tutorial, numa ligação que já era um retorno
	#          e perto do fim do turno (o retorno nunca fica para depois da meia-noite)
	for kind in ["tutorial", "retorno", "fim do turno"]:
		var cc: PhoneCall = m.tut if kind == "tutorial" else PhoneCall.from_transfer(load("res://data/calls/transfer_01_dona_lurdes_farmacia_santa_rita.tres"))
		if kind == "retorno":
			cc.retry = PhoneCall.Retry.MISSED
			cc.retried.append(PhoneCall.Retry.MISSED)
		if kind == "fim do turno":
			m.minutes = m.SHIFT_END - 3.0
		m.ring(cc)
		_answer(cc)
		ok(await wait_until(func(): return cc.phase == PhoneCall.Phase.AWAIT and not cc.talking), "pedido: " + kind)
		var wrong_dest := 142 if cc.target != "142" else 305
		_move(1, cc.line + 10)
		_move(2, wrong_dest)
		m.transfer()
		_move(0, -1)
		ok(await wait_until(func(): return cc.ended), "desligaram: " + kind)
		var again: Array = m.sched.filter(func(r): return r.retry == PhoneCall.Retry.WRONG_NUMBER and r.caller == cc.caller)
		ok(again.size() == 1, "vai ligar de novo: " + kind)
		ok(again[0].at <= m.SHIFT_END, "liga de novo antes do fim do turno: " + kind)
		m.sched.erase(again[0])
		_clear_board()
	m.minutes = 0.0
	print("OK 2c número errado com o FONE fora: tutorial, retorno e fim do turno")

	# ---- 3. registro com tipo errado
	var nb = m.notebook
	while nb.has_pending():
		nb.register(T.Key.TYPE_COMMON)
	var before := _faults("register_wrong")
	var prank := {"time": "23:00", "who": "Garoto (linha 01)", "where": "—", "unit": "—", "obs": "",
		"kind": PhoneCall.Kind.PRANK, "missed": false, "tut": false}
	nb.add(prank.duplicate())
	nb.register(T.Key.TYPE_COMMON)
	ok(_faults("register_wrong") == before + 1, "trote registrado como ligação comum")
	nb.add(prank.duplicate())
	nb.register(T.Key.TYPE_PRANK)
	ok(_faults("register_wrong") == before + 1, "tipo certo não gera advertência")
	print("OK 3 registro errado")

	# ---- 4. despacho no endereço errado: rádio reclama, unidades voltam, a pessoa liga de novo e dá para refazer
	var e4: EmergencyCall = C.emergencies[0]
	var c4 := PhoneCall.from_emergency(e4)
	m.ring(c4)
	_answer(c4)
	ok(await wait_until(func(): return c4.phase == PhoneCall.Phase.EMERGENCY and not c4.talking), "emergência")
	var wrong_street := "flores" if e4.street != "flores" else "sol"
	m.dispatch.set_location(wrong_street, 0, "Endereço errado")
	m.dispatch.set_occurrence(e4.occurrence)
	for u in e4.units:
		(m.dispatch._unit_buttons[u] as Button).button_pressed = true
	m.dispatch._send()
	ok(not c4.secured and c4.urgent(), "endereço errado não para a barra de agravamento")
	ok(await wait_until(func(): return c4.ended, 20.0), "agradeceu e desligou")
	ok(await wait_until(func(): return _faults("dispatch_wrong_place") == 1, 20.0), "advertência grave: endereço errado")
	ok(await wait_until(func(): return m.dispatch._units.values().all(func(s): return s == 0), 10.0), "unidades disponíveis")
	var r4 := _ring_retry(PhoneCall.Retry.WORSE)
	r4.too_late = false
	_answer(r4)
	ok(await wait_until(func(): return r4.phase == PhoneCall.Phase.EMERGENCY and not r4.talking), "ligou de novo")
	ok(_said(r4, C.retry_worse), "reclamou que piorou")
	m.dispatch.set_location(e4.street, e4.block, e4.address)
	m.dispatch.set_occurrence(e4.occurrence)
	for u in e4.units:
		(m.dispatch._unit_buttons[u] as Button).button_pressed = true
	m.dispatch._send()
	ok(await wait_until(func(): return m.report.is_resolved(e4), 20.0), "resolvida no segundo despacho")
	ok(m.report.outcomes()[e4] == ShiftReport.Outcome.LATE, "no jornal: com atraso")
	_clear_board()
	print("OK 4 despacho errado / liga de novo / novo despacho")

	# ---- 5. emergência encerrada sem despacho; quando liga de novo já é tarde
	var e5: EmergencyCall = C.emergencies[1]
	var c5 := PhoneCall.from_emergency(e5)
	m.ring(c5)
	_answer(c5)
	ok(await wait_until(func(): return c5.phase == PhoneCall.Phase.EMERGENCY and not c5.talking), "emergência 2")
	m.hangup()
	ok(_faults("emergency_dropped") == 1, "advertência grave: sem despacho")
	var r5 := _ring_retry(PhoneCall.Retry.WORSE)
	r5.too_late = true
	_answer(r5)
	ok(await wait_until(func(): return r5.ended), "tarde demais: desligou")
	ok(_said(r5, C.retry_too_late) and m.report.outcomes()[e5] == ShiftReport.Outcome.BAD, "no jornal: ninguém foi")
	_clear_board()
	print("OK 5 sem despacho / tarde demais")

	# ---- 6. espera longa: a pessoa desiste
	var c6 := PhoneCall.from_transfer(GameData.transfers(TransferCall.Group.EXTRA)[1])
	m.ring(c6)
	_answer(c6)
	_move(0, -1)
	ok(ex.line(c6.line) == Exchange.Line.HOLD, "em espera")
	c6.hold_since = m.minutes - m.HOLD_GIVE_UP - 1.0
	m._check_hold()
	ok(c6.ended and _faults("hold") == 1, "desistiu na espera")
	ok(m.sched.any(func(r): return r.retry == PhoneCall.Retry.MISSED and r.caller == c6.caller), "vai ligar de novo")
	_clear_board()
	print("OK 6 espera longa")

	# ---- 7. informação errada: advertência leve e a pessoa liga de novo
	var c7 := PhoneCall.info("f", "Moça", "Qual é o número do Hotel Estrela?", "o Hotel Estrela", "305")
	m.ring(c7)
	_answer(c7)
	ok(await wait_until(func(): return c7.phase == PhoneCall.Phase.INFO and not c7.talking), "pedido de informação")
	var wrong_opt: Dictionary = c7.options.filter(func(o): return not "305" in String(o["label"]))[0]
	wrong_opt["fn"].call()
	ok(await wait_until(func(): return c7.ended), "desligou")
	ok(_faults("wrong_info") == 1, "advertência: informação errada")
	var r7 := _ring_retry(PhoneCall.Retry.WRONG_INFO)
	_answer(r7)
	ok(await wait_until(func(): return _said(r7, C.retry_wrong_info)), "reclamou da informação")
	m.hangup()
	_clear_board()
	print("OK 7 informação errada")

	# ---- 8. despacho no lugar certo, mas com unidade a mais e tipo de ocorrência errado; sem tipo não envia
	var e8: EmergencyCall = C.emergencies.filter(func(x): return Array(x.units) == ["amb"])[0]
	var c8 := PhoneCall.from_emergency(e8)
	m.ring(c8)
	_answer(c8)
	ok(await wait_until(func(): return c8.phase == PhoneCall.Phase.EMERGENCY and not c8.talking), "emergência 3")
	await wait_until(func(): return m.dispatch._units.values().all(func(s): return s == 0), 30.0)
	m.dispatch.set_location(e8.street, e8.block, e8.address)
	m.dispatch.set_occurrence("")
	for u in ["amb", "bomb"]:
		(m.dispatch._unit_buttons[u] as Button).button_pressed = true
	m.dispatch._send()
	ok(not c8.dispatched and not m.dispatch.can_send() and m.dispatch._send_button.disabled, "sem tipo de ocorrência não envia (Enviar apagado)")
	var wrong_type: String = "Incêndio" if e8.occurrence != "Incêndio" else "Outro"
	m.dispatch.set_occurrence(wrong_type)
	for u in ["amb", "bomb"]:
		(m.dispatch._unit_buttons[u] as Button).button_pressed = true
	m.dispatch._send()
	ok(await wait_until(func(): return m.report.is_resolved(e8), 20.0), "resolvida mesmo com unidade a mais")
	ok(_faults("dispatch_extra") == 1 and _faults("dispatch_type") == 1, "advertências: unidade a mais e tipo errado")
	ok(m.report.outcomes()[e8] == ShiftReport.Outcome.OK, "no jornal: a tempo")
	ok(await wait_until(func(): return m.dispatch._units["bomb"] == 0, 10.0) and m.dispatch._units["amb"] != 0,
		"bombeiros liberados antes da ambulância")
	_clear_board()
	print("OK 8 unidade a mais / tipo errado")

	# ---- 9. relatório do supervisor
	var view = m._ending._report
	view.show_report(m.report)
	var text: String = view._body.get_parsed_text()
	ok(T.text(T.Key.REPORT_WARNINGS) in text and T.text(T.Key.REPORT_NEWS) in text and e4.address in text and e5.address in text, "relatório com advertências e jornal")
	ok(m.report.verdict() == 2 and view._verdict.text == C.verdicts[2], "parecer: turno ruim")
	var sev: int = m.report.count(ShiftReport.Severity.SEVERE)
	m.report.severe_before = ShiftReport.SEVERE_LIMIT - sev - 1
	ok(not m.report.fired(), "ainda não foi demitido")
	m.report.severe_before += 1
	ok(m.report.fired(), "graves acumuladas entre as noites: demitido")
	print("OK 9 relatório (%d advertências)" % m.report.faults.size())

	# ---- 10. barra de agravamento (o relógio está parado: a barra anda por _worsen chamado à mão)
	var e10: EmergencyCall = C.emergencies.filter(func(x): return not x in [e4, e5, e8] and not x.worsening_units.is_empty() and not x.critical_units.is_empty())[0]
	var c10 := PhoneCall.from_emergency(e10)
	m.ring(c10)
	_answer(c10)
	m._worsen(1.0)
	ok(c10.urgency > 0.0 and c10.stage == 0, "a barra corre desde que atendeu")
	ok(await wait_until(func(): return c10.phase == PhoneCall.Phase.EMERGENCY and not c10.talking), "emergência 4")
	c10.options[0]["fn"].call()   # uma pergunta: a barra para até a resposta terminar
	await frames(2)
	var u10 := c10.urgency
	m._worsen(5.0)
	ok(c10.asking and c10.urgency == u10, "pausada durante pergunta e resposta")
	ok(await wait_until(func(): return not c10.asking), "respondeu")
	m._worsen(e10.stage_sec.x)
	ok(c10.stage == 1 and Array(m.dispatch.required()) == Array(e10.required(1)), "agravando: passa a exigir mais unidades")
	ok(await wait_until(func(): return c10.transcript.any(func(l): return l["text"] == e10.worsening)), "contou o que piorou")
	ok(await wait_until(func(): return c10.options.any(func(o): return o["label"] == e10.worsening_question)), "pergunta nova sobre o que mudou")
	var w10 := _faults("emergency_worse")
	await wait_until(func(): return m.dispatch._units.values().all(func(s): return s == 0), 30.0)
	m._worsen(0.0)
	ok(m.radio._alert == 1, "luz de ocorrência no rádio, na cor do estágio")
	var need: Array = m.dispatch.required()
	ok(need.size() >= 2, "o caso testado precisa de duas unidades")
	# só uma unidade: a pessoa desliga, mas a barra continua (e o rádio segue com a luz acesa)
	m.dispatch.set_location(e10.street, e10.block, e10.address)
	m.dispatch.set_occurrence(e10.occurrence)
	(m.dispatch._unit_buttons[need[0]] as Button).button_pressed = true
	m.dispatch._send()
	var u_part := c10.urgency
	m._worsen(1.0)
	ok(c10.urgent() and c10.urgency > u_part and _faults("emergency_worse") == w10 and m.radio._alert == 1, "despacho incompleto não para a barra")
	ok(await wait_until(func(): return c10.ended, 20.0), "desligou mesmo assim")
	m._worsen(0.0)
	ok(m.radio._away != "", "fora da linha da emergência, o rádio inteiro avisa")
	m.dispatch.set_location(e10.street, e10.block, e10.address)
	m.dispatch.set_occurrence(e10.occurrence)
	for u in need.slice(1):
		(m.dispatch._unit_buttons[u] as Button).button_pressed = true
	m.dispatch._send()
	m._worsen(0.0)
	ok(c10.secured and not c10.urgent() and m.radio._alert == -1, "socorro completo: a barra para e a luz apaga")
	ok(_faults("emergency_worse") == w10 + 1, "despachou agravando: advertência média")
	ok(await wait_until(func(): return m.report.is_resolved(e10), 20.0) and m.report.outcomes()[e10] == ShiftReport.Outcome.OK, "resolvida; no jornal: a tempo")
	await wait_until(func(): return m.dispatch._units.values().all(func(s): return s == 0), 30.0)
	_clear_board()
	# perdida: gravíssima na hora, jornal ruim, e ainda dá para despachar (sem outra advertência pela barra)
	var e11: EmergencyCall = C.emergencies.filter(func(x): return x != e10 and x != e4 and x != e5 and x != e8 and x.lost != "")[0]
	var c11 := PhoneCall.from_emergency(e11)
	m.ring(c11)
	_answer(c11)
	ok(await wait_until(func(): return c11.phase == PhoneCall.Phase.EMERGENCY and not c11.talking), "emergência 5")
	var crit: int = m.report.count(ShiftReport.Severity.CRITICAL)
	for i in 3:
		m._worsen(e11.stage_sec[i])
	ok(c11.stage == 3 and m.report.count(ShiftReport.Severity.CRITICAL) == crit + 1, "perdida: advertência gravíssima")
	ok(await wait_until(func(): return c11.transcript.any(func(l): return l["text"] == e11.lost)), "reclamou")
	var hurt := T.text(T.Key.OP_ANYONE_HURT)
	ok(await wait_until(func(): return c11.options.map(func(o): return o["label"]) == [e11.questions[0], hurt, T.text(T.Key.OP_HOLD_EMERGENCY)]),
		"perdida: só o endereço e \"Tem alguém ferido?\"")
	c11.options[1]["fn"].call()
	ok(await wait_until(func(): return c11.transcript.any(func(l): return l["text"] == e11.lost_answer) and not c11.asking), "contou quem se feriu")
	ok(Array(e11.lost_units).all(func(u): return u in m.dispatch.required()), "o ferido passa a exigir unidade")
	var faults11: int = m.report.faults.size()
	m.dispatch.set_location(e11.street, e11.block, e11.address)
	m.dispatch.set_occurrence(e11.occurrence)
	for u in m.dispatch.required():
		(m.dispatch._unit_buttons[u] as Button).button_pressed = true
	m.dispatch._send()
	ok(await wait_until(func(): return c11.ended, 20.0) and m.report.faults.size() == faults11, "despachou depois: nenhuma advertência a mais")
	ok(m.report.outcomes()[e11] == ShiftReport.Outcome.BAD, "no jornal: ruim")
	ok(m.report.severe_total() >= m.report.count(ShiftReport.Severity.SEVERE) + ShiftReport.CRITICAL_WEIGHT, "gravíssima pesa mais na demissão")
	print("OK 10 barra de agravamento")
	finish("consequências e relatório")
