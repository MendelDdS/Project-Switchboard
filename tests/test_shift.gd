extends "res://tests/test_base.gd"
## Um robô joga o turno inteiro na agenda real (use `-- --seed=N` para repetir a agenda).
## Com `-- --human` cada ação (atender, plugar, transferir, despachar, registrar...) leva HUMAN_STEP segundos reais,
## como uma pessoa: mede se o ritmo das ligações cabe no tempo de quem joga de verdade.
## Com `-- --clumsy` ele deixa de atender 1 em cada 3 ligações (como alguém sobrecarregado): mede a bola de neve
## dos retornos (quem liga de novo).
## Falha se houver travamento: o turno precisa chegar ao final (00:00) depois da ligação desconhecida.
## `m` e `b` ficam sem tipo: Main e Switchboard usam o autoload Sfx, que ainda não existe quando o Godot
## compila um script passado com -s.

var m   # Main
var max_live := 0
var f2 := 0
var f3 := 0
var fall := 0
var starved := 0
var post := 0
var myst_at := ""
var answered := {}
var clumsy := "--clumsy" in OS.get_cmdline_user_args()
var skipped := 0
var human := "--human" in OS.get_cmdline_user_args()
const HUMAN_STEP := 5.0   ## segundos reais por ação no modo --human
var next_act := 0.0       ## instante (s, na velocidade do jogo) em que a "pessoa" pode agir de novo


## Segundos na velocidade do jogo (o relógio do turno para às 00:00; este não).
func _now() -> float:
	return Time.get_ticks_msec() / 1000.0 * Engine.time_scale


## Marca o tempo que a ação levou (só no modo --human).
func _acted(steps := 1.0) -> void:
	if human:
		next_act = _now() + HUMAN_STEP * steps
var seen := {}
var last_ring := 0.0
var kinds := {}           ## tipo -> quantas tocaram
var max_quiet := 0.0      ## maior intervalo (min de jogo) sem nenhuma ligação nova tocando


func _home(b, e: int) -> void:
	if b.ends[e] != -1:
		b.pick_up(e)
		b.go_home(e)


func _fone_to(b, j: int) -> void:
	if b.ends[0] != -1:
		b.pick_up(0)
	else:
		b.held = 0
	b.place(0, j)


