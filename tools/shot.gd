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
##   --busy                 todos os cabos de conexão em uso e uma transferência esperando: o [Todas as linhas ocupadas]
##   --badges=all           os broches na almofada da prateleira (all ou ids com vírgulas, `Badges.ALL`); --badgehover=id:
##                          o mouse num deles (a etiqueta); --badgenote=id: o papel da descrição aberto
##   --news                 o jornal da manhã na mesa · --read: já lido, dobrado de outro jeito
##   --listen               a linha 3 conectada, com o FONE nela e a chave de escuta levantada
##   --tapes                a B4 ligada: o gravador e o compartimento de fitas na coluna do lado do painel, com uma fita no
##                          gravador (--tapes=empty: sem, com a tampinha da fenda fechada; --tapes=rec: com --listen,
##                          gravando a conversa da linha 3, a REC presa e a lâmpada acesa; com --tapewrong, a conversa
##                          não é a pedida (a faixa riscada); com --tapefull, a fita cheia e a lâmpada no apagado do pisca;
##                          --tapefly=in|deliver|back,0.2: a fita voando, parada nesse instante do voo (a do meio subindo
##                          do compartimento e entrando, indo para a mesa ou, virgem, voltando ao compartimento);
##                          --tapehover=1|deck: o mouse na fita 1 do compartimento ou na do gravador; --delivered=3: tantas tiradas, empilhadas na mesa ao lado do
##                          bloco de fichas; --pile: com elas, a pilha aberta de perto, com o Descartar)
##   --patch=312,4          um cabo de conexão da saída da linha 4 (o padrão) ao destino dado, conectado (o aro aceso)
##   --plugs=3:296,4:162    outras pontas encaixadas nas tomadas dadas, sem ligação (os fios passando pelos plugs)
##   --lines=2:ring,4:conn  as lâmpadas dessas linhas no estado dado (`Exchange.Line`, em minúsculas), sem ligação
##   --toll                 um interurbano contando no calculógrafo, dois bilhetes na mesa (um carimbado) e três na caixinha
##   --clues                palavras-chave ouvidas (uma marcada, uma riscada, uma ouvida duas vezes) e a lista nas anotações
##   --screen=id            uma tela por cima: intro (a de início), pause, settings, report (o relatório com advertências;
##                          --rating=great|good|fair|poor o conceito, padrão poor, a segunda noite seguida;
##                          --warned, com intro, o bilhete depois de uma noite Insuficiente; --tapenote, com o resumo das
##                          fitas da noite anterior, da B4; --aside, o aviso do save que não deu para ler, `Progress.aside`)
##   --street=sol,1         com --tool=despacho: o mouse no trecho 1 da Rua do Sol (a rua inteira de leve e os números)
##   --draft                com --street: o primeiro clique nela (o local datilografado, à espera do segundo)
##   --mapzoom=1.44         com --tool=despacho: o mapa aproximado por esse fator (o anel girado)
##   --spot=Posto           com --tool=despacho: o mouse no lugar de referência com esse nome (a etiqueta dele)
##   --hover=id             o mouse em cima do objeto da mesa (os ids de `Tools`): ele erguido e a etiqueta com o nome
##   --zoom=x,y,w,h         o recorte, em px do jogo, ampliado `ZOOM` vezes
##   --car=fusca            um carro de cada modelo dado (vírgulas) parado na rua lá fora, um em cada mão (--car_t=0.45: onde, de 0 a 1; --rack: com o bagageiro)
##   --walk=2,-4            gente parada na calçada de lá, em cada x dado (m ao longo da rua; o 1º poste fica em 1,6)
##                          (--walk_dir=-1: indo para a esquerda; --stride: a mesma pessoa, cada uma num quadro da passada, na ordem;
##                          --outfit=short|long|dress|bag: a roupa dela)
##   --walk_z=20,45         e na calçada da direita da rua do cruzamento, em cada distância dada (m)
##   --bar                  a porta do bar aberta, com a luz saindo
##   --man=0.5              o homem do mistério chegando, nessa fração do caminho até o poste (1: parado embaixo dele)
##   --beating=12           a cena da rua da noite 3 (`Beating`) nesse instante (s desde o começo); --beating=8,0.1,30: de
##                          8 s em diante, de 0,1 em 0,1 s, 30 capturas (<nome>_00.png..., e os recortes do --zoom)
##   --behind=0.5           alguém passando atrás da última janela acesa do prédio de tijolos (de 0 a 1 do caminho)
##   --blind=1              a persiana descida (de 0, aberta, a 1, fechada)
##   --smoke[=s]            alguém fumando na varanda, `s` segundos depois de sair (10,5: no meio do sopro da tragada)
##   --cat                  o gato da noite (na marquise ou no gradil, pela noite)
##   --bike=-2              alguém de bicicleta parado nesse x (m; --papers: o menino do jornal) · --dog=3: um vira-lata nesse x
##   --taxi=4.5             o táxi que para no hotel, tantos segundos depois de aparecer (parado de 3,2 a 9,7; o passageiro de 3,7 a 7,3);
##                          com --police, a viatura da noite 7 (os policiais descem de 3,8 a 8,0, entram, saem de 73,2 a 77,7)
##   --damp=4               a mancha de umidade de 4 noites de chuva
##   --phones=2,1           os telefones da vista (hotel, bar): 1 tocando, 2 na linha
##   --sips=3               goles tomados do café · --cabinet: a porta do armário aberta
##   --keys                 as teclas do painel do operador todas ativas (a cor acesa delas), sem ligação
##   --written=2            fichas registradas (o lugar do lápis no bloco)
##   --bolt                 um relâmpago caindo na hora da captura (o primeiro clarão)
##   --wait=5               segundos antes de capturar (a luminária esquenta em 4)
##   --dim=N                a luminária presa no nível N (0 a 1), como no meio de uma piscada
##   --lamp=0               sem a luz da luminária no shader do cenário (`SceneView.lamp_light`)
##   --grade=0              sem a gradação de cor do `GameView` (a captura passa por ela, como a janela do jogo)
##   --still                sem a poeira do feixe da luminária e com o relógio das animações parado (`PixelArt.ms`):
##                          duas capturas iguais saem idênticas (para comparar pixel a pixel, `tools/diff_shots.gd`)
##   --still=N              ...parado N-1 ms depois (a sirene da viatura em outro ponto do giro: `--still=226`)
## As do jogo também valem: --weather=rain|fog|clear, --night=N, --seed=N, --lang=en.

