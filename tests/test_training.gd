extends "res://tests/test_base.gd"
## O treinamento da noite 0 (`Training`): a Cecília liga pela entrada 1 (com o FONE já nela), depois pela 2 com o
## pedido de transferência, comenta o cabo na saída errada; na última, ensina o caderno (e comenta o tipo errado) e a
## prancheta; na quarta, finge uma emergência (despacho: marcar, triturar, perfurar, transmitir, o rádio), a espera
## e o fim do turno; no fim, o relógio volta a andar. Também: a pausa não conta a demora, o cartão enviado ao endereço
## errado antes da hora não vale como chegada, o FONE fora da linha dela dá a dica de voltar, e o treinamento não demite.

var m: Main
var b: Switchboard


func _move(e: int, j: int) -> void:
	if b.ends[e] != -1:
		b.pick_up(e)
	else:
		b.held = e
	if j == -1:
		b.go_home(e)
	else:
		ok(b.place(e, j), "não encaixou %d em %d" % [e, j])


func _ringing(line: int) -> Callable:
	return func(): return m.training.call != null and m.training.call.ringing and m.training.call.line == line


func _waiting(until: String) -> Callable:
	return func(): return m.training._step != null and m.training._step.kind == LessonStep.Kind.WAIT and m.training._step.until == until


func _choose() -> bool:
	if not await wait_until(func(): return not m.training.call.options.is_empty()):
		return false
	m.training.call.options[0]["fn"].call()
	return true


## O cartão vai para a trituradora (o que a máquina faz ao engoli-lo).
func _shred(d: Dispatch) -> void:
	d.machines.clear()
	d.machines.discarded.emit()


func _said(text: String) -> bool:
	return m.training.call.transcript.any(func(l: Dictionary): return text in String(l["text"]))


