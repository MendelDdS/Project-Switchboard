extends Node
## Captura de tela do jogo numa situação escolhida, para conferir mudanças visuais (sem montar um script a cada vez).
## Roda COM tela (sem --headless: sem ela nada é desenhado) e grava a tela inteira e, com --zoom, um recorte ampliado:
##   Godot --path . tools/shot.tscn -- --hour=22:30 --weather=rain --tool=despacho --card --zoom=760,420,240,140
## Opções (depois do `--`):
##   --out=build/shot.png   onde gravar (o recorte vai em <nome>_zoom.png)
##   --width=960            a largura do `main.tscn` (540 de altura; o jogo, no `GameView`, é sempre 960)
##   --hour=20:00           a hora do turno no relógio e lá fora
##   --tool=id              abre a ferramenta (os ids de `Tools`: lista, despacho, caderno, registro, jornal, calculografo)
##   --debug=N              abre o painel de debug na aba N (0 = Jogo, 1 = Vozes)
##   --card                 marca um local no mapa e espera o cartão sair impresso (--card=closed: e guarda o despacho)
##   --punch                com --card: o cartão perfurado, uma unidade fora e a etiqueta de um trecho no mapa
##   --emergency            toca uma emergência e atende (a luz vermelha da unidade, a barra, o rádio)
##   --news                 o jornal da manhã na mesa · --read: já lido, dobrado de outro jeito
##   --listen               a linha 3 conectada, com o FONE nela e a chave de escuta levantada
##   --patch=312,4          um cabo de conexão da saída da linha 4 (o padrão) ao destino dado, conectado (o aro aceso)
##   --lines=2:ring,4:conn  as lâmpadas dessas linhas no estado dado (`Exchange.Line`, em minúsculas), sem ligação
##   --toll                 um interurbano contando no calculógrafo, dois bilhetes na mesa (um carimbado) e três na caixinha
##   --clues                palavras-chave ouvidas (uma marcada, uma riscada, uma ouvida duas vezes) e a lista nas anotações
##   --screen=id            uma tela por cima: intro (a de início), pause, settings, report (o relatório com advertências;
##                          --rating=great|good|fair|poor o conceito, padrão poor, a segunda noite seguida;
##                          --warned, com intro, o bilhete depois de uma noite Insuficiente)
##   --hover=id             o mouse em cima do objeto da mesa (os ids de `Tools`): ele erguido e a etiqueta com o nome
##   --zoom=x,y,w,h         o recorte, em px do jogo, ampliado `ZOOM` vezes
##   --car=fusca            um carro de cada modelo dado (vírgulas) parado na rua lá fora, um em cada mão (--car_t=0.45: onde, de 0 a 1; --rack: com o bagageiro)
##   --walk=2,-4            gente parada na calçada de lá, em cada x dado (m ao longo da rua; o 1º poste fica em 1,6)
##   --walk_z=20,45         e na calçada da direita da rua do cruzamento, em cada distância dada (m)
##   --bar                  a porta do bar aberta, com a luz saindo
##   --behind=0.5           alguém passando atrás da última janela acesa do prédio de tijolos (de 0 a 1 do caminho)
##   --blind=1              a persiana descida (de 0, aberta, a 1, fechada)
##   --smoke[=s]            alguém fumando na varanda, `s` segundos depois de sair (10,5: no meio do sopro da tragada)
##   --cat                  o gato da noite (na marquise ou no gradil, pela noite)
##   --bike=-2              alguém de bicicleta parado nesse x (m; --papers: o menino do jornal) · --dog=3: um vira-lata nesse x
##   --taxi=4.5             o táxi que para no hotel, tantos segundos depois de aparecer (parado de 3,2 a 9,7; o passageiro de 3,7 a 7,3)
##   --damp=4               a mancha de umidade de 4 noites de chuva
##   --phones=2,1           os telefones da vista (hotel, bar): 1 tocando, 2 na linha
##   --sips=3               goles tomados do café · --cabinet: a porta do armário aberta
##   --written=2            fichas registradas (o lugar do lápis no bloco)
##   --bolt                 um relâmpago caindo na hora da captura (o primeiro clarão)
##   --wait=5               segundos antes de capturar (a luminária esquenta em 4)
##   --dim=N                a luminária presa no nível N (0 a 1), como no meio de uma piscada
##   --lamp=0               sem a luz da luminária no shader do cenário (`SceneView.lamp_light`)
##   --grade=0              sem a gradação de cor do `GameView` (a captura passa por ela, como a janela do jogo)
##   --still                sem a poeira do feixe da luminária, que muda a cada captura (para comparar capturas pixel a
##                          pixel, `tools/diff_shots.gd`)
## As do jogo também valem: --weather=rain|fog|clear, --night=N, --seed=N, --lang=en.

