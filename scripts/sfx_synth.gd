class_name SfxSynth
extends RefCounted
## A síntese de todos os sons do jogo (`build`): receitas de ondas, ruído filtrado, ressonâncias e vozes por sílaba,
## convertidas em `AudioStreamWAV`. Quem toca, mixa e cuida do ambiente é o autoload `Sfx`, que chama `build` ao
## iniciar, uma vez: as receitas em pedaços (`PARTS`), montados ao mesmo tempo nos núcleos do processador (~0,9 s num
## Mac recente um depois do outro).

const RATE := 22050
# Vozes: cada vogal vira uma sílaba sintetizada (fonte glotal + formantes).
# f0 = altura, breath = sopro, dur = duração da sílaba, bus = por onde toca, tract = o tamanho da boca (os formantes
# multiplicados: a mulher e a criança com as ressonâncias mais altas que as do homem; antes todas iguais às dele).
# As do telefone (bus "Phone") ganham a banda da linha no barramento (default_bus_layout.tres: distorção do microfone
# de carvão, 300–3400 Hz, pico em 2 kHz); as outras levam o filtro na própria sílaba: muffle = corte do passa-baixa
# (quanto menor, mais abafado).
const VOICE := {
	"f": {"f0": 225.0, "breath": 0.10, "dur": 0.13, "tract": 1.15, "db": -7.0, "bus": &"Phone"},
	"m": {"f0": 118.0, "breath": 0.08, "dur": 0.14, "tract": 1.0, "db": -6.0, "bus": &"Phone"},
	"k": {"f0": 320.0, "breath": 0.06, "dur": 0.11, "tract": 1.25, "db": -9.0, "bus": &"Phone"},
	"w": {"f0": 140.0, "breath": 0.45, "dur": 0.14, "tract": 0.97, "db": -8.0, "bus": &"Phone"},
	"g": {"f0": 92.0, "breath": 0.30, "muffle": 700.0, "dur": 0.21, "tract": 0.92, "db": -5.0, "bus": &"Voices"},
	"r": {"f0": 135.0, "breath": 0.18, "muffle": 2300.0, "dur": 0.12, "tract": 1.0, "db": -11.0, "bus": &"Voices"},
}
## Formantes (F1, F2, F3) aproximados das vogais do português, em cadeia (`_formant`, como os sintetizadores de
## formantes), com as larguras de banda (Hz) da fala, e F4 (Hz, largura) igual em todas, o brilho. (Antes eram F1 e F2
## em paralelo e um 2600 Hz fixo: o "e" e o "i", o "o" e o "u" se confundiam.)
const VOWEL := {"a": Vector3(780, 1250, 2600), "e": Vector3(480, 1850, 2550), "i": Vector3(310, 2250, 3000),
	"o": Vector3(500, 880, 2500), "u": Vector3(350, 720, 2400)}
const BANDWIDTHS := Vector3(90, 110, 170)
const F4 := Vector2(3500, 250)
## Vogal nasal ("ã", "õ", "am", "em"...): o F1 vezes `f1` e com a largura vezes `f1_width`, e o ressoar do nariz em
## `hz` (logo acima do corte de 300 Hz do telefone) com o ganho `gain`.
const NASAL := {"f1": 0.8, "f1_width": 2.0, "hz": 320.0, "gain": 0.6}
## A fonte da voz: o pulso glotal de Rosenberg (fração do período abrindo, x, e fechando, y; a derivada, como sai da
## boca) e o quanto cada ciclo varia de período e de força (jitter e shimmer), como uma garganta e não um oscilador.
## O sopro é mais forte com a glote aberta.
const GLOTTIS := Vector2(0.4, 0.16)
const CYCLE_JITTER := 0.01
const CYCLE_SHIMMER := 0.06
## O pico da vogal entrando no filtro da voz (`_voice_line`), o nível que a sílaba tinha antes da cadeia de formantes:
## a saturação do rádio depende dele (100 vezes mais forte, cortava tudo numa onda quadrada e a voz ficava estridente).
const LEVEL := 0.4
## A tônica e a última sílaba da frase mais longas (cada vogal também gravada com a duração vezes LONG, `Sfx._long`).
const LONG := 1.35
## O silêncio antes de cada vogal, onde entra o ataque da consoante (`_attack`), e o pico de cada ataque (a vogal tem 0,8).
const LEAD := 0.045
const ATTACKS := {"stop": 0.35, "fric": 0.2, "nasal": 0.3}
## Toque da mesa: "bi-bip" suave (a campainha de metal antiga incomodava). Frequência (Hz), duração e intervalo
## de cada bipe (s), quantos bipes.
const BEEP := {"f": 740.0, "dur": 0.13, "gap": 0.09, "count": 2}
## Impressora do cartão: colunas de agulhas por segundo (o "zzrt" com tom) e passos por segundo do motor do papel.
const PRINTER_COLS := 1150.0
const PRINTER_STEPS := 230.0
## A chuva do lado esquerdo, em relação ao direito: a janela fica à direita da tela (0,4 = 8 dB mais baixo).
const RAIN_LEFT := 0.4

## Os pedaços das receitas ([função, argumentos...]), cada um montado sozinho numa instância (`build`; mais as vozes,
## uma por pedaço); os mais pesados (a chuva, a brisa, o fio, os grilos, os carros, o sino) ficam em pedaços próprios
## para se dividirem entre os núcleos.
const CAR_PEAK := 0.58   ## onde fica o mais alto da passagem do carro (fração da duração): chega devagar, some rápido
const WET_SWEEP := Vector2(3000, 1000)   ## o chiado do pneu molhado, chegando e indo embora (Hz, o centro do filtro)
const WET_TOP := 4000.0   ## acima disso, a janela fechada abafa (como na chuva)
const WET_SPLASHES := Vector2i(2, 3)   ## as poças por onde o pneu passa (respingos)
const WET_NEAR := 1.25   ## o carro da mão de cá: o chiado e o corte dos agudos mais altos (mais claro)
const CAR_NEAR_SHARP := 1.8   ## o carro da mão de cá: a passagem mais concentrada no meio (expoente da curva)
const CAR_TAKES := 3   ## versões de cada carro, cada uma com o seu sorteio
const PARTS := [["_build_basic"], ["_build_ring"], ["_build_clock"], ["_build_rub"], ["_build_unroll"], ["_build_card"],
	["_build_thunder"], ["_build_bell"], ["_build_dog"], ["_build_dog", true], ["_build_outside"],
	["_build_lamp"], ["_build_rain"], ["_build_breeze"], ["_build_crickets"], ["_build_sabia"]]
