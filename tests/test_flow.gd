extends "res://tests/test_base.gd"
## Cenários dirigidos: transferência, várias ligações, desistência, caderno, lugar fechado,
## cortar conversa, ligar de volta para a 07, clique/arraste dos plugs.
## FONE = ponta 0; cabos de conexão = pontas 1..6 (da SAÍDA ao destino).

var m


func _pick(c: Dictionary, label_start: String) -> void:
	for o in c["opts"]:
		if String(o["label"]).begins_with(label_start):
			o["fn"].call()
			return
	ok(false, "opção não encontrada: " + label_start)

func _mkcall(src: Dictionary, kind: String) -> Dictionary:
	var c: Dictionary = m._mk(src, kind, -1)
	c["filler"] = true
	return c

func _move(b, e: int, j: int) -> void:
	if b.ends[e] != -1:
		b.pick_up(e)
	if j == -1:
		b.go_home(e)
	else:
		ok(b.place(e, j), "não encaixou %d em %d" % [e, j])

func _initialize() -> void:
	Engine.time_scale = 20.0
	m = await load_main()
	m.sched = []
	m.intro.visible = false
	m.running = true
	var b = m.board

	# ---- 1. transferência completa; tirar o FONE não derruba a conversa
	var a: Dictionary = m.tut
	m.ring(a)
	var ln: int = a["line"]
	ok(not b.place(0, ln + 10), "FONE não entra na saída")
	ok(not b.place(1, ln), "cabo de conexão não entra na entrada")
	_move(b, 0, ln)
	ok(is_same(m._focus(), a))
	m.answer()
	ok(a["active"])
	ok(await wait_until(func(): return a.get("phase", "") == "await" and not a.get("talking", false)))
	var tgt := int(a["target"])
	_move(b, 1, ln + 10)
	ok(not b.place(2, ln + 11 if ln < 10 else ln + 9), "as duas pontas não podem ir em saídas")
	_move(b, 2, tgt)
	ok(m._dest_of_line(ln) == tgt)
	m.transfer()
	ok(m.dests[tgt] == "ring")
	ok(await wait_until(func(): return m.dests[tgt] == "conn"))
	ok(not a.get("ended", false), "com o FONE na entrada o operador segue na linha")
	_move(b, 0, -1)
	ok(a["ended"] and a["connected"] and m.lines[ln - 1] == "conn" and m.dests[tgt] == "conn", "tirar o FONE não derruba")
	m.minutes = m.line_until[ln - 1] + 1.0
	await process_frame
	ok(m.lines[ln - 1] == "done" and m.dests[tgt] == "done")
	_move(b, 1, -1)
	ok(m.lines[ln - 1] == "free")
	_move(b, 2, -1)
	ok(m.dests[tgt] == "free" and b.free_patches() == 3)
	print("OK 1 transferência completa / tirar o FONE mantém a ligação")

	# ---- 2. três ligações ao mesmo tempo, com espera
	var t1 := _mkcall(GameData.T1[1], "transfer")
	var info := _mkcall(m._info_call(), "info")
	var t3 := _mkcall(GameData.FILL[0], "transfer")
	m.ring(t1)
	_move(b, 0, t1["line"])
	m.answer()
	m.ring(info)
	m.ring(t3)
	ok(m.live.size() == 3)
	ok(await wait_until(func(): return t1.get("phase", "") == "await" and not t1.get("talking", false)))
	_move(b, 0, info["line"])      # FONE vai para outra entrada: t1 em espera
	ok(m.lines[int(t1["line"]) - 1] == "hold")
	ok(is_same(m._focus(), info) and is_same(m.shown, info))
	m.answer()
	var n1: int = t1["t_lines"].size()
	ok(await wait_until(func(): return info.get("phase", "") == "info" and not info.get("talking", false)))
	t1["last_talk"] = 0
	for i in 30:
		await process_frame
	ok(t1["t_lines"].size() == n1, "em espera ninguém fala")
	var right := ""
	for o in info["opts"]:
		var lbl := String(o["label"])
		if info["what"] == "num" and lbl.contains(String(info["answer"])):
			right = lbl
		for k in 10:
			if info["what"] == "time" and lbl == "São %s." % m.fmt(m.minutes - k):
				right = lbl
	_pick(info, right)
	ok(await wait_until(func(): return info.get("ended", false)))
	ok(info["info_ok"] and m.lines[int(info["line"]) - 1] == "done")
	_move(b, 0, t1["line"])        # volta para t1; a linha da informação fica livre
	ok(m.lines[int(info["line"]) - 1] == "free")
	ok(m.lines[int(t1["line"]) - 1] == "talk" and is_same(m.shown, t1))
	ok(t3["ringing"] and m.live.size() == 2)
	print("OK 2 três ligações simultâneas / espera")

	# ---- 3. t3 desiste; caderno em fila
	ok(await wait_until(func(): return t3.get("ended", false), 10.0))
	ok(t3["rec"]["obs"] == "Não atendida.")
	ok(m.pending_q.size() >= 1)
	var before: int = m.pending_q.size()
	m.p_type.select(1)
	m._register()
	ok(m.pending_q.size() == before - 1 and not m.pending.is_empty())
	print("OK 3 desistência / fila do caderno")

	# ---- 4. lugar fechado à noite e sugestão do operador
	m.hangup()
	ok(m.lines[int(t1["line"]) - 1] == "done")
	_move(b, 0, -1)
	ok(m.lines[int(t1["line"]) - 1] == "free")
	var fa := _mkcall(GameData.FILL[3], "transfer")   # Farmácia Central -> Santa Rita
	m.ring(fa)
	var fl: int = fa["line"]
	_move(b, 0, fl)
	m.answer()
	ok(await wait_until(func(): return fa.get("phase", "") == "await" and not fa.get("talking", false)))
	_move(b, 3, fl + 10)
	_move(b, 4, 118)
	m.transfer()
	ok(await wait_until(func(): return fa.get("no_answer", false)))
	_pick(fa, "Ninguém atende")
	ok(fa["target"] == "162")
	_move(b, 4, 162)
	ok(await wait_until(func(): return not fa.get("talking", false)))
	m.transfer()
	_move(b, 0, -1)                # tira o FONE com o destino ainda tocando
	ok(m.lines[fl - 1] == "hold" and not fa.get("ended", false))
	ok(await wait_until(func(): return fa.get("connected", false)), "completa sozinha quando o destino atende")
	ok(fa["rec"]["where"] == "Farmácia Santa Rita" and fa["rec"]["obs"] == "")
	print("OK 4 lugar fechado / alternativa / FONE fora durante o toque")

	# ---- 5. cortar uma conversa em andamento puxando a SAÍDA
	_move(b, 3, -1)
	ok(m.lines[fl - 1] == "free" and m.dests[162] == "done")
	_move(b, 4, -1)
	ok(m.dests[162] == "free")
	print("OK 5 cortar conversa")

	# ---- 6. ligar de volta para a 07
	m.after = true
	m.note_shown = true
	_move(b, 0, 7)
	ok(await wait_until(func(): return m.disp_lbl.text == "NÚMERO NÃO EXISTE", 10.0))
	print("OK 6 ligação de volta 07")

	# ---- 7. clicar num plug encaixado devolve à base (com animação); arrastar move
	var c7 := _mkcall(GameData.T1[0], "transfer")
	m.after = false
	m.ring(c7)
	var l7: int = c7["line"]
	_move(b, 0, -1)
	await process_frame
	b.held = 0
	b.place(0, l7)
	var jc: Vector2 = b.jack_rect(l7).get_center()
	b._press(jc); b._release(jc)
	ok(b.ends[0] == -1 and b.held == -1 and b._anim.has(0), "FONE volta sozinho, animando")
	ok(await wait_until(func(): return not b._anim.has(0), 5.0))
	b.held = 1; b.place(1, l7 + 10)
	b.held = 2; b.place(2, 142)
	var jd: Vector2 = b.jack_rect(142).get_center()
	b._press(jd); b._release(jd)
	ok(b.ends[2] == -1 and b.ends[1] == l7 + 10, "só a ponta clicada volta")
	ok(b.free_patches() < 3, "o cabo só volta à base com as duas pontas")
	var js: Vector2 = b.jack_rect(l7 + 10).get_center()
	b._press(js); b._release(js)
	ok(b.ends[1] == -1)
	ok(await wait_until(func(): return b._anim.is_empty(), 5.0))
	ok(b.free_patches() == 3)
	# arrastar de uma tomada para outra move o plug
	b.held = 0; b.place(0, l7)
	var other_in := 1 if l7 != 1 else 2
	b._press(jc); b._release(b.jack_rect(other_in).get_center())
	ok(b.ends[0] == other_in, "arrastar move o FONE")
	print("OK 7 clique devolve à base / arrastar move")
	finish("fluxo da central")