func _initialize() -> void:
	Engine.time_scale = 12.0
	m = await load_main()
	m._intro.visible = false
	m._start_shift()
	var b = m.board
	var ex: Exchange = m.exchange
	var frames_left := 0   # só para espaçar os registros no caderno
	var deadline := Time.get_ticks_msec() + 180000   # limite em tempo real: a quantidade de quadros varia com a máquina
	while not m.ending and Time.get_ticks_msec() < deadline and not failed:
		await process_frame
		frames_left += 1
		max_live = maxi(max_live, m.live.size())
		for c in m.live:
			if not seen.has(c.time + str(c.line)):
				seen[c.time + str(c.line)] = true
				kinds[c.kind] = int(kinds.get(c.kind, 0)) + 1
				max_quiet = maxf(max_quiet, m.minutes - last_ring)
				last_ring = m.minutes
		if not m.after:
			fall += 1
			if m.live.size() >= 2: f2 += 1
			if m.live.size() >= 3: f3 += 1
			if m.live.any(func(c: PhoneCall): return c.phase == PhoneCall.Phase.AWAIT) and b.free_patches() == 0: starved += 1
		# desmonta o que desligou
		for n in range(1, 11):
			if ex.line(n) == Exchange.Line.DONE and m._call_on_line(n) == null:
				var e: int = b.cord_at(n + 10)
				if e != -1:
					_home(b, e)
					_home(b, b.mate(e))
				if b.fone_line() == n:
					_home(b, 0)
		for d in ex.dest_numbers():
			if ex.dest(d) == Exchange.Dest.DONE and b.cord_at(d) != -1:
				_home(b, b.cord_at(d))
		if _now() < next_act:
			continue
		var f: PhoneCall = m._focus()
		if f == null or not f.active:
			for c in m.live:
				var key: String = c.time + str(c.line)
				if c.ringing and not answered.has(key):
					if clumsy and c.kind != PhoneCall.Kind.MYSTERY and c != m.tut and answered.size() % 3 == 1:
						answered[key] = true
						skipped += 1
						continue
					_fone_to(b, c.line)
					m.answer()
					_acted()
					answered[key] = true
					if c.kind == PhoneCall.Kind.MYSTERY:
						myst_at = "%s na linha %02d" % [c.time, c.line]
					elif m.after:
						post += 1
					break
			f = m._focus()
		if f == null or not f.active or f.talking:
			if m.notebook.has_pending() and frames_left % 120 == 0:
				m.notebook._type.select(1)
				m.notebook.register()
				_acted()
			continue
		match f.kind:
			PhoneCall.Kind.TRANSFER:
				if f.phase == PhoneCall.Phase.AWAIT:
					var tg := int(f.target)
					var s: int = b.cord_at(f.line + 10)
					var d: int = b.dest_of_output(f.line)
					if s == -1:
						for k in b.PATCHES:
							if b.ends[1 + k * 2] == -1 and b.ends[2 + k * 2] == -1:
								b.held = 1 + k * 2
								b.place(1 + k * 2, f.line + 10)
								_acted()
								break
					elif d == -1:
						if b.cord_at(tg) == -1:
							b.held = b.mate(s)
							b.place(b.mate(s), tg)
							_acted()
					elif ex.dest(d) == Exchange.Dest.FREE:
						if f.no_answer and (f.data as TransferCall).alt_target != "" and not f.alt_done:
							f.options.back()["fn"].call()
							_home(b, b.cord_at(d))
						else:
							m.transfer()
						_acted()
					elif ex.dest(d) == Exchange.Dest.CONN:
						_home(b, 0)
						_acted()
			_:
				if f.kind == PhoneCall.Kind.EMERGENCY and not f.options.is_empty() and String(f.options[0]["label"]).begins_with("Fique") and not f.dispatched:
					var e: EmergencyCall = f.data
					m.dispatch.set_location(e.street, e.block, e.address)
					m.dispatch.set_occurrence(e.occurrence)
					for u in e.units:
						(m.dispatch._unit_buttons[u] as Button).button_pressed = true
					m.dispatch._send()
					_acted(4.0)   # mapa, tipo, unidades e enviar
				elif not f.options.is_empty():
					f.options[0]["fn"].call()
					_acted()
	var recs: Array = m.notebook.entries + m.notebook.queue + ([m.notebook.pending] if m.notebook.has_pending() else [])
	var lost := recs.filter(func(e): return e["obs"] == "Não atendida.").size()
	if human:
		print("humano: %.0f s por ação" % HUMAN_STEP)
	if clumsy:
		print("desastrado: deixou tocar %d, retornos=%d" % [skipped, recs.filter(func(e): return e["who"].begins_with("Desconhecido")).size()])
	max_quiet = maxf(max_quiet, m.minutes - last_ring)
	print("desconhecida tocou às %s, atendidas depois=%d, fim às %s | máx=%d  2+=%d%%  3+=%d%%  sem_cabo=%d%%  perdidas=%d  ligações=%d (emerg=%d trotes=%d)  maior_silêncio=%d min" % [
		myst_at, post, m.fmt(m.minutes), max_live, 100 * f2 / maxi(fall, 1), 100 * f3 / maxi(fall, 1),
		100 * starved / maxi(fall, 1), lost, recs.size(), int(kinds.get(PhoneCall.Kind.EMERGENCY, 0)),
		int(kinds.get(PhoneCall.Kind.PRANK, 0)), max_quiet])
	ok(myst_at != "", "a ligação desconhecida tocou")
	ok(m.ending and m.minutes >= m.SHIFT_END, "o turno terminou no horário")
	finish("turno completo")