## O sabiá-laranjeira do amanhecer (`_build_sabia`): quantas frases diferentes (cada uma uma versão do som, `sabia~N`),
## e o tom das notas (Hz, do mais grave ao mais agudo).
const SABIA_TAKES := 4
const SABIA_HZ := Vector2(1700.0, 3300.0)

var streams := {}   ## id -> AudioStreamWAV
var _w := PackedFloat32Array()   ## o som sendo montado (`_begin` ... `_end`)
var _near := false   # o carro sendo montado é o da mão de cá (`_build_car`)
var _rng := RandomNumberGenerator.new()   ## o sorteio desta instância (o global não é seguro entre linhas de execução)


## Todos os sons, por id. Cada pedaço (`PARTS`) numa instância própria, ao mesmo tempo (`WorkerThreadPool`); espera
## todos.
static func build() -> Dictionary:
	var jobs := []
	for take in CAR_TAKES:   # os carros, cada versão num pedaço, primeiro (são dos mais demorados)
		for wet in [false, true]:
			for near in [false, true]:
				jobs.append(["_build_car", wet, near, take])
	jobs.append_array(PARTS)
	for v in VOICE:
		for long in [false, true]:   # (as curtas e as longas em pedaços próprios: as vozes são dos mais demorados)
			jobs.append(["_build_voice", v, long])
	var parts: Array[SfxSynth] = []
	for i in jobs.size():
		parts.append(SfxSynth.new())
		parts[i]._rng.seed = i + 1   # (cada pedaço com o seu ruído, sempre o mesmo)
	var task := WorkerThreadPool.add_group_task(func(i: int) -> void: parts[i].callv(jobs[i][0], jobs[i].slice(1)), jobs.size(),
		-1, true)   # (alta prioridade: as de baixa usam só parte dos núcleos)
	WorkerThreadPool.wait_for_group_task_completion(task)
	var out := {}
	for p in parts:
		out.merge(p.streams)
	return out


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
		x[i] = _rng.randf_range(-1.0, 1.0) * g * pow(0.0001, t / dur)
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


