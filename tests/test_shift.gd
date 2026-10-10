extends "res://tests/test_base.gd"
## Um robô joga o turno inteiro na agenda real (use `-- --seed=N` para repetir a agenda).
## Com `-- --human` cada ação (atender, plugar, transferir, despachar, registrar...) leva HUMAN_STEP segundos reais,
## como uma pessoa: mede se o ritmo das ligações cabe no tempo de quem joga de verdade.
## Com `-- --clumsy` ele deixa de atender 1 em cada 3 ligações (como alguém sobrecarregado): mede a bola de neve
## dos retornos (quem liga de novo).
## Falha se houver travamento: o turno precisa chegar ao final (00:00) depois da ligação desconhecida.

var m: Main
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


var sim := 0.0           ## segundos simulados (somando o delta de cada quadro; com --fixed-fps não seguem o relógio real)


## Segundos na velocidade do jogo (o relógio do turno para às 00:00; este não).
func _now() -> float:
	return sim


## Marca o tempo que a ação levou (só no modo --human).
func _acted(steps := 1.0) -> void:
	if human:
		next_act = _now() + HUMAN_STEP * steps
var seen := {}
var last_ring := 0.0
var kinds := {}           ## tipo -> quantas tocaram
var stages := []          ## estágio da barra de agravamento em cada despacho (e quanto ela correu)
var max_quiet := 0.0      ## maior intervalo (min de jogo) sem nenhuma ligação nova tocando
var max_empty := 0.0      ## maior tempo (min de jogo) com a mesa vazia, sem ninguém tocando nem na linha


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


## Um passo do despacho pelo cartão (modo --human). Devolve se fez alguma ação (que conta tempo); esperar a
## impressora ou o transmissor não conta.
func _card_step(f: PhoneCall, e: EmergencyCall) -> bool:
	var d := m.dispatch
	var card := d.machines
	if not f.has_meta("planned"):
		f.set_meta("planned", true)   # consultar o protocolo
		return true
	if card.state == card.State.IDLE and d._location.is_empty():
		d.set_location(e.street, e.block, e.address)
		return true
	if card.state != card.State.READY:
		return false   # imprimindo ou entrando
	if d.occurrence() == "":
		d.set_occurrence(e.occurrence)
		for u in d.fleet.required(e):   # o que a situação pede agora (pode ter piorado)
			d.punch_unit(u)
		return true
	card._pos = Vector2(card._machine(card.Machine.SEND).get_center().x - card.CARD_W / 2.0, card._slot(card.Machine.SEND) - card.card.size.y + 8.0)
	card._drop()
	return true


