extends Node
## Autoload `Sfx`: todos os sons do jogo, sintetizados ao iniciar (nenhum arquivo de áudio).
## Para trocar por gravações reais, substitua as entradas de `streams` por AudioStreams importados.
## Barramentos (default_bus_layout.tres): Ambience (clima, coruja, zumbido, chiado), Voices (sílabas), Effects (o resto).
## Clima (`set_weather`): "rain" só chuva; "fog" grilos e coruja; "clear" brisa, grilos e coruja.

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
	"cut": -2.0, "static": -11.0, "crackle": -14.0, "thump": -5.0, "owl_0": -17.0, "owl_1": -17.0,
}
## Volume (dB) dos sons de ambiente em cada clima; o que não aparece fica mudo.
const WEATHER_MIX := {
	"rain": {"rain": -18.0},
	"fog": {"crickets": -31.0},
	"clear": {"breeze": -24.0, "crickets": -28.0},
}
const OWL_WEATHERS := ["fog", "clear"]
const OWL_HERE := Vector2(30.0, 60.0)    # segundos (reais) em que a coruja fica por perto, piando de vez em quando
const OWL_AWAY := Vector2(45.0, 110.0)   # segundos em que ela some
const OWL_GAP := Vector2(7.0, 14.0)      # intervalo entre pios enquanto está por perto
# Modos de vibração de uma campânula de metal: (razão da frequência, amplitude, decaimento em s).
const BELL_MODES := [Vector3(1.0, 1.0, 0.22), Vector3(1.52, 0.7, 0.16), Vector3(2.38, 0.6, 0.12),
	Vector3(3.06, 0.45, 0.1), Vector3(4.0, 0.3, 0.08)]
const GONGS := [1150.0, 1370.0]   # as duas campânulas, levemente dissonantes (daí o "trrrim" áspero)

const VMAP := {"a": "a", "á": "a", "à": "a", "â": "a", "ã": "a", "e": "e", "é": "e", "ê": "e", "i": "i", "í": "i", "o": "o", "ó": "o", "ô": "o", "õ": "o", "u": "u", "ú": "u"}

var streams: Dictionary = {}
var pool: Array[AudioStreamPlayer] = []
var rain: AudioStreamPlayer
var breeze: AudioStreamPlayer
var crickets: AudioStreamPlayer
var hum: AudioStreamPlayer
var hiss: AudioStreamPlayer
var weather := "rain"
var _nature_on := false
var _hushed := false
var _owl_here := false
var _owl_switch := 0.0   # segundos até a coruja chegar ou ir embora
var _owl_next := 0.0     # segundos até o próximo pio
var _ring_on := false
var _ring_timer: Timer
var _ring_player: AudioStreamPlayer
var _w := PackedFloat32Array()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # o ambiente e os sons do menu seguem durante a pausa
	_build_all()
	for i in 20:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	rain = _make_loop("rain")
	breeze = _make_loop("breeze")
	crickets = _make_loop("crickets")
	hum = _make_loop("hum")
	hiss = _make_loop("hiss")
	_ring_timer = Timer.new()
	_ring_timer.wait_time = 3.0
	add_child(_ring_timer)
	_ring_timer.timeout.connect(_ring_burst)


# ------------------------------------------------------------------ reprodução

