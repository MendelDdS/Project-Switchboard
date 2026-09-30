class_name Sfx
extends Node
## Todos os sons do protótipo são sintetizados ao iniciar (nenhum arquivo de áudio).
## Para trocar por gravações reais, substitua as entradas de `streams` por AudioStreams importados.

const RATE := 22050
# Vozes abafadas: cada vogal vira uma sílaba sintetizada (fonte glotal + formantes + filtro abafado).
# f0 = altura, breath = sopro, muffle = corte do filtro (quanto menor, mais abafado), dur = duração da sílaba.
const VOICE := {
	"f": {"f0": 225.0, "breath": 0.10, "muffle": 1250.0, "dur": 0.13, "db": -7.0},
	"m": {"f0": 118.0, "breath": 0.08, "muffle": 1000.0, "dur": 0.14, "db": -6.0},
	"k": {"f0": 320.0, "breath": 0.06, "muffle": 1500.0, "dur": 0.11, "db": -9.0},
	"w": {"f0": 140.0, "breath": 0.45, "muffle": 950.0, "dur": 0.14, "db": -8.0},
	"g": {"f0": 92.0, "breath": 0.30, "muffle": 700.0, "dur": 0.21, "db": -5.0},
	"r": {"f0": 135.0, "breath": 0.18, "muffle": 2300.0, "dur": 0.12, "db": -11.0},
}
# Formantes (F1, F2) aproximados das vogais do português.
const VOWEL := {"a": Vector2(780, 1250), "e": Vector2(480, 1850), "i": Vector2(310, 2250), "o": Vector2(500, 880), "u": Vector2(350, 720)}
const VOL := {
	"click": -14.0, "sw": -10.0, "plug_in": -3.0, "plug_out": -9.0, "key": -13.0, "page": -11.0,
	"tick": -24.0, "pencil": -13.0, "ring": -5.0, "pulse": -10.0, "ringback": -13.0, "sit": -13.0,
	"cut": -2.0, "static": -11.0, "crackle": -14.0, "thump": -5.0,
}

var streams: Dictionary = {}
var pool: Array[AudioStreamPlayer] = []
var rain: AudioStreamPlayer
var hum: AudioStreamPlayer
var hiss: AudioStreamPlayer
var _ring_on := false
var _ring_timer: Timer
var _w := PackedFloat32Array()


func _ready() -> void:
	_build_all()
	for i in 20:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	rain = _make_loop("rain")
	hum = _make_loop("hum")
	hiss = _make_loop("hiss")
	_ring_timer = Timer.new()
	_ring_timer.wait_time = 3.0
	add_child(_ring_timer)
	_ring_timer.timeout.connect(_ring_burst)


# ------------------------------------------------------------------ reprodução

func play(id: String, db: float = 0.0, pitch: float = 1.0) -> void:
	if not streams.has(id):
		return
	var p: AudioStreamPlayer = null
	for q in pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = pool[0]
	p.stream = streams[id]
	p.volume_db = VOL.get(id, -10.0) + db
	p.pitch_scale = pitch
	p.play()


func later(t: float, id: String, db: float = 0.0) -> void:
	if t <= 0.0:
		play(id, db)
		return
	get_tree().create_timer(t).timeout.connect(play.bind(id, db))


func start_ambience() -> void:
	rain.play()
	hum.play()
	hiss.play()
	fade(rain, -20.0, 2.0)
	fade(hum, -29.0, 2.0)


func fade(p: AudioStreamPlayer, db: float, t: float) -> void:
	var tw := create_tween()
	tw.tween_property(p, "volume_db", db, t)


func ring_start() -> void:
	if _ring_on:
		return
	_ring_on = true
	_ring_burst()
	_ring_timer.start()


func ring_stop() -> void:
	_ring_on = false
	_ring_timer.stop()


func _ring_burst() -> void:
	if _ring_on:
		play("ring")


## Discagem por pulsos. Retorna a duração em segundos.
func dial(num: String) -> float:
	var t := 0.0
	for ch in num:
		var n := 10 if ch == "0" else int(ch)
		for i in n:
			later(t, "pulse")
			t += 0.075
		t += 0.35
	return t


func ringback(times: int) -> float:
	for i in times:
		later(i * 2.0, "ringback")
	return times * 2.0


## Toca uma sílaba abafada. `rise` sobe a entonação (perguntas, risadas).
func syllable(v: String, vowel: String, rise: bool = false) -> void:
	if not VOICE.has(v):
		v = "m"
	var id := "s_%s_%s_%d" % [v, vowel, randi() % 3]
	var pitch := randf_range(0.95, 1.05) * (1.13 if rise else 1.0)
	play(id, float(VOICE[v]["db"]) + 10.0, pitch)
	if v == "g" and randf() < 0.3:
		play("crackle", -4.0)


