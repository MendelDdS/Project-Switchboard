extends "res://tests/test_base.gd"
## As telas e cenas que só tinham captura: cada cena da rua corrida pelo relógio com a vista desenhada (sem tela ela não
## é desenhada, `Background._headless`; aqui sim, para o erro no desenho aparecer como SCRIPT ERROR), a pausa, a tela
## inicial e o fim do jogo da presa (a cena `Arrest`, o diário, o fecho e os créditos até o botão da volta ao menu).

const SPEED := 6.0   ## o tempo do jogo corre mais rápido (a cena inteira em poucos quadros)
const SCENE_SEC := 50.0   ## s de jogo de cada cena (as mais longas já passaram do meio)
const SCHEDULED := ["beating", "police", "curfew", "lookout", "stranger"]   ## as marcadas pela hora (`Background.schedule`)
const SCENES := ["speaker", "chase", "flyers", "graffiti", "paint", "newsstand", "parade", "moving", "raid", "stone",
	"flare", "battle", "banner", "closed", "arrest"]   ## as de `scene_at` (`Background.start_scene`)


func _initialize() -> void:
	Engine.time_scale = SPEED
	var m: Main = load("res://scenes/main.tscn").instantiate()
	m.night_no = GameData.CONTENT.nights.size()   # a última (o fim do jogo, no final do teste)
	get_tree().root.add_child(m)
	get_tree().current_scene = m
	await get_tree().process_frame
	var bg := m.background
	bg._headless = false
	await frames(10)
	ok(not bg._flats.is_empty(), "a vista é desenhada no teste")
	for kind: String in SCHEDULED:
		bg.schedule(kind, m.minutes)
		await frames(int(SCENE_SEC * 60.0 / SPEED))
	for kind: String in SCENES:
		bg.start_scene(kind)
		ok(await wait_until(func(): return bg._scene_car != kind, 60.0), "o carro da cena %s veio" % kind)   # (o dela espera a mão livre)
		await frames(int(SCENE_SEC * 60.0 / SPEED))
		ok(bg._scene_t.get(kind, -1.0) > 0.0 or kind in ["speaker", "parade"], "a cena %s andou" % kind)   # (essas duas são só o carro)
	m._pause.open()
	await frames(5)
	ok(get_tree().paused, "a pausa pausa")
	m._pause.resume()
	ok(not get_tree().paused, "e volta")
	var title: Node = load("res://scenes/title_screen.tscn").instantiate()
	get_tree().root.add_child(title)
	await frames(60)
	title.queue_free()
	m.flags.apply(Main.Rebellion.FINALS[Main.Rebellion.Final.PRISON])   # a presa: o fim do jogo, sem relatório
	m.start_ending()
	ok(await wait_until(func(): return not m._ending._restart.disabled, 600.0), "o fim da presa chega à volta ao menu")
	ok(m._ending._to_menu, "o fim do jogo volta ao menu")
	Engine.time_scale = 1.0
	finish("cenas da rua, pausa, tela inicial e o fim do jogo")
