class_name SfxSynth
extends RefCounted
## A síntese de todos os sons do jogo (`build`): receitas de ondas, ruído filtrado, ressonâncias e vozes por sílaba,
## convertidas em `AudioStreamWAV`. Quem toca, mixa e cuida do ambiente é o autoload `Sfx`, que chama `build` ao
## iniciar (cerca de 0,6 s num Mac recente, uma vez).

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
## Toque da mesa: "bi-bip" suave (a campainha de metal antiga incomodava). Frequência (Hz), duração e intervalo
## de cada bipe (s), quantos bipes.
const BEEP := {"f": 740.0, "dur": 0.13, "gap": 0.09, "count": 2}
## Impressora do cartão: colunas de agulhas por segundo (o "zzrt" com tom) e passos por segundo do motor do papel.
const PRINTER_COLS := 1150.0
const PRINTER_STEPS := 230.0

var streams := {}   ## id -> AudioStreamWAV
var _w := PackedFloat32Array()   ## o som sendo montado (`_begin` ... `_end`)


## Todos os sons, por id.
static func build() -> Dictionary:
	var s := SfxSynth.new()
	s._build_all()
	return s.streams


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
	_build_clock()
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
	# o fio terminando de entrar no buraco: um "tec" seco
	_begin(0.06); _noise(0, 0.015, "bp", 2200, 1.5, 1.0); _tone(0, 320, 0.03, "sine", 0.5); _end("cord_stop")
	# o fio caindo na mesa: "tap" macio e abafado
	_begin(0.09); _noise(0, 0.03, "lp", 700, 0.7, 1.0); _tone(0, 110, 0.05, "sine", 0.5); _end("cord_tap")
	# plug solto batendo na mesa
	_begin(0.14); _noise(0, 0.05, "lp", 1800, 0.7, 1.0); _tone(0, 150, 0.1, "sine", 0.6); _tone(0.005, 2100, 0.015, "square", 0.06); _end("drop")
	_build_rub()
	_build_unroll()
	_build_card()
	_begin(0.55)
	for k in 12:
		if randf() < 0.7:
			_noise(k * 0.04, 0.05, "bp", randf_range(1500, 4000), 0.8, randf())
	_end("static")
	# a situação da emergência mudou de estágio: chiado curto e dois bipes de rádio
	_begin(0.42)
	_noise(0, 0.13, "bp", 2400, 0.7, 0.9)
	_tone(0.15, 1150, 0.08, "square", 0.5); _tone(0.28, 1150, 0.1, "square", 0.5)
	_end("radio_alert", true)
	_begin(0.08); _noise(0, 0.06, "bp", 2600, 1, 1.0); _end("crackle")
	# 3 variações de entonação por vogal: descendo, reta, subindo.
	for v in VOICE:
		for vw in VOWEL:
			for k in 3:
				_syllable(v, vw, [-0.12, 0.0, 0.10][k], k == 0)
	_build_car()
	_build_car(true)
	_build_thunder()
	_build_neon()
	_build_bell()
	_build_outside()
	_build_lamp()
	# ambientes em loop
	_build_rain()
	_build_breeze()
	_build_crickets()
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

## Um carro passando lá fora: o motor grave caindo de tom ao passar (efeito Doppler) e o chiado dos pneus no asfalto,
## crescendo e sumindo. `wet`: na chuva, os pneus jogam água, um chiado agudo que ondula por cima de tudo.
func _build_car(wet := false) -> void:
	var L := 3.2
	_begin(L)
	var n := _w.size()
	var tires := PackedFloat32Array()
	tires.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += 52.0 * (1.08 - 0.16 * t / L) / RATE
		_w[i] = _wave("saw", ph) * 0.6 + sin(TAU * ph * 2.0) * 0.3
		tires[i] = randf_range(-1.0, 1.0)
	_w = _biquad(_w, "lp", 380.0, 0.7)
	tires = _biquad(_biquad(tires, "lp", 1400.0, 0.7), "hp", 200.0, 0.7)
	var water := PackedFloat32Array()
	if wet:
		water.resize(n)
		for i in n:
			water[i] = randf_range(-1.0, 1.0)
		water = _biquad(_biquad(water, "hp", 1800.0, 0.7), "lp", 7000.0, 0.7)
	for i in n:
		var env := pow(sin(PI * float(i) / n), 2.0)
		_w[i] = (_w[i] * 0.7 + tires[i] * 0.9) * env
		if wet:
			var t := float(i) / RATE
			_w[i] = _w[i] * 0.7 + water[i] * 1.1 * pow(sin(PI * float(i) / n), 1.5) * (0.7 + 0.3 * sin(TAU * 6.0 * t + sin(TAU * 1.3 * t)))
	_end("car_wet" if wet else "car")


