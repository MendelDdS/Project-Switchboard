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
	m = await load_main()
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
		ok(not GameData.is_closed(int(t.target)) or t.alt_target != "", "lugar fechado tem alternativa: " + t.resource_path)
	for e in C.emergencies:
		ok(GameData.street(e.street) != null and e.questions.size() == e.answers.size() and e.occurrence in C.occurrences, "emergência válida: " + e.resource_path)
	# unidades válidas, e cada caso troca no máximo as respostas que existem
	var valid := func(us: PackedStringArray): return not us.is_empty() and Array(us).all(func(u): return u in ["pol", "bomb", "amb"])
	for e in C.emergencies + C.emergency_templates:
		ok(valid.call(e.units) and e.cases.all(func(k: EmergencyCase): return valid.call(k.units) and k.answers.size() <= e.questions.size()),
			"unidades e casos válidos: " + e.resource_path)
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
		var talk: PackedStringArray = m.smalltalk()
		ok(not (C.get("smalltalk_" + w) as PackedStringArray).is_empty(), "falas do clima: " + w)
		ok(w == "rain" or not Array(talk).any(func(l): return "chuva" in l), "sem chuva na conversa: " + w)
	# moldes: nenhuma lacuna sobra sem preencher
	var holes := func(texts: Array) -> bool: return texts.any(func(x): return "{" in x or "}" in x)
	for i in 300:
		var t := GameData.template_transfer()
		ok(int(t.target) in nums and not GameData.is_closed(int(t.target)), "molde: destino atende")
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
	m.night.max_live = 10   # a agenda de verdade pode já ter ligações tocando; aqui só importa o marcador
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
	var chat: Array = Array(m.smalltalk())
	ok(said_at[0][0] >= m.SMALLTALK_AFTER and (said_at[0][1] in chat or said_at[0][1] in waiting), "primeira fala só depois de um tempo: " + said_at[0][1])
	ok(said_at[1][1] in waiting, "depois reclama da demora: " + said_at[1][1])
	ok(asked > 0 and not wc.transcript.slice(0, asked).any(func(l): return String(l["text"]) in chat), "sem conversa fiada logo depois do pedido")
	m.end_call(wc, PhoneCall.End.OPERATOR)
	print("OK 11 conversa fiada e reclamação na espera")

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
	print("OK 12 atalhos do telefone")

	# ---- 13. mapa e despacho numa tela: o tipo não marca unidades (a conversa decide), Enviar só com tudo, e depois limpa
	var d = m.dispatch
	d.set_occurrence("")
	ok(not d.can_send() and d._send_button.disabled, "despacho vazio não envia")
	d.set_location("sol", 0, "Rua do Sol, 1–99")
	d.set_occurrence("Incêndio")
	ok(d._selected_units().is_empty() and not d.can_send(), "o tipo não marca unidade")
	(d._unit_buttons["amb"] as Button).button_pressed = true
	ok(d.can_send() and not d._send_button.disabled, "local, tipo e unidade: Enviar acende")
	d._send()
	ok(d._location.is_empty() and d._occ_group.get_pressed_button() == null and d.city.sel.is_empty(), "depois de enviar, local e tipo limpos")
	ok(d._unit_buttons["amb"].disabled, "ambulância a caminho fica indisponível")
	print("OK 13 mapa e despacho")
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
