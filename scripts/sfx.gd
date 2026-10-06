extends Node
## Autoload `Sfx`: toca, mixa e cuida do ambiente de todos os sons do jogo, sintetizados ao iniciar por `SfxSynth`
## (nenhum arquivo de áudio).
## Para trocar por gravações reais, substitua as entradas de `streams` por AudioStreams importados.
## Barramentos (default_bus_layout.tres): Ambience (clima, zumbido, chiado), Voices (sílabas), Effects (o resto).
## Clima (`set_weather`): "rain" só chuva; "fog" grilos; "clear" brisa e grilos.

const VOL := {
	"click": -14.0, "sw": -10.0, "plug_in": -3.0, "plug_out": -9.0, "key": -13.0, "page": -11.0,
	"tick": -24.0, "pencil": -13.0, "ring": -9.0, "pulse": -10.0, "ringback": -13.0, "sit": -13.0,
	"cut": -2.0, "static": -11.0, "crackle": -14.0, "thump": -5.0, "drop": -12.0, "rub": -13.0, "cord_stop": -16.0, "cord_tap": -17.0, "unroll": -8.0,
	"typing": -13.0, "printer": -14.0, "punch": -8.0, "feed": -11.0, "read": -14.0, "shred": -10.0, "deny": -14.0,
	"chime": -11.0, "shift_bell": -13.0, "car": -15.0, "thunder": -8.0,
}
## Volume (dB) dos sons de ambiente em cada clima; o que não aparece fica mudo.
const WEATHER_MIX := {
	"rain": {"rain": -18.0},
	"fog": {"crickets": -31.0},
	"clear": {"breeze": -24.0, "crickets": -28.0},
}

## Atrito do fio no buraco (`cord_rub`): abaixo de RUB_MIN px/s, silêncio; em RUB_FULL, volume e tom no máximo.
const RUB_MIN := 25.0
const RUB_FULL := 600.0
const RUB_PITCH := Vector2(1.0, 1.5)
## O agudo do atrito (fibras e rangido) é um som à parte: mudo abaixo de RUB_HI_FROM px/s (devagar, só o fio),
## volume normal em RUB_HI_NORMAL (médio) e RUB_HI_BOOST dB a mais em RUB_FULL (rápido).
const RUB_HI_FROM := 120.0
const RUB_HI_NORMAL := 300.0
const RUB_HI_BOOST := 6.0
## Os dois passam pelo barramento "Rub" (vai para Effects), com um passa-baixa que abre com a velocidade: fechado em
## RUB_LP.x Hz até RUB_HI_FROM (devagar, só o "shhh" grave do fio), aberto em RUB_LP.y a partir de RUB_HI_NORMAL.
const RUB_LP := Vector2(900.0, 11000.0)
## Fio entrando no buraco (recolhendo) soa mais liso que saindo (puxado): multiplica tom e corte, soma dB ao agudo.
const RUB_IN := {"pitch": 0.9, "lp": 0.7, "hi_db": -6.0}
## O fio do FONE (sai do telefone) é mais macio e grave que os cabos de conexão (saem da base de latão). A diferença
## diminui com a velocidade: puxado rápido, sobra só `fast` dela (o puxão forte soa forte em qualquer fio).
const RUB_FONE := {"pitch": 0.85, "lp": 0.6, "hi_db": -4.0, "fast": 0.25}
const PAN := 0.7   # quanto os sons posicionados (`play_at`, atrito) vão para o seu lado (1 = só um lado do fone)
## Cada linha tem a campainha num tom levemente diferente (é o mesmo equipamento: só uma nuance), 01 a mais grave,
## 10 a mais aguda; passo relativo entre linhas vizinhas (0,006 = ±2,7% nas pontas, cerca de meio semitom).
const BELL_STEP := 0.006

## Sons mecânicos que se repetem muito (plugs, fios): cada vez sai com o tom e o volume levemente diferentes
## (± VARY_PITCH, ± VARY_DB), para a mesa cheia não soar como uma máquina.
const VARIED := ["plug_in", "plug_out", "thump", "drop", "cord_stop", "cord_tap", "click", "punch"]
const VARY_PITCH := 0.06
const VARY_DB := 1.5

const VMAP := {"a": "a", "á": "a", "à": "a", "â": "a", "ã": "a", "e": "e", "é": "e", "ê": "e", "i": "i", "í": "i", "o": "o", "ó": "o", "ô": "o", "õ": "o", "u": "u", "ú": "u"}