const ZOOM := 4

var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _args.has("still"):
		PixelArt.frozen_ms = 600000 + int(_args["still"]) - 1   # o relógio das animações parado (aos 10 min: as contas de "desde quando" ficam positivas)
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
		if _args.has("warned") or _args.has("tapenote") or _args.has("aside"):   # o lembrete de quem teve uma noite Insuficiente; o resumo das fitas (B4)
			var tapes := {"night": m.night_no - 1, "used": 3, "delivered": 1, "missed": ["Laura Pires (linha 4)"], "restocked": true}
			m._intro.setup(m.night_no, m.night, false, false, _args.has("warned"), tapes if _args.has("tapenote") else {},
				"user://progress.v2-1761600000.cfg" if _args.has("aside") else "")
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
	if _args.has("tapes"):
		m.bureaucracy.enable(true)
		m.bureaucracy.activate("b4_fitas")
		m.bureaucracy.rule("b4_fitas").night_started()
		if _args["tapes"] != "empty":
			m.bureaucracy.tapes.insert()
		if _args["tapes"] == "rec" and _args.has("listen"):   # uma conversa de verdade na linha 3, para a escuta (e a fita) pegar
			var c := PhoneCall.from_transfer(GameData.CONTENT.transfers[0])
			c.line = 3
			c.dest_num = int(c.target)
			m.eavesdrop.connected(c)
			m.exchange.set_key(3, true)   # (o `--listen` não levantou a chave: ainda não havia conversa)
			m.eavesdrop.tick(0.0)
			if not _args.has("tapewrong"):   # (--tapewrong: a conversa gravada não é a pedida, a faixa riscada)
				c.meta["b4"] = true
			m.bureaucracy.tapes.rec = true
			m.bureaucracy.tapes.bind(c)   # a fita gravando ela, com duas palavras-chave ouvidas
			m.bureaucracy.tapes.inside.words.append_array(["um", "dois"])
			if _args.has("tapefull"):   # a fita cheia, na fase apagada do pisca da lâmpada
				m.bureaucracy.tapes.inside.words.append_array(["três", "quatro"])
				PixelArt.frozen_ms = m.board._equipment["gravador"].BLINK_MS
		for i in int(_args.get("delivered", "0")):   # (a de cima com nome, hora e duas palavras-chave, para o `--pile`)
			var named := i == int(_args["delivered"]) - 1
			var c: PhoneCall = PhoneCall.from_transfer(GameData.CONTENT.transfers[0]) if named else null
			var t := Bureaucracy.Tapes.Tape.new()
			t.call = c
			t.hour = "21:40" if named else ""
			if named:
				t.words.append_array(["um", "dois"])
			t.fate = t.Fate.ON_DESK
			m.bureaucracy.tapes.done.append(t)
		if _args.has("tapefly"):   # o voo parado num instante (o gravador para de andar)
			var fly: PackedStringArray = _args["tapefly"].split(",")
			var rec: Control = m.board._equipment["gravador"]
			await get_tree().process_frame   # (a sala desenhada: o lugar da fita na mesa, `tape_spot`)
			var t := float(fly[1]) if fly.size() > 1 else 0.2
			var rack: Control = m.board._equipment["porta_fitas"]
			if fly[0] == "in":   # a do meio (a subida de dentro do compartimento é desenhada por ele)
				rec._had_tape = true
				m.bureaucracy.tapes.slots.assign([true, false, true])
				m.bureaucracy.tapes.inside.slot = 1
				rack._seen = m.bureaucracy.tapes.slots.duplicate()
				rack._move_slot = 1
				rack._move = maxf(rack.RISE_SEC - t, 0.0)
				rec._start_in(1)
			elif fly[0] == "back":   # como o clique na virgem
				m.bureaucracy.tapes.inside.call = null
				var back: int = m.bureaucracy.tapes.put_back()
				rack._seen = m.bureaucracy.tapes.slots.duplicate()
				rec._had_tape = false
				rec._start_back(back)
			else:   # como o clique na fita
				m.bureaucracy.tapes.eject()
				rec._had_tape = false
				rec._start_out()
			m.background.tapes_out = m.bureaucracy.tapes.on_desk().size() - (1 if fly[0] == "deliver" else 0)   # (a que voa, não)
			rec._step_fly(t)
			rec.set_process(false)
			rec.queue_redraw()
			rack.set_process(false)
			rack.queue_redraw()
		if _args.has("tapehover"):
			await get_tree().process_frame
			if _args["tapehover"] == "deck":
				m.board._equipment["gravador"]._hover = m.board._equipment["gravador"].Hover.TAPE
			else:
				m.board._equipment["porta_fitas"]._hover = int(_args["tapehover"])
		if _args.has("pile"):
			for i in 3:
				await get_tree().process_frame   # (a pilha desenhada: o lugar dela, `prop_rect`)
			m.get_node("TapePile").open()
	if _args.has("patch"):
		var pa := (_args["patch"] as String).split(",")
		m.board.plugged(1, 10 + (int(pa[1]) if pa.size() > 1 else 4))
		m.board.plugged(2, int(pa[0]))
		m.exchange.set_dest(int(pa[0]), Exchange.Dest.CONN)
	if _args.has("plugs"):
		for kv in (_args["plugs"] as String).split(","):
			m.board.plugged(int(kv.get_slice(":", 0)), int(kv.get_slice(":", 1)))
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
	if _args.has("badges"):
		var ids: Array = m.Badges.ALL.keys() if _args["badges"] == "all" else Array((_args["badges"] as String).split(","))
		var got := {}
		for i in ids.size():
			got[ids[i]] = i + 2
		m.badges.earned = got
		await get_tree().process_frame
		m.badges._hover = _args.get("badgehover", "")
		m.badges._open = _args.get("badgenote", "")
	if _args.has("busy"):
		for k in m.board.patches:
			m.board.plugged(1 + k * 2, [305, 312, 318, 327, 336][k])
		var t := PhoneCall.from_transfer(GameData.transfers(TransferCall.Group.ESTABLISHMENT)[2])
		m.ring(t)
		await get_tree().create_timer(0.5, false).timeout
		m.board.held = 0
		m.board.place(0, t.line)
		m.answer()
		while t.phase != PhoneCall.Phase.AWAIT or t.talking:
			await get_tree().process_frame
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
	if _args.has("street"):   # o mouse numa rua do mapa aberto (--street=id,trecho), ou num lugar (--spot=nome)
		var at: PackedStringArray = String(_args["street"]).split(",")
		var st := GameData.street(at[0])
		m.dispatch.city.hover = {"street": at[0], "block": int(at[1]), "label": "%s, %s" % [st.name, Street.block_label(int(at[1]))]}
		if _args.has("draft"):   # e o primeiro clique nela: o local datilografado à espera do segundo
			m.dispatch._pick(at[0], int(at[1]), m.dispatch.city.hover["label"])
		m.dispatch.city.queue_redraw()
	if _args.has("mapzoom"):   # o mapa aproximado pelo anel (o fator, 1.2 = um degrau)
		m.dispatch.city.zoom_by(float(_args["mapzoom"]))
	if _args.has("spot"):
		await get_tree().process_frame
		for pl in m.dispatch.city._places:
			if pl[1] == _args["spot"]:
				m.dispatch.city._spot = [(pl[0] as Rect2).get_center(), pl[1]]
		m.dispatch.city.queue_redraw()
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
	if _args.has("walk") or _args.has("walk_z") or _args.has("bar") or _args.has("smoke") or _args.has("bike") or _args.has("phones") or _args.has("dog") or _args.has("taxi") or _args.has("behind") or _args.has("man"):   # posto de novo a cada quadro, como o carro
		var bg := m.background
		bg._walk_in = INF
		for f in 60:
			if _args.has("walk") or _args.has("walk_z"):
				bg._walkers.clear()
				var walk_dir := float(_args.get("walk_dir", "1"))
				var xs := (_args.get("walk", "") as String).split(",", false)
				var same := bg._walker()   # (com --stride, todos com a mesma roupa: o ciclo de uma pessoa só)
				if _args.has("outfit"):
					same.merge({"dress": _args["outfit"] == "dress", "long": _args["outfit"] == "long", "bag": _args["outfit"] == "bag"}, true)
				for i in xs.size():
					var t := (float(xs[i]) * walk_dir + Background.WALK_SPAN) / (2.0 * Background.WALK_SPAN)
					var n := Background.STRIDE.size()   # com --stride, o i-ésimo no quadro i da passada
					bg._walkers.append((same.duplicate() if _args.has("stride") else bg._walker()).merged({"t": t, "dir": walk_dir, "sec": (posmod(i, 2 * n) + 0.5) / (n * Background.WALK_STEPS * t) if _args.has("stride") else 1e9,
						"z": Background.STREET["far_curb"] + 1.0}, true))
				for z in (_args.get("walk_z", "") as String).split(",", false):
					bg._walkers.append(bg._walker().merged({"t": 0.0, "dir": 1.0, "sec": 1e9, "z": Background.STREET["far_curb"] + 1.0,
						"corner": Background.WALK_RIGHT, "out": true, "turn": float(z)}, true))
			if _args.has("man"):   # o homem do mistério chegando, nessa fração do caminho até o poste
				bg.stranger = Vector2(bg.minutes + Background.MAN_WALK * (1.0 - float(_args["man"])), bg.minutes + 60.0)
			if _args.has("bike"):
				bg._walkers.append({"t": (float(_args["bike"]) + Background.WALK_SPAN) / (2.0 * Background.WALK_SPAN), "dir": 1.0, "sec": 1e9,
					"z": Background.STREET["far_curb"] - 0.6, "h": 1.0, "hat": false, "bike": true, "papers": _args.has("papers")})
			if _args.has("dog"):
				bg._walkers.append({"t": (float(_args["dog"]) + Background.WALK_SPAN) / (2.0 * Background.WALK_SPAN), "dir": 1.0, "sec": 1e9,
					"z": Background.STREET["far_curb"] + 1.0, "h": 1.0, "hat": false, "dog": true})
			if _args.has("taxi"):
				bg._car_in = [INF, INF]
				bg._cars.assign([{"t": 0.5, "lane": 0, "kind": "fusca", "tones": Pal.CAR_TONES[2], "taxi": true, "stop": true, "s": float(_args["taxi"])}])
				if _args.has("police"):
					bg._cars[0].merge(bg._patrol_car().merged({"kind": Background.PATROL_KIND}), true)
			if _args.has("bar"):
				bg._bar_t = 1.0
			if _args.has("behind") and not bg._flats.is_empty():   # na última janela acesa à vista (a mais alta)
				var lit := bg._flats.filter(func(f: Array) -> bool: return bg._win_lit(bg._houses[0], f[1]))
				if not lit.is_empty():
					bg._indoor = Vector3(Background.BEHIND_SEC * float(_args["behind"]), lit[-1][1], 1.0)
			if _args.has("smoke"):
				bg._smoke_t = 10.5 if _args["smoke"] == "1" else float(_args["smoke"])
			await get_tree().process_frame
	if _args.has("beating"):   # posto de novo a cada quadro (o cenário o avança sozinho)
		var bt := (_args["beating"] as String).split_floats(",")
		var bg := m.background
		bg._car_in = [INF, INF]
		bg._cars.clear()
		bg.beating = bg.minutes - 1.0
		var n := int(bt[2]) if bt.size() > 2 else 1
		for i in n:
			for f in 8:   # (a vista se desenha a 30 por segundo, e a captura sai um quadro depois)
				bg._beat_t = bt[0] + i * (bt[1] if n > 1 else 0.0)
				await get_tree().process_frame
			if n > 1:
				_grab(out, (_args.get("out", "build/shot.png") as String).get_basename() + "_%02d.png" % i)
		if n > 1:
			get_tree().quit()
			return
	if _args.has("keys"):   # o Main refaz as teclas a cada quadro: ativadas por último, antes do quadro da captura
		m.set_process(false)
		m.phone.set_buttons(true, true, true)
		m.phone.set_listen(true, false)
		await get_tree().process_frame
		await get_tree().process_frame
	_save(out)


func _save(vp: SubViewport) -> void:
	_grab(vp, _args.get("out", "build/shot.png"))
	get_tree().quit()


## Grava a tela em `out` e, com --zoom, o recorte ampliado.
func _grab(vp: SubViewport, out: String) -> void:
	var img := vp.get_texture().get_image()
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
