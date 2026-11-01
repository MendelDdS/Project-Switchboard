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

	# os caminhos do roteiro até a noite 11 (a carta) e a 15 (o golpe)
	var full := [R.HOTEL, R.HOSPITAL, R.IGNORED, R.PARISH]   # colaborou em tudo
	ok(R.level(_f(full), 11) == R.Level.HIGH, "colaborou: chances altas no Dia 11 (a carta amiga)")
	ok(R.level(_f(full + [R.TAPE_SEBASTIAO]), 15) == R.Level.HIGH and R.won(_f(full + [R.TAPE_SEBASTIAO]), 15), "colaborou: vence")
	var obeyed := full + [R.TAPE_SEBASTIAO, R.OBEYED + "a", R.OBEYED + "b"]
	ok(R.won(_f(obeyed), 15), "chances altas: dois vacilos não derrubam")
	ok(not R.won(_f(obeyed + [R.OBEYED + "c", R.OBEYED + "d"]), 15), "chances altas: vacilos grandes derrubam")
	var bitter := [R.HOTEL, R.TAPE_GUNS, R.HOSPITAL, R.IGNORED, R.PARISH]   # vitória amarga: entregou a das armas
	ok(R.level(_f(bitter), 11) == R.Level.MEDIUM, "fita das armas: cai pela metade, chances médias")
	ok(R.won(_f(bitter + [R.TAPE_SEBASTIAO]), 15) and R.level(_f(bitter + [R.TAPE_SEBASTIAO]), 14) != R.Level.HIGH, "vitória amarga: vence, mas a pedra vem")
	var late := [R.HOSPITAL, R.IGNORED, R.PARISH]   # não colaborou até o Dia 8, depois sim: só a rádio
	ok(R.level(_f(late), 11) == R.Level.MEDIUM, "voltou no Dia 8: chances médias, sem margem")
	ok(not R.won(_f(late + [R.OBEYED + "a"]), 15), "voltou no Dia 8: o primeiro vacilo derruba")
	ok(R.won(_f(late + [R.TAPE_SEBASTIAO, R.OBEYED + "a"]), 15), "voltou no Dia 8 e deu a fita a Sebastião: aguenta um vacilo")
	ok(R.level(_f([]), 11) == R.Level.LOW and not R.won(_f([]), 15), "não ajudou ninguém (esquecida): baixas, falha")
	ok(not R.won(_f([R.DENOUNCED, R.HOTEL, R.HOSPITAL, R.IGNORED, R.PARISH, R.TAPE_SEBASTIAO]), 15), "denunciou: despenca e falha")
	ok(R.level(_f(full + [R.TAPE_CHIEF]), 11) == R.Level.MEDIUM, "fita do comandante: cai pela metade")
	ok(R.level(_f(full + [R.WARNED_HOTEL]), 11) == R.Level.MEDIUM, "hotel avisado: cai um pouco (de 4 a 3)")
	ok(R.points(_f(full), 12) == R.points(_f(full), 13) + 1, "a fita de Sebastião que não veio só conta depois da noite 12")
	ok(R.points(_f([]), 8) == 0 and R.points(_f([]), 9) == -2, "o hospital esquecido só conta depois da noite 8")

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

	# as cenas da rua do roteiro com condição
	var C: GameContent = GameData.CONTENT
	var stone: Array = C.nights[13].street_events.filter(func(e): return e.kind == "stone")
	var raid: Array = C.nights[12].street_events.filter(func(e): return e.kind == "raid")
	ok(stone.size() == 1 and stone[0].requires == PackedStringArray(["!chance_alta"]), "a pedra (14) só sem chances altas")
	ok(raid.size() == 1 and raid[0].requires == PackedStringArray([R.HOTEL_TAPED]), "a batida (13) só com uma fita do hotel na polícia")
	finish("fator sucesso")