## O neon do hotel falhando, do outro lado da rua: o estalo do reator e o zumbido de 120 Hz, abafados pela distância
## (sem os agudos, com o ataque macio) e com o eco curto das fachadas da rua chegando depois.
func _build_neon() -> void:
	_begin(0.4)
	var n := _w.size()
	var dry := PackedFloat32Array()
	dry.resize(n)
	dry.fill(0.0)
	for i in int(0.16 * RATE):
		var t := float(i) / RATE
		var env := (1.0 - exp(-t / 0.008)) * exp(-t / 0.05)
		dry[i] = (randf_range(-1.0, 1.0) * 0.6 + _wave("saw", 120.0 * t) * 0.5) * env
	dry = _biquad(_biquad(dry, "lp", 900.0, 0.7), "lp", 900.0, 0.7)
	var echo := int(0.085 * RATE)   # o eco nas fachadas (~15 m de ida e volta)
	for i in n:
		_w[i] = dry[i] + (dry[i - echo] * 0.35 if i >= echo else 0.0) + (dry[i - echo * 2] * 0.12 if i >= echo * 2 else 0.0)
	_end("neon")


## O sino da igreja, no fim da rua: os parciais de um sino de bronze (o "hum" uma oitava abaixo, o principal, a terça
## menor, a quinta, o nominal e os agudos, cada um sumindo no seu tempo) com a pancada do badalo, abafados pela
## distância e com o eco da rua.
func _build_bell() -> void:
	_begin(4.5)
	var f := 392.0
	var parts := [Vector3(0.5, 0.5, 3.6), Vector3(1.0, 0.8, 2.6), Vector3(1.19, 0.55, 2.1), Vector3(1.5, 0.3, 1.6),
		Vector3(2.0, 0.6, 1.3), Vector3(2.52, 0.25, 0.8), Vector3(3.0, 0.15, 0.5)]   # (relação, força, quanto dura)
	var amp := PackedFloat32Array()
	var fall := PackedFloat32Array()
	var step := PackedFloat32Array()
	for p: Vector3 in parts:
		amp.append(p.y)
		fall.append(exp(-1.0 / (p.z * RATE)))   # o decaimento por amostra (sem `exp` a cada uma)
		step.append(TAU * f * p.x / RATE)
	for i in _w.size():
		var v := 0.0
		for k in parts.size():
			v += sin(step[k] * i) * amp[k]
			amp[k] *= fall[k]
		_w[i] = v * minf(1.0, i / (0.004 * RATE))
	_noise(0.0, 0.05, "bp", 2400.0, 1.0, 0.6)   # o badalo
	_w = _biquad(_biquad(_w, "lp", 1700.0, 0.7), "lp", 2200.0, 0.7)
	var echo := int(0.14 * RATE)
	for i in range(_w.size() - 1, echo - 1, -1):
		_w[i] += _w[i - echo] * 0.28
	_end("bell", false, false, 0.85)


