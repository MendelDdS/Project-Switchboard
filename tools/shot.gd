extends Node
## Captura de tela do jogo numa situação escolhida, para conferir mudanças visuais (sem montar um script a cada vez).
## Roda COM tela (sem --headless: sem ela nada é desenhado) e grava a tela inteira e, com --zoom, um recorte ampliado:
##   Godot --path . tools/shot.tscn -- --hour=22:30 --weather=rain --tool=despacho --card --zoom=760,420,240,140
## Opções (depois do `--`):
##   --out=build/shot.png   onde gravar (o recorte vai em <nome>_zoom.png)
##   --width=1280           a largura do `main.tscn` (720 de altura; o jogo, no `GameView`, é sempre 1280)
##   --hour=20:00           a hora do turno no relógio e lá fora
##   --tool=id              abre a ferramenta (os ids de `Tools`: lista, despacho, caderno, registro, jornal, calculografo)
##   --debug=N              abre o painel de debug na aba N (0 = Jogo, 1 = Vozes)
##   --card                 marca um local no mapa e espera o cartão sair impresso
##   --emergency            toca uma emergência e atende (a luz vermelha da unidade, a barra, o rádio)
##   --news                 o jornal da manhã na mesa
##   --listen               a linha 3 conectada, com o FONE nela e a chave de escuta levantada
##   --toll                 um interurbano contando no calculógrafo, dois bilhetes na mesa (um carimbado) e três na caixinha
##   --clues                palavras-chave ouvidas (uma marcada, uma riscada, uma ouvida duas vezes) e a lista nas anotações
##   --hover=id             o mouse em cima do objeto da mesa (os ids de `Tools`): o contorno e o nome
##   --zoom=x,y,w,h         o recorte, em px do jogo, ampliado `ZOOM` vezes
##   --scale=1.5            grava também a tela como o `GameView` a mostra nessa ampliação (o filtro `SHARP`;
##                          1.5 = 1080p, 2 = 1440p, 1.25 = 1600×900), em <nome>_x1.5.png
##   --wait=5               segundos antes de capturar (a luminária esquenta em 4)
## As do jogo também valem: --weather=rain|fog|clear, --night=N, --seed=N, --lang=en.

const ZOOM := 4

var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var vp := SubViewport.new()   # o jogo nessa largura, como o `GameView` o põe na janela
	vp.size = Vector2i(int(_args.get("width", "1280")), 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var m: Main = load("res://scenes/main.tscn").instantiate()
	if not _args.has("night"):
		m.night_no = 1   # não lê nem grava o progresso salvo
	vp.add_child(m)
	await get_tree().process_frame
	m.sched.clear()   # nada toca sozinho
	m._intro.visible = false
	m._start_shift()
	var hm: PackedStringArray = _args.get("hour", "20:00").split(":")
	m.minutes = (int(hm[0]) - Main.SHIFT_START_HOUR) * 60.0 + (int(hm[1]) if hm.size() > 1 else 0)
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
	await get_tree().create_timer(float(_args.get("wait", "5")), false).timeout
	var img := vp.get_texture().get_image()
	var out: String = _args.get("out", "build/shot.png")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + out.get_base_dir()))
	img.save_png("res://" + out)
	print("gravado: ", out)
	if _args.has("scale"):   # o jogo ampliado pelo filtro de verdade do `GameView`
		var k := float(_args["scale"])
		var big := SubViewport.new()
		big.size = Vector2i((Vector2(img.get_size()) * k).ceil())
		big.render_target_update_mode = SubViewport.UPDATE_ONCE
		var rect := TextureRect.new()
		rect.texture = ImageTexture.create_from_image(img)
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		rect.size = Vector2(big.size)
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		var shader := Shader.new()
		shader.code = GameView.SHARP
		rect.material = ShaderMaterial.new()
		(rect.material as ShaderMaterial).shader = shader
		(rect.material as ShaderMaterial).set_shader_parameter("scale", k)
		big.add_child(rect)
		add_child(big)
		await RenderingServer.frame_post_draw
		var sout := out.get_basename() + "_x%s.png" % _args["scale"]
		big.get_texture().get_image().save_png("res://" + sout)
		print("gravado: ", sout)
	if _args.has("zoom"):
		var z: PackedStringArray = _args["zoom"].split(",")
		var r := Rect2i(int(z[0]), int(z[1]), int(z[2]), int(z[3])).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var crop := img.get_region(r)
		crop.resize(r.size.x * ZOOM, r.size.y * ZOOM, Image.INTERPOLATE_NEAREST)
		var zout := out.get_basename() + "_zoom.png"
		crop.save_png("res://" + zout)
		print("gravado: ", zout)
	get_tree().quit()
