extends "res://tests/test_base.gd"
## O fator sucesso da rebelião (`scripts/model/rebellion.gd`) em cada caminho do roteiro, e os textos que dependem dos
## marcadores (`Night.note_for`, `stories_for`), sem a cena (~1 s):
##   tests/run.sh story

const R := preload("res://scripts/model/rebellion.gd")
const StoryText := preload("res://scripts/data/story_text.gd")


func _f(names: Array) -> StoryFlags:
	return StoryFlags.new(PackedStringArray(names))


func _initialize() -> void:
	# a TV: o hotel com a senha (Dia 4), sem a denúncia; só conta do fim da noite 4 em diante
	ok(not R.tv(_f([R.HOTEL]), 4) and R.tv(_f([R.HOTEL]), 5), "TV: o hotel com a senha, depois da noite 4")
	ok(not R.tv(_f([R.HOTEL, R.DENOUNCED]), 5), "TV: a denúncia derruba")
	ok(not R.tv(_f([]), 5), "TV: sem a senha (Dias 2 e 3 perdidos), não vem")
	# a rádio: o pedido do Dia 9 cumprido e nenhuma fita que a entrega
	var radio_ok := [R.IGNORED, R.HOSPITAL]
	ok(R.radio(_f(radio_ok), 10) and not R.radio(_f(radio_ok), 9), "rádio: cumpriu o Dia 9, depois da noite 9")
	ok(not R.radio(_f([R.HOSPITAL]), 10), "rádio: sem cumprir o Dia 9, não vem")
	ok(not R.radio(_f(radio_ok + [R.TAPE_RADIO]), 10), "rádio: a fita da rádio entregue")
	ok(not R.radio(_f(radio_ok + [R.TAPE_GROUPS]), 10), "rádio: a fita do local dos grupos entregue")
	ok(R.radio(_f(radio_ok + [R.TAPE_GUNS]), 10) and R.radio(_f(radio_ok + [R.TAPE_GROUP_C]), 10), "rádio: armas ou grupo C sozinhos não a entregam")
	ok(not R.radio(_f([R.IGNORED, R.TAPE_GUNS, R.TAPE_GROUP_C]), 10), "rádio: armas + grupo C + hospital esquecido")
	ok(not R.radio(_f(radio_ok + [R.TAPE_GUNS, R.TAPE_GROUP_C, R.WARNED_HOTEL]), 10), "rádio: armas + grupo C + hotel avisado")
	ok(R.radio(_f(radio_ok + [R.TAPE_GUNS, R.TAPE_GROUP_C]), 10), "rádio: armas + grupo C com o hospital avisado, ainda vem")
	var rare := _f([R.IGNORED, R.TAPE_GUNS, R.TAPE_GROUP_C])
	R.sync(rare, 9)
	ok(rare.has(R.TAKEOVER_LOST) and not R.takeover_lost(_f(radio_ok)), "tomada: já na noite 9, a mesma conta da rádio (o caso raro também)")

	# os caminhos do roteiro até a noite 11 (a carta) e a 15 (o golpe)
	var done: Array = []   # as ordens de Sebastião nas noites 14 e 15, cumpridas
	for o: Array in R.ORDERS:
		done.append_array(o[0])
	var full := [R.HOTEL, R.HOSPITAL, R.IGNORED, R.PARISH] + done   # colaborou em tudo
	ok(R.level(_f(full), 11) == R.Level.HIGH, "colaborou: chances altas no Dia 11 (a carta amiga)")
	ok(R.level(_f(full + [R.TAPE_SEBASTIAO]), 15) == R.Level.HIGH and R.won(_f(full + [R.TAPE_SEBASTIAO]), 15), "colaborou: vence")
	var obeyed := full + [R.TAPE_SEBASTIAO, R.OBEYED + "a", R.OBEYED + "b"]
	ok(R.won(_f(obeyed), 15), "chances altas: dois vacilos não derrubam")
	ok(not R.won(_f(obeyed + [R.OBEYED + "c", R.OBEYED + "d"]), 15), "chances altas: vacilos grandes derrubam")
	var bitter := [R.HOTEL, R.TAPE_GUNS, R.HOSPITAL, R.IGNORED, R.PARISH] + done   # vitória amarga: entregou a das armas
	ok(R.level(_f(bitter), 11) == R.Level.MEDIUM, "fita das armas: cai pela metade, chances médias")
	ok(R.won(_f(bitter + [R.TAPE_SEBASTIAO]), 15) and R.level(_f(bitter + [R.TAPE_SEBASTIAO]), 14) != R.Level.HIGH, "vitória amarga: vence, mas a pedra vem")
	var late := [R.HOSPITAL, R.IGNORED, R.PARISH] + done   # não colaborou até o Dia 8, depois sim: só a rádio
	ok(R.level(_f(late), 11) == R.Level.MEDIUM, "voltou no Dia 8: chances médias, sem margem")
	ok(not R.won(_f(late + [R.OBEYED + "a"]), 15), "voltou no Dia 8: o primeiro vacilo derruba")
	ok(R.won(_f(late + [R.TAPE_SEBASTIAO, R.OBEYED + "a"]), 15), "voltou no Dia 8 e deu a fita a Sebastião: aguenta um vacilo")
	ok(R.level(_f([]), 11) == R.Level.LOW and not R.won(_f([]), 15), "não ajudou ninguém (esquecida): baixas, falha")
	ok(not R.won(_f([R.DENOUNCED, R.HOTEL, R.HOSPITAL, R.IGNORED, R.PARISH, R.TAPE_SEBASTIAO]), 15), "denunciou: despenca e falha")
	ok(R.level(_f(full + [R.TAPE_CHIEF]), 11) == R.Level.MEDIUM, "fita do comandante: cai pela metade")
	ok(R.level(_f(full + [R.WARNED_HOTEL]), 11) == R.Level.MEDIUM, "hotel avisado: cai um pouco (de 4 a 3)")
	ok(R.points(_f(full), 12) == R.points(_f(full), 13) + 1, "a fita de Sebastião que não veio só conta depois da noite 12")
	var undone := full.filter(func(x: String) -> bool: return not x in done) + [R.TAPE_SEBASTIAO]
	ok(R.points(_f(undone), 15) == R.points(_f(full + [R.TAPE_SEBASTIAO]), 15), "as ordens da 15 não contam durante a noite")
	ok(R.points(_f(undone), 16) == R.points(_f(full + [R.TAPE_SEBASTIAO]), 16) - 2, "as ordens da 15 só contam à meia-noite (a conta como noite 16)")
	ok(R.points(_f(undone + ["sinal_centro_15"]), 16) == R.points(_f(undone), 16), "o sinal só a um dos setores não cumpre a ordem")
	ok(R.points(_f([]), 8) == 0 and R.points(_f([]), 9) == -2, "o hospital esquecido só conta depois da noite 8")

	# os finais, à meia-noite da 15
	var C: GameContent = GameData.CONTENT
	var won_full := full + [R.TAPE_SEBASTIAO]
	ok(R.final(_f(won_full), 15) == R.Final.SUCCESS, "final: sucesso")
	ok(R.final(_f(won_full + [R.DISOBEYED + "a"]), 15) == R.Final.SUCCESS, "final: desobedecer com o golpe vencido ainda é o sucesso")
	ok(R.final(_f(bitter + [R.TAPE_SEBASTIAO]), 15) == R.Final.SUCCESS and R.costly(_f(bitter)), "final: vitória amarga (sucesso que custou gente), a fita das armas")
	var no_parish := won_full.filter(func(x: String) -> bool: return x != R.PARISH)
	ok(R.won(_f(no_parish), 15) and R.final(_f(no_parish), 15) == R.Final.SUCCESS and R.costly(_f(no_parish)), "final: vitória amarga, a paróquia esquecida")
	ok(R.final(_f([]), 15) == R.Final.FAILURE, "final: fracasso")
	ok(R.final(_f([R.DISOBEYED + "a", R.DISOBEYED + "b", R.OBEYED + "c"]), 15) == R.Final.PRISON, "final: presa (o golpe falhou e ela desobedeceu mais do que obedeceu)")
	ok(R.final(_f([R.DISOBEYED + "a", R.OBEYED + "b"]), 15) == R.Final.FAILURE, "final: um corte só, obedecendo o resto, é o fracasso")
	var mother: PrankCall = C.epilogue.story.filter(func(x: StoryCall): return x.call.caller == "Mãe de Cecília")[0].call
	var sucesso: String = R.FINALS[R.Final.SUCCESS]   # o sucesso puro, a vitória amarga (o sucesso que custou gente) e o fracasso
	for req in [[sucesso, "!" + R.COST], [sucesso, R.COST], [R.FINALS[R.Final.FAILURE]]]:   # a mãe da Cecília liga em todos, cada um com a sua conversa
		ok(mother.steps.filter(func(st: PrankStep): return st.requires == PackedStringArray(req)).size() >= 5, "epílogo: a mãe com a conversa de " + str(req))

	# a madrugada da 15: o reforço da Capital vale o dobro, o aviso da armadilha soma; sem chance nem com o aviso, o
	# veredito sai antes das 4h
	var base := R.points(_f(full), 16)
	ok(R.points(_f(full + [R.REINFORCEMENT]), 16) == base - 2 and R.points(_f(full + [R.TRAP_WARNED]), 16) == base + 1,
		"madrugada: o reforço tira 2, o aviso da armadilha soma 1")
	ok(not R.hopeless(_f(full), 16, 360.0) and R.hopeless(_f([]), 16, 360.0), "madrugada: sem chance só quando nem o aviso salva")
	ok(R.WOUNDED_LOST in R.COSTLY, "madrugada: o ferido perdido custou gente")

	# as conclusões viram marcadores, para o roteiro usar
	var f := _f(full)
	R.sync(f, 11)
	ok(f.has(R.TV) and f.has(R.RADIO) and f.has("chance_alta") and not f.has("chance_media"), "sync: TV, rádio e o nível")
	f.apply(R.TAPE_GROUPS)
	R.sync(f, 11)
	ok(not f.has(R.RADIO) and f.has(R.HOTEL_TAPED) and f.has("chance_media") and not f.has("chance_alta"), "sync: a fita do hotel muda tudo")

	# o bilhete e o jornal com os marcadores
	var n := Night.new()
	n.note = "padrão"
	var v := StoryText.new()
	v.text = "variante"
	v.requires = PackedStringArray(["x"])
	n.notes = [v]
	n.news_stories = PackedStringArray(["sempre"])
	n.news_if = [v]
	ok(n.note_for(_f([])) == "padrão" and n.note_for(_f(["x"])) == "variante" and n.note_for(null) == "padrão", "bilhete: a versão que bate")
	ok(n.stories_for(_f(["x"])) == PackedStringArray(["variante", "sempre"]) and n.stories_for(_f([])) == PackedStringArray(["sempre"]),
		"jornal: a matéria que bate, na frente")

	# a carta de Sebastião (noite 11): amiga com chances altas, ameaça nas outras
	var n11: Night = GameData.CONTENT.nights[10]   # (a 0 da lista é a noite 1)
	var friend := n11.letter_for(_f(["chance_alta"]))
	var threat := n11.letter_for(_f(["chance_media"]))
	ok(friend != "" and threat != "" and friend != threat and "Cristóvão" in threat and not "Cristóvão" in friend,
		"carta do Dia 11: amiga com chances altas, ameaça com o nome do pai nas outras")
	ok(n.letter_for(_f([])) == "", "noite sem carta")

	# a senha do Dia 4: ligar para o hotel das 20:30 às 21h e dizer "A semente brotou" (fora disso, o hotel de sempre)
	var pw: Array = GameData.CONTENT.nights[3].dial.filter(func(d): return d.number == "305")
	ok(pw.size() == 1 and pw[0].from == 150.0 and pw[0].to == 180.0
		and pw[0].steps.any(func(st: PrankStep): return R.HOTEL in st.sets), "Dia 4: a senha ao hotel, das 20:30 às 21h")

	# as cenas da rua do roteiro com condição
	var stone: Array = C.nights[13].street_events.filter(func(e): return e.kind == "stone")
	var raid: Array = C.nights[12].street_events.filter(func(e): return e.kind == "raid")
	ok(stone.size() == 1 and stone[0].requires == PackedStringArray(["!chance_alta"]), "a pedra (14) só sem chances altas")
	ok(raid.size() == 1 and raid[0].requires == PackedStringArray([R.HOTEL_TAPED]), "a batida (13) só com uma fita do hotel na polícia")
	var banner: Array = C.nights[14].street_events.filter(func(e): return e.kind == "banner")
	ok(banner.size() == 1 and banner[0].at == 600.0 and banner[0].requires == PackedStringArray([R.WON]), "a bandeira (15) no veredito das 4h, só com o golpe vencido")
	for n_i in [12, 13]:
		ok(C.nights[n_i].street_events.any(func(e): return e.kind == "stranger" and e.at == 240.0), "o homem de sobretudo às 22h na noite %d" % (n_i + 1))
	# a presa na 15 (a cúpula no veredito) e o epílogo (a 16, fora de `nights`): uma ligação por final, a carta e o fecho
	var presa: Array = C.nights[14].story.filter(func(x: StoryCall): return x.requires == PackedStringArray([R.FINALS[R.Final.PRISON]]))
	ok(presa.size() == 1 and presa[0].at == 600.0 and presa[0].authority and not presa[0].again, "presa: a cúpula liga no veredito da 15 (às 4h, ou antes, quando ele sai antes)")
	var epi: Night = C.epilogue
	ok(epi != null and not epi in C.nights, "o epílogo, fora das noites")
	for fin in [[sucesso, R.WON], [sucesso, R.WON, R.COST], [R.FINALS[R.Final.FAILURE], R.LOST]]:
		var fl := _f(fin)
		ok(epi.ending_for(fl) != null and epi.story.any(func(x: StoryCall): return fl.allows(x.requires)), "epílogo: fecho e ligação no final " + str(fin))
	ok(epi.letter_for(_f([R.FINALS[R.Final.FAILURE]])) != "" and epi.letter_for(_f([R.FINALS[R.Final.SUCCESS]])) == "", "epílogo: a carta do supervisor só no fracasso")
	ok(C.nights[14].ending_for(_f([R.FINALS[R.Final.SUCCESS]])).title != "" and C.nights[14].ending_for(_f([R.FINALS[R.Final.FAILURE]])) == null,
		"noite 15: o encontro com Sebastião só no sucesso")
	finish("fator sucesso")