func _initialize() -> void:
	Engine.time_scale = 2.0
	m = await load_main()
	if human:   # pelo cartão, o despacho sai só depois da leitura no transmissor: o estágio é o daquela hora
		m.dispatch.sent.connect(func(_l, _u, _c, _n, e: EmergencyCall):
			var f: PhoneCall = m.emergency_of(e)
			if f != null:
				stages.append("%d(%.0fs)" % [f.stage, f.urgency] if f.retry == PhoneCall.Retry.NONE else "retorno"))
	m._intro.visible = false
	m._start_shift()
	var b := m.board
	ok(b.patches == 2 + GameData.sectors.size(), "3 cabos no setor 3 e um a mais por setor entregue")
	for n in b._slots:   # setor ainda coberto pela chapa: a tomada não responde
		ok((b.jack_at(b._slots[n]) == n) == GameData.in_service(str(n)), "tomada %d conforme o setor" % n)
	var ex: Exchange = m.exchange
	var frames_left := 0   # só para espaçar os registros no caderno
	var empty_at := m.minutes   # (a mesa vazia: desde o último quadro, e quanto já somou)
	var empty_for := 0.0
	var deadline := Time.get_ticks_msec() + 90000   # limite de segurança em tempo real (um turno leva ~6 s com --fixed-fps)
	while not m.ending and Time.get_ticks_msec() < deadline and not failed:
		await get_tree().process_frame
		sim += m.get_process_delta_time()
		frames_left += 1
		max_live = maxi(max_live, m.live.size())
		if m.live.is_empty():
			empty_for += m.minutes - empty_at
			max_empty = maxf(max_empty, empty_for)
		else:
			empty_for = 0.0
		empty_at = m.minutes
		for c in m.live:
			if not seen.has(c.time + str(c.line)):
				seen[c.time + str(c.line)] = true
				kinds[c.kind] = int(kinds.get(c.kind, 0)) + 1
				ok(not m.live.any(func(x: PhoneCall): return x != c and (x.story or x.kind == PhoneCall.Kind.MYSTERY)),
					"%s: nada toca com uma ligação do roteiro na mesa" % Main.fmt(m.minutes))
				max_quiet = maxf(max_quiet, m.minutes - last_ring)
				last_ring = m.minutes
		if not m.after or m.night.mystery.is_empty():   # antes da desconhecida (sem ela, o turno todo)
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
		var f: PhoneCall = m._focus()
		# a pessoa lê a resposta da emergência até o fim antes de pensar no próximo passo
		if human and f != null and f.kind == PhoneCall.Kind.EMERGENCY and f.talking:
			next_act = maxf(next_act, _now() + HUMAN_STEP)
		if _now() < next_act:
			continue
		if f == null or not f.active:
			for c in m.live:
				var key: String = c.time + str(c.line)
				if c.ringing and not answered.has(key):
					if clumsy and c.kind != PhoneCall.Kind.MYSTERY and answered.size() % 3 == 1:
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
				m.notebook.register(T.Key.TYPE_COMMON)
				_acted()
			elif m.toll.waiting() > 0 and frames_left % 120 == 0:   # o bilhete: carimbar e, depois, guardar
				var t: TollTicket = m.toll.tickets()[0]
				if t.stamped:
					m.toll.file(t)
				else:
					t.stamp(TollTicket.FIELD.get_center())
				_acted()
			continue
		match f.kind:
			PhoneCall.Kind.TRANSFER:
				if f.phase == PhoneCall.Phase.AWAIT:
					var tg := int(f.target)
					var s: int = b.cord_at(f.line + 10)
					var d: int = b.dest_of_output(f.line)
					if s == -1:
						for k in b.patches:
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
				if f.kind == PhoneCall.Kind.EMERGENCY and not f.options.is_empty() and String(f.options[0]["label"]) == T.text(T.Key.OP_HOLD_EMERGENCY) and not f.dispatched:
					var e: EmergencyCall = f.data
					if human:   # como uma pessoa, pelo cartão: pensar, marcar no mapa, esperar imprimir, perfurar, levar
						if not _card_step(f, e):
							continue
					else:
						m.dispatch.set_location(e.street, e.block, e.address)
						m.dispatch.set_occurrence(e.occurrence)
						for u in m.dispatch.fleet.required(e):   # o que a situação pede agora (pode ter piorado)
							m.dispatch.punch_unit(u)
						stages.append("%d(%.0fs)" % [f.stage, f.urgency] if f.retry == PhoneCall.Retry.NONE else "retorno")
						m.dispatch._send()
					_acted()
				elif not f.options.is_empty():
					f.options[0]["fn"].call()
					_acted()
	var recs: Array = m.notebook.entries + m.notebook.queue + ([m.notebook.pending] if m.notebook.has_pending() else [])
	var lost := recs.filter(func(e): return e.type == T.Key.TYPE_MISSED).size()
	if human:
		print("humano: %.0f s por ação" % HUMAN_STEP)
	if clumsy:
		print("desastrado: deixou tocar %d, retornos=%d" % [skipped, recs.filter(func(e): return e.who.begins_with(T.text(T.Key.UNKNOWN_CALLER))).size()])
	max_quiet = maxf(max_quiet, m.minutes - last_ring)
	print("desconhecida tocou às %s, atendidas depois=%d, fim às %s | máx=%d  2+=%d%%  3+=%d%%  sem_cabo=%d%%  perdidas=%d  ligações=%d (emerg=%d trotes=%d)  maior_silêncio=%d min  mesa_vazia=%d min" % [
		myst_at, post, m.fmt(m.minutes), max_live, 100 * f2 / maxi(fall, 1), 100 * f3 / maxi(fall, 1),
		100 * starved / maxi(fall, 1), lost, recs.size(), int(kinds.get(PhoneCall.Kind.EMERGENCY, 0)),
		int(kinds.get(PhoneCall.Kind.PRANK, 0)), max_quiet, max_empty])
	print("despachos (estágio e barra corrida): ", ", ".join(stages))
	print("bilhetes guardados=%d, esquecidos na mesa=%d" % [m.toll.filed, m.toll.waiting()])
	ok(myst_at != "" or m.night.mystery.is_empty(), "a ligação desconhecida tocou")
	ok(m.ending and m.minutes >= m.SHIFT_END, "o turno terminou no horário")
	finish("turno completo")