var streams: Dictionary = {}
var vol := VOL.duplicate()   ## o volume em uso; a mesa de som do debug mexe nele (o `VOL` é o padrão)
var pool: Array[AudioStreamPlayer] = []
var pool_2d: Array[AudioStreamPlayer2D] = []   # para `play_at` (som que vem de um lugar da tela)
var rain: AudioStreamPlayer
var breeze: AudioStreamPlayer
var crickets: AudioStreamPlayer
var hum: AudioStreamPlayer
var hiss: AudioStreamPlayer
var rub: AudioStreamPlayer        # atrito do fio no buraco, em loop: o fio (agarra e solta, corpo)
var rub_hi: AudioStreamPlayer     # e o agudo (fibras, rangido), com volume próprio
var _rub_speed := 0.0             # px/s pedidos desde o último quadro (zera a cada quadro: sem pedido, cala)
var _rub_v := 0.0                 # px/s, suavizado
var _rub_lp: AudioEffectLowPassFilter
var _rub_pan: AudioEffectPanner
var _rub_want := Vector3(0.5, 1.0, 0.0)   # pedido: x = lugar na tela (0..1), y = parte saindo, z = parte do FONE
var _rub_mood := Vector3(0.5, 1.0, 0.0)   # o mesmo, suavizado
var weather := "rain"
var _hushed := false
var _ring_on := false
var _ring_timer: Timer
var _ring_player: AudioStreamPlayer2D
var _bells := {}       # linhas chamando -> lugar da tomada na tela (0..1)
var _ring_turn := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # o ambiente e os sons do menu seguem durante a pausa
	streams = SfxSynth.build()
	for i in 20:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	for i in 16:
		var p := AudioStreamPlayer2D.new()
		p.attenuation = 0.0          # sem perda com a distância: só o lado muda
		p.max_distance = 100000.0
		p.panning_strength = PAN
		add_child(p)
		pool_2d.append(p)
	rain = _make_loop("rain")
	breeze = _make_loop("breeze")
	crickets = _make_loop("crickets")
	hum = _make_loop("hum")
	hiss = _make_loop("hiss")
	rub = _make_loop("rub")
	rub_hi = _make_loop("rub_hi")
	for p in [rub, rub_hi]:
		p.bus = &"Rub"
	var bus := AudioServer.get_bus_index(&"Rub")
	_rub_lp = AudioServer.get_bus_effect(bus, 0)
	_rub_pan = AudioServer.get_bus_effect(bus, 1)
	_ring_timer = Timer.new()
	_ring_timer.wait_time = 3.0
	add_child(_ring_timer)
	_ring_timer.timeout.connect(_ring_burst)


# ------------------------------------------------------------------ reprodução

