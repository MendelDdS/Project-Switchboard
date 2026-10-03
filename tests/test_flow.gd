extends "res://tests/test_base.gd"
## Cenários dirigidos: transferência, várias ligações, desistência, caderno, lugar fechado,
## cortar conversa, ligar de volta para o número desconhecido, clique/arraste dos plugs.
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


func _step(kind: PrankStep.Kind, text := "", requires := PackedStringArray()) -> PrankStep:
	var st := PrankStep.new()
	st.kind = kind
	st.text = text
	st.requires = requires
	return st


## Lacunas de um texto (%s, %02d, {place}...), para comparar entre idiomas.
func _holes(s: String) -> Array:
	var re := RegEx.create_from_string("%[0-9]*[sd]|\\{[a-z_]+\\}")
	var out := re.search_all(s).map(func(m: RegExMatch): return m.get_string())
	out.sort()
	return out


## Traduções: toda chave do enum tem texto nos três idiomas com as mesmas lacunas; toda chave usada nas cenas existe;
## as falas traduzidas (.po) mantêm as lacunas do português.
func _check_translations() -> void:
	for lang in ["en", "es", "pt_BR"]:
		TranslationServer.set_locale(lang)
		for k in T.Key.values():
			var name: String = T.Key.find_key(k)
			ok(T.text(k) != name, "chave sem texto em %s: %s" % [lang, name])
	var csv := FileAccess.open("res://translations/ui.csv", FileAccess.READ)
	csv.get_csv_line()
	while not csv.eof_reached():
		var row := csv.get_csv_line()
		if row.size() >= 4:
			ok(_holes(row[1]) == _holes(row[2]) and _holes(row[1]) == _holes(row[3]), "lacunas diferentes entre idiomas: " + row[0])
	for f in DirAccess.get_files_at("res://scenes/ui") + PackedStringArray(["../main.tscn"]):
		if f.ends_with(".tscn"):
			for line in FileAccess.get_file_as_string("res://scenes/ui/" + f).split("\n"):
				var m := RegEx.create_from_string("^(?:text|placeholder_text) = \"([A-Z][A-Z0-9_]+)\"$").search(line)
				ok(m == null or T.Key.has(m.get_string(1)), "chave inexistente na cena %s: %s" % [f, m.get_string(1) if m else ""])
	for lang in ["en", "es"]:
		var po := FileAccess.get_file_as_string("res://translations/content.%s.po" % lang)
		var empty := 0
		for m in RegEx.create_from_string("msgid \"((?:[^\"\\\\]|\\\\.)*)\"\nmsgstr \"((?:[^\"\\\\]|\\\\.)*)\"").search_all(po):
			if m.get_string(1) == "":
				continue
			if m.get_string(2) == "":
				empty += 1
			else:
				ok(_holes(m.get_string(1)) == _holes(m.get_string(2)), "lacunas diferentes (%s): %s" % [lang, m.get_string(1)])
		if empty > 0:
			print("aviso: %d falas sem tradução em %s (rode tools/update_translations.gd e traduza)" % [empty, lang])
	TranslationServer.set_locale("pt_BR")   # o padrão do jogo (Settings não existe ao compilar um teste)


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

	# ---- 0. conteúdo: todo roteiro aponta para números, ruas e unidades que existem
	var C: GameContent = GameData.CONTENT
	var nums := GameData.board_numbers()
	for t in C.transfers:
		ok(int(t.target) in nums and (t.alt_target == "" or int(t.alt_target) in nums), "destino existe: " + t.resource_path)
		ok(t.alt_target == "" or GameData.entry(t.target).category != "" and GameData.entry(t.alt_target).category == GameData.entry(t.target).category,
			"alternativa do mesmo ramo: " + t.resource_path)
	# todo ramo tem pelo menos dois estabelecimentos no mesmo setor (a alternativa existe desde a entrega do setor)
	for d in C.directory.filter(func(d: DirectoryEntry): return d.category != ""):
		ok(C.directory.any(func(o: DirectoryEntry): return o != d and o.category == d.category and o.number.left(1) == d.number.left(1)),
			"ramo sem alternativa no setor: " + d.name)
	for e in C.emergencies:
		ok(GameData.street(e.street) != null and e.questions.size() == e.answers.size() and e.occurrence in C.occurrences, "emergência válida: " + e.resource_path)
	# unidades válidas, e cada caso troca no máximo as respostas que existem
	var valid := func(us: PackedStringArray): return not us.is_empty() and Array(us).all(func(u): return u in ["pol", "bomb", "amb"])
	for e in C.emergencies + C.emergency_templates:
		ok(valid.call(e.units) and e.cases.all(func(k: EmergencyCase): return valid.call(k.units) and k.answers.size() <= e.questions.size()),
			"unidades e casos válidos: " + e.resource_path)
		ok(Array(e.worsening_units + e.critical_units).all(func(u): return u in ["pol", "bomb", "amb"]) and e.worsening != ""
			and e.critical != "" and e.lost != "" and e.stage_sec.x > 0.0 and e.worsening_question != "" and e.worsening_answer != ""
			and e.critical_question != "" and e.critical_answer != "" and e.lost_answer != "", "agravamento completo: " + e.resource_path)
	var fire: EmergencyCall = C.emergency_templates.filter(func(x): return x.cases.size() > 1)[0]
	var seen := {}
	for i in 40:
		var k := GameData.with_case(fire)
		ok(k.answers.size() == fire.answers.size() and k.cases.is_empty(), "caso sorteado com todas as respostas")
		seen[",".join(k.units)] = true
	ok(seen.size() > 1, "o mesmo molde pede unidades diferentes conforme o caso")
	for p in C.pranks:
		ok(p.steps.back().kind == PrankStep.Kind.END, "trote termina: " + p.resource_path)
	for n in C.nights:
		ok(n.story.all(func(st: StoryCall): return st.call is TransferCall or st.call is EmergencyCall or st.call is PrankCall),
			"ligações do roteiro com roteiro escrito: " + n.resource_path)
	# clima: cada um tem falas próprias, e a chuva só é comentada quando chove
	for w in m.WEATHERS:
		m.weather = w
		var talk: Array = m.conversation.topics()
		ok(talk.any(func(t): return t.weather == w), "assuntos do clima: " + w)
		ok(w == "rain" or not talk.any(func(t): return "chuva" in t.line), "sem chuva na conversa: " + w)
	# conversa fiada: cada assunto traz as próprias respostas (uma simpática e uma seca), cada uma com a continuação
	var topics: Array[ChatTopic] = C.smalltalk.duplicate()
	for n in C.nights:
		topics.append_array(n.smalltalk)
	for t in topics:
		ok(t.line != "" and t.replies.all(func(r: ChatReply): return r.text != "" and r.follow != "")
			and t.replies.any(func(r): return r.tone == ChatReply.Tone.WARM) and t.replies.any(func(r): return r.tone == ChatReply.Tone.CURT),
			"assunto com resposta simpática e seca: " + t.line)
	ok(not m.conversation.topics("m").any(func(t): return "Meu marido" in t.line) and not m.conversation.topics("f").any(func(t): return "Minha mulher" in t.line),
		"assunto só na voz que combina")
	# setores: o 3 desde a noite 1, o 1 na noite 5 e o 2 na noite 9; mesa, lista e ligações só com os atendidos
	ok(GameData.sectors_for(1) == [3] and GameData.sectors_for(4) == [3] and GameData.sectors_for(5).size() == 2
		and GameData.sectors_for(9).size() == 3, "setores entregues nas noites 1, 5 e 9")
	var per_sector := {}
	for e in C.directory:
		if not e.dispatch_only:
			per_sector[e.number.left(1)] = int(per_sector.get(e.number.left(1), 0)) + 1
	ok(per_sector == {"3": 10, "1": 12, "2": 12}, "lista: 10 números no setor 3 e 12 em cada um dos outros: %s" % per_sector)
	GameData.sectors = [3]
	ok(GameData.board_numbers().size() == 10 and GameData.board_numbers().all(func(n): return str(n).begins_with("3")), "noite 1: mesa só com o setor 3")
	ok(not GameData.transfers(TransferCall.Group.ESTABLISHMENT).is_empty(), "setor 3 tem estabelecimento para o tutorial")
	var used: Array = []
	var tpl := GameData.template_transfer(used)
	while tpl != null:
		ok(tpl.target.begins_with("3"), "molde só com número do setor 3")
		used.append(tpl.target)
		tpl = GameData.template_transfer(used)
	ok(not used.is_empty(), "moldes até acabarem os lugares, sem repetir")
	var sector3 := func(c: PhoneCall) -> bool:
		if c.kind == PhoneCall.Kind.TRANSFER:
			return c.target.begins_with("3")
		return c.kind != PhoneCall.Kind.INFO or c.answer.begins_with("3")
	for s in 5:
		ok(Schedule.build(C.nights[0], C.paces[0], m.LAST_CALL).calls.all(sector3), "agenda da noite 1 só pede números do setor 3")
	var em_streets := func(): return Schedule.build(C.nights[0], C.paces[4], m.LAST_CALL).calls.filter(func(c: PhoneCall): return c.kind == PhoneCall.Kind.EMERGENCY).map(func(c: PhoneCall): return GameData.street(c.data.street).block_sector(c.data.block))
	for s in 5:
		ok(em_streets.call().all(func(x): return x == 3), "emergências só nas ruas do setor 3")
	# mapa: setor sombreado não responde; a viagem do Centro é mais longa quanto mais longe
	var city = m.dispatch.city
	var on_street := func(id: String, b: int): return city.seg_geom(GameData.street(id), b)[2]
	ok(city._find_seg(on_street.call("brasil", 1)).get("block") == 1 and city._find_seg(on_street.call("brasil", 4)).is_empty(),
		"mapa: a Avenida Brasil só nos trechos do setor atendido")
	GameData.sectors = [1, 2, 3]
	var trip_c: float = city.trip("pol", {"street": "brasil", "block": 4})
	var trip_3: float = city.trip("pol", {"street": "comercio", "block": 2})
	var trip_2: float = city.trip("pol", {"street": "cruzeiro", "block": 0})
	city.remove_units(["pol"])
	ok(trip_c < trip_3 and trip_3 < trip_2, "viagem do Centro: %.1f s no Centro, %.1f s no setor 3, %.1f s no setor 2" % [trip_c, trip_3, trip_2])
	# lista telefônica: cada aba abre só a sua letra, com todos os contatos dela nas duas páginas; Virar passa de letra
	# em letra até as anotações, Voltar volta até a primeira
	var book = m.tools.find_child("PhoneBook", true, false)
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
	# emergências escritas: o endereço bate com a rua e o trecho do mapa (o trecho sai do número)
	for e: EmergencyCall in C.emergencies:
		var st := GameData.street(e.street)
		ok(st != null and e.address.get_slice(",", 0) == st.name and int(e.address.get_slice(",", 1)) / 100 == e.block,
			"emergência no trecho certo: " + e.address)
	ok([1, 2].all(func(sec): return C.emergencies.any(func(e): return GameData.street(e.street).block_sector(e.block) == sec)), "Centro e Alto da Serra têm emergências escritas")
	# dica do banco novo: só para o setor entregue na noite (o 3 o tutorial apresenta)
	m.night_no = 5
	ok(m._new_sector("142") and not m._new_sector("305") and not m._new_sector("237") and not m._new_sector(""), "banco novo na noite 5: o A")
	m.night_no = 1
	# revelação: o mapa sai do enquadramento de antes e chega no de agora
	ok(city._frame_of([3]).size == Vector2(600, 440) and city._frame_of([3, 1]).size == Vector2(1200, 440) and city._frame_of([1, 2, 3]).size == Vector2(1200, 880), "enquadramento por setores")
	# endereços: cada número fica numa rua do bairro dele (o Centro também tem a Praça da Matriz)
	for e in C.directory:
		var st: String = e.address.get_slice(",", 0)
		var sec := 1 if e.dispatch_only else int(e.number.left(1))
		var here := C.streets.filter(func(s: Street): return s.name == st)
		var block := int(e.address.get_slice(",", 1)) / 100
		ok((not here.is_empty() and block < here[0].blocks() and here[0].block_sector(block) == sec) or (sec == 1 and st == "Praça da Matriz"),
			"endereço no bairro do número: %s (%s)" % [e.name, e.address])
	# ritmo: nas primeiras noites só sobe se a anterior não foi ruim; depois sobe sempre, até o limite
	var top: int = C.paces.size()
	ok(Pace.next(1, 1, 0) == 2 and Pace.next(1, 1, 2) == 1 and Pace.next(2, 2, 2) == 2, "noite ruim no começo: repete o ritmo")
	ok(Pace.next(3, 3, 2) == 4 and Pace.next(2, 5, 2) == 3, "da noite 4 em diante: sobe mesmo depois de noite ruim")
	ok(Pace.next(top, 8, 0) == top and Pace.next(top - 1, 6, 0) == top, "o último nível é o limite")
	ok(Pace.next(4, 4, 0) == 4 and Pace.next(4, 5, 0) == 5 and Pace.expected(5) == 4 and Pace.expected(6) == 5,
		"noite de bairro novo (5): o ritmo não sobe")
	ok(range(1, top).all(func(i): return C.paces[i].call_gap.x <= C.paces[i - 1].call_gap.x), "o ritmo só aperta de um nível para o outro")
	# agenda: montada sem a cena (noite → ligações em ordem, espaçadas das do roteiro e entre emergências)
	for n in C.nights:
		var plan := Schedule.build(n, m.pace, m.LAST_CALL)
		var ats: Array = plan.calls.map(func(c: PhoneCall): return c.at)
		var in_order := ats.duplicate()
		in_order.sort()
		ok(ats == in_order and ats.all(func(a): return a >= 0.0 and a < m.SHIFT_END), "agenda em ordem: " + n.resource_path)
		ok(plan.calls.all(func(c: PhoneCall): return c.story or c.kind == PhoneCall.Kind.MYSTERY or c.at < m.LAST_CALL),
			"sorteadas antes da última ligação: " + n.resource_path)
		ok((plan.tut != null) == n.tutorial and (plan.tut == null or plan.tut == plan.calls[0]), "tutorial é a primeira: " + n.resource_path)
		ok((plan.mystery_at == INF) == n.mystery.is_empty(), "ligação desconhecida conforme a noite: " + n.resource_path)
		ok(plan.calls.all(func(c: PhoneCall): return c.kind != PhoneCall.Kind.MYSTERY or c.latest <= m.LAST_CALL - Schedule.MYSTERY_MARGIN),
			"desconhecida toca antes da última ligação: " + n.resource_path)
		var fixed := plan.calls.filter(func(c: PhoneCall): return c.story or c.kind == PhoneCall.Kind.MYSTERY)
		ok(fixed.size() == n.story.size() + (0 if n.mystery.is_empty() else 1), "roteiro inteiro na agenda: " + n.resource_path)
		ok(plan.calls.all(func(c: PhoneCall): return c in fixed or fixed.all(func(f): return absf(c.at - f.at) >= Schedule.STORY_GAP)),
			"sorteadas longe das do roteiro: " + n.resource_path)
		var ems: Array = plan.calls.filter(func(c: PhoneCall): return c.kind == PhoneCall.Kind.EMERGENCY).map(func(c): return c.at)
		ok(range(1, ems.size()).all(func(i): return ems[i] - ems[i - 1] >= Schedule.EMERGENCY_GAP), "emergências espaçadas: " + n.resource_path)
	# moldes: nenhuma lacuna sobra sem preencher
	var holes := func(texts: Array) -> bool: return texts.any(func(x): return "{" in x or "}" in x)
	for i in 300:
		var t := GameData.template_transfer()
		ok(int(t.target) in nums, "molde: destino existe")
		ok(t.alt_target == "" or GameData.entry(t.alt_target).category == GameData.entry(t.target).category and not "%" in t.alt_ask,
			"molde: alternativa do mesmo ramo")
		ok(GameData.entry(t.target).category == "" or t.alt_target != "", "molde: estabelecimento com ramo tem alternativa")
		ok(not holes.call(Array(t.opening) + [t.repeat, t.thanks]) and t.caller != "", "molde de transferência preenchido: " + " / ".join(t.opening))
		var e := GameData.template_emergency()
		var house := int(e.address.get_slice(", ", 1))
		ok(GameData.street(e.street) != null and e.block == floori(house / 100.0) and house >= 1, "molde: trecho bate com o número " + e.address)
		ok(not holes.call(Array(e.answers) + [e.opening, e.after]), "molde de emergência preenchido: " + e.opening)
	_check_translations()
	for c in m.find_children("*", "Control", true, false):
		if c is BaseButton or c is Slider:
			ok(c.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "sem cursor de dedo: %s" % m.get_path_to(c))
	var places := C.directory.filter(func(d): return not d.reasons.is_empty())
	print("OK 0 conteúdo (%d transferências, %d emergências, %d trotes; moldes: %d de transferência para %d contatos, %d de emergência)" % [
		C.transfers.size(), C.emergencies.size(), C.pranks.size(), C.transfer_templates.size(), places.size(), C.emergency_templates.size()])

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
	var sfx = m.get_node("/root/Sfx")
	ok(not sfx.pool.any(func(p): return p.playing and p.stream == sfx.streams["ring"]), "atender corta o toque na hora")
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
	ok(ex.dest(tgt) == Exchange.Dest.FREE and b.free_patches() == 3, "destino e cabo liberados")
	print("OK 1 transferência completa / tirar o FONE mantém a ligação")

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
	ok(t3.record["obs"] == T.text(T.Key.OBS_NOT_ANSWERED), "registro de não atendida")
	var nb = m.notebook
	ok(nb.entries.back()["type"] == T.Key.TYPE_MISSED and not nb.queue.any(func(r): return r["missed"]), "não atendida registrada sozinha")
	ok(nb.queue.size() >= 1, "ocorrências em fila")
	var before: int = nb.queue.size()
	nb.register(T.Key.TYPE_COMMON)
	ok(nb.queue.size() == before - 1 and nb.has_pending(), "registrou uma, a próxima veio da fila")
	ok(m.tools.find_child("Count", true, false).text == str(nb.pending_count()), "a aba do caderno mostra quantas faltam")
	ok(nb.entries.back()["type"] == T.Key.TYPE_COMMON, "registrada com o tipo do clique")
	# as ocorrências chegaram com a aba fechada: aberta, a página do livro ocupa toda a área (com e sem a ficha)
	m.tools.set_tab("caderno")
	await frames(3)
	ok(nb._page.size.y >= nb._scroll.size.y - 1, "página do caderno preenche a área (com ficha)")
	while nb.has_pending():
		nb.register(T.Key.TYPE_COMMON)
	await frames(3)
	ok(not nb._form.visible and nb._page.size.y >= nb._scroll.size.y - 1 and nb._scroll.size.y > 300, "sem ficha, a página cresce até embaixo")
	m.tools.set_tab("lista")
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
	_pick(fa, "Ninguém atende")
	ok(fa.target == "162", "trocou para a de plantão")
	_move(4, 162)
	ok(await wait_until(func(): return not fa.talking), "terminou de falar")
	m.transfer()
	_move(0, -1)              # tira o FONE com o destino ainda tocando
	ok(ex.line(fl) == Exchange.Line.HOLD and not fa.ended, "em espera durante o toque")
	ok(await wait_until(func(): return fa.connected), "completa sozinha quando o destino atende")
	ok(fa.record["where"] == "Farmácia Santa Rita" and fa.record["obs"] == "", "registro com o destino novo")
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
	ok(not b._loose[0]["direct"] and b.ropes[0]["old"][b.ROPE_N - 1].x < 400 - 5, "sai com o embalo da mão")
	ok(await wait_until(func(): return not b._loose.has(0), 5.0), "o fio recolheu o FONE")
	ok(not b.ropes.has(0), "fio do FONE todo dentro do encaixe")
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
	ok(await wait_until(func(): return b._loose.is_empty(), 5.0), "animações terminaram")
	ok(b.free_patches() == 3, "cabo de volta à base")
	_move(0, l7)
	var other_in := 1 if l7 != 1 else 2
	b._press(jc)
	b._release(b.jack_rect(other_in).get_center())
	ok(b.ends[0] == other_in, "arrastar move o FONE")
	ok(b._order.back() == 0, "o último plug mexido fica por cima")
	ok(await wait_until(func(): return b.ropes.has(0) and b.ropes[0].has("sleep"), 10.0), "fio parado deixa de ser simulado")
	_move(0, l7)
	await frames(1)
	ok(not b.ropes[0].has("sleep") and b.ropes[0]["pts"][b.ROPE_N - 1] == b._plug_base(0), "mexer no plug acorda o fio")
	var hp: Vector2 = b.home_pos(3)
	b._press(hp)
	b._release(hp)
	ok(b.held == -1 and b.ends[3] == -1, "clique sem arrastar não pega o plug da base")
	print("OK 7 clique desconecta / arrastar move")

	# ---- 8. silhueta na janela: aparece 15 min antes da ligação desconhecida e sai 10 min antes (vai ligar)
	var myst := PhoneCall.mystery()
	myst.at = m.minutes + 30.0   # na agenda, mas sem tocar durante o teste
	m.myst_plan = myst.at
	m.sched.append(myst)
	await frames(1)
	ok(not m.background.shadow, "ainda não aparece")
	m.myst_plan = m.minutes + 14.0
	await frames(1)
	ok(m.background.shadow, "silhueta na janela")
	m.myst_plan = m.minutes + 9.0
	await frames(1)
	ok(not m.background.shadow, "saiu antes de ligar")
	m.sched.erase(myst)
	print("OK 8 silhueta")

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
	ok(not paused and b.ends[1] == -1, "com plug na mão, o Esc só devolve o plug")
	await frames(2)
	var rc := _extra(GameData.transfers(TransferCall.Group.EXTRA)[2])
	m.ring(rc)
	m._unhandled_input(esc)
	ok(paused and m._pause.visible, "Esc pausa o turno")
	var frozen: float = m.minutes
	await frames(int(m.GIVE_UP_SEC * 60.0 / Engine.time_scale) + 60)
	ok(m.minutes == frozen and rc.ringing, "na pausa o relógio para e ninguém desiste")
	m._pause._unhandled_input(esc)
	ok(not paused and not m._pause.visible, "Esc no menu continua")
	m.end_call(rc, PhoneCall.End.OPERATOR)
	var st = root.get_node("Settings")
	m._pause.open_settings()
	st.set_volume("Effects", 0.3)
	ok(not m._pause.get_node("%Apply").disabled, "Aplicar acende com mudança")
	m._pause._back()
	ok(st.volumes["Effects"] == 1.0 and not m._pause.visible, "Voltar descarta")
	m._pause.open_settings()
	ok(m._pause.get_node("%Apply").disabled, "sem mudança, Aplicar apagado")
	st.set_volume("Effects", 0.3)
	m._pause._apply_settings()
	ok(st.volumes["Effects"] == 0.3 and not m._pause.visible, "Aplicar mantém")
	st.set_volume("Effects", 1.0)
	st.set_locale("en")
	ok(T.text(T.Key.RESUME) == "Resume" and st.locale == "en", "idioma muda na hora")
	st.set_locale("pt_BR")
	st.set_volume("Effects", 0.5)
	ok(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Effects")) - linear_to_db(0.5)) < 0.01, "volume do barramento")
	st.set_volume("Effects", 1.0)
	st.set_text_speed(2)
	ok(st.char_delay() < 1.0, "texto mais rápido")
	st.set_text_speed(1)
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
	var ask_opt := func(): return cc.options.filter(func(o): return String(o["label"]) == T.text(T.Key.OP_SMALLTALK))
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
	var tab: Button = m.find_child("TabDespacho", true, false)
	tab.focus_mode = Control.FOCUS_ALL
	tab.grab_focus()   # Espaço não pode apertar o botão em foco no lugar de atender
	_key(KEY_SPACE)
	ok(await wait_until(func(): return not kc.ringing, 5.0), "Espaço atende (mesmo com um botão em foco)")
	tab.release_focus()
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
	for pair in [[KEY_2, "despacho"], [KEY_3, "caderno"], [KEY_1, "lista"]]:
		_key(pair[0])
		await frames(2)
		ok(m.tools.tab == pair[1], "tecla abre a aba " + pair[1])
	print("OK 12 atalhos do telefone e das abas")

	# ---- 13. mapa e despacho numa tela: marcar o local imprime o cartão; perfura-se o tipo (um só) e as unidades (o
	#          tipo não marca unidades: a conversa decide); o cartão anda livre pelo mapa e fica onde é solto; no cartucho,
	#          envia (em branco também: ninguém sai e o supervisor anota) e tudo limpa; a ficha não mexe no mapa
	var d = m.dispatch
	var card = d.card   # sem tipo: PunchCard depende do autoload Sfx
	m.tools.set_tab("despacho")
	d.open_slip(false)
	await frames(2)
	ok(not d._slip.visible and d.get_node("%Open").visible, "ficha recolhida")
	d.set_occurrence("")
	ok(not d.can_send(), "despacho vazio não envia")
	var spot: Vector2 = d.city._off + Vector2(300, 220) * d.city._k   # um ponto do mapa, na tela
	d.set_location("sol", 0, "Rua do Sol, 1–99")
	await frames(2)
	ok(d._slip.visible, "marcar o local abre a ficha por cima do mapa")
	ok((d.city._off + Vector2(300, 220) * d.city._k).distance_to(spot) < 1.0, "o mapa não pula quando a ficha abre")
	ok(card.state == card.State.TYPING and card._sector == 3, "marcar o local datilografa o cartão, com o setor")
	ok(await wait_until(func(): return card.state == card.State.READY, 5.0) and card._pos == card._rest(), "o cartão sai impresso, pendurado na fenda")
	var cell := func(id: String) -> Vector2:
		for c in card._cells:
			if c[2] == id:
				return card._pos + (c[0] as Rect2).get_center()
		return Vector2.ZERO
	var drag := func(to: Vector2) -> void:   # pega o cartão pelo cabeçalho e solta com o canto dele em `to`
		var at: Vector2 = card._pos + Vector2(card.CARD_W - 20.0, 30.0)
		_mouse(card, at, 1)
		_mouse(card, at + to - card._pos)
		_mouse(card, at + to - card._pos, 0)
	var slot := func(machine: String) -> Vector2:   # o canto do cartão com a borda de baixo na fenda da máquina
		await wait_until(func(): return card._up >= 1.0, 2.0)   # o transmissor termina de subir
		return Vector2(card._machine(machine).get_center().x - card.CARD_W / 2.0, card._slot(machine) - card._card_h + 8.0)
	drag.call(await slot.call("send"))
	ok(card.state == card.State.FEEDING, "cartão em branco também entra no cartucho")
	ok(await wait_until(func(): return d._location.is_empty(), 3.0) and d._units.values().all(func(u): return u == 0)
		and m.report.faults.any(func(f): return f["id"] == "dispatch_blank"), "em branco: ninguém sai e o supervisor anota")
	d.set_location("sol", 0, "Rua do Sol, 1–99")
	ok(await wait_until(func(): return card.state == card.State.READY, 5.0), "outro cartão")
	var table: Vector2 = card._pos + Vector2(-300, 40)
	drag.call(table)
	ok(card.state == card.State.READY and card._pos == table, "solto na mesa, o cartão fica onde está")
	drag.call(Vector2(-500, 9000))
	ok(card._pos.x == 0.0 and card._pos.y + card._card_h <= card.size.y, "o cartão não sai do mapa")
	_mouse(card, cell.call("Outro"), 1)
	var faults: int = m.report.faults.size()
	drag.call(await slot.call("shred"))
	ok(card.state == card.State.FEEDING and card._into == "shred", "solto na trituradora, ela puxa o cartão")
	ok(await wait_until(func(): return card.state == card.State.IDLE, 3.0) and d._location.is_empty() and d.occurrence() == ""
		and d._slip.visible and m.report.faults.size() == faults, "triturado: nada sai, sem advertência, a impressora espera outro local")
	d.set_location("sol", 0, "Rua do Sol, 1–99")
	ok(await wait_until(func(): return card.state == card.State.READY, 5.0), "mais um cartão")
	_mouse(card, cell.call("Incêndio"), 1)
	_mouse(card, cell.call("Mal súbito"), 1)
	ok(d.occurrence() == "Incêndio", "um tipo só: o primeiro furo vale")
	ok(d._selected_units().is_empty() and not d.can_send(), "o tipo não marca unidade")
	_mouse(card, cell.call("amb"), 1)
	ok(d.can_send() and d.picked() == ["amb"], "local, tipo e unidade perfurados")
	drag.call(await slot.call("send"))
	ok(card.state == card.State.FEEDING and card._into == "send", "o transmissor puxa o cartão completo")
	ok(await wait_until(func(): return d._location.is_empty(), 3.0), "o cartão no cartucho envia")
	ok(d.occurrence() == "" and d.picked().is_empty() and d.city.sel.is_empty() and card.state == card.State.IDLE, "depois de enviar, local e tipo limpos")
	ok(not d.unit_free("amb"), "ambulância a caminho fica indisponível")
	ok(not d._slip.visible, "depois de enviar, a ficha se recolhe")
	await frames(2)
	ok(d.get_node("%Fleet").visible and d.get_node("%Report").text.contains(T.text(T.Key.UNIT_AMBULANCE)), "a faixa das viaturas mostra quem saiu")
	m.tools.set_tab("lista")
	print("OK 13 mapa e despacho")

	# ---- 14. painel de debug (F1): toca uma emergência, pula estágio, registra as pendências
	var dbg = m.get_node("%Debug")
	_key(KEY_F1)
	await frames(2)
	ok(dbg.visible, "F1 abre o painel de debug")
	dbg._emergency.select(0)
	dbg._ring_emergency()
	var de: PhoneCall = m.em_call
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
	m.notebook.add({"time": "18:00", "who": "x", "where": "—", "unit": "—", "obs": "", "kind": PhoneCall.Kind.TRANSFER, "missed": false, "tut": false})
	dbg._restore_all()
	await frames(2)
	ok(m.live.is_empty() and m.em_call == null and not de.urgent() and m.radio._alert == -1, "restaurar: ligações e emergência somem")
	ok(range(1, Exchange.LINES + 1).all(func(n): return m.exchange.line(n) == Exchange.Line.FREE), "restaurar: linhas livres")
	ok(await wait_until(func(): return m.board.ends.all(func(e): return e == -1), 10.0), "restaurar: cabos na base")
	ok(m.dispatch._units.values().all(func(s): return s == 0) and m.dispatch.required().is_empty(), "restaurar: despacho livre")
	ok(not m.notebook.has_pending() and m.report.faults.is_empty() and Engine.time_scale == 1.0, "restaurar: caderno, relatório e tempo zerados")
	ok(not m.sched.any(func(c): return c.retry != PhoneCall.Retry.NONE), "restaurar: ninguém liga de novo")
	Engine.time_scale = 8.0
	_key(KEY_F1)
	await frames(2)
	ok(not dbg.visible, "F1 fecha o painel")
	print("OK 14 painel de debug")
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
