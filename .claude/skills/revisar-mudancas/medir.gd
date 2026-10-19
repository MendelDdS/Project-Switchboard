extends "res://tests/test_base.gd"
## Medição de desempenho da skill `revisar-mudancas` (com tela e sem vsync, o jogo inteiro pelo `GameView`). Copie para
## `tests/test_zz_medir.gd`, rode `Godot --path . tests/runner.tscn -- --test=zz_medir --seed=1` (sem `--headless`) e
## apague a cópia e o `.uid` dela depois. Cada cenário: quadros por segundo, o tempo médio e o pior 1% dos quadros,
## quantos passaram de 8 e de 16 ms, as chamadas de desenho do último quadro e quantas vezes por segundo cada parte do
## cenário se redesenhou.

var m: Main
var _rec := false
var _last := 0
var _dts: Array = []
var _draws := {}


func _process(_d: float) -> void:
	var now := Time.get_ticks_usec()
	if _rec:
		_dts.append(now - _last)
	_last = now


func _count(name: String, c: CanvasItem) -> void:
	_draws[name] = 0
	c.draw.connect(func(): _draws[name] += 1)


func _measure(name: String, sec := 3.0, warm := 30) -> void:
	await frames(warm)
	_dts.clear()
	for k in _draws:
		_draws[k] = 0
	_rec = true
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < sec * 1000.0:
		await get_tree().process_frame
	_rec = false
	var d := _dts.duplicate()
	d.sort()
	var n := d.size()
	var sum := 0.0
	for x in d:
		sum += x
	var ds := []
	for k in _draws:
		if _draws[k] > 0:
			ds.append("%s %.0f/s" % [k, _draws[k] / sec])
	print("%-22s %4.0f q/s | média %5.2f ms  pior 1%% %5.2f  máx %6.2f | >8ms %3d  >16ms %3d | chamadas %4.0f | %s" % [
		name, n / sec, sum / n / 1000.0, d[int(n * 0.99)] / 1000.0, d[n - 1] / 1000.0,
		d.filter(func(x): return x > 8333).size(), d.filter(func(x): return x > 16667).size(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), ", ".join(ds)])


func _initialize() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var app: Control = load("res://scenes/app.tscn").instantiate()
	m = app.get_node("Box/View/Main")
	m.night_no = 1
	get_tree().root.add_child(app)
	get_tree().current_scene = app
	await frames(5)
	m.sched.clear()
	m._intro.visible = false
	m.running = true
	get_tree().paused = false
	var bg := m.background
	_count("sala", bg)
	_count("camada", bg._over)
	_count("vista", bg._view)
	_count("fundo", bg._back)
	_count("mesa", m.board)
	_count("sol", bg._sun_layer)
	await frames(240)   # (os primeiros quadros pagam o que é feito uma vez só: shaders, imagens guardadas)
	for w in ["clear", "fog", "rain"]:
		m.set_weather(w)
		await _measure("parado, " + w)
	m.flick = true
	await _measure("luminária piscando")
	m.flick = false
	bg._bolt_in = 0.0
	await _measure("relâmpago", 1.5, 1)
	for id in ["lista", "despacho"]:
		m.tools.set_tab(id)
		await _measure("abrindo " + id, 1.0, 0)
		m.tools.close()
		await _measure("guardando " + id, 1.0, 0)
	m.shift_end = 720.0   # o amanhecer da última noite: só o relógio, sem trocar de noite
	m.set_weather("clear")
	for h in [11 * 60 + 15.0, 11 * 60 + 40.0]:
		m.minutes = h
		await _measure("amanhecer %d:%02d" % [int(h / 60.0) - 6, int(h) % 60])
	m.minutes = 11 * 60 + 25.0   # o sol subindo depressa: a luz dele na mesa andando
	Engine.time_scale = 8.0
	await _measure("amanhecer, sol a 8×", 3.0, 1)
	Engine.time_scale = 1.0
	finish("medir")
