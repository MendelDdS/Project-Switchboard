extends "res://tests/test_base.gd"
## O conteúdo de `data/` (o que o roteirista escreve) bate com as regras do jogo, sem montar a cena (~2 s):
##   tests/run.sh content
## Todo roteiro aponta para números, ruas e unidades que existem; lacunas, palavras-chave e traduções; marcadores do
## roteiro que alguém liga; falas novas já no .po. Só confere: não escreve nem corrige nada.


## Lacunas de um texto (%s, %02d, {place}...), para comparar entre idiomas.
func _holes(s: String) -> Array:
	var re := RegEx.create_from_string("%[0-9]*[sd]|\\{[a-z_]+\\}|\\[[a-z]+:")   # [tipo: a marca da palavra-chave (`Clue`)
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


## As regras de escrita das conversas escutadas (README, "Cada motivo traz a conversa"): num lugar com ramo que pode
## ser trocado pela alternativa, a conversa não diz o tipo do lugar (`KIND_WORDS`; ramo novo entra nela); só lacunas
## que existem; palavras-chave (`Clue`) bem marcadas e de tipo conhecido; cada fala num fôlego (`TALK_MAX` letras,
## sem as marcas) nos três idiomas.
const KIND_WORDS := {"hospedagem": ["hotel", "pensão", "pousada"], "oficina": ["oficina", "borracharia"],
	"farmácia": ["farmácia", "drogaria"], "igreja": ["igreja", "paróquia", "paroquial"], "mercearia": ["mercearia", "armazém"]}
const TALK_MAX := 90
func _check_talks() -> void:
	var talks := []   # [contato, falas, se a alternativa pode atender no lugar]
	for d: DirectoryEntry in GameData.CONTENT.directory:
		ok(d.category == "" or KIND_WORDS.has(d.category), "ramo sem as palavras do tipo em KIND_WORDS: " + d.category)
		for mo: Motive in d.motives:
			for talk in mo.talks:
				talks.append([d, talk, true])
	for t: TransferCall in GameData.CONTENT.transfers:
		talks.append([GameData.entry(t.target), t.overheard, t.alt_target != ""])
	for x in talks:
		var words: Array = KIND_WORDS.get(x[0].category, []) if x[2] else []
		for line: String in x[1]:
			ok(not words.any(func(w: String): return w in line.to_lower()), "a conversa diz o tipo do lugar (%s): %s" % [x[0].name, line])
			var known := func(h: String): return h.trim_prefix("{").trim_suffix("}") in GameData.talk_holes() or h.trim_prefix("[").trim_suffix(":") in Clue.KINDS
			ok(_holes(line).all(known), "lacuna ou tipo de palavra-chave que não existe: " + line)
			var plain: String = Clue.parse(line)[0]
			ok(not "[" in plain and not "]" in plain, "palavra-chave mal marcada: " + line)
	var sus := GameData.CONTENT
	ok(sus.overheard_ask.size() >= 3 and sus.overheard_ask.size() == sus.overheard_sure.size(), "cada pergunta da suspeita tem a sua resposta")
	talks.append([DirectoryEntry.new(), sus.overheard_ask + sus.overheard_sure, false])
	ok(Clue.parse("[time:{hour}]. Na [street:Rua do Sol].") == ["{hour}. Na Rua do Sol.", [[0, 6, "time"], [11, 21, "street"]]],
		"palavras-chave: a fala sem as marcas e onde fica cada uma")
	var all_holes := " ".join(GameData.talk_holes().map(func(h: String): return "{%s}" % h))
	ok(not "{" in GameData.fill(all_holes, GameData.talk_vars()), "toda lacuna da conversa escutada é preenchida")
	for lang in ["pt_BR", "en", "es"]:
		TranslationServer.set_locale(lang)
		for x in talks:
			for line: String in x[1]:
				ok(Clue.parse(tr(line))[0].length() <= TALK_MAX, "fala escutada longa demais (%s): %s" % [lang, tr(line)])
	TranslationServer.set_locale("pt_BR")


