extends "res://tests/test_base.gd"
## Teclas e pausa pelo `GameView` (app.tscn), com o evento entrando na janela como o de uma pessoa: o jogo fica dentro
## de um SubViewport, e o `SubViewportContainer` parado na pausa deixava de repassar as teclas (Esc não despausava).


func _key(k: Key) -> void:
	for p in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
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
	await _key(KEY_ESCAPE)
	ok(get_tree().paused and not m.can_process(), "Esc pausa e o jogo para")
	await _key(KEY_ESCAPE)
	ok(not get_tree().paused, "Esc de novo despausa")
	get_tree().root.remove_child(app)
	app.free()
	finish("teclas pelo GameView")