func static_burst(strength: float = 0.0) -> void:
	play("static", strength, randf_range(0.9, 1.1))


# ------------------------------------------------------------------ síntese

func _make_loop(id: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = streams[id]
	p.volume_db = -80.0
	add_child(p)
	return p


func _begin(sec: float) -> void:
	_w = PackedFloat32Array()
	_w.resize(int(sec * RATE))
	_w.fill(0.0)


func _wave(kind: String, ph: float) -> float:
	var p := ph - floorf(ph)
	match kind:
		"sine":
			return sin(p * TAU)
		"square":
			return 1.0 if p < 0.5 else -1.0
		"saw":
			return p * 2.0 - 1.0
		"tri":
			return 1.0 - 4.0 * absf(p - 0.5)
	return 0.0


func _tone(at: float, f: float, dur: float, kind: String, g: float, attack: float = 0.004) -> void:
	var s0 := int(at * RATE)
	var n := int(dur * RATE)
	for i in n:
		var idx := s0 + i
		if idx >= _w.size():
			break
		var t := float(i) / RATE
		var env := g * (t / attack if t < attack else pow(0.0001, (t - attack) / maxf(dur - attack, 0.001)))
		_w[idx] += _wave(kind, f * t) * env


func _noise(at: float, dur: float, ftype: String, f: float, q: float, g: float) -> void:
	var n := int(dur * RATE)
	var x := PackedFloat32Array()
	x.resize(n)
	for i in n:
		var t := float(i) / RATE
		x[i] = randf_range(-1.0, 1.0) * g * pow(0.0001, t / dur)
	if ftype != "":
		x = _biquad(x, ftype, f, q)
	var s0 := int(at * RATE)
	for i in n:
		if s0 + i < _w.size():
			_w[s0 + i] += x[i]


func _biquad(x: PackedFloat32Array, ftype: String, f: float, q: float) -> PackedFloat32Array:
	var w0 := TAU * f / RATE
	var cw := cos(w0)
	var alpha := sin(w0) / (2.0 * q)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	match ftype:
		"lp":
			b0 = (1.0 - cw) / 2.0
			b1 = 1.0 - cw
			b2 = b0
		"hp":
			b0 = (1.0 + cw) / 2.0
			b1 = -(1.0 + cw)
			b2 = b0
		_:
			b0 = alpha
			b1 = 0.0
			b2 = -alpha
	var a0 := 1.0 + alpha
	var a1 := -2.0 * cw
	var a2 := 1.0 - alpha
	var y := PackedFloat32Array()
	y.resize(x.size())
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in x.size():
		var v := (b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0
		x2 = x1
		x1 = x[i]
		y2 = y1
		y1 = v
		y[i] = v
	return y


func _end(id: String, tel: bool = false, loop: bool = false, peak: float = 0.8) -> void:
	if tel:
		_w = _biquad(_w, "bp", 1500.0, 0.75)
	var m := 0.0001
	for v in _w:
		m = maxf(m, absf(v))
	var k := peak / m
	var bytes := PackedByteArray()
	bytes.resize(_w.size() * 2)
	for i in _w.size():
		bytes.encode_s16(i * 2, int(clampf(_w[i] * k, -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = _w.size()
	streams[id] = s


func _syllable(v: String, vw: String, contour: float, consonant: bool) -> void:
	var p: Dictionary = VOICE[v]
	var f0: float = p["f0"]
	var dur: float = p["dur"]
	var breath: float = p["breath"]
	var fm: Vector2 = VOWEL[vw]
	var n := int(dur * RATE)
	var src := PackedFloat32Array()
	src.resize(n)
	var ph := randf()
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var f := f0 * (1.0 + contour * k) * (1.0 + 0.015 * sin(TAU * 5.5 * t))
		ph += f / RATE
		var g := ph - floorf(ph)
		var s := (1.0 - g) * (1.0 - g) * 2.0 - 1.0   # pulso glotal suave
		s = s * (1.0 - breath) + randf_range(-1.0, 1.0) * breath
		var env := pow(sin(PI * k), 0.7)
		src[i] = s * env
	var a := _biquad(src, "bp", fm.x, 4.0)
	var b := _biquad(src, "bp", fm.y, 6.0)
	var c := _biquad(src, "bp", 2600.0, 7.0)
	_begin(dur + 0.04)
	var off := int(0.025 * RATE) if consonant else 0
	for i in n:
		if off + i < _w.size():
			_w[off + i] = a[i] + b[i] * 0.55 + c[i] * 0.18
	if consonant:
		_noise(0.0, 0.035, "hp", 2800.0, 0.7, 0.05)
	# abafado: dois passa-baixas + corte de graves (como se viesse do outro lado de um vidro / fone)
	var mf: float = p["muffle"]
	_w = _biquad(_biquad(_biquad(_w, "lp", mf, 0.7), "lp", mf * 1.2, 0.7), "hp", 160.0, 0.7)
	if v == "r":
		for i in _w.size():
			_w[i] = clampf(_w[i] * 40.0, -1.0, 1.0)
		_w = _biquad(_w, "bp", 1600.0, 0.9)
	_end("s_%s_%s_%d" % [v, vw, [-0.12, 0.0, 0.10].find(contour)], false, false, 0.8)


func _build_all() -> void:
	_begin(0.05); _tone(0, 1900, 0.02, "square", 0.3); _noise(0, 0.02, "bp", 4000, 1, 0.8); _end("click")
	_begin(0.06); _tone(0, 700, 0.03, "square", 0.3); _noise(0, 0.03, "bp", 2500, 1, 1.0); _end("sw")
	_begin(0.16); _noise(0, 0.06, "lp", 1400, 0.7, 1.0); _tone(0, 85, 0.12, "sine", 0.8); _tone(0.03, 1600, 0.02, "square", 0.08); _end("plug_in")
	_begin(0.08); _noise(0, 0.04, "bp", 3200, 1, 1.0); _tone(0, 240, 0.05, "sine", 0.35); _end("plug_out")
	_begin(0.05); _tone(0, 1100, 0.03, "square", 0.25); _noise(0, 0.02, "hp", 3000, 0.7, 0.5); _end("key")
	_begin(0.36); _noise(0, 0.28, "bp", 2400, 0.6, 1.0); _noise(0.2, 0.12, "lp", 600, 0.7, 0.8); _end("page")
	_begin(0.02); _tone(0, 3300, 0.008, "square", 0.3); _end("tick", false, false, 0.5)
	_begin(1.1)
	for i in 14:
		_noise(i * 0.07 + randf() * 0.03, 0.05, "bp", 5200 + randf() * 1500, 3, 0.8)
	_end("pencil")
	_begin(1.3)
	for i in 30:
		var w := i * 0.04
		_tone(w, 900, 0.03, "tri", 0.35)
		_tone(w, 1180, 0.03, "tri", 0.25)
		_tone(w, 450, 0.03, "square", 0.06)
	_end("ring")
	_begin(0.03); _tone(0, 1300, 0.012, "square", 0.3); _noise(0, 0.012, "bp", 2500, 1, 0.6); _end("pulse", true)
	_begin(1.05); _tone(0, 425, 1.0, "sine", 0.6, 0.02); _end("ringback", true)
	_begin(1.05)
	for i in 3:
		_tone(i * 0.33, [950.0, 1400.0, 1800.0][i], 0.3, "sine", 0.6, 0.01)
	_end("sit", true)
	_begin(0.3); _tone(0, 90, 0.2, "sine", 0.9); _noise(0, 0.05, "lp", 900, 0.7, 1.0); _end("cut")
	_begin(0.45); _tone(0, 60, 0.4, "sine", 0.9); _end("thump")
	_begin(0.55)
	for k in 12:
		if randf() < 0.7:
			_noise(k * 0.04, 0.05, "bp", randf_range(1500, 4000), 0.8, randf())
	_end("static")
	_begin(0.08); _noise(0, 0.06, "bp", 2600, 1, 1.0); _end("crackle")
	# 3 variações de entonação por vogal: descendo, reta, subindo.
	for v in VOICE:
		for vw in VOWEL:
			for k in 3:
				_syllable(v, vw, [-0.12, 0.0, 0.10][k], k == 0)
	# ambientes em loop
	_begin(3.0)
	for i in _w.size():
		_w[i] = randf_range(-1.0, 1.0)
	_w = _biquad(_biquad(_w, "lp", 1100, 0.7), "hp", 180, 0.7)
	_end("rain", false, true, 0.6)
	_begin(1.0)
	for i in _w.size():
		var t := float(i) / RATE
		_w[i] = sin(TAU * 60.0 * t) + 0.35 * sin(TAU * 120.0 * t)
	_end("hum", false, true, 0.6)
	_begin(2.0)
	for i in _w.size():
		_w[i] = randf_range(-1.0, 1.0)
	_w = _biquad(_w, "bp", 2000, 0.6)
	_end("hiss", false, true, 0.6)
