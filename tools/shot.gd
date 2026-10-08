extends Node
## Captura de tela do jogo numa situação escolhida, para conferir mudanças visuais (sem montar um script a cada vez).
## Roda COM tela (sem --headless: sem ela nada é desenhado) e grava a tela inteira e, com --zoom, um recorte ampliado:
##   Godot --path . tools/shot.tscn -- --hour=22:30 --weather=rain --tool=despacho --card --zoom=760,420,240,140
## Opções (depois do `--`):
##   --out=build/shot.png   onde gravar (o recorte vai em <nome>_zoom.png)
##   --width=1280           a largura do jogo (720 de altura; até `GameView.MAX_W`, 21:9)
##   --hour=20:00           a hora do turno no relógio e lá fora
##   --tool=id              abre a ferramenta (os ids de `Tools`: lista, despacho, caderno, registro, jornal)
##   --card                 marca um local no mapa e espera o cartão sair impresso
##   --emergency            toca uma emergência e atende (a luz vermelha da unidade, a barra, o rádio)
##   --news                 o jornal da manhã na mesa
##   --zoom=x,y,w,h         o recorte, em px do jogo, ampliado `ZOOM` vezes
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
	if _args.has("emergency"):
		m.ring(PhoneCall.from_emergency(GameData.template_emergency()))
		await get_tree().create_timer(0.5, false).timeout
		m.board.held = 0   # o FONE na linha dela
		m.board.place(0, m.live[0].line)
		m.answer()
	if _args.has("tool"):
		m.tools.set_tab(_args["tool"])
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
	if _args.has("zoom"):
		var z: PackedStringArray = _args["zoom"].split(",")
		var r := Rect2i(int(z[0]), int(z[1]), int(z[2]), int(z[3])).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var crop := img.get_region(r)
		crop.resize(r.size.x * ZOOM, r.size.y * ZOOM, Image.INTERPOLATE_NEAREST)
		var zout := out.get_basename() + "_zoom.png"
		crop.save_png("res://" + zout)
		print("gravado: ", zout)
	get_tree().quit()