func play(id: String, db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if not streams.has(id):
		return null
	var p: AudioStreamPlayer = _free(pool)
	_start(p, id, db, pitch)
	return p


## Como `play`, mas o som vem do lugar `screen_x` (0 = borda esquerda da tela, 1 = direita).
func play_at(id: String, screen_x: float, db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer2D:
	if not streams.has(id):
		return null
	var p: AudioStreamPlayer2D = _free(pool_2d)
	var screen := get_viewport().get_visible_rect().size
	p.position = Vector2(screen_x * screen.x, screen.y / 2.0)
	_start(p, id, db, pitch)
	return p


## Um player parado (ou, todos ocupados, o primeiro).
func _free(players: Array) -> Node:
	for q in players:
		if not q.playing:
			return q
	return players[0]


## `p`: AudioStreamPlayer ou AudioStreamPlayer2D.
func _start(p: Node, id: String, db: float, pitch: float) -> void:
	p.stream = streams[id]
	p.bus = &"Voices" if id.begins_with("s_") or id == "crackle" else &"Effects"
	if id in VARIED:
		db += randf_range(-VARY_DB, VARY_DB)
		pitch *= 1.0 + randf_range(-VARY_PITCH, VARY_PITCH)
	p.volume_db = vol.get(id, -10.0) + db
	p.pitch_scale = pitch
	p.play()


func later(t: float, id: String, db: float = 0.0) -> void:
	if t <= 0.0:
		play(id, db)
		return
	get_tree().create_timer(t).timeout.connect(play.bind(id, db))


func start_ambience(w: String) -> void:
	for p in [rain, breeze, crickets, hum, hiss]:
		p.play()
	fade(hum, -29.0, 2.0)
	set_weather(w, 2.0)


func stop_ambience(sec: float) -> void:
	for p in [rain, breeze, crickets, hum]:
		fade(p, -80.0, sec)
	fade(hiss, -80.0, minf(sec, 1.0))


## Troca o clima (os sons do anterior somem aos poucos).
func set_weather(w: String, sec: float = 4.0) -> void:
	weather = w
	_apply_mix(sec)


## Antes da ligação desconhecida a noite se cala: grilos param, chuva e brisa baixam.
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


## O fio está passando pelo buraco a `speed` px/s: o atrito acompanha, mais alto e mais agudo quanto mais rápido.
## `screen_x` (0..1) é onde fica o buraco na tela (o som vem daquele lado); `out_share`, quanto do fio está saindo
## (puxado; o resto entra, recolhendo, mais liso); `fone_share`, quanto é o fio do FONE (mais macio).
## Chamado a cada quadro pela mesa; parando de chamar (pausa), o som some.
func cord_rub(speed: float, screen_x := 0.5, out_share := 1.0, fone_share := 0.0) -> void:
	_rub_speed = speed
	if speed > 0.0:
		_rub_want = Vector3(screen_x, out_share, fone_share)


func _process(delta: float) -> void:
	_rub_v = lerpf(_rub_v, _rub_speed, minf(1.0, delta * 18.0))
	_rub_mood = _rub_mood.lerp(_rub_want, minf(1.0, delta * 10.0))
	_rub_speed = 0.0
	var level := clampf((_rub_v - RUB_MIN) / (RUB_FULL - RUB_MIN), 0.0, 1.0)
	if level < 0.01:
		rub.stop()
		rub_hi.stop()
		return
	if not rub.playing:   # cada arrasto começa num trecho diferente do loop
		rub.play(randf() * rub.stream.get_length())
		rub_hi.play(randf() * rub_hi.stream.get_length())
	var smooth := 1.0 - _rub_mood.y   # parte recolhendo
	var soft := _rub_mood.z * lerpf(1.0, RUB_FONE["fast"], level)
	rub.volume_db = vol["rub"] + linear_to_db(level)
	rub_hi.volume_db = rub.volume_db + _rub_hi_db(_rub_v) + RUB_IN["hi_db"] * smooth + RUB_FONE["hi_db"] * soft
	rub.pitch_scale = lerpf(RUB_PITCH.x, RUB_PITCH.y, level) * _blend("pitch", smooth, soft)
	rub_hi.pitch_scale = rub.pitch_scale
	var open := clampf((_rub_v - RUB_HI_FROM) / (RUB_HI_NORMAL - RUB_HI_FROM), 0.0, 1.0)
	# o corte abre em escala de oitavas, como o ouvido
	_rub_lp.cutoff_hz = RUB_LP.x * pow(RUB_LP.y / RUB_LP.x, open) * _blend("lp", smooth, soft)
	_rub_pan.pan = (_rub_mood.x * 2.0 - 1.0) * PAN


## Multiplicador de `key` ("pitch", "lp") para o fio recolhendo (`smooth`) e o do FONE (`soft`), ambos 0..1.
func _blend(key: String, smooth: float, soft: float) -> float:
	return lerpf(1.0, RUB_IN[key], smooth) * lerpf(1.0, RUB_FONE[key], soft)


## Volume do agudo do atrito em relação ao fio, pela velocidade (px/s): mudo devagar, igual no médio, mais forte rápido.
func _rub_hi_db(v: float) -> float:
	if v < RUB_HI_NORMAL:
		return maxf(linear_to_db(clampf((v - RUB_HI_FROM) / (RUB_HI_NORMAL - RUB_HI_FROM), 0.0, 1.0)), -80.0)
	return RUB_HI_BOOST * clampf((v - RUB_HI_NORMAL) / (RUB_FULL - RUB_HI_NORMAL), 0.0, 1.0)


func fade(p: AudioStreamPlayer, db: float, t: float) -> void:
	var tw := create_tween()
	tw.tween_property(p, "volume_db", db, t)


## Toca a campainha das linhas em `bells` (linha -> lugar da tomada na tela, 0..1), revezando entre elas a cada
## toque; cada linha no seu tom (`BELL_STEP`) e do seu lado. Chamar de novo atualiza as linhas.
func ring_start(bells: Dictionary) -> void:
	_bells = bells
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
	if not _ring_on or _bells.is_empty():
		return
	var lines := _bells.keys()
	lines.sort()
	_ring_turn = (_ring_turn + 1) % lines.size()
	var n: int = lines[_ring_turn]
	_ring_player = play_at("ring", _bells[n], 0.0, 1.0 + (n - 5.5) * BELL_STEP)


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
## `at`: de que lugar da tela vem a voz (como em `play_at`; -1 = do centro, como o fone).
func speak_char(voice: String, text: String, i: int, prev_vowel: bool, laugh: bool = false, at := -1.0) -> bool:
	var lc := text[i].to_lower()
	if not VMAP.has(lc):
		return false
	if not prev_vowel:
		var rise := laugh or (text.strip_edges().ends_with("?") and i > text.length() - 9)
		syllable(voice, VMAP[lc], rise, at)
	return true


## Toca uma sílaba abafada. `rise` sobe a entonação (perguntas, risadas).
func syllable(v: String, vowel: String, rise: bool = false, at := -1.0) -> void:
	if not SfxSynth.VOICE.has(v):
		v = "m"
	var id := "s_%s_%s_%d" % [v, vowel, randi() % 3]
	var pitch := randf_range(0.95, 1.05) * (1.13 if rise else 1.0)
	_sound(id, at, float(SfxSynth.VOICE[v]["db"]) + 10.0, pitch)
	if v == "g" and randf() < 0.3:
		_sound("crackle", at, -4.0)


func static_burst(strength: float = 0.0, at := -1.0) -> void:
	_sound("static", at, strength, randf_range(0.9, 1.1))


## `play` (do centro) ou, com `at` >= 0, `play_at` (daquele lugar da tela).
func _sound(id: String, at: float, db := 0.0, pitch := 1.0) -> void:
	if at >= 0.0:
		play_at(id, at, db, pitch)
	else:
		play(id, db, pitch)


# ------------------------------------------------------------------ ambiente

func _make_loop(id: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = streams[id]
	p.volume_db = -80.0
	p.bus = &"Ambience"
	add_child(p)
	return p