func _initialize() -> void:
	Engine.time_scale = 8.0
	var d := GameData.date_of(0)
	ok(d.day == 5 and d.weekday == 5, "o treinamento é na sexta, 5 de outubro")
	ok(GameData.sectors_for(0) == [3], "o treinamento é no setor 3")
	ok(Pace.next(3, 0, ShiftReport.Grade.POOR) == 1, "a noite 1 começa no primeiro nível depois do treinamento")
	ok(GameData.date_of(0, 1).day == 6, "o caderno do treinamento é da noite de 5 para 6")
	var r := ShiftReport.new()
	r.night = 0
	r.low_before = ShiftReport.LOW_LIMIT
	r.add("emergency_lost", "18:00")
	ok(not r.fired(), "o treinamento não demite")
	m = load("res://scenes/main.tscn").instantiate()
	m.night_no = 0
	get_tree().root.add_child(m)
	get_tree().current_scene = m
	await frames(2)
	b = m.board
	ok(m.night == GameData.CONTENT.training, "noite 0 é a do treinamento")
	ok(b.ends[0] == 1, "o FONE começa na entrada 1")
	m._intro.visible = false
	m._start_shift()
	ok(await wait_until(_ringing(1)), "ela liga pela entrada 1")
	await frames(2)
	ok(m.phone._blink != null, "Atender pisca")
	m.answer()
	await frames(2)
	ok(m.phone._blink == null, "atendeu: para de piscar")
	ok(await _choose(), "o operador responde")
	m.hangup()
	ok(m.training.call.active, "não dá para desligar na cara dela")
	ok(await wait_until(func(): return m.training.call.ended), "ela desliga para ligar pela 2")
	ok(await wait_until(_ringing(2)), "ela liga pela entrada 2")
	ok(m.minutes == 0.0, "o relógio fica parado no treinamento")
	_move(0, 2)
	m.answer()
	var c := m.training.call
	ok(await wait_until(_waiting("directory")), "pede para abrir a lista")
	get_tree().paused = true
	await frames(200)   # mais que a demora do passo (12 s de jogo)
	ok(not _said("capa mostarda"), "na pausa a demora não conta")
	get_tree().paused = false
	m.tools.set_tab(Tools.DIRECTORY)
	ok(await wait_until(_waiting("cord_out")), "pede o cabo na saída")
	_move(1, 13)
	ok(await wait_until(func(): return _said("saída 3")), "comenta a saída errada")
	_move(1, 12)
	ok(await wait_until(_waiting("cord_dest")), "pede a outra ponta no destino")
	_move(2, 305)
	ok(await wait_until(_waiting("transfer")), "pede para transferir")
	m.transfer()
	ok(await wait_until(func(): return c.connected), "o hotel atendeu e a ligação segue pelo cabo")
	ok(await wait_until(func(): return m.exchange.line(2) == Exchange.Line.DONE), "a conversa termina sozinha")
	_move(1, -1)
	_move(2, -1)
	_move(0, -1)
	ok(await wait_until(_ringing(1)), "ela liga de novo pela entrada 1")
	_move(0, 1)
	m.answer()
	_move(0, -1)
	ok(await wait_until(func(): return T.text(T.Key.HINT_TRAINING_BACK) % [tr(c.caller), 1] in m._hint.text), "FONE fora da linha dela: a dica de voltar")
	_move(0, 1)
	ok(await wait_until(_waiting("logbook")), "pede para abrir o caderno")
	ok(m.notebook.pending_count() == 2, "as duas ligações dela esperam registro")
	m.tools.set_tab(Tools.LOGBOOK)
	ok(await wait_until(_waiting("registered")), "pede para registrar")
	ok(m.flags.has(Main.SAW_SLIPS), "ensinou as tiras: a dica de primeira vez não repete")
	m.notebook.register(T.Key.TYPE_EMERGENCY)
	ok(await wait_until(func(): return _said("essa foi comum")), "comenta o tipo errado")
	m.notebook.register(T.Key.TYPE_COMMON)
	ok(await wait_until(_waiting("call_log")), "pede para abrir a prancheta")
	m.tools.set_tab(Tools.CALL_LOG)
	ok(await wait_until(func(): return m.training.call.ended), "ela desliga para a emergência de treino")
	ok(await wait_until(_ringing(3)), "ela liga pela entrada 3")
	var dp := m.dispatch
	ok(dp.fleet.incident_of(m.training.drill) != null, "o despacho espera a emergência de treino")
	_move(0, 3)
	m.answer()
	ok(await wait_until(_waiting("dispatch")), "pede para abrir o despacho")
	m.tools.set_tab(Tools.DISPATCH)
	ok(await wait_until(_waiting("card")), "pede para marcar o local")
	dp.set_location("flores", 0, "Rua das Flores, 1–99")
	ok(await wait_until(_waiting("shred")), "corrige o endereço e pede para triturar")
	# o jogador perfura e envia o cartão do endereço errado em vez de triturar: os bombeiros vão para lá
	dp.set_occurrence("Incêndio")
	dp.punch_unit("bomb")
	dp.machines.clear()
	dp.machines.inserted.emit()
	ok(await wait_until(func(): return _waiting("card").call() and m.training._step.street == ""), "pede o lugar certo")
	dp.set_location("sol", 0, "Rua do Sol, 1–99")
	ok(await wait_until(func(): return _said("Esse não é o lugar")), "comenta o cartão do lugar errado")
	_shred(dp)
	dp.set_location("acacias", 0, "Rua das Acácias, 1–99")
	ok(await wait_until(_waiting("punched")), "pede para perfurar")
	ok(await wait_until(func(): return dp.fleet.is_free("bomb"), 120.0), "os bombeiros voltam à base")
	ok(not m.training._arrived, "a chegada ao endereço errado não conta")
	dp.fleet.units["bomb"] = Fleet.Unit.RETURNING   # ainda voltando de outro cartão
	ok(await wait_until(func(): return T.text(T.Key.HINT_TRAINING_UNITS_AWAY) in m._hint.text), "os bombeiros ainda estão fora: a dica de esperar")
	dp.fleet.units["bomb"] = Fleet.Unit.AVAILABLE
	dp.set_occurrence("Incêndio")
	dp.punch_unit("bomb")
	ok(await wait_until(_waiting("sent")), "pede para levar ao transmissor")
	dp.machines.inserted.emit()
	ok(await wait_until(_waiting("arrived")), "manda escutar o rádio")
	ok(await wait_until(func(): return not _waiting("arrived").call(), 120.0), "as unidades chegam e o rádio fala")
	ok(await wait_until(_waiting("hold")), "pede para deixá-la em espera")
	_move(0, 1)
	ok(await wait_until(_waiting("resume")), "ela fica em espera")
	ok(m.exchange.line(3) == Exchange.Line.HOLD and not m.training.call.on_line, "a linha dela em espera")
	_move(0, 3)
	ok(await _choose(), "o operador se despede")
	ok(m.flags.has(Main.SAW_SHEET), "ensinou a folha nova")
	ok(await wait_until(func(): return not m.training.active), "o treinamento termina")
	ok(m.notebook.pending_count() == 2, "as duas últimas ligações dela vão para o caderno")
	var recs: Array = m.notebook.queue + [m.notebook.pending]
	ok(recs.all(func(x: PhoneCall.Record): return x.obs == T.text(T.Key.OBS_TRAINING)), "as fichas dela dizem que é treinamento")
	ok(recs.any(func(x: PhoneCall.Record): return x.card > 0 and "Acácias" in x.where), "a da emergência de treino leva o local e o cartão")
	ok(m.report._incidents.is_empty(), "a emergência de treino não vai para o relatório")
	ok(m.report.faults.is_empty(), "o treinamento não gera advertência")
	await frames(30)
	ok(m.minutes > 0.0, "depois do treinamento, o relógio anda")
	print("OK treinamento")
	finish("test_training")