## Todo número da lista serve para alguma coisa (`CLAUDE.md`): é destino de transferência. Conta a ligação escrita
## (avulsa, do roteiro de uma noite ou do treinamento, também a alternativa dela), o lugar que um molde pode sortear
## (`GameData.template_transfer`: com `spoken` e motivo) e o do mesmo ramo, oferecido quando ele não atende
## (`GameData.alternative`). Os só do despacho (`dispatch_only`) ficam de fora: servem às viaturas.
## As ligações escritas da noite (`Night.calls`) e quem volta a ligar depois delas (`StoryCall.callback`).
static func _night_calls(n: Night) -> Array:
	var out: Array = []
	for st: StoryCall in n.calls:
		out.append(st)
		out.append_array(st.callback)
	return out


func _check_destinations() -> void:
	var C: GameContent = GameData.CONTENT
	var written: Array[TransferCall] = C.transfers.duplicate()
	for n: Night in C.nights + [C.training]:
		for st: StoryCall in (n.story as Array) + _night_calls(n):
			if st.call is TransferCall:
				written.append(st.call)
		for step: LessonStep in n.lesson:
			if step.call != null:
				written.append(step.call)
	var asked := {}   # número -> true
	for t in written:
		asked[t.target] = true
		if t.alt_target != "":
			asked[t.alt_target] = true
	for d: DirectoryEntry in C.directory:
		if d.spoken != "" and not d.motives.is_empty() and not d.dispatch_only:
			asked[d.number] = true
	var branches := {}   # ramo com algum destino: os outros do ramo entram como alternativa
	for d: DirectoryEntry in C.directory:
		if d.category != "" and asked.has(d.number):
			branches[d.category] = true
	for d: DirectoryEntry in C.directory:
		var alt := d.category != "" and d.spoken != "" and branches.has(d.category)
		ok(d.dispatch_only or asked.has(d.number) or alt,
			"número que não serve para nada (nenhuma ligação nem molde transfere para ele): %s, %s" % [d.number, d.name])


