extends "res://tests/test_base.gd"
## O discador (`Dialing`, `Conversation._outgoing`): digitar e discar, os avisos do visor (tronco, despacho, setor que
## não é do operador, número que não existe, ocupado), a conversa com o lugar (atende, uma pergunta, encerrar), a
## linha dele ocupada enquanto isso, o foco que volta ao FONE, desligar no meio e a ligação do roteiro (`DialCall`)
## com os marcadores dela.

const DialCall := preload("res://scripts/data/dial_call.gd")

var m: Main
var d: Main.Dialing


func _type(number: String) -> void:
	d.end()   # (apaga o que houver)
	d.end()
	for ch in number:
		d.press(ch)


func _pick(c: PhoneCall, label_start: String) -> bool:
	for o in c.options:
		if String(o["label"]).begins_with(label_start):
			o["fn"].call()
			return true
	return false


func _initialize() -> void:
	Engine.time_scale = 8.0
	m = await load_main([3])
	m.sched.clear()
	m._intro.visible = false
	m.running = true
	d = m.dialing

	# ---- digitar: até três algarismos; o quarto não entra; Encerrar apaga
	_type("3901")
	ok(d.digits == "390", "o quarto algarismo não entra (%s)" % d.digits)
	d.end()
	ok(d.digits == "" and d.status == d.Status.IDLE, "Encerrar apaga o número")
	d.press("3")
	d.dial()
	ok(d.call == null and d.status == d.Status.IDLE, "número incompleto não disca")

	# ---- os avisos do visor
	for c: Array in [["901", d.Status.TRUNK], ["190", d.Status.DISPATCH], ["101", d.Status.NOT_SERVED], ["300", d.Status.NO_NUMBER]]:
		_type(c[0])
		d.dial()
		ok(d.call == null and d.status == c[1], "%s: visor %s (deu %s)" % [c[0], c[1], d.status])
	# as centrais (001–003): fora dos setores; a própria dá ocupado; a da Cecília some da noite 9 em diante
	_type("003")
	d.dial()
	ok(d.call == null and d.status == d.Status.BUSY, "003, a própria central: ocupado")
	var was: int = m.night_no
	m.night_no = 9
	_type("002")
	d.dial()
	ok(d.call == null and d.status == d.Status.NO_NUMBER, "002 na noite 9: não existe mais")
	m.night_no = was
	ok(GameData.entry("001") != null and GameData.entry("002").answers_until < 8, "001 e 002 no discador; a Cecília some do 8")
	m.exchange.set_dest(305, Exchange.Dest.CONN)   # o hotel conectado numa transferência
	_type("305")
	d.dial()
	ok(d.call == null and d.status == d.Status.BUSY, "lugar já conectado: ocupado")
	m.exchange.set_dest(305, Exchange.Dest.FREE)

	# ---- a ligação para a rádio: chama, atende, uma pergunta, encerrar
	var fone_call := PhoneCall.from_transfer(GameData.CONTENT.transfers[0])
	m.ring(fone_call)
	m.board.ends[0] = fone_call.line   # ponytail: o FONE posto direto na entrada, sem o arraste
	m.answer()
	ok(m._focus() == fone_call, "com o FONE na entrada, o foco é dela")
	_type("390")
	d.dial()
	var c := d.call
	ok(c != null and c.kind == PhoneCall.Kind.OUTGOING and d.status == d.Status.CALLING, "discou: chamando")
	ok(m._focus() == c and not fone_call.on_line, "a feita é o foco; a do FONE fica em espera")
	ok(m.exchange.line(fone_call.line) == Exchange.Line.HOLD, "a linha do FONE em espera (quem espera demais desiste)")
	m._vacated(390, 3)   # ponytail: um cabo saindo da tomada da rádio (a ponta não importa: a linha chamada não se solta)
	ok(m.exchange.dest(390) == Exchange.Dest.RING and d.call == c, "o cabo solto na tomada chamada não solta a linha")
	ok(m.exchange.dest(390) == Exchange.Dest.RING, "a linha da rádio toca")
	ok(await wait_until(func(): return d.status == d.Status.TALK, 30.0), "a rádio atendeu")
	ok(m.exchange.dest(390) == Exchange.Dest.CONN and m.flags.allows(["ligou_390_1"]), "conectada, e o marcador ligou_390_1")
	ok(await wait_until(func(): return c.options.size() >= 2, 30.0), "as perguntas e o Encerrar")
	var bye := T.text(T.Key.CHOICE_DIAL_BYE)
	ok(String(c.options[-1]["label"]) == bye and c.options.size() <= Conversation.DIAL_ASKS + 1, "até %d perguntas e o Encerrar" % Conversation.DIAL_ASKS)
	c.options[0]["fn"].call()
	ok(await wait_until(func(): return c.options.size() == 1, 30.0), "respondida, só resta encerrar")
	ok(_pick(c, bye), "Encerrar ligação")
	ok(await wait_until(func(): return d.call == null, 30.0), "a ligação acabou depois da despedida")
	ok(d.status == d.Status.ENDED and m.exchange.dest(390) == Exchange.Dest.FREE, "a linha da rádio livre de novo")
	ok(c.transcript.any(func(l): return l["text"] == T.text(T.Key.OP_DIAL_BYE)), "o operador se despediu")
	ok(m._focus() == fone_call and fone_call.on_line, "o foco volta ao FONE")
	ok(m.exchange.line(fone_call.line) == Exchange.Line.TALK, "a do FONE sai da espera")
	m.end_call(fone_call, PhoneCall.End.OPERATOR)

	# ---- desligar no meio (Desligar do console, com a feita em foco)
	_type("344")
	d.dial()
	ok(d.call != null, "discou para o cinema")
	m.hangup()
	ok(d.call == null and m.exchange.dest(344) == Exchange.Dest.FREE, "Desligar encerra a feita e solta a linha")

	# ---- rediscar: Discar com o número da última ainda no visor, ou com ele vazio, liga de novo para ela
	d.dial()
	ok(d.call != null and d.call.target == "344", "Discar de novo rediscou o 344")
	d.hang_up()
	d.end()
	ok(d.digits == "", "Encerrar apagou o visor")
	d.dial()
	ok(d.call != null and d.call.target == "344", "com o visor vazio, Discar liga para o último")
	d.hang_up()

	# ---- o lugar fechado não atende: a pensão fecha às 22h
	m.minutes = 250.0
	_type("312")
	d.dial()
	c = d.call
	ok(await wait_until(func(): return d.status == d.Status.NO_ANSWER, 40.0), "depois das 22h, ninguém atende na pensão")
	m.minutes = 30.0

	# ---- a palavra-chave dita na resposta vai para as anotações da lista
	var cine: DirectoryEntry = GameData.entry("344")
	var keep := cine.answers
	var topic := ChatTopic.new()
	topic.line = "Cine Odeon."
	var reply := ChatReply.new()
	reply.text = "Quem esteve aí?"
	reply.follow = "O [person:Benedito Souza] veio às nove."
	topic.replies.append(reply)
	cine.answers = [topic]
	_type("344")
	d.dial()
	c = d.call
	ok(await wait_until(func(): return not c.options.is_empty(), 30.0), "o cinema atendeu")
	c.options[0]["fn"].call()
	ok(await wait_until(func(): return m.eavesdrop.clues.any(func(k: Clue): return k.word == "Benedito Souza" and k.number == "344"), 30.0),
		"a palavra-chave da resposta foi anotada, com o número do cinema")
	ok(await wait_until(func(): return c.transcript.any(func(l): return "Benedito Souza veio" in String(l["text"])), 30.0), "a fala sem as marcas")
	d.hang_up()
	cine.answers = keep

	# ---- a ligação do roteiro: atende no lugar do de sempre, liga os marcadores e, feita, não volta
	var story := DialCall.new()
	story.number = "355"
	story.requires = PackedStringArray(["teste_discador"])
	story.caller = "Voz estranha"
	story.sets = PackedStringArray(["fez_a_ligacao"])
	for k in [[PrankStep.Kind.CALLER, "Eu sabia que você ia ligar."], [PrankStep.Kind.OPERATOR, ""]]:
		var st := PrankStep.new()
		st.kind = k[0]
		st.text = k[1]
		if k[0] == PrankStep.Kind.OPERATOR:
			st.options = PackedStringArray(["Quem fala?"])
			st.sets = PackedStringArray([StoryFlags.FAULT + "teste"])   # (como a cobrança do Dia 12: advertência)
		story.steps.append(st)
	story.take_over_path("res://data/dial/teste.tres")   # (o nome do arquivo dá o marcador `discou_teste`)
	m.night.dial.append(story)
	_type("355")
	d.dial()
	ok(d.call != null and d.call.data != story, "sem o marcador, o bilhar atende como sempre")
	d.hang_up()
	m.flags.apply("teste_discador")
	_type("355")
	d.dial()
	c = d.call
	ok(c != null and c.data == story and c.caller == "Voz estranha", "com o marcador, atende a do roteiro")
	ok(await wait_until(func(): return not c.options.is_empty(), 30.0), "a pergunta do roteiro")
	c.options[0]["fn"].call()
	ok(await wait_until(func(): return d.call == null, 30.0), "a do roteiro acaba sozinha")
	ok(m.flags.allows([StoryFlags.FAULT + "teste", "fez_a_ligacao", "discou_teste"]), "os marcadores da escolha, do fim e do feito")
	ok(m.report.faults.any(func(f): return f["id"] == "authority_ignored"), "o marcador advertencia_ vira advertência")
	_type("355")
	d.dial()
	ok(d.call != null and d.call.data != story, "feita, o número volta ao de sempre")
	var done := {}   # as de dentro de uma noite: uma feita não cala as outras
	var dials := (load("res://data/nights/night_15.tres") as Night).dial
	for dc: DialCall in dials:
		done[dc.done_flag()] = true
	ok(done.size() == dials.size() and done.has("discou_night_15_D_ser"), "o marcador do feito é de cada ligação: %s" % [done.keys()])
	d.hang_up()
	m.night.dial.erase(story)
	finish("discador")
