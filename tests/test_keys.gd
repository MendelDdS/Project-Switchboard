extends "res://tests/test_base.gd"
## Teclas e pausa pelo `GameView` (app.tscn), com o evento entrando na janela como o de uma pessoa: o jogo fica dentro
## de um SubViewport, e o `SubViewportContainer` parado na pausa deixava de repassar as teclas (Esc não despausava).
## E o mouse: o objeto da mesa abre a ferramenta e o mapa do despacho já vê o mouse.


func _key(k: Key) -> void:
	for p in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)
		await frames(3)


func _mouse(e: InputEventMouse, at: Vector2) -> void:
	e.position = at
	e.global_position = at
	Input.parse_input_event(e)
	await frames(3)


func _initialize() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var app: Control = load("res://scenes/app.tscn").instantiate()
	var m: Main = app.get_node("Box/View/Main")
	m.night_no = 1
	get_tree().root.add_child(app)
	get_tree().current_scene = app
	await frames(3)
	m.sched.clear()
	m._intro.visible = false
	m.running = true
	get_tree().paused = false
	await frames(5)
	await _key(KEY_1)
	ok(m.tools.open, "a tecla 1 abre a lista")
	await _key(KEY_1)
	ok(not m.tools.open, "a tecla 1 de novo guarda a lista")
	var got := []
	for sig in ["answer_pressed", "transfer_pressed", "listen_pressed", "hangup_pressed"]:
		for c in m.phone.get_signal_connection_list(sig):
			m.phone.disconnect(sig, c["callable"])
		m.phone.connect(sig, func(): got.append(sig))
	m.phone.set_buttons(true, true, true)
	m.phone.set_listen(true, false)
	await frames(2)
	for k in [KEY_SPACE, KEY_TAB, KEY_Z, KEY_X]:
		await _key(k)
	ok(got == ["answer_pressed", "transfer_pressed", "listen_pressed", "hangup_pressed"], "Espaço, Tab, Z e X apertam os botões (%s)" % [got])
	# o clique no objeto da mesa age ao soltar: aberta ao apertar, a ferramenta surgia sob o mouse com o botão apertado,
	# a soltura se perdia e a cena ficava com o mouse (o mapa do despacho não via o mouse até outro clique)
	get_window().size = GameView.BASE   # (sem tela a janela tem 64 px: o jogo a 1/15 e o mouse caía fora do mapa)
	await frames(3)
	var box: SubViewportContainer = app.get_node("Box")
	var win := func(p: Vector2) -> Vector2: return box.get_global_transform() * (p * box.size / Vector2(box.get_node("View").size))
	var at: Vector2 = win.call(m.background.get_global_transform() * m.background.prop_rect(Tools.DISPATCH).get_center())
	await _mouse(InputEventMouseMotion.new(), at)
	for p in [true, false]:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = p
		await _mouse(b, at)
	await frames(40)
	var city := m.dispatch.city
	var g := city.seg_geom(GameData.street("sol"), 1)
	for i in 2:   # (o primeiro só atualiza o que está sob o mouse)
		await _mouse(InputEventMouseMotion.new(), win.call(city.get_global_transform() * (city._off + (g[2] as Vector2) * city._k)) + Vector2(i, 0))
	ok(m.tools.open and m.tools.tab == Tools.DISPATCH and city.hover.get("street") == "sol", "o objeto da mesa abre o despacho e o mapa já vê o mouse")
	m.tools.close()
	await frames(20)
	# os broches na prateleira: sob o mouse, a etiqueta; o clique abre o papel; o clique fora fecha e a mesa fica com o mouse
	m.badges.earned = {"anjo": 2, "rush": 5}
	var pin := func(id: String) -> Vector2: return win.call(m.board.get_global_transform() * m.badges._spot(id))
	for i in 2:
		await _mouse(InputEventMouseMotion.new(), pin.call("anjo") + Vector2(i, 0))
	ok(m.badges._hover == "anjo" and m.badges.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "o mouse no broche: o nome e o dedo")
	for p in [true, false]:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = p
		await _mouse(b, pin.call("anjo"))
	ok(m.badges._open == "anjo", "o clique abre o papel do broche")
	var empty: Vector2 = pin.call("primorosas")   # (um lugar sem broche: o feltro)
	await _mouse(InputEventMouseMotion.new(), empty)
	ok(m.badges._hover == "" and m.badges.mouse_default_cursor_shape == m.board.mouse_default_cursor_shape, "no feltro, o cursor é o da mesa")
	for p in [true, false]:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = p
		await _mouse(b, empty)
	ok(m.badges._open == "", "o clique fora fecha o papel")
	await _key(KEY_ESCAPE)
	ok(get_tree().paused and not m.can_process(), "Esc pausa e o jogo para")
	await _key(KEY_ESCAPE)
	ok(not get_tree().paused, "Esc de novo despausa")
	# Recomeçar da pausa (`Main.restart`) com uma espera por quadro pendente, como a da conversa ouvida: recarregada no
	# meio do evento, a cena saía da árvore antes de a SubViewport acabar de entregá-lo, e a espera acordava sem árvore
	m.eavesdrop._wait(100.0)
	await _key(KEY_ESCAPE)
	(m.find_child("RestartNight", true, false) as Button).grab_focus()
	await _key(KEY_ENTER)
	ok(not is_instance_valid(app) and get_tree().current_scene.scene_file_path == "res://scenes/app.tscn", "Recomeçar troca a cena")
	get_tree().current_scene.free()
	finish("teclas pelo GameView")