## A chuva e a rua de perto da janela: o pingo da calha no peitoril de fora, as gotas batendo no vidro (em loop), o
## vidro e a persiana chocalhando no trovão perto, e os passos de quem passa na calçada de lá, seco ou molhado (de
## longe: sem os agudos).
func _build_outside() -> void:
	_begin(0.16)   # o pingo: um "plic" que cai de tom depressa
	var ph := 0.0
	for i in _w.size():
		var t := float(i) / RATE
		ph += (900.0 + 700.0 * exp(-t / 0.012)) / RATE
		_w[i] = sin(TAU * ph) * exp(-t / 0.035)
	_noise(0.0, 0.01, "hp", 3000.0, 0.7, 0.3)
	_end("drip")
	_begin(4.4)   # as gotas no vidro: batidinhas agudas e espalhadas
	var n := _w.size()
	var taps := PackedFloat32Array()
	taps.resize(n)
	taps.fill(0.0)
	for k in int(4.4 * 38):
		taps[randi() % n] += (1.0 if randf() < 0.5 else -1.0) * randf_range(0.2, 1.0)
	var hi := _biquad(taps, "bp", 4200.0, 1.6)
	var lo := _biquad(taps, "bp", 1900.0, 3.0)
	for i in n:
		_w[i] = hi[i] * 1.2 + lo[i] * 0.8 + randf_range(-1.0, 1.0) * 0.02
	_loopify(0.3)
	_end("rain_glass", false, true, 0.6)
	_begin(0.9)   # o chocalho: estalinhos rápidos, crescendo e sumindo com o ronco
	var t0 := 0.0
	while t0 < 0.8:
		var g := sin(PI * t0 / 0.8) * randf_range(0.5, 1.0)
		_noise(t0, 0.012, "bp", randf_range(2200.0, 3400.0), 2.0, g)
		_noise(t0, 0.02, "bp", 900.0, 4.0, g * 0.4)
		t0 += randf_range(0.015, 0.04)
	_end("rattle")
	for wet in [false, true]:   # os passos
		_begin(0.2)
		_noise(0.0, 0.06, "lp", 280.0, 0.7, 1.0)
		_noise(0.0, 0.03, "bp", 1500.0, 1.0, 0.35)
		if wet:
			_noise(0.01, 0.12, "hp", 2200.0, 0.7, 0.45)
		_w = _biquad(_w, "lp", 2600.0, 0.7)
		_end("step_wet" if wet else "step")


## A luminária: o zumbido elétrico bem baixo da lâmpada acesa (120 Hz e harmônicos, em loop) e o estalo de quando ela
## pisca.
func _build_lamp() -> void:
	_begin(1.0)   # 120 ciclos inteiros: o loop fecha sem emenda
	for i in _w.size():
		var t := float(i) / RATE
		_w[i] = _wave("saw", 120.0 * t) * 0.5 + sin(TAU * 240.0 * t) * 0.3 + sin(TAU * 360.0 * t) * 0.1
	_w = _biquad(_w, "lp", 1400.0, 0.7)
	_end("lamp_buzz", false, true, 0.5)
	_begin(0.06)
	_noise(0.0, 0.02, "hp", 2500.0, 0.7, 0.8)
	_tone(0.0, 60.0, 0.04, "sine", 0.4)
	_end("lamp_tick")


## Trovão de longe: um estalo abafado e o ronco grave rolando, em ondas, até sumir.
func _build_thunder() -> void:
	var L := 6.0
	_begin(L)
	var b := 0.0
	for i in _w.size():
		var t := float(i) / RATE
		b = b * 0.985 + randf_range(-1.0, 1.0) * 0.06
		var roll := 0.65 + 0.35 * sin(TAU * t * 0.9 + sin(TAU * t * 0.37) * 2.0)
		_w[i] = b * (1.0 - exp(-t / 0.12)) * exp(-t / 2.0) * roll
	_w = _biquad(_biquad(_w, "lp", 220.0, 0.7), "hp", 25.0, 0.7)
	_noise(0.02, 0.5, "lp", 1100.0, 0.7, 0.25)
	_end("thunder", false, false, 0.9)


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


