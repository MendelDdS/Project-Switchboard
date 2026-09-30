extends "res://tests/test_base.gd"
## Cenários dirigidos: transferência, várias ligações, desistência, caderno, lugar fechado,
## cortar conversa, ligar de volta para a 07, clique/arraste dos plugs.
## FONE = ponta 0; cabos de conexão = pontas 1..6 (da SAÍDA ao destino).
## `m` e `b` ficam sem tipo: Main e Switchboard usam o autoload Sfx, que ainda não existe quando o Godot
## compila um script passado com -s.

var m   # Main
var b   # Switchboard
var ex: Exchange


func _pick(c: PhoneCall, label_start: String) -> void:
	for o in c.options:
		if String(o["label"]).begins_with(label_start):
			o["fn"].call()
			return
	ok(false, "opção não encontrada: " + label_start)


func _extra(t: TransferCall) -> PhoneCall:
	var c := PhoneCall.from_transfer(t)
	c.filler = true
	return c


func _move(e: int, j: int) -> void:
	if b.ends[e] != -1:
		b.pick_up(e)
	else:
		b.held = e
	if j == -1:
		b.go_home(e)
	else:
		ok(b.place(e, j), "não encaixou %d em %d" % [e, j])


func _awaiting(c: PhoneCall) -> Callable:
	return func(): return c.phase == PhoneCall.Phase.AWAIT and not c.talking


