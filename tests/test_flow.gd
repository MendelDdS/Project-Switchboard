extends "res://tests/test_base.gd"
## Cenários dirigidos: transferência, várias ligações, desistência, caderno, lugar fechado,
## cortar conversa, ligar de volta para o número desconhecido, clique/arraste dos plugs.
## FONE = ponta 0; cabos de conexão = pontas 1..6 (da SAÍDA ao destino).

var m: Main
var b: Switchboard
var ex: Exchange


func _pick(c: PhoneCall, label_start: String) -> void:
	for o in c.options:
		if String(o["label"]).begins_with(label_start):
			o["fn"].call()
			return
	ok(false, "opção não encontrada: " + label_start)


func _step(kind: PrankStep.Kind, text := "", requires := PackedStringArray()) -> PrankStep:
	var st := PrankStep.new()
	st.kind = kind
	st.text = text
	st.requires = requires
	return st


func _extra(t: TransferCall) -> PhoneCall:
	return PhoneCall.from_transfer(t)


## Mouse sobre o nó `n` (coordenadas dele): `pressed` 1 aperta, 0 solta, -1 só move.
func _mouse(n: Control, p: Vector2, pressed := -1) -> void:
	var e: InputEventMouse = InputEventMouseMotion.new() if pressed == -1 else InputEventMouseButton.new()
	if e is InputEventMouseButton:
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed == 1
	e.position = p
	n._gui_input(e)


## Arrasta com o mouse de `a` até `b` (coordenadas da tela): aperta, anda em 8 passos com o botão apertado e solta.
## Um interurbano de um minuto na entrada `n`, já encerrado: o bilhete impresso.
func _ticket(n: int) -> TollTicket:
	m.toll.start(n, "Capital", "45-12", m.minutes)
	return m.toll.stop(n, m.minutes + 1.0)


func _drag_mouse(a: Vector2, b: Vector2) -> void:
	var vp := get_viewport()
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = a
	vp.push_input(e)
	for i in 8:
		var mm := InputEventMouseMotion.new()
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		mm.position = a.lerp(b, (i + 1) / 8.0)
		mm.relative = (b - a) / 8.0
		vp.push_input(mm)
		await frames(1)
	var u := e.duplicate()
	u.pressed = false
	u.position = b
	vp.push_input(u)
	await frames(2)