func play(id: String, db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if not streams.has(id):
		return null
	var p: AudioStreamPlayer = null
	for q in pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = pool[0]
	p.stream = streams[id]
	p.bus = &"Voices" if id.begins_with("s_") or id == "crackle" else (&"Ambience" if id.begins_with("owl") else &"Effects")
	p.volume_db = VOL.get(id, -10.0) + db
	p.pitch_scale = pitch
	p.play()
	return p


func later(t: float, id: String, db: float = 0.0) -> void:
	if t <= 0.0:
		play(id, db)
		return
	get_tree().create_timer(t).timeout.connect(play.bind(id, db))


func start_ambience(w: String) -> void:
	for p in [rain, breeze, crickets, hum, hiss]:
		p.play()
	fade(hum, -29.0, 2.0)
	_nature_on = true
	_owl_switch = randf_range(10.0, 30.0)
	set_weather(w, 2.0)


func stop_ambience(sec: float) -> void:
	_nature_on = false
	for p in [rain, breeze, crickets, hum]:
		fade(p, -80.0, sec)
	fade(hiss, -80.0, minf(sec, 1.0))


## Troca o clima (os sons do anterior somem aos poucos).
func set_weather(w: String, sec: float = 4.0) -> void:
	weather = w
	_apply_mix(sec)


## Antes da ligação desconhecida a noite se cala: grilos e coruja param, chuva e brisa baixam.
func hush_nature(on: bool, sec: float) -> void:
	_hushed = on
	_apply_mix(sec)


func _apply_mix(sec: float) -> void:
	var mix: Dictionary = WEATHER_MIX[weather]
	for id in ["rain", "breeze", "crickets"]:
		var db: float = mix.get(id, -80.0)
		if _hushed:
			db = -80.0 if id == "crickets" else db - 10.0
		fade(get(id), db, sec)


## A coruja aparece por um tempo, pia de vez em quando e some de novo.
func _process(delta: float) -> void:
	if not _nature_on or _hushed or not weather in OWL_WEATHERS:
		return
	_owl_switch -= delta
	if _owl_switch <= 0.0:
		_owl_here = not _owl_here
		_owl_switch = randf_range(OWL_HERE.x, OWL_HERE.y) if _owl_here else randf_range(OWL_AWAY.x, OWL_AWAY.y)
		_owl_next = randf_range(1.0, 4.0)
	if _owl_here:
		_owl_next -= delta
		if _owl_next <= 0.0:
			play("owl_%d" % (randi() % 2))
			_owl_next = randf_range(OWL_GAP.x, OWL_GAP.y)


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
	# corta o toque que está soando (o player pode já ter sido reaproveitado por outro som)
	if _ring_player != null and _ring_player.stream == streams["ring"]:
		_ring_player.stop()


func _ring_burst() -> void:
	if _ring_on:
		_ring_player = play("ring")


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


## Fala o caractere i de `text`: cada grupo de vogais dispara uma sílaba abafada (ritmo de fala,
## estilo Papers, Please). Devolve se o caractere é vogal (passe de volta em `prev_vowel`).
func speak_char(voice: String, text: String, i: int, prev_vowel: bool, laugh: bool = false) -> bool:
	var lc := text[i].to_lower()
	if not VMAP.has(lc):
		return false
	if not prev_vowel:
		var rise := laugh or (text.strip_edges().ends_with("?") and i > text.length() - 9)
		syllable(voice, VMAP[lc], rise)
	return true


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
	p.bus = &"Ambience"
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
	_build_ring()
	_begin(0.03); _tone(0, 1300, 0.012, "square", 0.3); _noise(0, 0.012, "bp", 2500, 1, 0.6); _end("pulse", true)
	# chamando: "tuuuu" contínuo de 425 Hz, pela linha
	_begin(1.3)
	var on := 1.15
	for i in int(on * RATE):
		var t := float(i) / RATE
		var env := minf(1.0, minf(t / 0.03, (on - t) / 0.06))
		_w[i] = (sin(TAU * 425.0 * t) + 0.15 * sin(TAU * 850.0 * t) + randf_range(-0.02, 0.02)) * env
	_w = _biquad(_biquad(_w, "hp", 300.0, 0.7), "lp", 3000.0, 0.7)
	_end("ringback")
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
	_build_rain()
	_build_breeze()
	_build_crickets()
	for v in 2:
		_build_owl(v)
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


# ------------------------------------------------------------------ ambientes e campainhas

## Fecha o loop sem estalo: os últimos `sec` segundos se misturam com o começo e são cortados.
func _loopify(sec: float) -> void:
	var f := int(sec * RATE)
	var n := _w.size() - f
	for i in f:
		var k := float(i) / f
		_w[i] = _w[i] * sqrt(k) + _w[n + i] * sqrt(1.0 - k)
	_w.resize(n)


## Chuva: chiado de fundo, milhares de gotinhas finas (impulsos filtrados) e batidas mais graves na janela e no telhado.
func _build_rain() -> void:
	_begin(5.4)
	var n := _w.size()
	var bed := PackedFloat32Array()
	var fine := PackedFloat32Array()
	var taps := PackedFloat32Array()
	for a in [bed, fine, taps]:
		a.resize(n)
		a.fill(0.0)
	for i in n:
		bed[i] = randf_range(-1.0, 1.0)
	for k in int(5.4 * 1400):
		fine[randi() % n] += randf_range(-1.0, 1.0) * pow(randf(), 2.5)   # muitas fracas, poucas fortes
	for k in int(5.4 * 40):
		taps[randi() % n] += (1.0 if randf() < 0.5 else -1.0) * randf_range(0.3, 1.0)
	bed = _biquad(_biquad(bed, "lp", 2400.0, 0.7), "hp", 500.0, 0.7)
	var rumble := _biquad(_biquad(bed, "lp", 260.0, 0.7), "lp", 260.0, 0.7)
	fine = _biquad(_biquad(fine, "bp", 3400.0, 0.8), "hp", 1200.0, 0.7)
	taps = _biquad(taps, "bp", 1250.0, 4.0)
	for i in n:
		_w[i] = bed[i] * 0.22 + rumble[i] * 1.5 + fine[i] * 2.2 + taps[i] * 1.6
	_w = _biquad(_w, "lp", 5500.0, 0.7)   # atrás da janela
	_loopify(0.4)
	_end("rain", false, true, 0.6)


## Brisa leve: ruído grave em rajadas lentas (ciclos inteiros no loop de 8 s) e um assobio fraquinho.
func _build_breeze() -> void:
	_begin(8.6)
	var n := _w.size()
	var b := 0.0
	for i in n:
		b = b * 0.995 + randf_range(-1.0, 1.0) * 0.05
		_w[i] = b
	_w = _biquad(_biquad(_w, "lp", 650.0, 0.7), "hp", 70.0, 0.7)
	var hiss := PackedFloat32Array()
	hiss.resize(n)
	for i in n:
		hiss[i] = randf_range(-1.0, 1.0)
	hiss = _biquad(hiss, "bp", 900.0, 3.0)
	for i in n:
		var t := float(i) / RATE
		var gust := 0.55 + 0.3 * sin(TAU * t / 8.0) + 0.15 * sin(TAU * t * 3.0 / 8.0 + 1.3)
		_w[i] = _w[i] * gust + hiss[i] * 0.05 * gust * gust
	_loopify(0.6)
	_end("breeze", false, true, 0.6)


## Grilos: um coro de grilos em distâncias diferentes, cada um com seu tom e seu ritmo. Cada "cri" tem de 3 a 5
## sílabas curtas e ásperas (o raspar da asa), com o tom caindo um pouco; ao fundo, um trilo contínuo bem longe.
func _build_crickets() -> void:
	var L := 8.4
	_begin(L)
	var amps := [1.0, 0.6, 0.4, 0.3, 0.2]
	for c in amps.size():
		var f := randf_range(3900.0, 5100.0)
		var syl := randi_range(3, 5)
		var gap := randf_range(0.028, 0.036)
		var every := randf_range(0.38, 0.75)
		var t := randf() * every
		while t < L - 0.3:
			for s in syl:
				_cricket_syllable(t + s * gap, f, 0.02, float(amps[c]) * randf_range(0.8, 1.0))
			t += every * randf_range(0.9, 1.12)
	# grilos de trilo: "criiiiii" de 1,5 a 4 s (pulsos rápidos, ~40 por segundo), pausa, e de novo
	for tr in [[3800.0, 38.0, 0.55], [4400.0, 46.0, 0.35]]:
		var t := randf() * 1.0
		while t < L - 0.5:
			var len := minf(randf_range(1.5, 4.0), L - 0.2 - t)
			var p := 1.0 / float(tr[1])
			var k := 0.0
			while k < len:
				var fade := minf(1.0, minf(k / 0.3, (len - k) / 0.3))
				_cricket_syllable(t + k, tr[0], p * 0.6, float(tr[2]) * fade)
				k += p
			t += len + randf_range(0.5, 2.0)
	_w = _biquad(_biquad(_w, "lp", 7000.0, 0.7), "hp", 2500.0, 0.7)
	_loopify(0.4)
	_end("crickets", false, true, 0.5)


## Uma sílaba de grilo: ataque curto, tom caindo um pouco, final mais lento.
func _cricket_syllable(at: float, f: float, dur: float, g: float) -> void:
	var s0 := int(at * RATE)
	var ph := randf()
	for i in int(dur * RATE):
		if s0 + i >= _w.size():
			break
		var t := float(i) / RATE
		var k := t / dur
		ph += f * (1.01 - 0.02 * k) / RATE
		var env := minf(1.0, t / 0.003) * pow(1.0 - k, 0.8)
		_w[s0 + i] += sin(TAU * ph) * env * g


## Coruja ao longe: "hu... hu-hu... huuu" (ou só "hu... huuu"), grave, soprado, com eco.
func _build_owl(v: int) -> void:
	_begin(2.4)
	var hoots := [[0.0, 0.32], [0.55, 0.16], [0.78, 0.16], [1.05, 0.55]] if v == 0 else [[0.0, 0.42], [0.7, 0.55]]
	for h in hoots:
		var s0 := int(float(h[0]) * RATE)
		var dur: float = h[1]
		var ph := 0.0
		for i in int(dur * RATE):
			var k := float(i) / (dur * RATE)
			ph += lerpf(395.0, 350.0, k) / RATE
			var env := pow(sin(PI * k), 1.5)
			_w[s0 + i] += (sin(TAU * ph) + 0.25 * sin(TAU * ph * 2.0) + randf_range(-0.15, 0.15)) * env
	_w = _biquad(_w, "lp", 900.0, 0.7)
	var d := int(0.14 * RATE)
	for i in range(d, _w.size()):
		_w[i] += _w[i - d] * 0.25
	_end("owl_%d" % v, false, false, 0.7)


## Campainha antiga, "trrrim-trrrim": o martelinho bate 20 vezes por segundo em cada campânula, alternando.
## Cada batida realimenta os modos de vibração do metal (ressonadores afinados), então o som vai se somando
## e fica áspero.
func _build_ring() -> void:
	_begin(1.8)
	var n := _w.size()
	var hits := [PackedFloat32Array(), PackedFloat32Array()]
	for h: PackedFloat32Array in hits:
		h.resize(n)
		h.fill(0.0)
	for burst in [0.0, 0.6]:
		var k := 0
		while k * 0.025 < 0.4:
			var i := int((burst + k * 0.025 + randf() * 0.002) * RATE)
			hits[k % 2][i] = randf_range(0.8, 1.0)
			k += 1
	for g in 2:
		for m: Vector3 in BELL_MODES:
			var y := _resonator(hits[g], GONGS[g] * m.x, m.z)
			for i in n:
				_w[i] += y[i] * m.y
	# o estalo do martelinho no metal
	var click := PackedFloat32Array()
	click.resize(n)
	for i in n:
		click[i] = (hits[0][i] + hits[1][i]) * randf_range(-1.0, 1.0)
	click = _biquad(click, "hp", 3000.0, 0.7)
	for i in n:
		_w[i] += click[i] * 0.05
	_end("ring")


## Ressonador de dois polos: `x` excita um modo de frequência `f` que decai em `tau` segundos.
func _resonator(x: PackedFloat32Array, f: float, tau: float) -> PackedFloat32Array:
	var r := exp(-1.0 / (tau * RATE))
	var c := 2.0 * r * cos(TAU * f / RATE)
	var s := sin(TAU * f / RATE)   # normaliza: cada batida vira uma senoide de amplitude ~1
	var r2 := r * r
	var y := PackedFloat32Array()
	y.resize(x.size())
	var y1 := 0.0
	var y2 := 0.0
	for i in x.size():
		var v := x[i] + c * y1 - r2 * y2
		y2 = y1
		y1 = v
		y[i] = v * s
	return y