func _initialize() -> void:
	Engine.time_scale = 20.0
	m = await load_main()
	m.sched.clear()
	m._intro.visible = false
	m.running = true
	b = m.board
	ex = m.exchange

	# ---- 1. transferência completa; tirar o FONE não derruba a conversa
	var a: PhoneCall = m.tut
	m.ring(a)
	var ln := a.line
	b.held = 0
	ok(not b.place(0, ln + 10), "FONE não entra na saída")
	b.held = 1
	ok(not b.place(1, ln), "cabo de conexão não entra na entrada")
	b.held = -1
	_move(0, ln)
	ok(m._focus() == a, "FONE na entrada dá foco à ligação")
	m.answer()
	ok(a.active, "atendeu")
	ok(await wait_until(_awaiting(a)), "pedido de transferência")
	var tgt := int(a.target)
	_move(1, ln + 10)
	b.held = 2
	ok(not b.place(2, ln + 11 if ln < 10 else ln + 9), "as duas pontas não podem ir em saídas")
	b.held = -1
	_move(2, tgt)
	ok(b.dest_of_output(ln) == tgt, "cabo liga a saída ao destino")
	m.transfer()
	ok(ex.dest(tgt) == Exchange.Dest.RING, "destino tocando")
	ok(await wait_until(func(): return ex.dest(tgt) == Exchange.Dest.CONN), "destino atendeu")
	ok(not a.ended, "com o FONE na entrada o operador segue na linha")
	_move(0, -1)
	ok(a.ended and a.connected and ex.line(ln) == Exchange.Line.CONN and ex.dest(tgt) == Exchange.Dest.CONN, "tirar o FONE não derruba")
	m.minutes = ex.line_until(ln) + 1.0
	await frames(1)
	ok(ex.line(ln) == Exchange.Line.DONE and ex.dest(tgt) == Exchange.Dest.DONE, "conversa terminou")
	_move(1, -1)
	ok(ex.line(ln) == Exchange.Line.FREE, "linha liberada")
	_move(2, -1)
	ok(ex.dest(tgt) == Exchange.Dest.FREE and b.free_patches() == 3, "destino e cabo liberados")
	print("OK 1 transferência completa / tirar o FONE mantém a ligação")

	# ---- 2. três ligações ao mesmo tempo, com espera
	var t1 := _extra(GameData.transfers(TransferCall.Group.ESTABLISHMENT)[1])
	var info: PhoneCall = m._info_call()
	info.filler = true
	var t3 := _extra(GameData.transfers(TransferCall.Group.EXTRA)[0])
	m.ring(t1)
	_move(0, t1.line)
	m.answer()
	m.ring(info)
	m.ring(t3)
	ok(m.live.size() == 3, "três ligações")
	ok(await wait_until(_awaiting(t1)), "t1 esperando")
	_move(0, info.line)       # FONE vai para outra entrada: t1 em espera
	ok(ex.line(t1.line) == Exchange.Line.HOLD, "t1 em espera")
	ok(m._focus() == info and m.phone.shown() == info, "painel mostra a informação")
	m.answer()
	var n1 := t1.transcript.size()
	ok(await wait_until(func(): return info.phase == PhoneCall.Phase.INFO and not info.talking), "pedido de informação")
	t1.last_talk = 0
	await frames(30)
	ok(t1.transcript.size() == n1, "em espera ninguém fala")
	var right := ""
	for o in info.options:
		var lbl := String(o["label"])
		if info.about != "" and lbl.contains(info.answer):
			right = lbl
		for k in 10:
			if info.about == "" and lbl == "São %s." % m.fmt(m.minutes - k):
				right = lbl
	_pick(info, right)
	ok(await wait_until(func(): return info.ended), "informação encerrada")
	ok(info.info_ok == 1 and ex.line(info.line) == Exchange.Line.DONE, "respondeu certo; linha desligou")
	_move(0, t1.line)         # volta para t1; a linha da informação fica livre
	ok(ex.line(info.line) == Exchange.Line.FREE, "linha da informação liberada")
	ok(ex.line(t1.line) == Exchange.Line.TALK and m.phone.shown() == t1, "voltou para t1")
	ok(t3.ringing and m.live.size() == 2, "t3 ainda tocando")
	print("OK 2 três ligações simultâneas / espera")

	# ---- 3. t3 desiste; caderno em fila
	ok(await wait_until(func(): return t3.ended, 10.0), "t3 desistiu")
	ok(t3.record["obs"] == "Não atendida.", "registro de não atendida")
	var nb = m.notebook
	ok(nb.queue.size() >= 1, "ocorrências em fila")
	var before: int = nb.queue.size()
	nb._type.select(1)
	nb.register()
	ok(nb.queue.size() == before - 1 and nb.has_pending(), "registrou uma, a próxima veio da fila")
	print("OK 3 desistência / fila do caderno")

	# ---- 4. lugar fechado à noite e sugestão do operador
	m.hangup()
	ok(ex.line(t1.line) == Exchange.Line.DONE, "desligar deixa a linha em desligou")
	_move(0, -1)
	ok(ex.line(t1.line) == Exchange.Line.FREE, "tirar o FONE libera")
	var fa := _extra(GameData.transfers(TransferCall.Group.EXTRA)[3])   # Farmácia Central -> Santa Rita
	m.ring(fa)
	var fl := fa.line
	_move(0, fl)
	m.answer()
	ok(await wait_until(_awaiting(fa)), "pedido da farmácia")
	_move(3, fl + 10)
	_move(4, 118)
	m.transfer()
	ok(await wait_until(func(): return fa.no_answer), "ninguém atende")
	_pick(fa, "Ninguém atende")
	ok(fa.target == "162", "trocou para a de plantão")
	_move(4, 162)
	ok(await wait_until(func(): return not fa.talking), "terminou de falar")
	m.transfer()
	_move(0, -1)              # tira o FONE com o destino ainda tocando
	ok(ex.line(fl) == Exchange.Line.HOLD and not fa.ended, "em espera durante o toque")
	ok(await wait_until(func(): return fa.connected), "completa sozinha quando o destino atende")
	ok(fa.record["where"] == "Farmácia Santa Rita" and fa.record["obs"] == "", "registro com o destino novo")
	print("OK 4 lugar fechado / alternativa / FONE fora durante o toque")

	# ---- 5. cortar uma conversa em andamento puxando a SAÍDA
	_move(3, -1)
	ok(ex.line(fl) == Exchange.Line.FREE and ex.dest(162) == Exchange.Dest.DONE, "cortou a conversa")
	_move(4, -1)
	ok(ex.dest(162) == Exchange.Dest.FREE, "destino liberado")
	print("OK 5 cortar conversa")

	# ---- 6. ligar de volta para a 07
	m.after = true
	m.note_shown = true
	_move(0, 7)
	ok(await wait_until(func(): return m.phone.display_text() == "NÚMERO NÃO EXISTE", 10.0), "07 não existe")
	print("OK 6 ligação de volta 07")

	# ---- 7. clicar num plug encaixado devolve à base (com animação); arrastar move
	var c7 := _extra(GameData.transfers(TransferCall.Group.ESTABLISHMENT)[0])
	m.after = false
	m.ring(c7)
	var l7 := c7.line
	_move(0, -1)
	await frames(1)
	_move(0, l7)
	var jc: Vector2 = b.jack_rect(l7).get_center()
	b._press(jc)
	b._release(jc)
	ok(b.ends[0] == -1 and b.held == -1 and b._anim.has(0), "FONE volta sozinho, animando")
	ok(await wait_until(func(): return not b._anim.has(0), 5.0), "animação terminou")
	_move(1, l7 + 10)
	_move(2, 142)
	var jd: Vector2 = b.jack_rect(142).get_center()
	b._press(jd)
	b._release(jd)
	ok(b.ends[2] == -1 and b.ends[1] == l7 + 10, "só a ponta clicada volta")
	ok(b.free_patches() < 3, "o cabo só volta à base com as duas pontas")
	var js: Vector2 = b.jack_rect(l7 + 10).get_center()
	b._press(js)
	b._release(js)
	ok(b.ends[1] == -1, "a outra ponta também voltou")
	ok(await wait_until(func(): return b._anim.is_empty(), 5.0), "animações terminaram")
	ok(b.free_patches() == 3, "cabo de volta à base")
	_move(0, l7)
	var other_in := 1 if l7 != 1 else 2
	b._press(jc)
	b._release(b.jack_rect(other_in).get_center())
	ok(b.ends[0] == other_in, "arrastar move o FONE")
	print("OK 7 clique devolve à base / arrastar move")
	finish("fluxo da central")