## Aperta e solta o mouse em `p` (coordenadas da tela), pela janela.
func _tap_mouse(p: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = p
	get_viewport().push_input(e)
	var u := e.duplicate()
	u.pressed = false
	get_viewport().push_input(u)
	await frames(2)


## Onde pegar o carimbo do calculógrafo (o meio dele cai na caixa).
func _grip() -> Vector2:
	var s: Control = m.toll._stamp
	return s.global_position + s.size / 2.0


## Leva o carimbo com o meio do fundo em `p` (na tela) e clica nele: carimba o que estiver embaixo.
func _stamp_at(p: Vector2) -> void:
	await _drag_mouse(_grip(), p - Toll.RUBBER_MID + m.toll._stamp.size / 2.0)
	await _tap_mouse(_grip())
	await frames(int(Toll.PRESS_SEC * 60.0) + 2)   # (carimba quando as rodas encostam, no fim da descida)


## Clique (aperta e solta no mesmo lugar) sobre o nó `n`.
func _click(n: Control, p: Vector2) -> void:
	_mouse(n, p, 1)
	_mouse(n, p, 0)


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
	Engine.time_scale = 8.0
	m = await load_main([1, 2, 3])
	m.sched.clear()
	m._intro.visible = false
	m.running = true
	b = m.board
	ex = m.exchange
	ok(b.patches == b.SHELF_SLOTS, "com os três setores, os cinco cabos (um par por setor novo)")

	# ---- 0. regras com a cena (o conteúdo em si, sem ela: test_content)
	var C: GameContent = GameData.CONTENT
	# clima: cada um tem falas próprias, e a chuva só é comentada quando chove
	for w in m.WEATHERS:
		m.weather = w
		var talk: Array = m.conversation.topics()
		ok(talk.any(func(t): return t.weather == w), "assuntos do clima: " + w)
		ok(w == "rain" or not talk.any(func(t): return "chuva" in t.line), "sem chuva na conversa: " + w)
	ok(not m.conversation.topics("m").any(func(t): return "Meu marido" in t.line) and not m.conversation.topics("f").any(func(t): return "Minha mulher" in t.line),
		"assunto só na voz que combina")
	# setores: o 3 desde a noite 1, o 1 na noite 5 e o 2 na noite 9; mesa, lista e ligações só com os atendidos
	ok(GameData.sectors_for(1) == [3] and GameData.sectors_for(4) == [3] and GameData.sectors_for(5).size() == 2
		and GameData.sectors_for(9).size() == 3, "setores entregues nas noites 1, 5 e 9")
	var per_sector := {}
	for e in C.directory:
		if not e.dispatch_only:
			per_sector[e.number.left(1)] = int(per_sector.get(e.number.left(1), 0)) + 1
	ok(per_sector == {"3": 12, "1": 12, "2": 12}, "lista: 12 números em cada setor: %s" % per_sector)
	GameData.sectors = [3]
	ok(GameData.board_numbers().size() == 12 and GameData.board_numbers().all(func(n): return str(n).begins_with("3")), "noite 1: mesa só com o setor 3")
	ok(not GameData.transfers(TransferCall.Group.ESTABLISHMENT).is_empty(), "setor 3 tem estabelecimento")
	var used: Array = []
	var tpl := GameData.template_transfer(used)
	while tpl != null:
		ok(tpl.target.begins_with("3"), "molde só com número do setor 3")
		used.append(tpl.target)
		tpl = GameData.template_transfer(used)
	ok(not used.is_empty(), "moldes até acabarem os lugares, sem repetir")
	var sector3 := func(c: PhoneCall) -> bool:
		if c.kind == PhoneCall.Kind.TRANSFER:
			return c.target.begins_with("3") or GameData.is_trunk(c.target)   # os troncos são da cidade toda
		return c.kind != PhoneCall.Kind.INFO or c.answer.begins_with("3")
	for s in 5:
		ok(Schedule.build(C.nights[0], C.paces[0], m.last_call).calls.all(sector3), "agenda da noite 1 só pede números do setor 3")
	var em_streets := func(): return Schedule.build(C.nights[0], C.paces[4], m.last_call).calls.filter(func(c: PhoneCall): return c.kind == PhoneCall.Kind.EMERGENCY).map(func(c: PhoneCall): return GameData.street(c.data.street).block_sector(c.data.block))
	for s in 5:
		ok(em_streets.call().all(func(x): return x == 3), "emergências só nas ruas do setor 3")
	# mapa: setor sombreado não responde; a viagem do Centro é mais longa quanto mais longe
	var city := m.dispatch.city
	var on_street := func(id: String, b: int): return city.seg_geom(GameData.street(id), b)[2]
	ok(city._find_seg(on_street.call("brasil", 1)).get("block") == 1 and city._find_seg(on_street.call("brasil", 4)).is_empty(),
		"mapa: a Avenida Brasil só nos trechos do setor atendido")
	var cross := Vector2.INF   # um cruzamento: onde um trecho vertical corta um horizontal
	var both := []
	for v: Street in C.streets.filter(func(s: Street): return not s.horizontal):
		for h: Street in C.streets.filter(func(s: Street): return s.horizontal):
			for bv in v.blocks():
				for bh in h.blocks():
					var gv := city.seg_geom(v, bv)
					var gh := city.seg_geom(h, bh)
					var x = Geometry2D.segment_intersects_segment(gv[0], gv[1], gh[0], gh[1])
					if cross == Vector2.INF and x != null and v.block_sector(bv) == 3 and h.block_sector(bh) == 3:
						cross = x
						both = [{"street": v.id, "block": bv, "label": ""}, {"street": h.id, "block": bh, "label": ""}]
	ok(both.size() == 2, "mapa: há um cruzamento no setor 3")
	for pick: Dictionary in both:
		city.hover = pick
		ok(city._find_seg(cross + Vector2(2, 2)) == pick, "mapa: no cruzamento fica a rua que o mouse vinha seguindo (%s)" % pick["street"])
	city.hover = {}
	GameData.sectors = [1, 2, 3]
	var trip_c: float = city.trip("pol", {"street": "brasil", "block": 4})
	var trip_3: float = city.trip("pol", {"street": "comercio", "block": 2})
	var trip_2: float = city.trip("pol", {"street": "cruzeiro", "block": 0})
	var going := city.trips[0]
	await wait_until(func(): return going.t >= going.dur, 15.0)
	var site: Vector2 = going.pts[-1]
	ok(is_equal_approx(city.go_home("pol"), trip_2) and going.back and going.t == 0.0 and going.pts[-1] == city.STATION["pol"]["p"]
		and going.pts[0] == site, "a viatura volta do local para a base pelo mesmo caminho, no mesmo tempo")
	city.remove_units(["pol"])
	ok(trip_c < trip_3 and trip_3 < trip_2, "viagem do Centro: %.1f s no Centro, %.1f s no setor 3, %.1f s no setor 2" % [trip_c, trip_3, trip_2])
	# viaturas e emergência (`Fleet`, sem tela nem tempo): completo só com tudo a caminho do lugar certo; a chegada diz
	# o que faltou, o que sobrou e quem pode voltar logo
	var frota := Fleet.new()
	var em: EmergencyCall = GameData.CONTENT.emergencies.filter(func(x: EmergencyCall): return Array(x.required(0)) == ["amb"])[0]
	var fl_here := {"street": em.street, "block": em.block}
	var fl_away := {"street": em.street, "block": em.block + 1}
	ok(frota.target_of(fl_here) == null and not frota.send(["pol"], fl_here, null) and frota.arrive(["pol"], fl_here, null).result == Fleet.Result.IDLE \
		and frota.leave(["pol"]) == ["pol"], "frota: sem emergência, a chegada não encontra nada")
	frota.home(["pol"])
	frota.set_incident(em)
	var inc := frota.target_of(fl_here)
	ok(not frota.send(["pol"], fl_here, inc) and frota.available(["pol", "amb"]) == ["amb"] and frota.en_route(), "frota: polícia a caminho, incompleto")
	var fl_got := frota.arrive(["pol"], fl_here, inc)
	ok(fl_got.result == Fleet.Result.MISSING and fl_got.missing == ["amb"] and fl_got.extra == ["pol"] and fl_got.unneeded == ["pol"],
		"frota: faltou a ambulância e a polícia sobrou")
	ok(frota.target_of(fl_away) == inc, "frota: cartão fora de todas vai para a única emergência")
	frota.send(["amb"], fl_away, inc)
	fl_got = frota.arrive(["amb"], fl_away, inc)
	ok(fl_got.result == Fleet.Result.WRONG_PLACE and fl_got.unneeded == ["amb"], "frota: endereço errado")
	ok(frota.leave(["pol", "amb"]) == ["pol", "amb"] and frota.busy() == ["pol", "amb"], "frota: as duas voltando")
	frota.home(["pol", "amb"])
	ok(frota.busy().is_empty() and frota.send(["amb"], fl_here, inc), "frota: a ambulância no lugar certo completa o socorro")
	ok(frota.arrive(["amb"], fl_here, inc).result == Fleet.Result.OK and frota.arrive([], fl_here, inc).result == Fleet.Result.IDLE,
		"frota: resolvida, e depois não há mais nada lá")
	# duas ao mesmo tempo: o cartão vai para a do lugar marcado; fora de todas, para a que está sendo atendida
	var em2: EmergencyCall = GameData.CONTENT.emergencies.filter(func(x: EmergencyCall): return x.street != em.street)[0]
	frota.set_incident(em2)
	var fl_two := {"street": em2.street, "block": em2.block}
	ok(frota.target_of(fl_two).call == em2 and frota.target_of(fl_here).call == em and frota.target_of(fl_away, em).call == em \
		and frota.target_of(fl_away).call == em2 and frota.required(em2) == Array(em2.required(0)), "frota: duas emergências, cada cartão na sua")
	# a viatura de reserva só sai com duas emergências: com uma, quem errou espera a outra voltar
	frota.send(frota.crew(["pol"]), fl_here, null)
	ok(not frota.is_free("pol") and frota.crew(["pol"]).is_empty(), "frota: sem reserva, a polícia fora deixa o tipo ocupado")
	frota.spare = true
	var fl_crew := frota.crew(["pol"])
	frota.send(fl_crew, fl_two, frota.target_of(fl_two))
	ok(fl_crew == ["pol" + Fleet.SPARE] and Fleet.kind(fl_crew[0]) == "pol" and not frota.is_free("pol")
		and frota.target_of(fl_two).going == ["pol"], "frota: com duas emergências, sai a de reserva, e conta como polícia")
	var fl_gen := frota.gen
	frota.reset(true)
	ok(frota.gen == fl_gen + 1 and frota.busy().is_empty() and frota.incidents.is_empty(), "frota: reset libera tudo e esquece as emergências")
	# lista telefônica: cada aba abre só a sua letra, com todos os contatos dela nas duas páginas; Virar passa de letra
	# em letra até as anotações, Voltar volta até a primeira
	var book: PhoneBook = m.tools.find_child("PhoneBook", true, false)
	for l in book._index:
		book.jump(l)
		var pg: Array = book.pages()
		var shown_entries: Array = pg[0] + pg[1]
		var of_letter: Array = book._entries.filter(func(e): return book.initial(e) == l)
		var right_h: float = book.TOP + pg[1].reduce(func(acc, e): return acc + book.entry_height(e), 0.0)
		ok(book.current_letter() == l and shown_entries == of_letter and right_h <= book.bottom, "aba %s: só a letra, inteira" % l)
	book.jump(book._index[0])
	var walked := 0
	while not book._next.disabled:
		book.turn(1)
		walked += 1
	ok(walked == book._index.size() and book.current_letter() == "", "Virar passa letra a letra até as anotações")
	var names: Array = book._entries.map(func(e): return e.name)
	ok(names.find("Célia Rocha") < names.find("Cine Odeon"), "ordem da lista ignora acento")
	for i in walked:
		book.turn(-1)
	ok(book.current_letter() == book._index[0] and book._prev.disabled, "Voltar chega à primeira letra")
	# dica do banco novo: só para o setor entregue na noite (o 3 o treinamento apresenta)
	m.night_no = 5
	ok(m._new_sector("142") and not m._new_sector("305") and not m._new_sector("237") and not m._new_sector(""), "banco novo na noite 5: o A")
	m.night_no = 1
	# revelação: o mapa sai do enquadramento de antes e chega no de agora
	ok(city.frame_of([3]).size == Vector2(600, 440) and city.frame_of([3, 1]).size == Vector2(1200, 440) and city.frame_of([1, 2, 3]).size == Vector2(1200, 880), "enquadramento por setores")
	# ritmo: nas primeiras noites só sobe se a anterior não foi ruim; depois sobe sempre, até o limite
	var top: int = C.paces.size()
	ok(Pace.next(1, 1, ShiftReport.Grade.GREAT) == 2 and Pace.next(1, 1, ShiftReport.Grade.POOR) == 1 and Pace.next(2, 2, ShiftReport.Grade.POOR) == 2, "noite ruim no começo: repete o ritmo")
	ok(Pace.next(3, 3, ShiftReport.Grade.POOR) == 4 and Pace.next(2, 5, ShiftReport.Grade.POOR) == 3, "da noite 4 em diante: sobe mesmo depois de noite ruim")
	ok(Pace.next(top, 8, ShiftReport.Grade.GREAT) == top and Pace.next(top - 1, 6, ShiftReport.Grade.GREAT) == top, "o último nível é o limite")
	ok(Pace.next(4, 4, ShiftReport.Grade.GREAT) == 4 and Pace.next(4, 5, ShiftReport.Grade.GREAT) == 5 and Pace.expected(5) == 4 and Pace.expected(6) == 5,
		"noite de bairro novo (5): o ritmo não sobe")
	ok(range(1, top).all(func(i): return C.paces[i].call_gap.x <= C.paces[i - 1].call_gap.x), "o ritmo só aperta de um nível para o outro")
	# agenda: montada sem a cena (noite → ligações em ordem, espaçadas das do roteiro e entre emergências)
	for n in C.nights:
		var last := n.shift_end - Main.LAST_CALL_BEFORE   # (a última noite vai até as 6h)
		var plan := Schedule.build(n, m.pace, last)
		var ats: Array = plan.calls.map(func(c: PhoneCall): return c.at)
		var in_order := ats.duplicate()
		in_order.sort()
		ok(ats == in_order and ats.all(func(a): return a >= 0.0 and a < n.shift_end), "agenda em ordem: " + n.resource_path)
		ok(plan.calls.all(func(c: PhoneCall): return c.story or c.kind == PhoneCall.Kind.MYSTERY or c.at < last),
			"sorteadas antes da última ligação: " + n.resource_path)
		ok((plan.mystery_at == INF) == n.mystery.is_empty(), "ligação desconhecida conforme a noite: " + n.resource_path)
		ok(plan.calls.all(func(c: PhoneCall): return c.kind != PhoneCall.Kind.MYSTERY or c.latest <= last - Schedule.MYSTERY_MARGIN),
			"desconhecida toca antes da última ligação: " + n.resource_path)
		var fixed := plan.calls.filter(func(c: PhoneCall): return c.story or c.kind == PhoneCall.Kind.MYSTERY)
		ok(fixed.size() == n.story.size() + (0 if n.mystery.is_empty() else 1), "roteiro inteiro na agenda: " + n.resource_path)
		ok(plan.calls.all(func(c: PhoneCall): return c in fixed or fixed.all(func(f): return absf(c.at - f.at) >= Schedule.STORY_GAP)),
			"sorteadas longe das do roteiro: " + n.resource_path)
		var ems: Array = plan.calls.filter(func(c: PhoneCall): return c.kind == PhoneCall.Kind.EMERGENCY).map(func(c): return c.at)
		ok(range(1, ems.size()).all(func(i): return ems[i] - ems[i - 1] >= Schedule.EMERGENCY_GAP), "emergências espaçadas: " + n.resource_path)
	for c in m.find_children("*", "Control", true, false):
		if c is BaseButton or c is Slider:
			ok(c.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "sem cursor de dedo: %s" % m.get_path_to(c))

	# ---- 1. transferência completa; tirar o FONE não derruba a conversa
	var quiet: TransferCall = GameData.transfers(TransferCall.Group.ESTABLISHMENT)[0].duplicate()
	quiet.overheard = PackedStringArray()   # falas escritas seguram a linha até a última (cenário 1a)
	var a := _extra(quiet)
	a.away = false
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
	ok(not Sfx.pool.any(func(p): return p.playing and p.stream == Sfx.streams["ring"]), "atender corta o toque na hora")
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
	ok(a.options.is_empty(), "transferiu: as opções de conversa somem")
	_move(2, -1)
	ok(not a.options.is_empty(), "cancelou a transferência: as opções voltam")
	_move(2, tgt)
	m.transfer()
	ok(await wait_until(func(): return ex.dest(tgt) == Exchange.Dest.CONN), "destino atendeu")
	ok(await wait_until(func(): return a.connected), "conecta assim que o destino atende, mesmo com o FONE na entrada")
	ok(a.ended and ex.line(ln) == Exchange.Line.CONN and ex.dest(tgt) == Exchange.Dest.CONN, "conectada com o FONE na entrada")
	_move(0, -1)
	ok(ex.line(ln) == Exchange.Line.CONN and ex.dest(tgt) == Exchange.Dest.CONN, "tirar o FONE não derruba")
	m.minutes = ex.line_until(ln) + 1.0
	await frames(1)
	ok(ex.line(ln) == Exchange.Line.DONE and ex.dest(tgt) == Exchange.Dest.DONE, "conversa terminou")
	_move(1, -1)
	ok(ex.line(ln) == Exchange.Line.FREE, "linha liberada")
	_move(2, -1)
	ok(ex.dest(tgt) == Exchange.Dest.FREE and b.free_patches() == b.patches, "destino e cabo liberados")
	print("OK 1 transferência completa / tirar o FONE mantém a ligação")

	# ---- 1a. escuta: a chave sobe com o destino tocando e desce quando atendem; a tecla Escutar (Z) ou a alavanca a
	# sobe com o FONE na linha conectada; entrar na linha estala; ouvindo, a suspeita sobe (sem ouvir, baixa) e, em 1,
	# eles desligam e denunciam (advertência grave no relatório da noite seguinte)
	var ed: TransferCall = GameData.transfers(TransferCall.Group.ESTABLISHMENT)[1].duplicate()
	ed.overheard = ["Liguei pra saber da reunião de amanhã.", "Ficou pras [time:oito], na casa do [person:Benedito Souza]."]
	ed.overheard_sets = ["ouviu_teste"]
	ed.overheard_flags = ["", "ouviu_hora"]
	ed.wary = 1.5
	var ea := _extra(ed)
	ea.away = false
	m.ring(ea)
	var el := ea.line
	var et := int(ea.target)
	_move(0, el)
	m.answer()
	ok(await wait_until(_awaiting(ea)), "escuta: pedido de transferência")
	_move(1, el + 10)
	_move(2, et)
	m.transfer()
	ok(b.lever_up(el) and not ex.key(el), "escuta: a alavanca sobe com o destino tocando")
	ok(await wait_until(func(): return ea.connected), "escuta: conectada")
	ok(not b.lever_up(el), "escuta: o destino atendeu e a alavanca desceu sozinha")
	var m0 := m.minutes
	m.minutes = ex.line_until(el) + 1.0
	await frames(1)
	ok(ex.line(el) == Exchange.Line.CONN and m.eavesdrop.speaking(el), "escuta: a conversa não acaba antes das falas escritas")
	m.minutes = m0
	ex.set_line(el, Exchange.Line.CONN, m.minutes + 200.0)   # (uma conversa longa: o TALK_LEN sorteado curto acabava no meio do cenário)
	ok(m.phone._transfer.disabled and not m.phone._listen.disabled and m.phone._listen.text == "LISTEN",
		"escuta: com o FONE na linha conectada, a tecla Escutar vale")
	m.listen()
	ok(ex.key(el) and m.phone._listen.text == "LISTEN_STOP", "escuta: Z sobe a chave e a tecla vira Soltar")
	await frames(2)
	var place_wary := GameData.entry(str(et)).wary
	ok(m.eavesdrop.listening(el) and ea.suspicion >= Eavesdrop.CLICK * ed.wary * place_wary,
		"escuta: entrar na linha estala (vezes a desconfiança de quem ligou e a do lugar)")
	ed.wary = 0.5   # (ouvindo o cumprimento e as falas de uma vez, a desconfiança comum chega a denunciar)
	ok(await wait_until(func(): return m.flags.allows(["ouviu_teste"])), "escuta: ouviu as falas escritas e o marcador da ligação liga")
	ok(m.flags.allows(["ouviu_hora"]), "escuta: e o da fala ouvida")
	ok(m.eavesdrop.clues.map(func(k: Clue): return [k.word, k.kind, k.call]) == [["oito", "time", ea], ["Benedito Souza", "person", ea]],
		"escuta: as palavras-chave ouvidas inteiras ficam guardadas, sem as marcas")
	var saved := Clue.from_dict(m.eavesdrop.clues[1].to_dict())
	ok([saved.word, saved.kind, saved.night, saved.caller, saved.number] == ["Benedito Souza", "person", m.night_no, ea.caller, str(et)],
		"escuta: a palavra-chave volta igual do progresso salvo (para as noites seguintes)")
	ok(m.phone.shown().transcript.all(func(l: Dictionary): return not "[" in l["text"]), "escuta: a marca não aparece na tela")
	var marked_line: Dictionary = m.phone.shown().transcript.filter(func(l: Dictionary): return l.has("marks")).back()
	ok(marked_line["marks"].map(func(r: Array): return marked_line["text"].substr(r[0], r[1] - r[0])) == ["oito", "Benedito Souza"]
		and "[u]oito[/u]" in m.phone._transcript.text, "escuta: a palavra-chave ouvida fica sublinhada na tela")
	var notes_book: PhoneBook = m.tools.book
	m.tools.set_tab(Tools.DIRECTORY)
	notes_book.turn(notes_book._index.size())
	await frames(2)
	var heard_clues := m.eavesdrop.clues
	var n0 := heard_clues.size()
	var newest: Clue = heard_clues.back()
	ok(notes_book._clue_hits.size() == 2 and notes_book._clue_hits[0][1] == [newest], "escuta: as palavras-chave vão para a página de anotações da lista, a mais nova em cima")
	var click_on := func(k: Clue):   # clica na linha da palavra de `k`
		for h: Array in notes_book._clue_hits:
			if k in h[1]:
				_mouse(notes_book, (h[0] as Rect2).get_center(), 1)
	click_on.call(newest)
	await frames(1)
	ok(newest.chosen and Clue.from_dict(newest.to_dict()).chosen, "escuta: o clique marca a palavra-chave para repassar (e a marca fica salva)")
	click_on.call(newest)
	await frames(1)
	ok(newest.struck and not newest.chosen and Clue.from_dict(newest.to_dict()).struck and notes_book._clue_hits.back()[1] == [newest],
		"escuta: o segundo clique a risca (salvo) e ela vai para o fim da página")
	click_on.call(newest)
	await frames(1)
	ok(not newest.struck and not newest.chosen, "escuta: o terceiro volta ao normal")
	# a mesma palavra ouvida de novo, noutra conversa: herda a marca e fica numa linha só, com quantas vezes
	heard_clues[0].chosen = true
	heard_clues[0].call = null   # (como se fosse de outra conversa)
	m.eavesdrop._clue(m.eavesdrop.talks[el].ear, -1, heard_clues[0].word, heard_clues[0].kind)
	await frames(1)
	var groups := notes_book.clue_groups()
	ok(heard_clues.size() == n0 + 1 and heard_clues.back().chosen and groups.size() == 2 and groups[0].size() == 2,
		"escuta: a palavra ouvida de novo herda a marca e se junta à anotada (uma linha, ×2)")
	# muitas palavras: as anotações continuam nas páginas seguintes, cada palavra uma vez
	for i in 30:
		heard_clues.append(Clue.from_dict({"word": "palavra %d" % i, "kind": "other", "night": 1, "minutes": 0.0, "number": "305"}))
	notes_book.notes_changed()
	var shown_groups := []
	for sp in notes_book.notes_spreads():
		notes_book._open(notes_book._index.size() + sp)
		await frames(1)
		shown_groups.append_array(notes_book._clue_hits.map(func(h: Array): return h[1]))
	ok(notes_book.notes_spreads() > 1 and notes_book._next.disabled and shown_groups.size() == notes_book.clue_groups().size()
		and notes_book.clue_groups().all(func(g: Array): return shown_groups.count(g) == 1), "escuta: anotações demais seguem nas páginas seguintes")
	heard_clues.resize(n0)
	heard_clues[0].chosen = false
	notes_book.notes_changed()
	m.tools.close()
	notes_book.turn(-notes_book._index.size() - 9)
	# a desconfiança do lugar multiplica a subida da suspeita: a pensão cismada percebe mais que o bar barulhento
	var rises := []
	for num in [312, 327]:
		var probe := PhoneCall.from_transfer(ed)
		probe.dest_num = num
		m.eavesdrop._raise(probe, 0.1)
		rises.append(probe.suspicion)
	ok(is_equal_approx(rises[0], 0.1 * ed.wary * 1.6) and is_equal_approx(rises[1], 0.1 * ed.wary * 0.5),
		"escuta: a suspeita sobe pela desconfiança de quem ligou e pela do lugar (pensão 1,6, bar 0,5)")
	var plain_call: TransferCall = ed.duplicate()   # o hotel (1) se cala antes de perguntar; a pensão (1,6) pergunta já
	plain_call.wary = 1.0
	var skeptic := [305, 312].map(func(num: int):
		var probe := PhoneCall.from_transfer(plain_call)
		probe.dest_num = num
		return m.eavesdrop._wary(probe) >= Eavesdrop.SKEPTIC)
	ok(skeptic == [false, true], "escuta: os muito desconfiados não se calam, vão direto à pergunta")
	ok(ea.suspicion > Eavesdrop.CLICK and m.flags.allows(["escutou_%d" % m.night_no]), "escuta: ouvindo, a suspeita sobe e o marcador liga")
	ok(m.phone.shown() != ea and m.phone.shown().line == el, "escuta: a tela mostra o que se ouve (fora do registro da ligação)")
	ok(await wait_until(func(): return ex.line(el) == Exchange.Line.DONE), "escuta: depois da última fala escrita, eles se despedem e desligam")
	ok(not ex.key(el) and not b.lever_up(el), "escuta: a conversa acabou e a chave desceu")
	_move(0, -1)
	_move(1, -1)
	_move(2, -1)
	ok(ex.line(el) == Exchange.Line.FREE and ex.dest(et) == Exchange.Dest.FREE, "escuta: linha e destino liberados")
	# a mesma ligação sem falas escritas (só o murmúrio, até o fim do TALK_LEN): alavanca, estalo e denúncia
	ed.overheard = []
	ed.wary = 1.0
	ea = _extra(ed)
	ea.away = false
	m.ring(ea)
	el = ea.line
	et = int(ea.target)
	_move(0, el)
	m.answer()
	ok(await wait_until(_awaiting(ea)), "escuta: pedido de transferência de novo")
	_move(1, el + 10)
	_move(2, et)
	m.transfer()
	ok(await wait_until(func(): return ea.connected), "escuta: conectada de novo")
	ex.set_line(el, Exchange.Line.CONN, m.minutes + 200.0)
	m.listen()
	await frames(30)
	var heard := ea.suspicion
	m.listen()
	await frames(10)
	ok(not ex.key(el) and ea.suspicion < heard, "escuta: a chave desce e a suspeita baixa devagar")
	_move(0, -1)
	_click(b, b.lever_rect(el - 1).get_center())
	ok(not ex.key(el), "escuta: sem o FONE na linha, a alavanca não sobe")
	_move(0, el)
	_click(b, b.lever_rect(el - 1).get_center())
	ok(ex.key(el), "escuta: com o FONE, o clique na alavanca a sobe")
	await frames(2)
	var s0 := ea.suspicion
	_move(0, -1)
	await frames(2)
	_move(0, el)
	await frames(2)
	ok(ea.suspicion > s0 + Eavesdrop.CLICK * 0.5 * place_wary, "escuta: o FONE encaixando com a chave em cima também estala")
	# a reação, no tempo: passando de HUSH com ele ouvindo, calam-se; soltando no silêncio, a conversa segue; ouvindo,
	# um pergunta; soltando no fim da pergunta, desconversam; ouvindo, o outro responde, eles sabem e, calados, reclamam
	var ear_now: PhoneCall = m.eavesdrop.talks[el].ear
	var hush_text := T.text(T.Key.SYS_LINE_SILENT)
	var silent := func(): return str(ear_now.transcript[-1]["text"]).begins_with(hush_text)
	var ask_heard := func(): return ear_now.transcript.any(func(l: Dictionary): return GameData.CONTENT.overheard_ask.has(l["text"]))
	ea.suspicion = Eavesdrop.HUSH
	ok(await wait_until(silent), "escuta: passando de HUSH com ele ouvindo, calam-se")
	ok(m.eavesdrop.silent == el, "escuta: no silêncio, o chiado da linha sobe")
	ok(await wait_until(func(): return str(ear_now.transcript[-1]["text"]).count("·") == 2), "escuta: no silêncio, um ponto a cada segundo")
	var said_before := ear_now.transcript.size()
	await frames(10)
	ok(ear_now.transcript.size() == said_before, "escuta: calados, a conversa não anda")
	m.listen()
	await frames(int(Eavesdrop.HUSH_SEC * 60 / Engine.time_scale) + 10)
	ok(not ask_heard.call() and not m.eavesdrop.knows(el) and ex.line(el) == Exchange.Line.CONN,
		"escuta: soltando a chave no silêncio, ninguém pergunta e a conversa segue")
	ok(m.eavesdrop.silent == -1, "escuta: acabado o silêncio, o chiado volta ao de sempre")
	m.listen()
	ea.suspicion = Eavesdrop.HUSH
	ok(await wait_until(silent), "escuta: de novo, calam-se")
	ok(await wait_until(func(): return ear_now.transcript[-1]["who"] != ""), "escuta: depois do silêncio, um pergunta")
	m.listen()
	await frames(int(4.0 * 60 / Engine.time_scale))
	ok(ea.suspicion < Eavesdrop.HUSH and not m.eavesdrop.knows(el), "escuta: sem ninguém ouvindo o fim da pergunta, desconversam")
	m.listen()
	ea.suspicion = Eavesdrop.HUSH
	var faults_was := m.report.faults.size()
	var later_was := m.report.later.size()
	ok(await wait_until(func(): return m.eavesdrop.knows(el)), "escuta: ouvindo até o fim da pergunta, vem a resposta")
	ok(m.report.later.size() == later_was + 1 and m.report.faults.size() == faults_was and m.report.later[-1]["id"] == "eavesdrop"
		and m.flags.allows(["denunciado_%d" % m.night_no]), "escuta: sabendo, a denúncia é certa (fica para o relatório de amanhã), e o marcador")
	ok(await wait_until(func(): return ear_now.transcript.any(func(l: Dictionary): return GameData.CONTENT.overheard_sure.has(l["text"]))),
		"escuta: a resposta é a da pergunta e aparece na tela")
	ok(await wait_until(silent), "escuta: sabendo, calam-se de novo")
	m.listen()   # soltar a chave agora não desfaz a denúncia; a conversa segue
	await frames(int((Eavesdrop.HUSH_SEC + 1.0) * 60 / Engine.time_scale))
	ok(ex.line(el) == Exchange.Line.CONN and m.eavesdrop.knows(el) and m.report.later.size() == later_was + 1,
		"escuta: soltando a chave sabendo, a conversa segue e a denúncia continua de pé")
	m.listen()
	ea.suspicion = Eavesdrop.HUSH
	var hung_up := func(): return ear_now.transcript.any(func(l: Dictionary): return GameData.CONTENT.overheard_caught.has(l["text"]))
	ok(await wait_until(hung_up), "escuta: sabendo e com ele ouvindo, calam-se e reclamam")
	ok(m.report.later.size() == later_was + 1, "escuta: a reclamação não denuncia duas vezes")
	m.report.later.clear()
	ok(await wait_until(func(): return ex.line(el) == Exchange.Line.DONE), "escuta: os dois desligam")
	ok(not ex.key(el) and not b.lever_up(el), "escuta: a conversa acabou e a chave desceu")
	_move(0, -1)
	_move(1, -1)
	_move(2, -1)
	ok(ex.line(el) == Exchange.Line.FREE and ex.dest(et) == Exchange.Dest.FREE, "escuta: linha e destino liberados")
	var grudged: DirectoryEntry = GameData.entry(str(ea.dest_num))
	ok(m.eavesdrop.grudges.get(str(ea.dest_num), 0) == 1 and is_equal_approx(m.eavesdrop._wary(ea), ed.wary * (grudged.wary + Eavesdrop.GRUDGE)),
		"escuta: o lugar que denunciou fica mais desconfiado")
	m.eavesdrop.calm()
	# a pergunta que ninguém ouviu acabar: as falas escritas seguem com quem as diz (A, quem ligou; B, o lugar)
	ed.overheard = ["Fala A0", "Fala B1", "Fala A2", "Fala B3"]
	ea = _extra(ed)
	ea.away = false
	m.ring(ea)
	el = ea.line
	et = int(ea.target)
	_move(0, el)
	m.answer()
	ok(await wait_until(_awaiting(ea)), "escuta: pedido de transferência, falas de teste")
	_move(1, el + 10)
	_move(2, et)
	m.transfer()
	ok(await wait_until(func(): return ea.connected), "escuta: conectada, falas de teste")
	m.listen()
	var ear2: PhoneCall = m.eavesdrop.talks[el].ear   # (os lambdas guardam a variável de quando foram criados)
	ok(await wait_until(func(): return ear2.transcript.any(func(l: Dictionary): return str(l["text"]).ends_with("A0"))), "escuta: a primeira fala escrita")
	ea.suspicion = Eavesdrop.HUSH
	ok(await wait_until(func(): return str(ear2.transcript[-1]["text"]).begins_with(hush_text)), "escuta: calados, falas de teste")
	ok(await wait_until(func(): return ear2.transcript[-1]["who"] != ""), "escuta: a pergunta começa")
	m.listen()
	await frames(int(4.0 * 60 / Engine.time_scale))
	ok(not m.eavesdrop.knows(el), "escuta: a pergunta sem ninguém ouvindo o fim fica sem resposta")
	m.listen()
	ea.suspicion = 0.0
	ok(await wait_until(func(): return ex.line(el) == Exchange.Line.DONE), "escuta: as falas de teste acabam")
	var speakers := {}
	for l: Dictionary in ear2.transcript:   # pelo número no fim: entrando no meio, a fala começa com "…"
		for t in ["0", "1", "2", "3"]:
			if str(l["text"]).ends_with(t):
				speakers[t] = l["who"]
	ok(speakers.get("2") == tr(ea.caller) and speakers.get("3") == m.eavesdrop._other(ea) and speakers.get("1") != tr(ea.caller),
		"escuta: depois da pergunta sem resposta, cada fala escrita fica com quem a diz")
	_move(0, -1)
	_move(1, -1)
	_move(2, -1)
	var lesson := _extra(GameData.transfers(TransferCall.Group.ESTABLISHMENT)[0])
	lesson.line = el
	lesson.lesson = true
	m.eavesdrop.connected(lesson)
	ok(not m.eavesdrop.talks.has(el), "escuta: a conversa do treinamento não se escuta")
	print("OK 1a escuta")

	# ---- 1b. interurbano: a saída no tronco da cidade; a telefonista de lá pede o número e completa
	ok(GameData.TRUNKS.size() == C.trunk_to.size() and GameData.TRUNKS.all(func(d): return ex.has_dest(d) and b.jack_at(b.jack_rect(d).get_center()) == d),
		"os troncos são tomadas de destino da mesa")
	var lt := GameData.trunk_transfer()
	var lc := _extra(lt)
	m.ring(lc)
	ln = lc.line
	_move(0, ln)
	m.answer()
	ok(await wait_until(_awaiting(lc)), "pedido de interurbano")
	tgt = int(lt.target)
	var wrong_trunk: int = GameData.TRUNKS.filter(func(d): return d != tgt)[0]
	_move(1, ln + 10)
	_move(2, wrong_trunk)
	m.transfer()
	ok(await wait_until(func(): return lc.wrong == 1 and ex.dest(wrong_trunk) == Exchange.Dest.FREE and not lc.talking), "tronco errado: o número não é de lá")
	ok(not lc.options.is_empty() and not lc.ended, "tronco errado: a transferência volta")
	_move(2, tgt)
	m.transfer()
	ok(await wait_until(func(): return lc.connected), "tronco certo: a telefonista de lá completa")
	ok(lc.transcript.any(func(l): return lt.far_number in String(l["text"])), "o operador passou o número de lá")
	ok(ex.line(ln) == Exchange.Line.CONN and ex.dest(tgt) == Exchange.Dest.CONN, "interurbano conectado")
	ok(m.toll.counting(ln) and m.toll.tickets().is_empty(), "o calculógrafo conta o interurbano")
	await frames(1)
	ok(m.background.counting == 1 << ln, "no calculógrafo da sala, o contador da entrada acende")
	m.minutes = ex.line_until(ln) + 1.0
	await frames(1)
	var tk: TollTicket = m.toll.tickets()[0] if m.toll.tickets().size() == 1 else null
	ok(tk != null and not m.toll.counting(ln) and tk.line == ln and tk.city == GameData.trunk_city(tgt) and tk.far == lt.far_number
		and tk.minutes() >= 1, "a conversa acabou: o calculógrafo imprimiu o bilhete")
	ok(lc.record != null and lc.record.ticket == tk.serial, "o número do bilhete vai para o caderno")
	for e in [0, 1, 2]:
		_move(e, -1)
	ok(ex.line(ln) == Exchange.Line.FREE and ex.dest(tgt) == Exchange.Dest.FREE, "interurbano encerrado")
	var toll_faults := m.report.faults.size()
	m.toll.file(tk)
	ok(m.report.faults.size() == toll_faults + 1 and m.report.faults[-1]["id"] == "toll_unstamped" and m.toll.tickets().is_empty(),
		"bilhete sem carimbo na caixinha: advertência leve")
	m.toll.start(5, "Capital", "45-12", m.minutes)
	var tk2 := m.toll.stop(5, m.minutes + 3.2)
	await frames(1)
	ok(m.background.tickets == 1, "impresso com ele fechado, na sala a ponta sai da fenda")
	m.tools.set_tab(Tools.TOLL)
	await frames(2)
	ok(tk2.clip_contents, "impresso com o calculógrafo fechado, o bilhete sai da fenda quando ele abre")
	await frames(28)
	var stamp: Control = m.toll._stamp
	await _drag_mouse(_grip(), tk2.get_global_rect().get_center() - Toll.RUBBER_MID + stamp.size / 2.0)
	ok(not tk2.stamped and (stamp.get_global_position() + Toll.RUBBER_MID).distance_to(tk2.get_global_rect().get_center()) < 1.5, "carimbo levado até o bilhete: ainda não carimba")
	var desk_at := m.toll._desk.position
	await _tap_mouse(_grip())
	await frames(int(Toll.PRESS_SEC * 60.0) + 2)
	var mark := tk2.mark
	ok(tk2.stamped and (stamp.get_global_position() + Toll.RUBBER_MID).distance_to(tk2.get_global_rect().get_center()) < 1.5, "clicado em cima do bilhete, carimba (e fica no lugar)")
	ok(m.toll._desk.position == desk_at, "a mesa sacudida pela batida volta ao lugar")
	await _stamp_at(tk2.get_global_rect().get_center() + Vector2(24, 6))
	ok(tk2.mark == mark and tk2.minutes() == 4, "uma marca só; o minuto começado conta inteiro")
	var desk: Control = m.toll._desk
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = tk2.get_global_position() + Vector2(10, 80)
	get_viewport().push_input(press)
	await frames(2)
	var was_held := tk2.held
	m.tools.close()
	var release := press.duplicate()
	release.pressed = false
	get_viewport().push_input(release)
	await frames(2)
	ok(was_held and not tk2.held and m.toll._held == null, "guardou a ferramenta com o bilhete na mão: ele fica na mesa")
	m.tools.set_tab(Tools.TOLL)
	await frames(30)
	await _drag_mouse(tk2.get_global_position() + Vector2(10, 80), desk.get_global_position() + m.toll._box().get_center())
	m.tools.close()
	ok(m.report.faults.size() == toll_faults + 1 and m.toll.filed == 2 and m.toll.tickets().is_empty(), "carimbado, arrastado até a caixinha sem advertência")
	ok(is_instance_valid(tk2) and tk2.clip_contents, "o bilhete desce para dentro da caixinha")
	await frames(20)
	ok(not is_instance_valid(tk2), "e some lá dentro")
	m.tools.set_tab(Tools.TOLL)
	await frames(2)
	var tk3 := _ticket(6)
	ok(tk3.clip_contents and m.toll._piece_at(tk3.get_rect().get_center()) != tk3, "com o calculógrafo aberto, o bilhete sai da fenda (e não se pega antes)")
	await frames(20)
	ok(not tk3.clip_contents and tk3.position.y >= 0.0, "e cai na mesa")
	var aside := Vector2(roundf(desk.size.x / 2.0 - stamp.size.x / 2.0), desk.size.y - stamp.size.y - 6.0)   # o bilhete novo cai por cima do carimbo
	stamp.position = aside
	await _stamp_at(tk3.get_global_rect().get_center())
	ok(tk3.stamped and tk3.ink == 0.5, "a segunda batida sai mais fraca")
	var tk4 := _ticket(7)
	await frames(20)
	stamp.position = aside
	await _stamp_at(tk4.get_global_rect().get_center())
	ok(not tk4.stamped and tk4.ink == 0.0, "com a borracha seca, fica só o vulto e não vale")
	await _drag_mouse(_grip(), desk.get_global_position() + m.toll._pad().get_center() - Toll.RUBBER_MID + stamp.size / 2.0)
	await _stamp_at(tk4.get_global_rect().get_center())
	ok(not tk4.stamped, "solto na almofada sem apertar, não ganha tinta")
	await _stamp_at(desk.get_global_position() + m.toll._pad().get_center())
	await _stamp_at(tk4.get_global_rect().get_center())
	ok(tk4.stamped and tk4.ink == 1.0, "passado na almofada, volta a marcar")
	var pad := desk.get_global_position() + m.toll._pad().get_center()
	await _stamp_at(pad)
	var tk5 := _ticket(8)
	await frames(20)
	await _stamp_at(tk5.get_global_rect().position + Vector2(10, 60))
	ok(tk5.stamped and tk5.mark.distance_to(Vector2(10, 60)) < 1.5, "na beira, a marca fica onde bateu (cortada no papel) e vale com mais da metade dentro")
	var tk6 := _ticket(9)
	await frames(20)
	await _stamp_at(tk6.get_global_rect().position + Vector2(-10, 60))
	ok(not tk6.stamped and tk6.ink > 0.0 and tk6.mark.x < 0.0, "com menos da metade no papel, é borrão: com tinta e não vale")
	await _stamp_at(pad)
	await _stamp_at(tk6.get_global_rect().get_center())
	ok(tk6.stamped and tk6.marks.size() == 2, "carimbado de novo, vale, e o borrão continua no papel")
	m.tools.close()
	ok(await wait_until(func(): return m.background.toll_desk.size() == 4 + m.toll.tickets().size()) and m.background.toll_desk[-1][1].size() == 2,
		"guardado, o calculógrafo da sala mostra os bilhetes soltos com as marcas")
	print("OK 1b interurbano pelo tronco da cidade")

	# ---- 2. três ligações ao mesmo tempo, com espera
	var t1 := _extra(GameData.transfers(TransferCall.Group.ESTABLISHMENT)[1])
	var info: PhoneCall = Schedule.info_call()
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
		if lbl.contains(info.answer):
			right = lbl
	_pick(info, right)
	await frames(2)           # ninguém clica e arrasta o FONE no mesmo quadro
	_move(0, t1.line)         # respondeu e já foi para t1: a pessoa agradece sozinha e desliga
	ok(ex.line(info.line) != Exchange.Line.HOLD, "resolvida não fica em espera")
	var said := info.transcript.size()
	ok(await wait_until(func(): return info.ended), "informação encerrada sem o operador voltar")
	ok(info.transcript.slice(said).all(func(t): return t["cls"] == "sys"), "fora da linha, a fala não aparece")
	ok(info.info_ok == 1 and ex.line(info.line) == Exchange.Line.FREE, "respondeu certo; linha liberada")
	ok(ex.line(t1.line) == Exchange.Line.TALK and m.phone.shown() == t1, "voltou para t1")
	ok(t3.ringing and m.live.size() == 2, "t3 ainda tocando")
	print("OK 2 três ligações simultâneas / espera")

	# ---- 3. t3 desiste; caderno em fila
	ok(await wait_until(func(): return t3.ended, 10.0), "t3 desistiu")
	ok(t3.record.obs == T.text(T.Key.OBS_NOT_ANSWERED), "registro de não atendida")
	var nb = m.notebook
	ok(nb.entries.back().type == T.Key.TYPE_MISSED and not nb.queue.any(func(r): return r.missed), "não atendida registrada sozinha")
	ok(nb.queue.size() >= 1, "ocorrências em fila")
	var before: int = nb.queue.size()
	var wrote: int = m.background.written
	nb.register(T.Key.TYPE_COMMON)
	ok(nb.queue.size() == before - 1 and nb.has_pending(), "registrou uma, a próxima veio da fila")
	ok(m.background.written == wrote + 1, "o lápis do bloco da mesa muda de lugar a cada registro")
	ok(m.background.pending == nb.pending_count(), "o caderno da mesa mostra quantas faltam")
	ok(nb.entries.back()["type"] == T.Key.TYPE_COMMON, "registrada com o tipo do clique")
	# as ocorrências chegaram com a aba fechada: aberta, a página do livro ocupa toda a área (com e sem a ficha)
	m.tools.set_tab(Tools.LOGBOOK)
	await frames(3)
	ok(nb._page.size.y >= nb._scroll.size.y - 1, "página do caderno preenche a área (com ficha)")
	while nb.has_pending():
		nb.register(T.Key.TYPE_COMMON)
	await frames(3)
	ok(not nb._form.visible and nb._page.size.y >= nb._scroll.size.y - 1 and nb._scroll.size.y > 300, "sem ficha, a página cresce até embaixo")
	m.tools.set_tab(Tools.DIRECTORY)
	print("OK 3 desistência / fila do caderno")

	# ---- 4. o lugar pedido não atende (sorteado) e o operador sugere a alternativa
	m.hangup()
	ok(ex.line(t1.line) == Exchange.Line.DONE, "desligar deixa a linha em desligou")
	_move(0, -1)
	ok(ex.line(t1.line) == Exchange.Line.FREE, "tirar o FONE libera")
	var fa := _extra(GameData.transfers(TransferCall.Group.EXTRA)[3])   # Farmácia Central -> Santa Rita
	fa.away = true
	m.ring(fa)
	var fl := fa.line
	_move(0, fl)
	m.answer()
	ok(await wait_until(_awaiting(fa)), "pedido da farmácia")
	_move(3, fl + 10)
	_move(4, 118)
	m.transfer()
	ok(await wait_until(func(): return fa.no_answer), "ninguém atende")
	ok(m.talk_clock - fa.last_talk < 1.0 and fa.chat == null, "chamando não conta como silêncio: a conversa fiada não vem junto da alternativa")
	_pick(fa, T.text(T.Key.CHOICE_OFFER_ALT))
	ok(fa.target == "162", "trocou para a de plantão")
	ok(await wait_until(func(): return fa.transcript.any(func(l): return l["text"] == (fa.data as TransferCall).alt_ask)),
		"o botão é curto, mas o operador diz a oferta inteira")
	_move(4, 162)
	ok(await wait_until(func(): return not fa.talking), "terminou de falar")
	m.transfer()
	_move(0, -1)              # tira o FONE com o destino ainda tocando
	ok(ex.line(fl) == Exchange.Line.HOLD and not fa.ended, "em espera durante o toque")
	ok(await wait_until(func(): return fa.connected), "completa sozinha quando o destino atende")
	ok(fa.record.where == "Farmácia Santa Rita" and fa.record.obs == "", "registro com o destino novo")
	print("OK 4 não atende / alternativa / FONE fora durante o toque")

	# ---- 5. cortar uma conversa em andamento puxando a SAÍDA
	_move(3, -1)
	ok(ex.line(fl) == Exchange.Line.FREE and ex.dest(162) == Exchange.Dest.DONE, "cortou a conversa")
	_move(4, -1)
	ok(ex.dest(162) == Exchange.Dest.FREE, "destino liberado")
	print("OK 5 cortar conversa")

	# ---- 6. ligar de volta para o número desconhecido (pela entrada por onde ele veio)
	m.after = true
	m.myst_line = 4
	_move(0, 4)
	ok(await wait_until(func(): return m.phone.display_text() == T.text(T.Key.DISPLAY_NO_NUMBER), 10.0), "número não existe")
	ok(m.flags.has("ligou_de_volta_1"), "marcador automático: ligou de volta")
	print("OK 6 ligação de volta ao desconhecido")

	# ---- 7. clicar num plug encaixado devolve à base (com animação); arrastar move
	var c7 := _extra(GameData.transfers(TransferCall.Group.ESTABLISHMENT)[0])
	m.after = false
	# o fio sozinho (`Switchboard.Cord`, sem mesa): preso nas duas pontas, com folga, deita na prateleira e dorme;
	# solto, o plug cai, bate nela e quica
	var cord := Switchboard.Cord.new(Vector2.ZERO, Vector2(200, 0))
	cord.floor_y = 40.0
	for _i in 400:
		cord.step(b.STEP, Vector2.ZERO, Vector2(200, 0), 260.0)
	var lowest := 0.0
	for q in cord.pts:
		lowest = maxf(lowest, q.y)
	ok(is_equal_approx(lowest, 40.0) and cord.asleep() and not cord.step(b.STEP, Vector2.ZERO, Vector2(200, 0), 260.0),
		"fio: deita na prateleira (%.1f) e dorme parado" % lowest)
	cord.free = true
	var bounced := false
	for _i in 200:
		cord.step(b.STEP, Vector2.ZERO, Vector2.ZERO, 260.0)
		bounced = bounced or cord.drop > Switchboard.Cord.BOUNCE_MIN
	ok(bounced and cord.tip().y <= 40.0 + 0.01, "fio: o plug solto cai, quica e para na prateleira")
	# a forma do fio encaixado: saindo da ponteira na horizontal, ele faz a curva e cai, sem subir acima do plug
	# (o calombo de quando a curva era um empurrão nos pontos), e o comprimento quase não estica
	for want: float in [440.0, 540.0, 640.0]:   # do buraco ao plug são 424 px
		var hung := Switchboard.Cord.new(Vector2(0, 300), Vector2(300, 0))
		hung.stub = Vector2.LEFT
		for _i in 600:
			hung.step(b.STEP, Vector2(0, 300), Vector2(300, 0), want)
		var high := INF
		var long := 0.0
		for i in hung.pts.size():
			high = minf(high, hung.pts[i].y)
			if i > 0:
				long += hung.pts[i].distance_to(hung.pts[i - 1])
		ok(high >= -1.0, "fio: com %d px, não sobe acima do plug (%.1f)" % [want, high])
		ok(long <= want * 1.02, "fio: com %d px, estica menos de 2%% (%.0f)" % [want, long])
	m.ring(c7)
	var l7 := c7.line
	_move(0, -1)
	await frames(1)
	_move(0, l7)
	var jc: Vector2 = b.jack_rect(l7).get_center()
	b._press(jc)
	b._release(jc)
	ok(b.ends[0] == -1 and b.held == -1 and b._loose.has(0), "FONE solto, caindo")
	await frames(2)
	var air: Vector2 = b._plug_base(0) + Vector2(0, -14).rotated(b._plug_angle(0))
	b._press(air)
	ok(b.held == 0 and not b._loose.has(0), "pega o FONE no ar (segurando)")
	b.cursor = Vector2(400, 200)   # longe do encaixe: cai antes de recolher
	b._mouse_vel = Vector2(1200, 0)
	b.go_home(0)
	ok(not b._loose[0]["direct"] and b.ropes[0].old[b.ropes[0].pts.size() - 1].x < 400 - 5, "sai com o embalo da mão")
	ok(await wait_until(func(): return not b._loose.has(0), 5.0), "o fio recolheu o FONE")
	ok(not b.ropes.has(0), "fio do FONE todo dentro do encaixe")
	_move(1, l7 + 10)
	_move(2, 142)
	var jd: Vector2 = b.jack_rect(142).get_center()
	b._press(jd)
	b._release(jd)
	ok(b.ends[2] == -1 and b.ends[1] == l7 + 10, "só a ponta clicada volta")
	ok(b.free_patches() < b.patches, "o cabo só volta à base com as duas pontas")
	var js: Vector2 = b.jack_rect(l7 + 10).get_center()
	# tirado da tomada e devolvido a ela no mesmo arraste: soltava perto de onde apertou, contava como clique e caía
	_mouse(b, js, 1)
	_mouse(b, js + Vector2(60, -40))
	_mouse(b, js, 0)
	ok(b.ends[1] == l7 + 10, "devolvido à mesma tomada no mesmo arraste, encaixa de novo")
	# apertado e segurado parado (não é clique): soltar sobre a mesma tomada encaixa de novo
	_mouse(b, js, 1)
	ok(b.held == 1, "segurando o plug que saiu da tomada")
	await frames(30)
	_mouse(b, js, 0)
	ok(b.ends[1] == l7 + 10, "segurado parado e solto na mesma tomada, encaixa de novo")
	b._press(js)
	b._release(js)
	ok(b.ends[1] == -1, "a outra ponta também voltou")
	ok(await wait_until(func(): return b._loose.is_empty(), 5.0), "animações terminaram")
	ok(b.free_patches() == b.patches, "cabo de volta à base")
	_move(0, l7)
	var other_in := 1 if l7 != 1 else 2
	b._press(jc)
	b._release(b.jack_rect(other_in).get_center())
	ok(b.ends[0] == other_in, "arrastar move o FONE")
	ok(b._order.back() == 0, "o último plug mexido fica por cima")
	ok(await wait_until(func(): return b.ropes.has(0) and b.ropes[0].asleep(), 10.0), "fio parado deixa de ser simulado")
	_move(0, l7)
	await frames(1)
	ok(not b.ropes[0].asleep() and b.ropes[0].tip() == b._plug_base(0), "mexer no plug acorda o fio")
	var hp: Vector2 = b.home_pos(3)
	b._press(hp)
	b._release(hp)
	ok(b.held == -1 and b.ends[3] == -1, "clique sem arrastar não pega o plug da base")
	var reach := true   # o plug guardado inteiro aceita o clique (o vão entre o painel e a prateleira também)
	for y in range(int(b._rest(3).y - b.PLUG_H + b.PLUG_SINK), int(b.hole(3).y + b.HOLE_LIP)):
		reach = reach and b._has_point(Vector2(b._rest(3).x, y)) and b._plug_under(Vector2(b._rest(3).x, y)) == 3
	ok(reach, "o plug guardado aceita o clique em toda a altura")
	print("OK 7 clique desconecta / arrastar move")

	# ---- 8. o homem na janela: chega andando, fica embaixo do poste de 25 a 10 min antes da ligação desconhecida e
	# volta andando (vai ligar)
	var myst := PhoneCall.mystery()
	myst.at = m.minutes + 60.0   # na agenda, mas sem tocar durante o teste
	m.myst_plan = myst.at
	m.sched.append(myst)
	await frames(1)
	var bg := m.background
	ok(is_nan(bg._man_x()), "ainda não aparece")
	m.myst_plan = m.minutes + Main.SHADOW_LEAD + Background.MAN_WALK / 2.0
	await frames(1)
	ok(bg._man_x() > Background.MAN_X and bg._man_x() < Background.MAN_FROM, "chegando andando: %.1f m" % bg._man_x())
	m.myst_plan = m.minutes + 20.0
	await frames(1)
	ok(bg._man_x() == Background.MAN_X, "parado embaixo do poste")
	m.myst_plan = m.minutes + Main.SHADOW_LEAVE - Background.MAN_WALK / 2.0
	await frames(1)
	ok(bg._man_x() > Background.MAN_X and bg._man_x() < Background.MAN_FROM, "indo embora andando: %.1f m" % bg._man_x())
	m.myst_plan = m.minutes + 1.0
	await frames(1)
	ok(is_nan(bg._man_x()), "foi ligar")
	m.sched.erase(myst)
	print("OK 8 o homem na janela")

	# ---- 9. marcadores do roteiro: condição, escolha que muda a conversa e ligação do roteiro conferida na hora
	var sf := StoryFlags.new(PackedStringArray(["a"]))
	ok(sf.allows(PackedStringArray(["a", "!b"])) and not sf.allows(PackedStringArray(["b"])), "condição com e sem !")
	sf.apply("!a")
	sf.apply("b")
	ok(not sf.has("a") and sf.has("b") and sf.names() == PackedStringArray(["b"]), "liga e desliga")
	var ask := _step(PrankStep.Kind.OPERATOR)
	ask.options = PackedStringArray(["Sim.", "Não."])
	ask.sets = PackedStringArray(["disse_sim", ""])
	var pk := PrankCall.new()
	pk.caller = "Teste"
	pk.steps.append(ask)
	pk.steps.append(_step(PrankStep.Kind.CALLER, "Que bom.", PackedStringArray(["disse_sim"])))
	pk.steps.append(_step(PrankStep.Kind.CALLER, "Que pena.", PackedStringArray(["!disse_sim"])))
	pk.steps.append(_step(PrankStep.Kind.END))
	m.flags = StoryFlags.new()
	var pc := PhoneCall.from_prank(pk)
	m.ring(pc)
	_move(0, pc.line)
	m.answer()
	ok(await wait_until(func(): return not pc.options.is_empty()), "escolha do operador")
	_pick(pc, "Sim.")
	ok(await wait_until(func(): return pc.ended), "conversa terminou")
	var lines := pc.transcript.map(func(t): return t["text"])
	ok(m.flags.has("disse_sim") and "Que bom." in lines and not "Que pena." in lines, "a escolha ligou o marcador e mudou a fala")
	_move(0, -1)
	var sc := PhoneCall.from_transfer(GameData.transfers(TransferCall.Group.EXTRA)[1])
	m.minutes = minf(m.minutes, m.last_call - 60.0)   # o relógio andou com os cenários de antes; depois de `last_call` nada toca
	sc.requires = PackedStringArray(["!disse_sim"])
	sc.at = m.minutes
	m.sched.push_front(sc)
	m._run_schedule()
	ok(not sc in m.live and not sc in m.sched, "condição não bate: a ligação do roteiro não toca")
	sc.requires = PackedStringArray(["disse_sim"])
	m.night = m.night.duplicate()
	m.pace.max_live = 10   # a agenda de verdade pode já ter ligações tocando; aqui só importa o marcador
	m.sched.push_front(sc)
	m._run_schedule()
	ok(sc in m.live, "condição bate: toca")
	print("OK 9 marcadores do roteiro")

	# ---- 10. pausa e configurações
	m.end_call(sc, PhoneCall.End.OPERATOR)
	var esc := InputEventKey.new()
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	_move(1, 11)
	b.pick_up(1)
	m._unhandled_input(esc)
	ok(not get_tree().paused and b.ends[1] == -1, "com plug na mão, o Esc só devolve o plug")
	await frames(2)
	var rc := _extra(GameData.transfers(TransferCall.Group.EXTRA)[2])
	m.ring(rc)
	m._unhandled_input(esc)
	ok(get_tree().paused and m._pause.visible, "Esc pausa o turno")
	var frozen: float = m.minutes
	await frames(int(m.GIVE_UP_SEC * 60.0 / Engine.time_scale) + 60)
	ok(m.minutes == frozen and rc.ringing, "na pausa o relógio para e ninguém desiste")
	m._pause._unhandled_input(esc)
	ok(not get_tree().paused and not m._pause.visible, "Esc no menu continua")
	m.end_call(rc, PhoneCall.End.OPERATOR)
	m._pause.open_settings()
	Settings.set_volume("Effects", 0.3)
	ok(not m._pause.get_node("%Apply").disabled, "Aplicar acende com mudança")
	m._pause._back()
	ok(Settings.volumes["Effects"] == 1.0 and not m._pause.visible, "Voltar descarta")
	m._pause.open_settings()
	ok(m._pause.get_node("%Apply").disabled, "sem mudança, Aplicar apagado")
	Settings.set_volume("Effects", 0.3)
	m._pause._apply_settings()
	ok(Settings.volumes["Effects"] == 0.3 and not m._pause.visible, "Aplicar mantém")
	Settings.set_volume("Effects", 1.0)
	Settings.set_locale("en")
	ok(T.text(T.Key.RESUME) == "Resume" and Settings.locale == "en", "idioma muda na hora")
	Settings.set_locale("pt_BR")
	Settings.set_volume("Effects", 0.5)
	ok(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Effects")) - linear_to_db(0.5)) < 0.01, "volume do barramento")
	Settings.set_volume("Effects", 1.0)
	print("OK 10 pausa e configurações")

	# ---- 11. esperando a transferência: às vezes conversa fiada depois de um tempo; se demorar mais, reclama
	var wc := _extra(GameData.transfers(TransferCall.Group.EXTRA)[3])
	m.ring(wc)
	_move(0, wc.line)
	m.answer()
	ok(await wait_until(_awaiting(wc)), "pedido feito")
	var said_at := []
	var asked := wc.transcript.size()
	while said_at.size() < 2 and not failed:
		var t0: float = m.talk_clock
		var n := wc.transcript.size()
		ok(await wait_until(func(): return wc.transcript.size() > n and not wc.talking, 60.0), "falou enquanto esperava")
		said_at.append([m.talk_clock - t0, String(wc.transcript.back()["text"])])
	var waiting: Array = Array(C.waiting)
	var chat: Array = (C.smalltalk + m.night.smalltalk).map(func(t): return t.line)
	ok(said_at[0][0] >= m.SMALLTALK_AFTER and (said_at[0][1] in chat or said_at[0][1] in waiting), "primeira fala só depois de um tempo: " + said_at[0][1])
	ok(said_at[1][1] in waiting, "depois reclama da demora: " + said_at[1][1])
	ok(asked > 0 and not wc.transcript.slice(0, asked).any(func(l): return String(l["text"]) in chat), "sem conversa fiada logo depois do pedido")
	m.end_call(wc, PhoneCall.End.OPERATOR)
	print("OK 11 conversa fiada e reclamação na espera")

	# ---- 11b. responder a conversa fiada: ela continua o assunto e a reclamação da demora fica para depois
	var cc := _extra(GameData.transfers(TransferCall.Group.EXTRA)[3])
	m.ring(cc)
	_move(0, cc.line)
	m.answer()
	ok(await wait_until(_awaiting(cc)), "pedido feito")
	var reply_with := func(tone: ChatReply.Tone) -> ChatReply:   # clica na resposta do tom pedido
		var r: ChatReply = cc.chat.replies.filter(func(x): return x.tone == tone)[0]
		cc.options.filter(func(o): return String(o["label"]) == r.text)[0]["fn"].call()
		return r
	m.conversation.heard.clear()
	m.flags.apply("!prometeu_quermesse")
	m.conversation.smalltalk(cc)
	ok(await wait_until(func(): return cc.chat != null and not cc.talking), "conversa fiada pede resposta")
	var topic: ChatTopic = cc.chat
	ok(topic == m.night.smalltalk[0] and topic in m.conversation.heard and not topic in m.conversation.topics(), "novidade da noite vem primeiro, uma vez só")
	ok(String(cc.transcript.back()["text"]) == topic.line, "puxou o assunto")
	var labels: Array = cc.options.slice(-topic.replies.size()).map(func(o): return String(o["label"]))
	ok(labels == topic.replies.map(func(r): return r.text), "as respostas do assunto viram opções (por último)")
	var warm: ChatReply = reply_with.call(ChatReply.Tone.WARM)
	ok(cc.chat == null and cc.chats == [topic] and not cc.chatted, "respondida: pode puxar outro assunto")
	ok(m.flags.has("prometeu_quermesse"), "a resposta liga o marcador")
	ok(C.nights[1].smalltalk.filter(func(t): return m.flags.allows(t.requires)).map(func(t): return t.line)
		== [C.nights[1].smalltalk[0].line], "na noite seguinte, a cidade lembra da promessa")
	ok(await wait_until(func(): return not cc.talking and String(cc.transcript.back()["text"]) == warm.follow), "ela continua o mesmo assunto")
	ok(cc.transcript.any(func(l): return l["cls"] == "op" and l["text"] == warm.text), "operador respondeu")
	var t_reply: float = m.talk_clock
	var n_reply := cc.transcript.size()
	ok(await wait_until(func(): return cc.transcript.size() > n_reply and not cc.talking, 60.0), "volta a falar depois")
	ok(m.talk_clock - t_reply >= m.SMALLTALK_AFTER + m.conversation.CHAT_WARM_PATIENCE, "simpática: ela espera mais antes de falar de novo")
	# o operador também puxa assunto (uma vez); resposta seca: ela não puxa mais
	var ask_opt := func(): return cc.options.filter(func(o): return String(o["label"]) == T.text(T.Key.CHOICE_SMALLTALK))
	if cc.chat != null:   # ela pode ter puxado outro assunto sozinha
		reply_with.call(ChatReply.Tone.WARM)
	ok(await wait_until(func(): return not cc.talking and not cc.chatting), "assunto encerrado")
	var pulled := cc.chats.size()
	ok(ask_opt.call().size() == 1, "operador pode puxar assunto")
	ask_opt.call()[0]["fn"].call()
	ok(ask_opt.call().is_empty(), "a opção some no clique")
	ok(await wait_until(func(): return cc.chat != null and not cc.talking), "ela conta alguma coisa")
	ok(cc.chats.size() == pulled + 1 and String(cc.transcript.back()["text"]) == cc.chat.line, "outro assunto")
	ok(String(cc.transcript[-2]["text"]) in Array(C.chat_bridge) and not cc.chat.unprompted_only, "responde à pergunta antes de puxar assunto")
	var curt: ChatReply = reply_with.call(ChatReply.Tone.CURT)
	ok(cc.chatted, "seca: ela não puxa mais assunto")
	ok(await wait_until(func(): return not cc.talking and String(cc.transcript.back()["text"]) == curt.follow), "respondeu")
	ok(ask_opt.call().is_empty(), "só puxa conversa uma vez por ligação")
	# duas falas ao mesmo tempo (assunto e agradecimento): a segunda espera a primeira terminar
	var n_two := cc.transcript.size()
	m.conversation.say(cc, "Primeira fala.")
	m.conversation.say(cc, "Segunda fala.")
	ok(await wait_until(func(): return cc.transcript.size() == n_two + 2), "as duas falas saíram")
	ok(cc.transcript[n_two]["text"] == "Primeira fala.", "a segunda só começa com a primeira inteira")
	m.end_call(cc, PhoneCall.End.OPERATOR)
	print("OK 11b responder e puxar conversa fiada")

	# ---- 12. atalhos do telefone (teclas de verdade): Espaço atende, Tab transfere, X desliga
	var kc := _extra(GameData.transfers(TransferCall.Group.EXTRA)[4])
	m.ring(kc)
	_move(0, kc.line)
	await frames(2)
	var other := Button.new()   # um botão qualquer da interface
	m.add_child(other)
	other.grab_focus()   # Espaço não pode apertar o botão em foco no lugar de atender
	_key(KEY_SPACE)
	ok(await wait_until(func(): return not kc.ringing, 5.0), "Espaço atende (mesmo com um botão em foco)")
	other.queue_free()
	ok(await wait_until(_awaiting(kc)), "pedido feito")
	var field := LineEdit.new()   # um campo de texto qualquer com foco fica com as teclas
	m.add_child(field)
	field.grab_focus()
	var typed := field.text
	_key(KEY_X)
	await frames(3)
	ok(kc.active and field.text.length() == typed.length() + 1, "digitando no caderno, o X vai para o campo (não desliga)")
	field.queue_free()
	_move(1, kc.line + 10)
	_move(2, int(kc.target))
	_key(KEY_TAB)
	await frames(2)
	ok(m.exchange.dest(int(kc.target)) == Exchange.Dest.RING, "Tab transfere (o destino toca)")
	_key(KEY_X)
	ok(await wait_until(func(): return not kc.active, 5.0), "X desliga")
	_move(1, -1)
	_move(2, -1)
	for pair in [[KEY_2, Tools.DISPATCH], [KEY_3, Tools.LOGBOOK], [KEY_1, Tools.DIRECTORY]]:
		_key(pair[0])
		await frames(2)
		ok(m.tools.tab == pair[1], "tecla abre a aba " + pair[1])
	ok(m.background.unread, "a conversa encerrada vira folha nova na prancheta da mesa")
	_key(KEY_4)
	await frames(2)
	ok(m.tools.tab == Tools.CALL_LOG and m.tools.open, "tecla 4 abre o registro das conversas")
	ok(not m.background.unread, "aberto o registro, a folha deixa de ser nova")
	ok(kc in m.tools.call_log._calls and m.tools.call_log.text.contains(kc.transcript[0]["text"].left(12)), "o registro tem a conversa")
	_key(KEY_4)
	await frames(2)
	ok(not m.tools.open, "a mesma tecla guarda a ferramenta (a janela aparece)")
	await frames(2)   # o cenário se redesenha e guarda onde ficou cada objeto
	for id in [Tools.DIRECTORY, Tools.DISPATCH, Tools.LOGBOOK, Tools.CALL_LOG]:   # objetos da cena abrem as ferramentas
		m.tools.close()
		await frames(12)
		var pe := InputEventMouseButton.new()
		pe.button_index = MOUSE_BUTTON_LEFT
		pe.pressed = true
		pe.position = (m.background._props[id] as Rect2).get_center()
		m.background.pointer(pe)
		ok(m.tools.open and m.tools.tab == id, "o objeto da cena abre " + id)
	m.tools.close()
	# o jornal da manhã na mesa (da segunda noite em diante), com as manchetes da noite anterior
	m.set_news([{"outcome": 0, "template": GameData.CONTENT.news_ok[0], "occurrence": "Outro", "address": "Rua do Sol, 10"}])
	await frames(3)
	var pj := InputEventMouseButton.new()
	pj.button_index = MOUSE_BUTTON_LEFT
	pj.pressed = true
	pj.position = (m.background._props[Tools.NEWS] as Rect2).get_center()
	m.background.pointer(pj)
	ok(m.tools.open and m.tools.tab == Tools.NEWS, "o jornal na mesa abre")
	ok(m.background.news_read, "lido, ele volta à mesa dobrado de outro jeito")
	ok(m.tools.news.get_node("Page/Text/Lead").text.contains("Rua do Sol"), "o jornal traz as manchetes da noite anterior")
	m.tools.close()
	# a persiana: clicada, desce até o peitoril e tampa o vidro; clicada de novo, sobe
	await frames(12)
	var room := m.background
	var pb := InputEventMouseButton.new()
	pb.button_index = MOUSE_BUTTON_LEFT
	pb.pressed = true
	pb.position = room._bounds(room._blind_poly).get_center()
	ok(room.prop_at(pb.position) == Background.BLIND_ID and room.pointer(pb) and room._shut_to == 1.0, "o clique na persiana a fecha")
	await wait_until(func() -> bool: return room._shut == 1.0, 10.0)
	ok(room._glass.is_empty(), "fechada, ela tampa o vidro")
	pb.position = room._bounds(room._blind_poly).get_center()
	room.pointer(pb)
	await wait_until(func() -> bool: return room._shut == 0.0, 10.0)
	ok(not room._glass.is_empty(), "clicada de novo, ela sobe")
	# a caneca: cada clique, um gole, até acabar o café; o armário: o clique abre e fecha a porta
	pb.position = (room._props[Background.MUG_ID] as Rect2).get_center()
	for i in Background.MUG_SIPS + 2:
		room.pointer(pb)
	ok(room.sips == Background.MUG_SIPS, "a caneca dá %d goles e acaba" % Background.MUG_SIPS)
	var cab := room._props[Background.CABINET_ID] as Rect2
	pb.position = cab.position + Vector2(cab.size.x / 2.0, 30.0)
	ok(room.prop_at(pb.position) == Background.CABINET_ID and room.pointer(pb) and room.cab_open, "o clique no armário abre a porta")
	room.pointer(pb)
	ok(not room.cab_open, "e outro a fecha")
	# a sala muda pelos marcadores do roteiro, a partir da noite de cada mudança
	for r in GameData.CONTENT.room:
		ok(r.detail in Background.DETAILS, "detalhe da sala conhecido: " + r.detail)
	var night_was := m.night_no
	m.night_no = 3
	m.flags.apply("desligou_desconhecida_2")
	ok("armario_entreaberto" in m.background.details, "um marcador ligado já muda a sala")
	m.flags.apply("!desligou_desconhecida_2")
	ok(not "armario_entreaberto" in m.background.details, "e desligado volta")
	m.night_no = night_was
	print("OK 12 atalhos do telefone e das abas")

	# ---- 13. mapa e despacho numa tela: marcar o local imprime o cartão; perfura-se o tipo (um só) e as unidades (o
	#          tipo não marca unidades: a conversa decide); o cartão anda livre pelo mapa e fica onde é solto; no cartucho,
	#          envia (em branco também: ninguém sai e o supervisor anota) e tudo limpa; a ficha não mexe no mapa
	var d := m.dispatch
	var card := d.machines
	m.tools.set_tab(Tools.DISPATCH)
	await frames(2)
	d.set_occurrence("")
	ok(not d.can_send(), "despacho vazio não envia")
	var spot: Vector2 = d.city._off + Vector2(300, 220) * d.city._k   # um ponto do mapa, na tela
	d.set_location("sol", 0, "Rua do Sol, 1–99")
	await frames(2)
	ok((d.city._off + Vector2(300, 220) * d.city._k).distance_to(spot) < 1.0, "o mapa não pula quando o cartão sai")
	ok(card.state == card.State.TYPING and card.card.sector == 3, "marcar o local datilografa o cartão, com o setor")
	ok(await wait_until(func(): return card.state == card.State.READY, 5.0) and card._pos == card._rest(), "o cartão sai impresso, em pé na fenda da impressora")
	ok(card._rest().x > card._mouth_x(0) + card.CARD_W / 3.0 and card._rest().x < card._mouth_x(2) - card.CARD_W / 3.0,
		"a impressora fica entre o transmissor e a trituradora, longe das duas fendas")
	var cell := func(id: String) -> Vector2:
		for c in card.card.cells:
			if c["id"] == id:
				return card._pos + (c["box"] as Rect2).get_center()
		return Vector2.ZERO
	var drag := func(to: Vector2) -> void:   # pega o cartão pelo cabeçalho e solta com o canto dele em `to`
		var at: Vector2 = card._pos + Vector2(card.CARD_W - 20.0, 30.0)
		_mouse(card, at, 1)
		_mouse(card, at + to - card._pos)
		_mouse(card, at + to - card._pos, 0)
	var slot := func(machine: CardMachines.Machine) -> Vector2:   # o canto do cartão com a borda de baixo na fenda da máquina
		return Vector2(card._machine(machine).get_center().x - card.CARD_W / 2.0, card._slot(machine) - card.card.size.y + 8.0)
	drag.call(await slot.call(card.Machine.SEND))
	ok(card.state == card.State.FEEDING, "cartão em branco também entra no cartucho")
	ok(await wait_until(func(): return d._location.is_empty(), 3.0) and d.fleet.units.values().all(func(u): return u == 0)
		and m.report.faults.any(func(f): return f["id"] == "dispatch_blank"), "em branco: ninguém sai e o supervisor anota")
	d.set_location("sol", 0, "Rua do Sol, 1–99")
	ok(await wait_until(func(): return card.state == card.State.READY, 5.0), "outro cartão")
	d.set_location("comercio", 0, "Rua do Comércio, 1–99")
	ok(card._refused >= 0.0 and card.serial() == 2 and d._location["label"] == "Rua do Sol, 1–99" and d.city.sel["label"] == "Rua do Sol, 1–99",
		"com um cartão na mesa, a impressora recusa outro e o mapa volta ao local dele")
	var table: Vector2 = card._pos + Vector2(-roundf((card._mouth_x(1) - card._mouth_x(0)) / 2.0), -2)
	drag.call(table)
	ok(card.state == card.State.READY and card._pos == table, "solto entre as máquinas, rente à base, o cartão fica onde está")
	drag.call(Vector2(9000, -9000))
	ok(card.state == card.State.READY and card._pos == Vector2(card.size.x - card.CARD_W, 0),
		"o cartão não sai da unidade (e, longe da fenda, não entra na trituradora embaixo dele)")
	drag.call(Vector2(card._mouth_x(1), 9000))
	ok(card.state == card.State.READY and is_equal_approx(card._pos.y + card.card.size.y, card.size.y),
		"o cartão vai até a borda de baixo, por cima das máquinas (na impressora, fica)")
	_click(card, cell.call("Outro"))
	var faults: int = m.report.faults.size()
	drag.call(await slot.call(card.Machine.SHRED))
	ok(card.state == card.State.FEEDING and card._into == card.Machine.SHRED, "solto na trituradora, ela puxa o cartão")
	ok(await wait_until(func(): return card.state == card.State.IDLE, 3.0) and d._location.is_empty() and d.occurrence() == ""
		and m.report.faults.size() == faults, "triturado: nada sai, sem advertência, a impressora espera outro local")
	d.set_location("sol", 0, "Rua do Sol, 1–99")
	ok(await wait_until(func(): return card.state == card.State.READY, 5.0), "mais um cartão")
	_click(card, cell.call("Incêndio"))
	_click(card, cell.call("Mal súbito"))
	ok(d.occurrence() == "Incêndio", "um tipo só: o primeiro furo vale")
	ok(d.fleet.available(d.picked()).is_empty() and not d.can_send(), "o tipo não marca unidade")
	var row: Vector2 = cell.call("amb") + Vector2(90, 14)   # no protocolo, longe do quadradinho
	var held: Vector2 = card._pos
	_mouse(card, row, 1)   # apertar na linha e arrastar move o cartão sem perfurar
	_mouse(card, row + Vector2(-40, -2))
	_mouse(card, row + Vector2(-40, -2), 0)
	ok(d.picked().is_empty() and card._pos == held + Vector2(-40, -2), "arrastar pela linha move o cartão, sem perfurar")
	row += Vector2(-40, -2)
	_click(card, row)
	ok(d.can_send() and d.picked() == ["amb"], "local, tipo e unidade perfurados (clicando em qualquer ponto da linha)")
	drag.call(await slot.call(card.Machine.SEND))
	ok(card.state == card.State.FEEDING and card._into == card.Machine.SEND, "o transmissor puxa o cartão completo")
	ok(await wait_until(func(): return d._location.is_empty(), 3.0), "o cartão no cartucho envia")
	ok(d.occurrence() == "" and d.picked().is_empty() and d.city.sel.is_empty() and card.state == card.State.IDLE, "depois de enviar, local e tipo limpos")
	ok(not d.fleet.is_free("amb"), "ambulância a caminho fica indisponível")
	await frames(2)
	ok(d.get_node("%Fleet").visible and d.get_node("%Report").text.contains(T.text(T.Key.UNIT_AMBULANCE)), "a faixa das viaturas mostra quem saiu")
	m.tools.set_tab(Tools.DIRECTORY)
	print("OK 13 mapa e despacho")

	# ---- 14. painel de debug (F1): toca uma emergência, pula estágio, registra as pendências
	var dbg = m.get_node("%Debug")
	_key(KEY_F1)
	await frames(2)
	ok(dbg.visible, "F1 abre o painel de debug")
	dbg._emergency.select(0)
	dbg._ring_emergency()
	var de: PhoneCall = m.emergencies.back()
	ok(de != null and de.ringing and de.data.street == C.emergencies[0].street, "painel toca a emergência escolhida")
	_move(0, de.line)
	m.answer()
	await frames(2)
	dbg._next_stage()
	await frames(2)
	ok(de.stage == 1, "painel pula para o próximo estágio")
	var live_before: int = m.live.size()   # um retorno de cenário anterior pode estar tocando
	dbg._ring_transfer(false)
	ok(m.live.size() == live_before + 1, "painel toca uma transferência junto")
	dbg._emergency.select(1)
	dbg._ring_emergency()
	dbg._ring_emergency()
	ok(m.in_progress().size() == Main.MAX_EMERGENCIES and m.dispatch.fleet.incidents.size() == Main.MAX_EMERGENCIES,
		"duas emergências ao mesmo tempo, e não uma terceira")
	m.urgency.tick(0.0)
	var de2: PhoneCall = m.emergencies.back()
	_move(0, de2.line)
	m.answer()
	await frames(2)
	m.urgency.tick(0.0)
	ok(m.phone.urgency.call == de2 and m.radio._away != "", "a barra é a da linha do FONE; o rádio avisa da outra")
	m.notebook.add(PhoneCall.Record.new())
	dbg._restore_all()
	await frames(2)
	ok(m.live.is_empty() and m.emergencies.is_empty() and not de.urgent() and m.radio._alert == -1, "restaurar: ligações e emergência somem")
	ok(range(1, Exchange.LINES + 1).all(func(n): return m.exchange.line(n) == Exchange.Line.FREE), "restaurar: linhas livres")
	ok(await wait_until(func(): return m.board.ends.all(func(e): return e == -1), 10.0), "restaurar: cabos na base")
	ok(m.dispatch.fleet.units.values().all(func(s): return s == 0) and m.dispatch.fleet.incidents.is_empty(), "restaurar: despacho livre")
	ok(not m.notebook.has_pending() and m.report.faults.is_empty() and Engine.time_scale == 1.0, "restaurar: caderno, relatório e tempo zerados")
	ok(not m.sched.any(func(c): return c.retry != PhoneCall.Retry.NONE), "restaurar: ninguém liga de novo")
	Engine.time_scale = 8.0
	_key(KEY_F1)
	await frames(2)
	ok(not dbg.visible, "F1 fecha o painel")
	print("OK 14 painel de debug")

	# ---- 15. clima do som: o cenário avisa a hora desde a introdução (antes, mixava o clima padrão, chuva, em 8 s, e
	# essa mistura terminava depois da da noite: numa noite limpa, os grilos sumiam e entrava a chuva)
	Sfx.stop_ambience(0.0)
	Sfx.weather = ""
	Sfx.set_late(0.0)
	Sfx.start_ambience("clear")
	await frames(int(10.0 * 60.0 / Engine.time_scale))
	ok(Sfx._rain_db <= -79.0 and Sfx.crickets.volume_db > -40.0, "noite limpa: chuva %.0f dB, grilos %.0f dB" % [Sfx._rain_db, Sfx.crickets.volume_db])
	Sfx.stop_ambience(0.0)
	print("OK 15 clima do som")

	# ---- 16. gente na calçada de lá: cada vez menos até as 22h, e daí ninguém (só o homem do mistério)
	m.minutes = Background.WALK_FROM - Main.SHIFT_START_HOUR * 60.0
	ok(await wait_until(func(): return not bg._walkers.is_empty(), 30.0), "às 18h passa gente")
	m.minutes = Background.WALK_UNTIL - Main.SHIFT_START_HOUR * 60.0 + 1.0
	ok(await wait_until(func(): return bg._walkers.is_empty(), 60.0), "quem estava passando termina de passar")
	await frames(int(60.0 * 60.0 / Engine.time_scale))
	ok(bg._walkers.is_empty(), "depois das 22h ninguém passa")
	print("OK 16 pedestres")

	# ---- 17. o painel de baixo não muda de altura: numa emergência com aviso, respostas em quatro fileiras e a barra,
	# as falas encolhem até a mais nova (antes, o painel crescia e empurrava a sala para cima)
	var ph: PhonePanel = m.phone
	var h0 := ph.size.y
	var pe := PhoneCall.from_emergency(GameData.template_emergency())
	m.ring(pe)
	_move(0, pe.line)
	m.answer()
	ok(await wait_until(func(): return ph.urgency.visible, 20.0), "emergência na linha, com a barra")
	var rows := 0.0
	for st in 3:
		var many: Array[Dictionary] = []
		for i in 4:   # uma resposta longa por fileira
			many.append({"label": "Alguém está ferido, preso ou precisando de ajuda? %d" % i, "fn": func(): pass})
		pe.set_options(many)
		ph.warn(T.text(T.Key.WARN_FONE_TO_BLINK))
		await frames(10)
		rows = maxf(rows, ph._choices.size.y)
		ok(ph.size.y == h0, "estágio %d: o painel fica em %d px (está em %d)" % [st, h0, ph.size.y])
		var e: EmergencyCall = pe.data
		pe.urgency = [e.stage_sec.x, e.stage_sec.x + e.stage_sec.y, e.stage_sec.x + e.stage_sec.y + e.stage_sec.z][pe.stage]
		await frames(2)
	ok(rows >= 4 * 18.0, "o pior caso chegou a quatro fileiras de respostas (%d px)" % rows)
	m.drop_all()
	ok(await wait_until(func(): return m.board.ends.all(func(x): return x == -1), 10.0), "cabos na base depois")
	print("OK 17 altura do painel")
	finish("fluxo da central")


## Aperta e solta uma tecla, como o jogador.
func _key(k: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = k
	e.keycode = k
	e.unicode = k if k < 128 else 0
	e.pressed = true
	Input.parse_input_event(e)
	var up: InputEventKey = e.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