const ZOOM := 4

var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var vp := SubViewport.new()   # o jogo nessa largura, como o `GameView` o põe na janela
	vp.size = Vector2i(int(_args.get("width", "960")), 540)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.snap_2d_transforms_to_pixel = true   # (como a `View` do `GameView`)
	vp.snap_2d_vertices_to_pixel = true
	var out := SubViewport.new()   # a tela que mostra o jogo com a gradação de cor, como o `Box` do `GameView`
	out.size = vp.size
	out.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(out)
	var box := SubViewportContainer.new()
	box.size = Vector2(vp.size)
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.material = GameView.grade_material()
	out.add_child(box)
	box.add_child(vp)
	GameView.set_grade(vp, _args.get("grade", "1") != "0")
	SceneView.lamp_light = _args.get("lamp", "1") != "0"
	var m: Main = load("res://scenes/main.tscn").instantiate()
	if not _args.has("night"):
		m.night_no = 1   # não lê nem grava o progresso salvo
	vp.add_child(m)
	m.background.lamp_hold = float(_args.get("dim", "-1"))
	await get_tree().process_frame
	m.sched.clear()   # nada toca sozinho
	if _args.get("screen") == "intro":
		if _args.has("warned"):   # o bilhete com o lembrete de quem teve uma noite Insuficiente
			m._intro.setup(m.night_no, m.night, false, false, true)
		await get_tree().create_timer(float(_args.get("wait", "5")), false).timeout
		_save(out)
		return
	m._intro.visible = false
	m._start_shift()
	var hm: PackedStringArray = _args.get("hour", "20:00").split(":")
	m.minutes = (posmod(int(hm[0]) - Main.SHIFT_START_HOUR, 24)) * 60.0 + (int(hm[1]) if hm.size() > 1 else 0)   # (05:30 é depois da meia-noite)
	if _args.has("news"):
		m.set_news([{"outcome": 0, "template": GameData.CONTENT.news_ok[0], "occurrence": "Outro", "address": "Rua do Sol, 10"}])
	if _args.has("toll"):
		m.toll.start(4, GameData.trunk_city(901), "23-118", m.minutes - 6.4)
		m.toll.stop(4, m.minutes)
		m.toll.start(7, GameData.trunk_city(903), "4-52", m.minutes - 3.2)
		m.toll.stop(7, m.minutes).stamp(TollTicket.FIELD.get_center())
		for i in 3:   # e três já na caixinha, dois carimbados
			m.toll.start(8, GameData.trunk_city(904), "9-%d" % i, m.minutes - 2.0)
			var t := m.toll.stop(8, m.minutes)
			if i != 1:
				t.stamp(TollTicket.FIELD.get_center())
			m.toll.file(t)
		m.exchange.set_line(2, Exchange.Line.CONN, m.minutes + 60.0)   # senão a linha livre já imprime o bilhete
		m.toll.start(2, GameData.trunk_city(902), "7-30", m.minutes - 2.0)
	if _args.has("listen"):
		m.exchange.set_line(3, Exchange.Line.CONN, m.minutes + 60.0)
		m.board.plugged(0, 3)
		m.listen()
	if _args.has("patch"):
		var pa := (_args["patch"] as String).split(",")
		m.board.plugged(1, 10 + (int(pa[1]) if pa.size() > 1 else 4))
		m.board.plugged(2, int(pa[0]))
		m.exchange.set_dest(int(pa[0]), Exchange.Dest.CONN)
	if _args.has("lines"):
		for l in (_args["lines"] as String).split(","):
			var kv := l.split(":")
			m.exchange.set_line(int(kv[0]), Exchange.Line[kv[1].to_upper()], m.minutes + 60.0)
	if _args.has("emergency"):
		m.ring(PhoneCall.from_emergency(GameData.template_emergency()))
		await get_tree().create_timer(0.5, false).timeout
		m.board.held = 0   # o FONE na linha dela
		m.board.place(0, m.live[0].line)
		m.answer()
	if _args.has("clues"):
		for w in [["Benedito Souza", "person", 271], ["Rua do Moinho", "street", 305], ["oito", "time", 305], ["Benedito Souza", "person", 312]]:
			m.eavesdrop.clues.append(Clue.from_dict({"word": w[0], "kind": w[1], "night": 2, "minutes": 190.0, "number": str(w[2])}))
		m.eavesdrop.clues[1].chosen = true
		m.eavesdrop.clues[2].struck = true
		m.tools.set_tab(Tools.DIRECTORY)
		m.tools.book.turn(99)
	if _args.has("tool"):
		m.tools.set_tab(_args["tool"])
	if _args.has("still"):
		m.background.dust.visible = false
	if _args.has("hover"):
		m.background._hot = _args["hover"]
		m.get_node("Scene").queue_redraw()
	if _args.has("debug"):   # o painel de debug aberto, na aba N (0 = Jogo, 1 = Vozes)
		m.get_node("%Debug").visible = true
		(m.get_node("%Debug").find_child("Tabs") as TabContainer).current_tab = int(_args["debug"])
	if _args.has("card"):
		m.tools.set_tab(Tools.DISPATCH)
		await get_tree().create_timer(0.5, false).timeout
		m.dispatch.set_location("sol", 0, "Rua do Sol, 1–99")
		while m.dispatch.machines.state != CardMachines.State.READY:
			await get_tree().process_frame
		if _args.has("punch"):   # o cartão perfurado (o tipo e a ambulância), os bombeiros fora e a etiqueta do mapa
			m.dispatch.fleet.units["bomb"] = Fleet.Unit.EN_ROUTE
			m.dispatch.set_occurrence(GameData.CONTENT.occurrences[0])
			m.dispatch.punch_unit("amb")
			m.dispatch.city.hover = {"street": "sol", "block": 1, "label": "Rua do Sol, 100–199"}
			m.dispatch.city.queue_redraw()
		if _args["card"] == "closed":   # o cartão na mesa e o despacho guardado: a unidade da mesa com o cartão saindo
			m.tools.close()
	match _args.get("screen", ""):
		"pause":
			m.pause()
		"settings":
			m.pause()
			m._pause.open_settings()
		"report":   # --rating=great|good|fair|poor: as advertências que dão esse conceito (padrão: poor, a segunda noite)
			var faults := {"great": ["wrong_info"], "good": ["missed", "wrong_info"], "fair": ["missed", "hold", "wrong_number"],
				"poor": ["missed", "hold", "wrong_number", "eavesdrop", "wrong_info"]}
			var rating: String = _args.get("rating", "poor")
			for f in faults[rating]:
				m.report.add(f, "21:%02d" % (f.length() * 3))
			for c in ["transfer", "transfer", "transfer", "transfer", "transfer", "transfer", "info", "info", "info", "emergency_ok", "occurrence"]:
				m.report.credit(c, "20:00")
			m.report.low_before = 1 if rating == "poor" else 0
			m._ending.play(m.report, true)
			await get_tree().create_timer(4.0, false).timeout
	await get_tree().create_timer(float(_args.get("wait", "5")), true).timeout   # (conta também na pausa)
	if _args.has("car"):   # (depois da espera: em `CAR_SEC` ele já teria passado)
		var kinds: PackedStringArray = _args["car"].split(",")
		m.background._car_in = [INF, INF]
		for f in 12:   # posto de novo a cada quadro: um quadro demorado o levava para fora da vista
			m.background._cars.clear()
			for lane in 2:
				if not Background.CAR_KINDS.has(kinds[lane % kinds.size()]):   # (--car=picape,- : só o de lá)
					continue
				m.background._cars.append({"t": float(_args.get("car_t", "0.45")), "lane": lane, "kind": kinds[lane % kinds.size()],
					"tones": Pal.CAR_TONES[lane + 1], "taxi": false, "rack": _args.has("rack")})
			await get_tree().process_frame
	if _args.has("blind"):
		m.background._shut = float(_args["blind"])
		m.background._shut_to = m.background._shut
		m.background._blind_shape()
		for f in 4:   # (o brilho das luzes vem um quadro depois da camada de cima)
			await get_tree().process_frame
	var room := m.background
	if _args.has("damp"):
		room.damp = int(_args["damp"])
	if _args.has("sips"):
		room.sips = int(_args["sips"])
	if _args.has("written"):
		room.written = int(_args["written"])
	room.news_read = _args.has("read")
	if _args.has("cabinet"):
		room.cab_open = true
	if _args.has("cat"):
		room.cat_here = true
	if _args.has("phones"):
		var st: PackedStringArray = _args["phones"].split(",")
		for i in st.size():
			m.exchange.set_dest(Background.CALLED[i], int(st[i]))
	for f in 12:   # (a sala se redesenha no quadro seguinte; a camada da poeira, a 30 por segundo)
		await get_tree().process_frame
	if _args.has("bolt"):   # um relâmpago caindo agora (no primeiro clarão)
		room._bolt = 0.0
		room._thunder_at = INF
		for f in 2:
			await get_tree().process_frame
	if _args.has("walk") or _args.has("walk_z") or _args.has("bar") or _args.has("smoke") or _args.has("bike") or _args.has("phones") or _args.has("dog") or _args.has("taxi") or _args.has("behind"):   # posto de novo a cada quadro, como o carro
		var bg := m.background
		bg._walk_in = INF
		for f in 60:
			if _args.has("walk") or _args.has("walk_z"):
				bg._walkers.clear()
				for x in (_args.get("walk", "") as String).split(",", false):
					bg._walkers.append(bg._walker().merged({"t": (float(x) + Background.WALK_SPAN) / (2.0 * Background.WALK_SPAN), "dir": 1.0, "sec": 1e9,
						"z": Background.STREET["far_curb"] + 1.0}, true))
				for z in (_args.get("walk_z", "") as String).split(",", false):
					bg._walkers.append(bg._walker().merged({"t": 0.0, "dir": 1.0, "sec": 1e9, "z": Background.STREET["far_curb"] + 1.0,
						"corner": Background.WALK_RIGHT, "out": true, "turn": float(z)}, true))
			if _args.has("bike"):
				bg._walkers.append({"t": (float(_args["bike"]) + Background.WALK_SPAN) / (2.0 * Background.WALK_SPAN), "dir": 1.0, "sec": 1e9,
					"z": Background.STREET["far_curb"] - 0.6, "h": 1.0, "hat": false, "bike": true, "papers": _args.has("papers")})
			if _args.has("dog"):
				bg._walkers.append({"t": (float(_args["dog"]) + Background.WALK_SPAN) / (2.0 * Background.WALK_SPAN), "dir": 1.0, "sec": 1e9,
					"z": Background.STREET["far_curb"] + 1.0, "h": 1.0, "hat": false, "dog": true})
			if _args.has("taxi"):
				bg._car_in = [INF, INF]
				bg._cars.assign([{"t": 0.5, "lane": 0, "kind": "fusca", "tones": Pal.CAR_TONES[2], "taxi": true, "stop": true, "s": float(_args["taxi"])}])
			if _args.has("bar"):
				bg._bar_t = 1.0
			if _args.has("behind") and not bg._flats.is_empty():   # na última janela acesa à vista (a mais alta)
				var lit := bg._flats.filter(func(f: Array) -> bool: return bg._win_lit(bg._houses[0], f[1]))
				if not lit.is_empty():
					bg._indoor = Vector3(Background.BEHIND_SEC * float(_args["behind"]), lit[-1][1], 1.0)
			if _args.has("smoke"):
				bg._smoke_t = 10.5 if _args["smoke"] == "1" else float(_args["smoke"])
			await get_tree().process_frame
	_save(out)


func _save(vp: SubViewport) -> void:
	var img := vp.get_texture().get_image()
	var out: String = _args.get("out", "build/shot.png")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + out.get_base_dir()))
	img.save_png("res://" + out)
	print("gravado: ", out)
	if _args.has("zoom"):
		var z: PackedStringArray = _args["zoom"].split(",")
		var r := Rect2i(int(z[0]), int(z[1]), int(z[2]), int(z[3])).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var crop := img.get_region(r)
		crop.resize(r.size.x * ZOOM, r.size.y * ZOOM, Image.INTERPOLATE_NEAREST)
		var zout := out.get_basename() + "_zoom.png"
		crop.save_png("res://" + zout)
		print("gravado: ", zout)
	get_tree().quit()
