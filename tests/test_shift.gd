extends "res://tests/test_base.gd"
## Um robô joga o turno inteiro na agenda real (use `-- --seed=N` para repetir a agenda).
## Falha se houver travamento: o turno precisa chegar ao final das 06:00 depois da linha 07.

var m
var max_live := 0
var f2 := 0
var f3 := 0
var fall := 0
var starved := 0
var answered := {}
var post := 0
var myst_at := ""

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
	m._start_shift()
	var b = m.board
	var frames := 0
	while not m.ending and frames < 60 * 200:
		await process_frame
		frames += 1
		max_live = maxi(max_live, m.live.size())
		if not m.after:
			fall += 1
			if m.live.size() >= 2: f2 += 1
			if m.live.size() >= 3: f3 += 1
			if m.live.any(func(c): return c.get("phase", "") == "await") and b.free_patches() == 0: starved += 1
		# desmonta o que desligou
		for n in range(1, 11):
			if m.lines[n - 1] == "done" and m._call_on_line(n).is_empty():
				var e: int = b.cord_at(n + 10)
				if e != -1:
					_home(b, e)
					_home(b, b.mate(e))
				if b.fone_line() == n:
					_home(b, 0)
		for d in m.dests:
			if m.dests[d] == "done" and b.cord_at(d) != -1:
				_home(b, b.cord_at(d))
		var f: Dictionary = m._focus()
		if f.is_empty() or not f.get("active", false):
			for c in m.live:
				if c.get("ringing", false) and not answered.has(c["time"] + str(c["line"])):
					_fone_to(b, int(c["line"]))
					m.answer()
					answered[c["time"] + str(c["line"])] = true
					if c["kind"] == "mystery":
						myst_at = c["time"]
					elif m.after:
						post += 1
					break
			f = m._focus()
		if f.is_empty() or not f.get("active", false) or f.get("talking", false):
			if not m.pending.is_empty() and frames % 120 == 0:
				m.p_type.select(1)
				m._register()
			continue
		var n := int(f["line"])
		match f["kind"]:
			"transfer":
				if f.get("phase", "") == "await":
					var tg := int(f["target"])
					var s: int = b.cord_at(n + 10)
					var d: int = m._dest_of_line(n)
					if s == -1:
						for k in b.PATCHES:
							if b.ends[1 + k * 2] == -1 and b.ends[2 + k * 2] == -1:
								b.held = 1 + k * 2
								b.place(1 + k * 2, n + 10)
								break
					elif d == -1:
						if b.cord_at(tg) == -1:
							b.held = b.mate(s)
							b.place(b.mate(s), tg)
					elif m.dests[d] == "free":
						if f.get("no_answer", false) and f.has("alt") and not f.get("alt_done", false):
							f["opts"].back()["fn"].call()
							_home(b, b.cord_at(d))
						else:
							m.transfer()
					elif m.dests[d] == "conn":
						_home(b, 0)
			"emergency", "prank", "info", "mystery":
				if f["kind"] == "emergency" and not f["opts"].is_empty() and String(f["opts"][0]["label"]).begins_with("Fique") and not f.get("dispatched", false):
					var inc: Dictionary = m.incident
					m.map_sel = {"street": inc["street"], "block": inc["block"], "label": inc["addr"]}
					m.unit_sel = inc["req"].duplicate()
					m._send()
				elif not f["opts"].is_empty():
					f["opts"][0]["fn"].call()
	var recs: Array = m.entries + m.pending_q + ([] if m.pending.is_empty() else [m.pending])
	var lost := recs.filter(func(e): return e["obs"] == "Não atendida.").size()
	print("07 tocou %s, atendidas depois=%d, fim às %s | " % [myst_at, post, m.fmt(m.minutes)] + "fim: max=%d  2+=%d%%  3+=%d%%  sem_cabo=%d%%  perdidas=%d  ending=%s  ligacoes=%d" % [max_live, 100 * f2 / maxi(fall, 1), 100 * f3 / maxi(fall, 1), 100 * starved / maxi(fall, 1), lost, m.ending, recs.size()])
	ok(myst_at != "", "a linha 07 tocou")
	ok(m.ending and m.minutes >= m.SHIFT_END, "o turno terminou às 06:00")
	finish("turno completo")