## Marcadores do roteiro (`StoryFlags`): todo nome pedido em `requires` é ligado por alguém, um `sets` do conteúdo
## ou um `flags.apply("nome")` do código (com `_%d`, o da noite: "escutou_3"). Pega o nome digitado errado, que
## deixaria o ramo do roteiro sem nunca tocar.
func _check_flags() -> void:
	var asked := {}   # nome -> arquivo onde foi pedido
	var given := {}
	_walk_flags(GameData.CONTENT, "", {}, asked, given)
	var code := ""
	for dir in ["res://scripts/", "res://scripts/model/", "res://scripts/ui/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				code += FileAccess.get_file_as_string(dir + f)
	var by_night := []   # os prefixos dos marcadores da noite ("escutou_%d")
	for m in RegEx.create_from_string("(?:flags\\.apply|_teach|_opened)\\((?:Tools\\.[A-Z_]+, )?\"([a-z_]+?)(_%d)?\"").search_all(code):
		if m.get_string(2) != "":
			by_night.append(m.get_string(1))
		else:
			given[m.get_string(1)] = true
	var rebellion := preload("res://scripts/model/rebellion.gd")   # as conclusões do fator sucesso (`Rebellion.sync`)
	for d: String in rebellion.DERIVED + rebellion.FINALS + [rebellion.WON, rebellion.LOST, rebellion.COST]:
		given[d] = true
	for i in GameData.CONTENT.nights.size():   # as cenas da rua com `requires` ligam "rua_<kind>_<noite>" (`Main._street_check`)
		for e in GameData.CONTENT.nights[i].street_events:
			given["rua_%s_%d" % [e.kind, i + 1]] = true
	for name: String in asked:
		var nightly := RegEx.create_from_string("^(.+)_[0-9]+$").search(name)
		ok(given.has(name) or nightly != null and nightly.get_string(1) in by_night,
			"marcador que ninguém liga (digitado errado?): %s, em %s" % [name, asked[name]])


func _walk_flags(r: Resource, src: String, seen: Dictionary, asked: Dictionary, given: Dictionary) -> void:
	if r == null or seen.has(r):
		return
	seen[r] = true
	if r.resource_path != "" and not "::" in r.resource_path:
		src = r.resource_path
	for p in r.get_property_list():
		if not (p["usage"] & PROPERTY_USAGE_STORAGE) or p["name"] == "script":
			continue
		var v = r.get(p["name"])
		if p["name"] in ["requires", "done"]:   # (o `done` das tarefas do diário também pede marcador que exista)
			for f: String in v:
				asked[f.trim_prefix("!")] = src
		elif p["name"] in ["sets", "overheard_sets", "overheard_flags"] or p["name"].begins_with("if_"):
			for f: String in v:
				given[f.trim_prefix("!")] = true
		elif v is Resource:
			_walk_flags(v, src, seen, asked, given)
		elif v is Array:
			for item in v:
				if item is Resource:
					_walk_flags(item, src, seen, asked, given)


## Toda fala do conteúdo já está nos .po (pela mesma busca do `tools/update_translations.gd`): fala nova sem entrada
## é o aviso de rodar a ferramenta (sem ela, a fala nunca chega aos tradutores).
func _check_po() -> void:
	var tool: Object = load("res://tools/update_translations.gd").new()
	tool._visit(load("res://data/content.tres"), "res://data/content.tres", {})
	for lang in ["en", "es"]:
		var po := FileAccess.get_file_as_string("res://translations/content.%s.po" % lang)
		var missing: Array = tool._ids.keys().filter(func(id: String): return not ("msgid %s\n" % tool._quote(id)) in po)
		ok(missing.is_empty(), "%d fala(s) fora de content.%s.po (rode tools/update_translations.gd), como: %s" % [missing.size(), lang,
			missing.slice(0, 3)])
	tool.free()


func _initialize() -> void:
	GameData.sectors = [1, 2, 3]   # o conteúdo inteiro (a noite só mostra parte dele)
	var C: GameContent = GameData.CONTENT
	var nums := GameData.board_numbers()
	for t in C.transfers:
		ok(int(t.target) in nums and (t.alt_target == "" or int(t.alt_target) in nums), "destino existe: " + t.resource_path)
		ok(t.alt_target == "" or GameData.entry(t.target).category != "" and GameData.entry(t.alt_target).category == GameData.entry(t.target).category,
			"alternativa do mesmo ramo: " + t.resource_path)
	# B1: quem liga tem nome e sobrenome, sem apelido nem tratamento; toda descrição dos moldes tem nome
	var treat := RegEx.create_from_string("^(Seu|Dona|Sr\\.|Sra\\.|Dr\\.|Dra\\.|Doutor|Doutora|Padre) ")
	var named := func(n: String): return n.split(" ").size() >= 2 and treat.search(n) == null
	var calls: Array = C.transfers.duplicate()
	for n: Night in C.nights:
		calls.append_array(((n.story as Array) + _night_calls(n)).map(func(st: StoryCall): return st.call).filter(func(x): return x is TransferCall))
	for t: TransferCall in calls:
		ok(named.call(t.caller_name), "quem liga sem nome e sobrenome, ou com tratamento: " + t.resource_path)
	for n in C.caller_names:
		ok(named.call(n.get_slice(":", 1)), "nome de molde sem sobrenome, ou com tratamento: " + n)
	for w in C.callers:
		ok(GameData.caller_name(w.get_slice(":", 1)) != "", "descrição de molde sem nome em caller_names: " + w)
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
	for i in C.nights.size():
		var n := C.nights[i]
		ok(n.story.all(func(st: StoryCall): return st.call is TransferCall or st.call is EmergencyCall or st.call is PrankCall),
			"ligações do roteiro com roteiro escrito: " + n.resource_path)
		# as escritas que entram no sorteio: transferências para um número do setor atendido, fora dos do roteiro da noite
		var story_targets := n.story.map(func(st: StoryCall): return st.call.target if st.call is TransferCall else "")
		for st: StoryCall in _night_calls(n):
			ok(st.call is TransferCall and int(st.call.target.left(1)) in GameData.sectors_for(i + 1) and not st.call.target in story_targets,
				"ligação da noite no setor e sem disputar número com o roteiro: %s (%s)" % [n.resource_path, st.call.resource_path])
			var e: EmergencyCall = st.call.turns if st.call is TransferCall else null
			if e != null:   # a que vira emergência: no setor atendido, perguntas com resposta e a despedida que dispensa a transferência
				ok(GameData.street(e.street).block_sector(e.block) in GameData.sectors_for(i + 1) and not e.units.is_empty()
					and e.questions.size() == e.answers.size() and e.after != "", "emergência da ligação que vira: " + e.resource_path)
		# as fotos do jornal, da noite e das manchetes que trocam a dela, existem
		ok(([n.news_photo] + n.news_if.map(func(v: Resource): return v.photo)).all(func(ph: String): return ph == "" or ph in NewsView.PHOTOS),
			"foto do jornal conhecida: " + n.resource_path)
	var f := StoryFlags.new()   # a foto segue a manchete: a da noite, ou a da variante que vira manchete
	ok(C.nights[5].photo_for(f)[0] == "rua", "noite 6 sem denúncia: a foto da rua")
	f.apply("denunciou_bar_4")
	ok(C.nights[5].photo_for(f)[0] == "viatura" and C.nights[5].photo_for(f)[1] != C.nights[5].news_caption, "noite 6 com a denúncia: a viatura, com a legenda dela")
	# conversa fiada: cada assunto traz as próprias respostas (uma simpática e uma seca), cada uma com a continuação
	var topics: Array[ChatTopic] = C.smalltalk.duplicate()
	for n in C.nights:
		topics.append_array(n.smalltalk)
	for t in topics:
		ok(t.line != "" and t.replies.all(func(r: ChatReply): return r.text != "" and r.follow != "")
			and t.replies.any(func(r): return r.tone == ChatReply.Tone.WARM) and t.replies.any(func(r): return r.tone == ChatReply.Tone.CURT),
			"assunto com resposta simpática e seca: " + t.line)
	# o discador (`Dialing`): todo número da cidade atende quem liga da central (as centrais, 001 e 002, à parte), cada
	# atendimento com a fala e as perguntas com resposta; as ligações do roteiro num número da cidade, com o roteiro
	for e in C.directory:
		if not e.number.begins_with("0") and not e.dispatch_only:
			ok(not e.answers.is_empty(), "o discador: %s atende quem liga da central" % e.name)
		for t in e.answers:
			ok(t.line != "" and not t.replies.is_empty() and t.replies.all(func(r: ChatReply): return r.text != "" and r.follow != ""),
				"atendimento com fala e perguntas com resposta: %s" % e.name)
			for r in t.replies:   # as palavras-chave das respostas (vão para as anotações da lista): de tipo conhecido e bem marcadas
				ok(_holes(r.follow).all(func(h: String): return not h.begins_with("[") or h.trim_prefix("[").trim_suffix(":") in Clue.KINDS)
					and not "[" in Clue.parse(r.follow)[0] and not "]" in Clue.parse(r.follow)[0], "palavra-chave mal marcada na resposta: " + r.follow)
	ok(not C.dial_byes.is_empty(), "as despedidas gerais de quem atende o discador")
	var dials: Array = C.dial.duplicate()
	for n in C.nights:
		dials.append_array(n.dial)
	for dc in dials:
		ok(dc.number.length() == 3 and dc.number.is_valid_int() and not GameData.is_trunk(dc.number) and not dc.steps.is_empty(),
			"ligação do roteiro pelo discador num número da cidade, com roteiro: " + dc.resource_path)
	# emergências escritas: o endereço bate com a rua e o trecho do mapa (o trecho sai do número)
	for e: EmergencyCall in C.emergencies:
		var st := GameData.street(e.street)
		ok(st != null and e.address.get_slice(",", 0) == st.name and int(e.address.get_slice(",", 1)) / 100 == e.block,
			"emergência no trecho certo: " + e.address)
	ok([1, 2].all(func(sec): return C.emergencies.any(func(e): return GameData.street(e.street).block_sector(e.block) == sec)), "Centro e Alto da Serra têm emergências escritas")
	# endereços: cada número fica numa rua do bairro dele (o Centro também tem a Praça da Matriz)
	for e in C.directory:
		var st: String = e.address.get_slice(",", 0)
		var sec := 1 if e.dispatch_only else int(e.number.left(1))
		var here := C.streets.filter(func(s: Street): return s.name == st)
		var block := int(e.address.get_slice(",", 1)) / 100
		ok((not here.is_empty() and block < here[0].blocks() and here[0].block_sector(block) == sec) or (sec == 1 and st == "Praça da Matriz"),
			"endereço no bairro do número: %s (%s)" % [e.name, e.address])
	# lugares do mapa: todos com a forma de quem liga ("do posto"); os que encostam em dois trechos de cada rua vizinha
	# não entram nas falas (não daria para saber qual trecho clicar)
	var spots: Array = MapGrid.landmark_spots()
	for sheet in MapGrid.LM:
		for key in MapGrid.LM[sheet]:
			ok(T.Key.has(T.Key.find_key(MapGrid.LM[sheet][key]) + "_OF"), "lugar do mapa sem a fala: " + T.Key.find_key(MapGrid.LM[sheet][key]))
	ok(spots.size() > 30, "lugares do mapa ao lado de um trecho: %d" % spots.size())
	var landmarks := 0
	# moldes: nenhuma lacuna sobra sem preencher
	var holes := func(texts: Array) -> bool: return texts.any(func(x): return "{" in x or "}" in x)
	for i in 300:
		var t := GameData.template_transfer()
		ok(int(t.target) in nums, "molde: destino existe")
		ok(t.alt_target == "" or GameData.entry(t.alt_target).category == GameData.entry(t.target).category and not "%" in t.alt_ask,
			"molde: alternativa do mesmo ramo")
		ok(GameData.entry(t.target).category == "" or t.alt_target != "", "molde: estabelecimento com ramo tem alternativa")
		ok(not holes.call(Array(t.opening) + [t.repeat, t.thanks]) and t.caller != "", "molde de transferência preenchido: " + " / ".join(t.opening))
		ok(GameData.entry(t.target).motives.any(func(mo: Motive): return (t.overheard in mo.talks or mo.talks.is_empty() and t.overheard.is_empty()) and tr(mo.text) in "".join(t.opening + PackedStringArray([t.repeat]))),
			"molde: a conversa escutada é a do motivo pedido")
		var tt := GameData.trunk_transfer()
		ok(GameData.is_trunk(tt.target) and tt.far_number != "" and not holes.call(Array(tt.opening) + [tt.repeat]),
			"molde de interurbano preenchido: " + " / ".join(tt.opening))
		var e := GameData.template_emergency()
		var house := int(e.address.get_slice(", ", 1))
		if house > 0:
			ok(GameData.street(e.street) != null and e.block == floori(house / 100.0), "molde: trecho bate com o número " + e.address)
		else:   # pela rua e um lugar do mapa: o trecho é o que fica ao lado do lugar
			landmarks += 1
			ok(spots.any(func(sp): return sp["street"].id == e.street and sp["block"] == e.block)
				and e.address.begins_with(GameData.street(e.street).name), "molde: lugar do mapa ao lado do trecho " + e.address)
		ok(not holes.call(Array(e.answers) + [e.opening, e.after]), "molde de emergência preenchido: " + e.opening)
	ok(landmarks > 60 and landmarks < 180, "às vezes quem liga diz um lugar do mapa: %d de 300" % landmarks)
	_check_translations()
	_check_talks()
	var places := C.directory.filter(func(d): return not d.motives.is_empty())
	for d: DirectoryEntry in places:
		ok(d.motives.all(func(mo: Motive): return mo.talks.size() >= 2 and mo.talks.all(func(k: PackedStringArray): return k.size() >= 4)), "duas conversas escutadas de cada motivo: " + d.name)
	for t: TransferCall in C.transfers:
		ok(t.overheard.size() >= 4, "conversa escutada da ligação escrita: " + t.caller + " -> " + t.destination)
	print("conteúdo (%d transferências, %d emergências, %d trotes; moldes: %d de transferência para %d contatos, %d de emergência)" % [
		C.transfers.size(), C.emergencies.size(), C.pranks.size(), C.transfer_templates.size(), places.size(), C.emergency_templates.size()])
	_check_destinations()
	_check_flags()
	_check_po()
	_check_street()
	finish("conteúdo")


## A cena da rua (`Beating`): na hora em que ainda passa gente para assistir, e no fim os dois fora do vidro e todo o
## sangue no chão.
func _check_street() -> void:
	var beating: GDScript = load("res://scripts/ui/beating.gd")
	for n: Night in GameData.CONTENT.nights:
		for e in n.street_events:
			ok(e.at >= 0.0 and e.at < n.shift_end and e.every >= 0.0, "cena da rua dentro do turno")
			if e.kind in ["beating", "speaker", "chase", "flyers", "newsstand", "parade", "moving"]:   # (as que têm gente na calçada reagindo)
				ok(e.at + Main.SHIFT_START_HOUR * 60 < Background.WALK_UNTIL - 30.0, "cena da rua com gente na calçada")
			if e.kind == "newsstand":   # (com a banca ainda aberta)
				ok(e.at + Main.SHIFT_START_HOUR * 60 < Background.NEWSSTAND_SHUT.x - 10.0, "a banca fechada antes da hora dela")
	var marks := {}   # a tinta por cima numa noite depois da pichação
	for i in GameData.CONTENT.nights.size():
		for e in GameData.CONTENT.nights[i].street_events:
			marks[e.kind] = i
	ok(not marks.has("paint") or marks.get("graffiti", INF) < marks["paint"], "a tinta por cima depois da pichação")
	var stand: GDScript = load("res://scripts/ui/newsstand.gd")
	var shut: Vector3 = stand.state(1e5)
	ok(shut == Vector3(1, 0, 1) and stand.state(0.0).y == 1.0, "a banca esvaziada, fechada e lacrada no fim")
	ok(stand.figures(stand.wait() + stand.ARRIVE - 0.1).size() == 1, "os dois homens no carro antes de ele sair")
	var stone: GDScript = load("res://scripts/ui/stone.gd")
	ok(not stone.cracked(stone.FLY - 0.01) and stone.cracked(stone.FLY) and stone.at(stone.FLY / 2.0).z > stone.at(0.0).z,
		"a pedra cresce voando e só trinca o vidro ao chegar")
	ok(stone.at(stone.END - 0.01).y > stone.HIT.y + 0.3 and stone.at(stone.END).z == 0.0, "a pedra quica e cai depois da batida")
	ok(stone.art().get_size() == Vector2(stone.ART), "o trincado desenhado")
	var tag: GDScript = load("res://scripts/ui/graffiti.gd")
	ok(tag.tag(tag.SPRAY_END).size() == tag._paint_order().size() and tag.tag(tag.SPRAY_AT - 0.01).is_empty(), "a pichação no tempo do spray")
	ok(tag.tagger(1e5).is_empty() and tag.painter(1e5).is_empty(), "o pichador e o pintor saem da vista")
	var kiosk: GDScript = load("res://scripts/ui/newsstand.gd")
	kiosk.state(0.0)
	ok(kiosk._puts.size() == 4 and kiosk._puts.all(func(p: float) -> bool: return kiosk.lid(p) == 1.0) and kiosk.lid(kiosk._in.min()) == 0.0,
		"o porta-malas aberto a cada pilha e fechado antes de os homens entrarem")
	var moving: GDScript = load("res://scripts/ui/moving.gd")
	moving.figures(0.0)
	var last: float = moving._in.values().max()
	ok(moving.figures(last).is_empty() and last < moving.ARRIVE + moving.wait(), "a família entra na Kombi antes de ela sair")
	ok(moving.FAMILY_AT > moving.DARK_AT, "a luz do apartamento apaga antes de a família descer")
	ok(moving.laundry(moving.DARK_AT) == 0 and moving.balcony(moving.DARK_AT).x < -1.5, "a roupa recolhida antes de a luz apagar")
	var raid: GDScript = load("res://scripts/ui/raid.gd")
	raid.figures(0.0)
	var last_in: float = range(raid.PRISONERS.size()).map(func(i: int) -> float: return raid._in["p%d" % i]).max()
	ok(last_in < raid._rear.z and raid.rear(last_in).x == 1.0 and raid.rear(last_in).y == 1.0 and raid.rear(raid.end()) == Vector2.ZERO,
		"os presos sobem com as portas do cofre abertas, e elas fecham depois do último")
	ok(raid.figures(raid.ARRIVE + raid.wait(0) - 0.05).all(func(f: Dictionary) -> bool: return f["cop"]) and raid.figures(raid.end()).is_empty(),
		"todos nos carros antes de eles saírem")
	ok(raid.floors(1e5) == raid.FLOORS.size() and raid.floors(raid.FLOORS[0] - 0.1) == 0, "os andares do hotel acendem na batida e ficam")
	var flare: GDScript = load("res://scripts/ui/flare.gd")
	ok(flare.at(flare.RISE).z == flare.APEX and flare.light(flare.RISE - 0.1) == 0.0 and flare.light(flare.RISE + 1.0) > 0.0, "o sinalizador acende no alto")
	ok(flare.light(flare.RISE + flare.BURN) == 0.0 and flare.at(flare.RISE + flare.BURN).z > 0.0, "o sinalizador apaga ainda no ar")
	ok(flare.smoke(flare.END + 0.1).is_empty(), "a fumaça do sinalizador some")
	ok(flare.light(flare.RISE + 0.12) > 1.5 and flare.light(flare.RISE + 5.0) < 1.01, "o sinalizador estoura ao acender e assenta")
	ok(range(60).all(func(i: int) -> bool: var t: float = flare.RISE + i * 0.8; return flare.glow(t) <= flare.light(t) and flare.glow(t) == flare.glow(t)), "a cintilação só apaga, e é a mesma a cada vez")
	var flyers: GDScript = load("res://scripts/ui/flyers.gd")
	ok(flyers.ground(1e5).all(func(f: Vector3) -> bool: return f.y < flyers.SIDEWALK.x or absf(f.x) >= flyers.VIEW), "os varredores limpam a calçada à vista")
	ok(flyers.figures(1e5).is_empty(), "os varredores saem da vista")
	var chase: GDScript = load("res://scripts/ui/chase.gd")
	var door: float = chase._young_keys()[-1][0]
	ok(chase.MEN_START.all(func(t0: float) -> bool: return t0 > door), "os homens da corrida chegam depois de o rapaz entrar")
	ok(chase.figures(chase.END - 0.01).all(func(f: Dictionary) -> bool: return f["x"] < -12.0), "os homens da corrida saem pela esquerda")
	var end: float = beating.END
	ok(beating.officer(end)["x"] > 11.0 and beating.victim(end)["x"] > 10.0, "o policial e o homem saem da vista")
	ok(beating.drops(end).all(func(d: Array) -> bool: return d[1] == 0.0), "o sangue todo no chão no fim")