## Mapa de papel desenrolando (ao abrir a aba do mapa): estalinhos do papel se soltando, cada vez mais espaçados,
## sobre um "fffff" de folha deslizando, e a folha assentando na mesa no fim.
func _build_unroll() -> void:
	_begin(0.8)
	var t := 0.0
	while t < 0.55:
		_noise(t, randf_range(0.004, 0.012), "bp", randf_range(2500.0, 5500.0), 2.0, randf_range(0.25, 0.8) * (1.0 - t / 0.7))
		t += randf_range(0.006, 0.012) + t * 0.05
	var slide := PackedFloat32Array()   # deslizar: ruído que cresce e some
	slide.resize(int(0.55 * RATE))
	for i in slide.size():
		var k := float(i) / slide.size()
		slide[i] = randf_range(-1.0, 1.0) * 0.35 * sin(PI * k)
	slide = _biquad(slide, "bp", 1800.0, 0.7)
	for i in slide.size():
		_w[i] += slide[i]
	_noise(0.56, 0.1, "lp", 800, 0.7, 0.8)   # a folha assenta
	_tone(0.56, 120, 0.08, "sine", 0.35)
	_end("unroll")


## Ficha de despacho (`CardMachines`): a impressora datilografa o local ("typing"), imprime o cartão numa impressora de
## agulhas ("printer": linhas de zumbido áspero e o avanço do papel entre elas), o furador ("punch"), o cartucho
## puxando o cartão ("feed": motor subindo e o papel raspando), o leitor do transmissor lendo os furos coluna a coluna
## enquanto o cartão entra ("read": "tec tec" seco e regular, e dois no fim), a impressora recusando outro cartão
## com um já na mesa ("deny": dois bipes graves) e a trituradora ("shred": motor grave roncando e o
## papel rasgando aos trancos).
func _build_card() -> void:
	_begin(0.95)
	var t := 0.0
	while t < 0.85:
		_noise(t, 0.012, "bp", randf_range(2600.0, 3600.0), 1.5, randf_range(0.6, 1.0))
		_tone(t, randf_range(160.0, 210.0), 0.035, "sine", 0.45)
		t += randf_range(0.055, 0.1)
	_end("typing")
	# impressora matricial: cada batida de agulha é um impulso que faz soar o metal da agulha e o rolo; o motor de
	# passo puxa o papel aos "tk" regulares; tudo ressoa na carcaça
	_begin(1.4)
	var hits := PackedFloat32Array()
	hits.resize(_w.size())
	t = 0.03
	var word := randi_range(2, 7)
	while t < 1.22:
		for col in 7:   # um caractere: colunas de agulhas (algumas das 9 em cada), a última vazia
			var i := int((t + randf_range(0.0, 0.00015)) * RATE)
			hits[i] += (randi_range(1, 7) if col < 6 and randf() < 0.85 else 0) / 9.0
			t += 1.0 / PRINTER_COLS
		word -= 1
		if word == 0:   # espaço entre palavras: a cabeça anda sem bater
			t += randi_range(1, 2) * 7.0 / PRINTER_COLS
			word = randi_range(2, 7)
	var steps := PackedFloat32Array()
	steps.resize(_w.size())
	t = 0.0
	while t < 1.27:
		steps[int(t * RATE)] = 1.0
		t += 1.0 / (PRINTER_STEPS * minf(0.4 + t / 0.12, 1.0))   # o motor embala no começo
	steps[int(1.29 * RATE)] = 2.0   # o rolo solta o cartão
	var x := _modes(hits, [[3100.0, 0.0015, 0.5], [4700.0, 0.001, 0.3], [190.0, 0.006, 0.6]])
	var feed := _modes(steps, [[850.0, 0.004, 0.5], [140.0, 0.012, 0.7]])
	for i in x.size():
		x[i] += feed[i] * 0.45
	var box := _modes(x, [[1.0, 0.0, 1.0], [320.0, 0.025, 0.3], [1200.0, 0.012, 0.2]])   # a carcaça
	for i in box.size():
		var ts := float(i) / RATE
		_w[i] = box[i] * minf(ts / 0.02, 1.0) * clampf((1.38 - ts) / 0.06, 0.0, 1.0)
	_end("printer")
	_begin(0.12)
	_noise(0, 0.012, "hp", 2500.0, 0.7, 1.0); _tone(0, 150.0, 0.07, "sine", 0.8); _tone(0.002, 2600.0, 0.01, "square", 0.15)
	_end("punch")
	_begin(0.85)
	var ph := 0.0
	for i in int(0.7 * RATE):
		var ts := float(i) / RATE
		ph += (110.0 + 90.0 * minf(ts / 0.15, 1.0)) / RATE
		var env := minf(ts / 0.05, 1.0) * minf((0.7 - ts) / 0.1, 1.0)
		_w[i] = (_wave("saw", ph) * 0.25 + randf_range(-1.0, 1.0) * 0.35) * env
	_w = _biquad(_w, "lp", 1800.0, 0.7)
	_noise(0.7, 0.05, "bp", 1200.0, 1.0, 0.8); _tone(0.7, 130.0, 0.06, "sine", 0.5)   # o cartão assenta
	_end("feed")
	_begin(1.1)
	t = 0.05
	while t < 0.8:
		_noise(t, 0.01, "bp", 3200.0, 2.0, 0.8); _tone(t, 900.0, 0.012, "square", 0.25)
		t += 0.065
	for k in 2:
		_noise(0.92 + k * 0.08, 0.012, "bp", 2600.0, 2.0, 1.0); _tone(0.92 + k * 0.08, 600.0, 0.02, "square", 0.35)
	_end("read")
	_begin(0.3)
	_tone(0, 170.0, 0.11, "square", 0.4); _tone(0.15, 170.0, 0.11, "square", 0.4)
	_w = _biquad(_w, "lp", 1200.0, 0.7)
	_end("deny")
	_begin(1.4)
	ph = 0.0
	for i in int(1.3 * RATE):
		var ts := float(i) / RATE
		ph += (62.0 + 6.0 * sin(ts * 23.0)) / RATE   # o motor roncando, com as lâminas pegando
		var env := minf(ts / 0.08, 1.0) * minf((1.3 - ts) / 0.15, 1.0)
		_w[i] = (_wave("saw", ph) * 0.5 + _wave("square", ph * 2.0) * 0.15) * env
	_w = _biquad(_w, "lp", 700.0, 0.7)
	t = 0.08
	while t < 1.1:   # o papel rasgando aos trancos
		_noise(t, randf_range(0.03, 0.07), "bp", randf_range(1800.0, 4200.0), 0.9, randf_range(0.4, 0.9))
		t += randf_range(0.03, 0.08)
	_end("shred")