## `right`: o lado direito, num som em estéreo (`_w` é o esquerdo).
func _end(id: String, tel: bool = false, loop: bool = false, peak: float = 0.8, right := PackedFloat32Array()) -> void:
	if tel:
		_w = _biquad(_w, "bp", 1500.0, 0.75)
	var m := 0.0001
	for v in _w:
		m = maxf(m, absf(v))
	for v in right:
		m = maxf(m, absf(v))
	var k := peak / m
	var st := not right.is_empty()
	var step := 4 if st else 2
	var bytes := PackedByteArray()
	bytes.resize(_w.size() * step)
	for i in _w.size():
		bytes.encode_s16(i * step, int(clampf(_w[i] * k, -1.0, 1.0) * 32000.0))
		if st:
			bytes.encode_s16(i * step + 2, int(clampf(right[i] * k, -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = st
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = _w.size()
	streams[id] = s


## A vogal `vw` da voz `v` (`nasal`: "ã", "õ", "am", "em"...), com a curva de entonação `contour` (`long`: a duração
## vezes LONG). Começa depois de LEAD s de silêncio, o lugar do ataque da consoante (`_attack`), que toca junto com ela.
## A fonte é o pulso glotal (GLOTTIS) e o sopro, passando pelos formantes em cadeia (VOWEL, `_formant`).
func _syllable(v: String, vw: String, nasal: bool, contour: float, long: bool) -> void:
	var p: Dictionary = VOICE[v]
	var f0: float = p["f0"]
	var dur: float = p["dur"] * (LONG if long else 1.0)
	var breath: float = p["breath"]
	var tract: float = p["tract"]
	var fm: Vector3 = VOWEL[vw] * tract
	var n := int(dur * RATE)
	var src := PackedFloat32Array()   # o pulso (a derivada do fluxo pela glote)
	src.resize(n)
	var air := PackedFloat32Array()   # o sopro
	air.resize(n)
	var ph := _rng.randf()
	var r := _rng.randi()   # o ruído e a variação de cada ciclo sorteados aqui mesmo (ver `_passes`)
	var jit := 1.0
	var amp := 1.0
	var flow := 0.0
	var src_sq := 0.0
	var air_sq := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += f0 * (1.0 + contour * t / dur) * jit * (1.0 + 0.015 * sin(TAU * 5.5 * t)) / RATE
		if ph >= 1.0:   # um ciclo novo, um pouco diferente do anterior
			ph -= 1.0
			r = (r * 1103515245 + 12345) & 0x7fffffff
			jit = 1.0 + (r / 1073741823.5 - 1.0) * CYCLE_JITTER
			r = (r * 1103515245 + 12345) & 0x7fffffff
			amp = 1.0 + (r / 1073741823.5 - 1.0) * CYCLE_SHIMMER
		var g := 0.0
		if ph < GLOTTIS.x:
			g = 0.5 * (1.0 - cos(PI * ph / GLOTTIS.x))
		elif ph < GLOTTIS.x + GLOTTIS.y:
			g = cos(PI * (ph - GLOTTIS.x) / (2.0 * GLOTTIS.y))
		src[i] = g * amp - flow
		flow = g * amp
		r = (r * 1103515245 + 12345) & 0x7fffffff
		air[i] = (r / 1073741823.5 - 1.0) * (0.4 + g)
		src_sq += src[i] * src[i]
		air_sq += air[i] * air[i]
	var ks := (1.0 - breath) / sqrt(maxf(src_sq / n, 1e-12))   # os dois na mesma força média antes de misturar
	var ka := breath / sqrt(maxf(air_sq / n, 1e-12))
	for i in n:
		src[i] = (src[i] * ks + air[i] * ka) * pow(sin(PI * float(i) / n), 0.7)
	# nasal: o F1 mais baixo e largo e o ressoar do nariz embaixo (NASAL)
	var y := _formant(src, fm.x * (NASAL["f1"] if nasal else 1.0), BANDWIDTHS.x * (NASAL["f1_width"] if nasal else 1.0))
	y = _formant(_formant(_formant(y, fm.y, BANDWIDTHS.y), fm.z, BANDWIDTHS.z), F4.x * tract, F4.y)
	var m := PackedFloat32Array()
	var km := 0.0
	if nasal:
		m = _formant(src, NASAL["hz"], 100.0)
		km = NASAL["gain"] * _peak(y) / _peak(m)
	_begin(LEAD + dur + 0.04)
	var off := int(LEAD * RATE)
	for i in n:
		_w[off + i] = y[i] + (m[i] * km if nasal else 0.0)
	var k := LEVEL / _peak(_w)   # (a cadeia de formantes ganha 100 vezes ou mais)
	for i in _w.size():
		_w[i] *= k
	_voice_line(v)
	_end("s_%s_%s%s_%d%s" % [v, vw, "n" if nasal else "", [-0.12, 0.0, 0.10].find(contour), "l" if long else ""], false,
		false, 0.8)


## Um formante em `f` Hz com a largura de banda `bw` Hz: o `_resonator`, que decai em 1/(π·bw) s. Em cadeia, a
## força de cada formante sai como na fala, sem acertar ganhos à mão.
func _formant(x: PackedFloat32Array, f: float, bw: float) -> PackedFloat32Array:
	return _resonator(x, f, 1.0 / (PI * bw))


static func _peak(x: PackedFloat32Array) -> float:
	var m := 0.0001
	for v in x:
		m = maxf(m, absf(v))
	return m


## O ataque da consoante antes da vogal (`ATTACKS`), na voz `v`: termina em LEAD s, quando a vogal começa.
## "stop" (p, t, b, d...): a boca fechada e o estalo; "fric" (s, f, ch, j...): o chiado; "nasal" (m, n): o zumbido
## de boca fechada.
func _attack(v: String, kind: String) -> void:
	var f0: float = VOICE[v]["f0"]
	_begin(LEAD + 0.01)
	var n := int(LEAD * RATE)
	match kind:
		"stop":
			_noise(LEAD - 0.014, 0.014, "bp", 2000.0, 0.9, 1.0)
		"fric":
			var x := PackedFloat32Array()
			x.resize(n)
			for i in n:
				x[i] = _rng.randf_range(-1.0, 1.0) * sin(PI * float(i) / n)
			x = _biquad(x, "bp", 2900.0, 1.2)
			for i in n:
				_w[i] = x[i]
		"nasal":
			var ph := 0.0
			for i in n:
				ph += f0 / RATE
				_w[i] = sin(TAU * ph) * minf(1.0, float(i) / (n * 0.3))
			_w = _biquad(_w, "lp", 450.0, 0.7)
	_voice_line(v)
	_end("s_%s_%s" % [v, kind], false, false, ATTACKS[kind])


## O filtro de cada voz sobre `_w`: o abafado das que não vão pelo telefone (a voz do outro lado e o rádio: dois
## passa-baixas), o corte dos graves e o rádio saturado.
func _voice_line(v: String) -> void:
	var p: Dictionary = VOICE[v]
	if p.has("muffle"):
		var mf: float = p["muffle"]
		_w = _biquad(_biquad(_w, "lp", mf, 0.7), "lp", mf * 1.2, 0.7)
	_w = _biquad(_w, "hp", 160.0, 0.7)
	if v == "r":
		for i in _w.size():
			_w[i] = clampf(_w[i] * 40.0, -1.0, 1.0)
		_w = _biquad(_w, "bp", 1600.0, 0.9)


## Os sons da interface e da mesa, o chiado e o zumbido da sala.
func _build_basic() -> void:
	_begin(0.05); _tone(0, 1900, 0.02, "square", 0.3); _noise(0, 0.02, "bp", 4000, 1, 0.8); _end("click")
	_begin(0.06); _tone(0, 700, 0.03, "square", 0.3); _noise(0, 0.03, "bp", 2500, 1, 1.0); _end("sw")
	_begin(0.16); _noise(0, 0.06, "lp", 1400, 0.7, 1.0); _tone(0, 85, 0.12, "sine", 0.8); _tone(0.03, 1600, 0.02, "square", 0.08); _end("plug_in")
	_begin(0.08); _noise(0, 0.04, "bp", 3200, 1, 1.0); _tone(0, 240, 0.05, "sine", 0.35); _end("plug_out")
	_begin(0.05); _tone(0, 1100, 0.03, "square", 0.25); _noise(0, 0.02, "hp", 3000, 0.7, 0.5); _end("key")
	_begin(0.36); _noise(0, 0.28, "bp", 2400, 0.6, 1.0); _noise(0.2, 0.12, "lp", 600, 0.7, 0.8); _end("page")
	_begin(0.02); _tone(0, 3300, 0.008, "square", 0.3); _end("tick", false, false, 0.5)
	_begin(0.03); _noise(0, 0.012, "bp", 1800, 1, 0.7); _tone(0, 620, 0.008, "square", 0.15); _end("knob_tick")   # o anel do mapa: um sulco
	_begin(0.06); _noise(0, 0.025, "bp", 2800, 1.4, 1.0); _tone(0, 210, 0.02, "sine", 0.3); _end("snap", true)   # o estalo de dedos, pelo telefone
	# as fitas da B4: saindo da fenda do porta-fitas, batendo no gravador, a porta dele fechando, a tecla de piano e a mola da ejeção
	_begin(0.08); _noise(0, 0.06, "bp", 1800, 0.8, 0.5); _tone(0, 520, 0.02, "square", 0.08); _end("tape_out")
	_begin(0.12); _noise(0, 0.02, "bp", 2400, 1.5, 1.0); _tone(0, 330, 0.04, "sine", 0.4); _tone(0.004, 110, 0.07, "sine", 0.5); _end("tape_in")
	_begin(0.1); _tone(0, 900, 0.012, "square", 0.25); _noise(0, 0.02, "hp", 3000, 0.7, 0.6); _tone(0, 170, 0.06, "sine", 0.5); _end("tape_door")
	_begin(0.1); _tone(0, 140, 0.05, "sine", 0.6); _noise(0, 0.03, "lp", 1200, 0.7, 0.8); _tone(0, 620, 0.012, "square", 0.15); _end("tape_key")
	_begin(0.2); _noise(0, 0.015, "bp", 3200, 1.2, 0.7); _tone(0, 480, 0.15, "sine", 0.25); _tone(0.01, 720, 0.1, "sine", 0.12); _tone(0, 160, 0.05, "sine", 0.4); _end("tape_pop")
	_begin(1.1)
	for i in 14:
		_noise(i * 0.07 + _rng.randf() * 0.03, 0.05, "bp", 5200 + _rng.randf() * 1500, 3, 0.8)
	_end("pencil")
	_begin(0.03); _tone(0, 1300, 0.012, "square", 0.3); _noise(0, 0.012, "bp", 2500, 1, 0.6); _end("pulse", true)
	# chamando: "tuuuu" contínuo de 425 Hz, pela linha
	_begin(1.3)
	var on := 1.15
	for i in int(on * RATE):
		var t := float(i) / RATE
		var env := minf(1.0, minf(t / 0.03, (on - t) / 0.06))
		_w[i] = (sin(TAU * 425.0 * t) + 0.15 * sin(TAU * 850.0 * t) + _rng.randf_range(-0.02, 0.02)) * env
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
	# o fio parado agarrado na borda do buraco e soltando de uma vez: tranco abafado de pano com dois grãos de atrito
	_begin(0.08); _noise(0, 0.025, "bp", 900, 0.9, 1.0); _tone(0, 140, 0.04, "sine", 0.45)
	_noise(0.012, 0.012, "bp", 2300, 1.2, 0.5); _noise(0.026, 0.01, "bp", 1900, 1.2, 0.35); _end("cord_snag")
	# o puxão parando de repente: as fibras raspam um instante na borda, "tsk"
	_begin(0.06); _noise(0, 0.025, "bp", 3200, 1.3, 1.0); _noise(0.004, 0.018, "bp", 1600, 1.0, 0.5); _end("cord_snap")
	# o fio caindo na mesa: "tap" macio e abafado
	_begin(0.09); _noise(0, 0.03, "lp", 700, 0.7, 1.0); _tone(0, 110, 0.05, "sine", 0.5); _end("cord_tap")
	# plug solto batendo na mesa
	_begin(0.14); _noise(0, 0.05, "lp", 1800, 0.7, 1.0); _tone(0, 150, 0.1, "sine", 0.6); _tone(0.005, 2100, 0.015, "square", 0.06); _end("drop")
	# o objeto da mesa assentando depois de erguido sob o mouse: o papel, um "fft" curto e abafado...
	_begin(0.09); _noise(0, 0.05, "bp", 2600, 0.7, 0.7); _noise(0.01, 0.05, "lp", 500, 0.7, 1.0); _end("set_paper")
	# ...e o metal, um "tim" de chapa abafado
	_begin(0.16); _noise(0, 0.012, "bp", 3000, 1.2, 0.6); _tone(0, 1230, 0.12, "sine", 0.3); _tone(0, 2950, 0.05, "sine", 0.12); _tone(0, 130, 0.05, "sine", 0.5); _end("set_metal")
	# a persiana descendo: as lâminas batendo umas nas outras, cada vez mais juntas, e o trilho de baixo no peitoril
	_begin(1.45)
	for k in 22:
		var at := 1.3 * sqrt(k / 22.0)
		_noise(at, 0.02, "bp", _rng.randf_range(2200, 3600), 1.4, 0.35 + 0.4 * k / 22.0)
		_tone(at, _rng.randf_range(800, 1000), 0.015, "sine", 0.12)
	_noise(1.3, 0.06, "lp", 700, 0.7, 1.0); _tone(1.3, 120, 0.1, "sine", 0.6); _end("blind")
	# um gole de café: dois "glup" baixos e a caneca de volta na mesa, um tim de louça
	_begin(0.62)
	for at in [0.0, 0.2]:
		_tone(at, 240, 0.05, "sine", 0.45); _tone(at + 0.04, 170, 0.06, "sine", 0.35); _noise(at, 0.07, "lp", 500, 0.7, 0.3)
	_noise(0.5, 0.012, "bp", 2600, 1.4, 0.5); _tone(0.5, 2350, 0.08, "sine", 0.12); _tone(0.5, 3700, 0.04, "sine", 0.06); _end("gulp")
	# a porta do armário de aço: o trinco, a dobradiça rangendo um pouco e a chapa batendo de leve
	_begin(0.55)
	_noise(0, 0.015, "bp", 3200, 1.5, 0.8); _tone(0, 900, 0.03, "sine", 0.25)
	for k in 5:
		_noise(0.08 + k * 0.05, 0.04, "bp", 1100 + k * 160, 3.0, 0.25)
	_noise(0.42, 0.05, "lp", 900, 0.7, 0.7); _tone(0.42, 180, 0.08, "sine", 0.4); _tone(0.42, 1400, 0.06, "sine", 0.08); _end("locker")
	# a campainha de bicicleta, de longe: duas batidas, "trim-trim"
	_begin(0.5)
	for at in [0.0, 0.16]:
		_tone(at, 2650, 0.14, "sine", 0.35); _tone(at, 3950, 0.08, "sine", 0.15); _noise(at, 0.01, "bp", 4000, 1.5, 0.3)
	_end("bike_bell")
	# a porta do táxi batendo do outro lado da rua, pela janela fechada: um baque surdo e o trinco
	_begin(0.3); _noise(0, 0.06, "lp", 600, 0.7, 1.0); _tone(0, 92, 0.13, "sine", 0.6); _noise(0.008, 0.02, "bp", 1700, 1.3, 0.22); _end("car_door")
	_begin(0.55)
	for k in 12:
		if _rng.randf() < 0.7:
			_noise(k * 0.04, 0.05, "bp", _rng.randf_range(1500, 4000), 0.8, _rng.randf())
	_end("static")
	# a situação da emergência mudou de estágio: chiado curto e dois bipes de rádio
	_begin(0.42)
	_noise(0, 0.13, "bp", 2400, 0.7, 0.9)
	_tone(0.15, 1150, 0.08, "square", 0.5); _tone(0.28, 1150, 0.1, "square", 0.5)
	_end("radio_alert", true)
	_begin(0.08); _noise(0, 0.06, "bp", 2600, 1, 1.0); _end("crackle")
	_begin(1.0)
	for i in _w.size():
		var t := float(i) / RATE
		_w[i] = sin(TAU * 60.0 * t) + 0.35 * sin(TAU * 120.0 * t)
	_end("hum", false, true, 0.6)
	_begin(2.0)
	for i in _w.size():
		_w[i] = _rng.randf_range(-1.0, 1.0)
	_w = _biquad(_w, "bp", 2000, 0.6)
	_end("hiss", false, true, 0.6)


## A voz `v` por sílaba: cada vogal, oral e nasal, em 3 entonações (descendo, reta, subindo), curta ou longa (`long`,
## LONG); com as curtas, os ataques das consoantes.
func _build_voice(v: String, long: bool) -> void:
	for vw in VOWEL:
		for nasal in [false, true]:
			for k in 3:
				_syllable(v, vw, nasal, [-0.12, 0.0, 0.10][k], long)
	if not long:
		for kind in ATTACKS:
			_attack(v, kind)


# ------------------------------------------------------------------ ambientes e campainhas

## Um carro passando lá fora: o motor grave caindo de tom ao passar (efeito Doppler) e o chiado dos pneus no asfalto,
## crescendo e sumindo. `wet`: na chuva, o pneu no molhado (`_wet_tires`) no lugar do pneu seco. `near`: pela mão de
## cá, mais perto (`_near`): mais claro, com mais Doppler e a passagem mais concentrada no meio. `take`: uma das
## `CAR_TAKES` versões, cada uma num pedaço (`build`) com o seu sorteio (`Sfx._take` toca uma delas): a primeira com
## o id, as outras com "~1", "~2"...
func _build_car(wet: bool, near: bool, take: int) -> void:
	_near = near
	var id := ("car_wet" if wet else "car") + ("_near" if near else "")
	var L := 3.2
	_begin(L)
	var n := _w.size()
	var tires := PackedFloat32Array()
	tires.resize(n)
	var ph := 0.0
	var r := _rng.randi()   # o ruído sorteado aqui mesmo (ver `_passes`)
	var hz := 52.0 * _rng.randf_range(0.85, 1.2)   # cada carro com o seu motor
	var doppler := 0.24 if near else 0.16
	for i in n:
		var t := float(i) / RATE
		ph += hz * (1.0 + doppler / 2.0 - doppler * smoothstep(CAR_PEAK - 0.3, CAR_PEAK + 0.2, t / L)) / RATE
		_w[i] = ((ph - floorf(ph)) * 2.0 - 1.0) * 0.6 + sin(TAU * ph * 2.0) * 0.3   # (o dente de serra aqui mesmo: ver `_passes`)
		r = (r * 1103515245 + 12345) & 0x7fffffff
		tires[i] = r / 1073741823.5 - 1.0
	_w = _biquad(_w, "lp", 480.0 if near else 380.0, 0.7)
	tires = _biquad(_biquad(tires, "lp", 2000.0 if near else 1400.0, 0.7), "hp", 200.0, 0.7)
	var env := _passes(n)
	var water := _wet_tires(env) if wet else PackedFloat32Array()
	for i in n:
		_w[i] = _w[i] * 0.45 * env[i] + water[i] if wet else (_w[i] * 0.7 + tires[i] * 0.9) * env[i]
	_end(id + ("~%d" % take if take > 0 else ""))


## A força da passagem do carro em cada uma das `n` amostras: chega aos poucos, mais alto um pouco depois do meio
## (`CAR_PEAK`) e some mais rápido, atrás do prédio; o de perto, mais concentrado no meio (`CAR_NEAR_SHARP`). Numa
## lista, não numa função por amostra: chamar função a cada amostra (do próprio script ou de um objeto, como o
## `_rng`) trava as linhas de execução umas nas outras (8 carros ao mesmo tempo levavam 10 vezes o tempo de um); o
## ruído dos carros sai de um sorteio simples escrito no laço.
func _passes(n: int) -> PackedFloat32Array:
	var k := CAR_NEAR_SHARP if _near else 1.0
	var env := PackedFloat32Array()
	env.resize(n)
	for i in n:
		var u := float(i) / n
		env[i] = pow(sin(PI / 2.0 * u / CAR_PEAK), 2.4 * k) if u < CAR_PEAK \
			else pow(cos(PI / 2.0 * (u - CAR_PEAK) / (1.0 - CAR_PEAK)), 1.6 * k)
	return env


## O pneu no asfalto molhado, ouvido pela janela fechada: um chiado liso ("chhhh") que fica mais claro chegando e
## mais escuro indo embora (o filtro desce de `WET_SWEEP.x` a `WET_SWEEP.y` Hz na passagem, como o tom do motor),
## o chapinhar grave da água embaixo e, no meio, os respingos de duas ou três poças (`WET_SPLASHES`: lufadas de
## ~0,2 s, não estalos). Sem os agudos acima de `WET_TOP` Hz, como a chuva.
func _wet_tires(env: PackedFloat32Array) -> PackedFloat32Array:
	var n := env.size()
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0   # o filtro que varre (estado variável: passa-banda largo)
	var band := 0.0
	var drift := 0.0   # uma oscilação lenta e irregular da força (o pneu passando por mais ou menos água)
	var drift_to := 1.0
	var sweep := WET_SWEEP * (WET_NEAR if _near else 1.0)
	var r := _rng.randi()   # o ruído sorteado aqui mesmo (ver `_passes`)
	for i in n:
		var u := float(i) / n
		var f := lerpf(sweep.x, sweep.y, smoothstep(CAR_PEAK - 0.25, CAR_PEAK + 0.15, u))
		var k := 2.0 * sin(PI * f / RATE)
		r = (r * 1103515245 + 12345) & 0x7fffffff
		var high := r / 1073741823.5 - 1.0 - low - 1.2 * band
		band += k * high
		low += k * band
		if i % 2205 == 0:
			drift_to = _rng.randf_range(0.8, 1.0)
		drift += (drift_to - drift) * 0.0004
		out[i] = band * 0.9 * drift * env[i]
	var slosh := PackedFloat32Array()
	slosh.resize(n)
	for i in n:
		r = (r * 1103515245 + 12345) & 0x7fffffff
		slosh[i] = r / 1073741823.5 - 1.0
	slosh = _biquad(_biquad(slosh, "lp", 420.0, 0.7), "hp", 90.0, 0.7)
	for i in n:
		out[i] += slosh[i] * 0.8 * env[i]
	for s in _rng.randi_range(WET_SPLASHES.x, WET_SPLASHES.y):
		var at := int(_rng.randf_range(CAR_PEAK - 0.15, CAR_PEAK + 0.1) * n)
		var len := int(_rng.randf_range(0.16, 0.28) * RATE)
		var burst := PackedFloat32Array()
		burst.resize(len)
		for i in len:
			r = (r * 1103515245 + 12345) & 0x7fffffff
			burst[i] = r / 1073741823.5 - 1.0
		burst = _biquad(burst, "bp", _rng.randf_range(1300.0, 2100.0), 0.9)
		var amp := _rng.randf_range(0.5, 0.8)
		for i in len:
			var t := float(i) / RATE
			if at + i < n:
				out[at + i] += burst[i] * amp * minf(t / 0.025, 1.0) * exp(-t / 0.07)
	var top := WET_TOP * (WET_NEAR if _near else 1.0)
	return _biquad(_biquad(out, "lp", top, 0.7), "lp", top, 0.7)


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


## Um cachorro latindo bem longe, do outro lado da cidade: latidos curtos e roucos (o tom sobe e cai em cada um, com
## sopro), espaçados, abafados pela distância (só o meio do espectro, sem graves nem agudos) e com o eco dos morros
## chegando depois. `low`: outro cachorro, maior, que late menos e mais devagar (o que responde).
func _build_dog(low := false) -> void:
	_begin(3.6)
	var f0 := 300.0 if low else 430.0
	var at := 0.05
	for k in (2 if low else 3):
		var d := _rng.randf_range(0.13, 0.19) * (1.25 if low else 1.0)
		var f := f0 * _rng.randf_range(0.94, 1.06)
		var s0 := int(at * RATE)
		var ph := 0.0
		for i in int(d * RATE):
			var t := float(i) / RATE
			var u := t / d
			ph += f * (1.0 + 0.3 * sin(PI * minf(u * 1.6, 1.0)) - 0.25 * u) / RATE   # sobe e cai
			var env := minf(1.0, t / 0.006) * pow(1.0 - u, 1.4)
			_w[s0 + i] += (_wave("saw", ph) * 0.7 + _rng.randf_range(-1.0, 1.0) * 0.35) * env
		at += d + _rng.randf_range(0.5, 0.8) * (1.4 if low else 1.0)
	_w = _biquad(_w, "bp", 750.0 if low else 900.0, 1.1)   # a garganta, e a distância comendo graves e agudos
	_w = _biquad(_biquad(_w, "lp", 1100.0, 0.7), "hp", 220.0, 0.7)
	for e: Vector2 in [Vector2(0.27, 0.3), Vector2(0.58, 0.17), Vector2(0.95, 0.08)]:   # o eco dos morros
		var n := int(e.x * RATE)
		for i in range(_w.size() - 1, n - 1, -1):
			_w[i] += _w[i - n] * e.y
	_end("dog_low" if low else "dog", false, false, 0.7)


## A janela: o vidro e a persiana chocalhando no trovão perto.
func _build_outside() -> void:
	_begin(0.9)   # o chocalho: estalinhos rápidos, crescendo e sumindo com o ronco
	var t0 := 0.0
	while t0 < 0.8:
		var g := sin(PI * t0 / 0.8) * _rng.randf_range(0.5, 1.0)
		_noise(t0, 0.012, "bp", _rng.randf_range(2200.0, 3400.0), 2.0, g)
		_noise(t0, 0.02, "bp", 900.0, 4.0, g * 0.4)
		t0 += _rng.randf_range(0.015, 0.04)
	_end("rattle")


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
		b = b * 0.985 + _rng.randf_range(-1.0, 1.0) * 0.06
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


## Chuva ouvida de dentro, em estéreo (cada lado com o seu chiado; em mono era um chiado de rádio) e mais do lado da
## janela, à direita (`RAIN_LEFT`): o ronco grave da água nos telhados e no asfalto, igual nos dois lados; o lençol de
## gotas longe, sem os agudos (a janela fechada); e o grão miúdo das gotas, denso e por igual. Gotas soltas (batidas,
## bolhas de poça, gotas no vidro) saíram a pedido: soavam como "tic".
func _build_rain() -> void:
	var L := 7.0
	_begin(L)
	var n := _w.size()
	var rumble := PackedFloat32Array()
	rumble.resize(n)
	for i in n:
		rumble[i] = _rng.randf_range(-1.0, 1.0)
	rumble = _biquad(_biquad(rumble, "lp", 320.0, 0.7), "hp", 40.0, 0.7)
	var sides: Array[PackedFloat32Array] = []
	for side in 2:
		var bed := PackedFloat32Array()
		var fine := PackedFloat32Array()
		bed.resize(n)
		fine.resize(n)
		fine.fill(0.0)
		for i in n:
			bed[i] = _rng.randf_range(-1.0, 1.0)
		for k in int(L * 3000):
			fine[_rng.randi() % n] += _rng.randf_range(-1.0, 1.0)
		bed = _biquad(bed, "bp", 700.0, 0.5)
		fine = _biquad(fine, "bp", 2600.0, 0.7)
		for i in n:
			_w[i] = rumble[i] * 0.6 + bed[i] * 0.6 + fine[i] * 1.1
		_w = _biquad(_w, "lp", 4500.0, 0.7)   # atrás da janela
		_loopify(0.4)
		if side == 0:
			for i in _w.size():
				_w[i] *= RAIN_LEFT
		sides.append(_w)
		_begin(L)
	_w = sides[0]
	_end("rain", false, true, 0.6, sides[1])


## Brisa leve: ruído grave em rajadas lentas (ciclos inteiros no loop de 8 s) e um assobio fraquinho.
func _build_breeze() -> void:
	_begin(8.6)
	var n := _w.size()
	var b := 0.0
	for i in n:
		b = b * 0.995 + _rng.randf_range(-1.0, 1.0) * 0.05
		_w[i] = b
	_w = _biquad(_biquad(_w, "lp", 650.0, 0.7), "hp", 70.0, 0.7)
	var hiss := PackedFloat32Array()
	hiss.resize(n)
	for i in n:
		hiss[i] = _rng.randf_range(-1.0, 1.0)
	hiss = _biquad(hiss, "bp", 900.0, 3.0)
	for i in n:
		var t := float(i) / RATE
		var gust := 0.55 + 0.3 * sin(TAU * t / 8.0) + 0.15 * sin(TAU * t * 3.0 / 8.0 + 1.3)   # (a mesma conta de `Sfx.gust`)
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
		var f := _rng.randf_range(3900.0, 5100.0)
		var syl := _rng.randi_range(3, 5)
		var gap := _rng.randf_range(0.028, 0.036)
		var every := _rng.randf_range(0.38, 0.75)
		var t := _rng.randf() * every
		while t < L - 0.3:
			for s in syl:
				_cricket_syllable(t + s * gap, f, 0.02, float(amps[c]) * _rng.randf_range(0.8, 1.0))
			t += every * _rng.randf_range(0.9, 1.12)
	# grilos de trilo: "criiiiii" de 1,5 a 4 s (pulsos rápidos, ~40 por segundo), pausa, e de novo
	for tr in [[3800.0, 38.0, 0.55], [4400.0, 46.0, 0.35]]:
		var t := _rng.randf() * 1.0
		while t < L - 0.5:
			var len := minf(_rng.randf_range(1.5, 4.0), L - 0.2 - t)
			var p := 1.0 / float(tr[1])
			var k := 0.0
			while k < len:
				var fade := minf(1.0, minf(k / 0.3, (len - k) / 0.3))
				_cricket_syllable(t + k, tr[0], p * 0.6, float(tr[2]) * fade)
				k += p
			t += len + _rng.randf_range(0.5, 2.0)
	_w = _biquad(_biquad(_w, "lp", 7000.0, 0.7), "hp", 2500.0, 0.7)
	_loopify(0.4)
	_end("crickets", false, true, 0.5)


## Uma sílaba de grilo: ataque curto, tom caindo um pouco, final mais lento.
func _cricket_syllable(at: float, f: float, dur: float, g: float) -> void:
	var s0 := int(at * RATE)
	var ph := _rng.randf()
	for i in int(dur * RATE):
		if s0 + i >= _w.size():
			break
		var t := float(i) / RATE
		var k := t / dur
		ph += f * (1.01 - 0.02 * k) / RATE
		var env := minf(1.0, t / 0.003) * pow(1.0 - k, 0.8)
		_w[s0 + i] += sin(TAU * ph) * env * g


## O sabiá-laranjeira cantando no escuro, antes de o sol nascer (`SABIA_TAKES` frases, cada uma uma versão do som):
## notas de flauta (o seno com um pouco da oitava), umas retas, outras subindo ou descendo e umas em trinado,
## cada uma entrando e saindo devagar (nada de estalo: batida solta soa como "tic"), longe, com o eco da rua.
func _build_sabia() -> void:
	for take in SABIA_TAKES:
		_begin(2.8)
		var at := 0.05
		for n in _rng.randi_range(4, 7):
			var d := _rng.randf_range(0.09, 0.28)
			var f0 := _rng.randf_range(SABIA_HZ.x, SABIA_HZ.y)
			var f1 := f0 * _rng.randf_range(0.8, 1.25)   # para onde a nota vai (subindo ou descendo)
			var trill := _rng.randf() < 0.25   # o trinado: o tom indo e vindo depressa
			var s0 := int(at * RATE)
			var ph := 0.0
			for i in int(d * RATE):
				if s0 + i >= _w.size():
					break
				var t := float(i) / RATE
				var u := t / d
				var f := lerpf(f0, f1, u * u * (3.0 - 2.0 * u))
				if trill:
					f *= 1.0 + 0.12 * sin(TAU * 22.0 * t)
				ph += f * (1.0 + 0.01 * sin(TAU * 31.0 * t)) / RATE
				var env := minf(1.0, minf(t / 0.018, (d - t) / 0.03))
				_w[s0 + i] += (sin(TAU * ph) + 0.15 * sin(TAU * 2.0 * ph)) * env
			at += d + _rng.randf_range(0.03, 0.14)
			if at > 2.4:
				break
		_w = _biquad(_w, "lp", 4500.0, 0.7)
		var echo := int(0.11 * RATE)
		for i in range(_w.size() - 1, echo - 1, -1):
			_w[i] += _w[i - echo] * 0.2
		_end("sabia" if take == 0 else "sabia~%d" % take, false, false, 0.7)


## Mapa de papel desenrolando (ao abrir a aba do mapa): estalinhos do papel se soltando, cada vez mais espaçados,
## sobre um "fffff" de folha deslizando, e a folha assentando na mesa no fim.
func _build_unroll() -> void:
	_begin(0.8)
	var t := 0.0
	while t < 0.55:
		_noise(t, _rng.randf_range(0.004, 0.012), "bp", _rng.randf_range(2500.0, 5500.0), 2.0, _rng.randf_range(0.25, 0.8) * (1.0 - t / 0.7))
		t += _rng.randf_range(0.006, 0.012) + t * 0.05
	var slide := PackedFloat32Array()   # deslizar: ruído que cresce e some
	slide.resize(int(0.55 * RATE))
	for i in slide.size():
		var k := float(i) / slide.size()
		slide[i] = _rng.randf_range(-1.0, 1.0) * 0.35 * sin(PI * k)
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
		_noise(t, 0.012, "bp", _rng.randf_range(2600.0, 3600.0), 1.5, _rng.randf_range(0.6, 1.0))
		_tone(t, _rng.randf_range(160.0, 210.0), 0.035, "sine", 0.45)
		t += _rng.randf_range(0.055, 0.1)
	_end("typing")
	# impressora matricial: cada batida de agulha é um impulso que faz soar o metal da agulha e o rolo; o motor de
	# passo puxa o papel aos "tk" regulares; tudo ressoa na carcaça
	_begin(1.4)
	var hits := PackedFloat32Array()
	hits.resize(_w.size())
	t = 0.03
	var word := _rng.randi_range(2, 7)
	while t < 1.22:
		for col in 7:   # um caractere: colunas de agulhas (algumas das 9 em cada), a última vazia
			var i := int((t + _rng.randf_range(0.0, 0.00015)) * RATE)
			hits[i] += (_rng.randi_range(1, 7) if col < 6 and _rng.randf() < 0.85 else 0) / 9.0
			t += 1.0 / PRINTER_COLS
		word -= 1
		if word == 0:   # espaço entre palavras: a cabeça anda sem bater
			t += _rng.randi_range(1, 2) * 7.0 / PRINTER_COLS
			word = _rng.randi_range(2, 7)
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
		_w[i] = (_wave("saw", ph) * 0.25 + _rng.randf_range(-1.0, 1.0) * 0.35) * env
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
		_noise(t, _rng.randf_range(0.03, 0.07), "bp", _rng.randf_range(1800.0, 4200.0), 0.9, _rng.randf_range(0.4, 0.9))
		t += _rng.randf_range(0.03, 0.08)
	_end("shred")


## A madeira do móvel por baixo do atrito do fio: o pico dela, em fração do pico dos estalos.
const WOOD := 0.3


## Atrito do fio na borda do buraco: três loops que tocam juntos (`cord_rub` controla o volume de cada um).
## - "rub" e "rub_slow", o fio: prende e escorrega ("agarra e solta") sobre um corpo grave contínuo, com a madeira
##   do móvel soando a cada estalo. No "rub" (rápido) os estalos são bem juntos e viram um zumbido áspero; no
##   "rub_slow" (devagar) são esparsos, cada agarrão separado. `cord_rub` cruza um no outro pela velocidade.
## - "rub_hi", o agudo: brilho de fibras raspando e o rangido de corda esfregada (o agarra-e-solta em ritmo quase
##   regular faz a corda vibrar, como um arco). Some quando o fio passa devagar.
## Saem com o mesmo ganho, como se fossem um som só.
func _build_rub() -> void:
	var cord := _rub_cord(1.4, Vector2(0.005, 0.010), Vector2(0.008, 0.016), Vector2(1550.0, 2850.0))
	var slow := _rub_cord(2.0, Vector2(0.022, 0.05), Vector2(0.01, 0.02), Vector2(1300.0, 2500.0))

	_begin(1.4)
	var t := 0.0
	while t < 1.39:   # fibras
		_noise(t, 0.06, "bp", _rng.randf_range(1700.0, 5700.0), 2.0, _rng.randf_range(0.08, 0.25))
		t += _rng.randf_range(0.003, 0.008)
	# rangido: pulsos quase regulares (o ritmo e a força variam devagar, em trechos que vêm e vão) que fazem
	# soar duas ressonâncias curtas
	var creak := PackedFloat32Array()
	creak.resize(_w.size())
	var rate := 220.0
	var amp := 0.5
	var i := 0
	while i < creak.size():
		creak[i] = amp * _rng.randf_range(0.7, 1.0)
		rate = clampf(rate + _rng.randf_range(-20.0, 20.0), 170.0, 290.0)
		amp = clampf(amp + _rng.randf_range(-0.04, 0.04), 0.1, 1.0)
		i += int(RATE / rate * _rng.randf_range(0.92, 1.08))
	var ring_a := _resonator(creak, 2500.0, 0.003)
	var ring_b := _resonator(creak, 3700.0, 0.002)
	for k in _w.size():
		_w[k] += (ring_a[k] + ring_b[k] * 0.6) * 0.35
	var hi := _w

	# mesmo ganho em todos: cada um sai com o pico que teria dentro da mistura
	var layers := {"rub": cord, "rub_slow": slow, "rub_hi": hi}
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


## Um loop do fio, de `sec` s: estalos de agarra e solta a cada `gap` s (x..y), de `dur` s, na banda `band` Hz,
## sobre o corpo grave e com a madeira do móvel soando a cada um.
func _rub_cord(sec: float, gap: Vector2, dur: Vector2, band: Vector2) -> PackedFloat32Array:
	_begin(sec)
	var knock := PackedFloat32Array()   # cada agarra e solta bate na borda do buraco e faz soar o móvel
	knock.resize(_w.size())
	var t := 0.0
	while t < sec - 0.01:   # agarra e solta
		var g := _rng.randf_range(0.5, 1.0)
		_noise(t, _rng.randf_range(dur.x, dur.y), "bp", _rng.randf_range(band.x, band.y), 1.2, g)
		knock[int(t * RATE)] += g
		t += _rng.randf_range(gap.x, gap.y)
	var body := PackedFloat32Array()   # corpo
	body.resize(_w.size())
	for i in body.size():
		body[i] = _rng.randf_range(-0.6, 0.6)
	body = _biquad(body, "lp", 920.0, 0.8)
	# a madeira: dois modos graves e bem amortecidos, um murmúrio oco por baixo do atrito, WOOD do pico dele
	var wood := _resonator(knock, 210.0, 0.006)
	var wood_b := _resonator(knock, 330.0, 0.004)
	var peak := 0.0001
	var wood_peak := 0.0001
	for i in _w.size():
		wood[i] += wood_b[i] * 0.6
		peak = maxf(peak, absf(_w[i]))
		wood_peak = maxf(wood_peak, absf(wood[i]))
	for i in _w.size():
		_w[i] += body[i] + wood[i] * WOOD * peak / wood_peak
	return _w


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