## Atrito do fio na borda do buraco: dois loops que tocam juntos (`cord_rub` controla o volume de cada um).
## - "rub", o fio: prende e escorrega ("agarra e solta"), estalos médios bem juntos que viram um zumbido áspero,
##   sobre um corpo grave contínuo.
## - "rub_hi", o agudo: brilho de fibras raspando e o rangido de corda esfregada (o agarra-e-solta em ritmo quase
##   regular faz a corda vibrar, como um arco). Some quando o fio passa devagar.
## Os dois saem com o mesmo ganho, como se fossem um som só.
func _build_rub() -> void:
	_begin(1.4)
	var t := 0.0
	while t < 1.39:   # agarra e solta
		_noise(t, randf_range(0.008, 0.016), "bp", randf_range(1550.0, 2850.0), 1.2, randf_range(0.5, 1.0))
		t += randf_range(0.005, 0.010)
	var body := PackedFloat32Array()   # corpo
	body.resize(_w.size())
	for i in body.size():
		body[i] = randf_range(-0.6, 0.6)
	body = _biquad(body, "lp", 920.0, 0.8)
	for i in _w.size():
		_w[i] += body[i]
	var cord := _w

	_begin(1.4)
	t = 0.0
	while t < 1.39:   # fibras
		_noise(t, 0.06, "bp", randf_range(1700.0, 5700.0), 2.0, randf_range(0.08, 0.25))
		t += randf_range(0.003, 0.008)
	# rangido: pulsos quase regulares (o ritmo e a força variam devagar, em trechos que vêm e vão) que fazem
	# soar duas ressonâncias curtas
	var creak := PackedFloat32Array()
	creak.resize(_w.size())
	var rate := 220.0
	var amp := 0.5
	var i := 0
	while i < creak.size():
		creak[i] = amp * randf_range(0.7, 1.0)
		rate = clampf(rate + randf_range(-20.0, 20.0), 170.0, 290.0)
		amp = clampf(amp + randf_range(-0.04, 0.04), 0.1, 1.0)
		i += int(RATE / rate * randf_range(0.92, 1.08))
	var ring_a := _resonator(creak, 2500.0, 0.003)
	var ring_b := _resonator(creak, 3700.0, 0.002)
	for k in _w.size():
		_w[k] += (ring_a[k] + ring_b[k] * 0.6) * 0.35
	var hi := _w

	# mesmo ganho nos dois: cada um sai com o pico que teria dentro da mistura
	var layers := {"rub": cord, "rub_hi": hi}
	for id in layers:
		_w = _biquad(layers[id], "lp", 8000.0, 0.7)
		_loopify(0.2)
		layers[id] = _w
	var mix := 0.0001
	for k in mini(layers["rub"].size(), layers["rub_hi"].size()):
		mix = maxf(mix, absf(layers["rub"][k] + layers["rub_hi"][k]))
	for id in layers:
		_w = layers[id]
		var own := 0.0001
		for v in _w:
			own = maxf(own, absf(v))
		_end(id, false, true, 0.8 * own / mix)


## Toque da mesa: bipes curtos de seno (com um pouco do 2º e 3º harmônicos, para não soar eletrônico demais),
## ataque e saída suaves (sem estalo) e um passa-baixa que tira o agudo.
func _build_ring() -> void:
	var step: float = BEEP.dur + BEEP.gap
	_begin(step * BEEP.count)
	for b in BEEP.count:
		var s0 := int(b * step * RATE)
		for i in int(BEEP.dur * RATE):
			var t := float(i) / RATE
			var env := minf(1.0, minf(t / 0.012, (BEEP.dur - t) / 0.05))
			var f: float = BEEP.f
			_w[s0 + i] = (sin(TAU * f * t) + 0.2 * sin(TAU * 2.0 * f * t) + 0.08 * sin(TAU * 3.0 * f * t)) * env
	_w = _biquad(_w, "lp", 2400.0, 0.7)
	_end("ring")


## O relógio da sala: a badalada de gongo de mola a cada hora cheia ("chime": a batida do martelo excita os modos
## inarmônicos do arame enrolado, que soam longos) e a campainha de latão quando o turno pode ser encerrado
## ("shift_bell": duas batidas rápidas, agudas e curtas).
func _build_clock() -> void:
	_begin(2.6)
	var hit := PackedFloat32Array()
	hit.resize(_w.size())
	hit[0] = 1.0
	_w = _modes(hit, [[247.0, 1.5, 1.0], [662.0, 0.7, 0.4], [1270.0, 0.35, 0.18], [2080.0, 0.12, 0.08]])
	_noise(0, 0.012, "bp", 3000, 1, 0.3)   # o martelo
	_end("chime")
	_begin(1.3)
	var hits := PackedFloat32Array()
	hits.resize(_w.size())
	hits[0] = 1.0
	hits[int(0.17 * RATE)] = 0.8
	_w = _modes(hits, [[1480.0, 0.5, 1.0], [3720.0, 0.15, 0.35], [6150.0, 0.05, 0.12]])
	_end("shift_bell")


## Soma de modos de vibração excitados por `x`: cada um [frequência, decaimento (s), ganho], normalizado pelo pico
## (frequência 1 com decaimento 0 = o próprio `x`).
func _modes(x: PackedFloat32Array, modes: Array) -> PackedFloat32Array:
	var y := PackedFloat32Array()
	y.resize(x.size())
	for m in modes:
		var r := x if m[1] == 0.0 else _resonator(x, m[0], m[1])
		var top := 0.0001
		for v in r:
			top = maxf(top, absf(v))
		for i in r.size():
			y[i] += r[i] * m[2] / top
	return y


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
