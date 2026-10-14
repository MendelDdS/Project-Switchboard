extends Node
## Autoload `Sfx`: toca, mixa e cuida do ambiente de todos os sons do jogo, sintetizados ao iniciar por `SfxSynth`
## (nenhum arquivo de áudio).
## Para trocar por gravações reais, substitua as entradas de `streams` por AudioStreams importados.
## Barramentos (default_bus_layout.tres): Ambience (clima, zumbido, chiado), Voices (sílabas), Effects (o resto); Phone
## (a banda da linha telefônica) vai para Voices e leva as vozes de quem liga (`SfxSynth.VOICE`, "bus").
## Clima (`set_weather`): "rain" só chuva; "fog" grilos; "clear" brisa e grilos.

const VOL := {
	"click": -14.0, "sw": -10.0, "plug_in": -3.0, "plug_out": -9.0, "key": -13.0, "page": -11.0,
	"tick": -24.0, "pencil": -13.0, "ring": -9.0, "pulse": -10.0, "ringback": -13.0, "sit": -13.0,
	"cut": -2.0, "static": -11.0, "crackle": -14.0, "thump": -5.0, "drop": -12.0, "set_paper": -27.0, "set_metal": -27.0, "rub": -13.0, "cord_stop": -16.0, "cord_tap": -17.0, "cord_snag": -18.0, "cord_snap": -21.0, "unroll": -8.0,
	"typing": -13.0, "printer": -14.0, "punch": -8.0, "feed": -11.0, "read": -14.0, "shred": -10.0, "deny": -14.0,
	"chime": -11.0, "shift_bell": -13.0, "car": -15.0, "car_near": -13.0, "car_wet": -14.0, "car_wet_near": -12.0, "thunder": -8.0,
	"bell": -15.0, "rattle": -17.0, "dog": -27.0, "dog_low": -28.0, "lamp_tick": -27.0,
}
## Volume (dB) dos sons de ambiente em cada clima; o que não aparece fica mudo.
const WEATHER_MIX := {
	"rain": {"rain": -21.0},
	"fog": {"crickets": -31.0},
	"clear": {"breeze": -24.0, "crickets": -28.0},
}

## Atrito do fio no buraco (`cord_rub`): abaixo de RUB_MIN px/s, silêncio; em RUB_FULL, volume e tom no máximo.
const RUB_MIN := 25.0
const RUB_FULL := 600.0
## Mais rápido, o agarra e solta fica mais junto (o fio esparso, `rub_slow`, passa para o denso, `rub`, entre
## RUB_DENSE.x e RUB_DENSE.y px/s) e o tom sobe pouco: subindo só o tom (era até 1,5×), soava como fita acelerada.
const RUB_DENSE := Vector2(80.0, 450.0)
const RUB_PITCH := Vector2(1.0, 1.15)
## O agudo do atrito (fibras e rangido) é um som à parte: mudo abaixo de RUB_HI_FROM px/s (devagar, só o fio),
## volume normal em RUB_HI_NORMAL (médio) e RUB_HI_BOOST dB a mais em RUB_FULL (rápido).
const RUB_HI_FROM := 120.0
const RUB_HI_NORMAL := 300.0
const RUB_HI_BOOST := 6.0
## Os três passam pelo barramento "Rub" (vai direto para o Master, com uma reverberação mais seca que a do Effects:
## o fio está na mão; o volume segue o de Effects, `Settings.FOLLOWS`), com um passa-baixa que abre com a velocidade: fechado em
## RUB_LP.x Hz até RUB_HI_FROM (devagar, só o "shhh" grave do fio), aberto em RUB_LP.y a partir de RUB_HI_NORMAL.
const RUB_LP := Vector2(900.0, 11000.0)
## O fio batendo na mesa (`cord_tap`) abaixa o atrito RUB_DUCK.x dB, que volta em RUB_DUCK.y s: a batida fica clara.
const RUB_DUCK := Vector2(3.0, 0.05)
## Fio entrando no buraco (recolhendo) soa mais liso que saindo (puxado): multiplica tom e corte, soma dB ao agudo.
const RUB_IN := {"pitch": 0.9, "lp": 0.7, "hi_db": -6.0}
## O fio do FONE (sai do telefone) é mais macio e grave que os cabos de conexão (saem da base de latão). A diferença
## diminui com a velocidade: puxado rápido, sobra só `fast` dela (o puxão forte soa forte em qualquer fio).
const RUB_FONE := {"pitch": 0.85, "lp": 0.6, "hi_db": -4.0, "fast": 0.25}
## O fio do plug solto (caindo ou recolhendo sozinho) passa sem mão puxando: frouxo, mais grave, liso e baixo, quase
## sem o agudo. Multiplica tom e corte; soma dB ao atrito todo (`db`) e ao agudo (`hi_db`).
const RUB_LOOSE := {"pitch": 0.85, "lp": 0.6, "db": -3.0, "hi_db": -10.0}
const PAN := 0.7   # quanto os sons posicionados (`play_at`, atrito) vão para o seu lado (1 = só um lado do fone)
## Cada linha tem a campainha num tom levemente diferente (é o mesmo equipamento: só uma nuance), 01 a mais grave,
## 10 a mais aguda; passo relativo entre linhas vizinhas (0,006 = ±2,7% nas pontas, cerca de meio semitom).
const BELL_STEP := 0.006

## Sons mecânicos que se repetem muito (plugs, fios): cada vez sai com o tom e o volume levemente diferentes
## (± VARY_PITCH, ± VARY_DB), para a mesa cheia não soar como uma máquina.
const VARIED := ["plug_in", "plug_out", "thump", "drop", "cord_stop", "cord_tap", "cord_snag", "cord_snap", "click", "punch", "lamp_tick"]
## O zumbido da luminária acesa (dB; era -40, alto demais).
const LAMP_BUZZ := -44.0
## O zumbido elétrico de 60 Hz da sala, a noite toda (dB; era -29, depois -37: tom grave e constante, cansava, sobretudo em fone),
## e quanto ele baixa quando a noite se cala antes da ligação desconhecida (depois dela, some).
const HUM_DB := -45.0
const HUM_HUSHED := -50.0
## A chuva cresce e diminui em ondas lentas (dB de cada onda, período em s), em vez de um chiado constante.
const RAIN_WAVES := [Vector2(2.5, 37.0), Vector2(1.5, 11.0)]
## A força da chuva muda durante a noite (`set_rain`, de garoa a forte): dB a mais na chuva, de RAIN_GAIN.x (garoa) a
## RAIN_GAIN.y (forte), em RAIN_GAIN.z s.
const RAIN_GAIN := Vector3(-8.0, 3.0, 6.0)
## Com a noite avançando a cidade se cala: os grilos sobem e a brisa baixa (dB, com `set_late` em 1).
const LATE_CRICKETS := 4.0
const LATE_BREEZE := -3.0
## Na pausa o jogo fica como ouvido de longe: um passa-baixa no Master fecha até MUFFLE.x Hz e o volume baixa
## MUFFLE.y dB, em MUFFLE.z s (`muffle`).
const MUFFLE := Vector3(700.0, -5.0, 0.35)
const MUFFLE_OPEN := 20500.0
const VARY_PITCH := 0.06
const VARY_DB := 1.5

## Entonação das falas (`_tone`): a altura cai DECLINE do começo ao fim da frase, com JITTER de sorteio por sílaba;
## a tônica de cada palavra sobe STRESS e STRESS_DB dB; a última sílaba da afirmação cai (FINAL_FALL).
## Pergunta ("?"): a frase fica reta (sem a queda) e as últimas QUESTION_TAIL sílabas sobem, em rampa, até QUESTION_RISE.
## Exclamação ("!"): a frase toda mais aguda e mais alta (EXCLAIM), a tônica com EXCLAIM_STRESS vezes a ênfase e o fim
## caindo mais (EXCLAIM_FALL). Cada pessoa tem a sua altura, até PERSON_PITCH acima ou abaixo da voz (`pitch_of`).
const DECLINE := 0.04
const JITTER := 0.02
const STRESS := 0.06
const STRESS_DB := 2.0
const FINAL_FALL := 0.95
const QUESTION_RISE := 1.12
const QUESTION_TAIL := 3
const EXCLAIM := {"pitch": 1.08, "db": 3.0}
const EXCLAIM_STRESS := 1.8
const EXCLAIM_FALL := 0.88
const PERSON_PITCH := 0.08
## Emergência: quem liga se agita com a barra de agravamento (`agitation`), cada um do seu jeito (`PhoneCall.temper`).
## No máximo, a voz sobe `pitch`, treme `shake` (sorteio por sílaba), fica `db` mais alta e fala `speed` mais rápido
## (`Conversation.say`). AGITATION_STAGE: quanto do máximo em cada estágio (`PhoneCall.stage`), vezes o temperamento.
const AGITATION := {"pitch": 0.12, "shake": 0.04, "db": 2.0, "speed": 0.25}
const AGITATION_STAGE := [0.3, 0.65, 1.0, 1.0]
## Fração da duração da sílaba (`SfxSynth.VOICE`, "dur") que precisa passar antes da próxima da mesma voz (`_syllable_wait`).
const SYLLABLE_GAP := 0.7
const ACCENTED := "áàâãéêíóôõú"
const OXYTONE := "rlzuix"
## dB a mais em todas as falas, sobre o `db` de cada voz (`SfxSynth.VOICE`; era 10). As mais fortes (a tônica de uma
## exclamação) passam de 0 dB: o barramento Voices tem um limitador (`default_bus_layout.tres`) para não estourar.
const VOICE_GAIN := 12.0
## dB a mais em cada vogal (a vogal aberta, "a", saía forte demais).
const VOWEL_DB := {"a": -2.5}
## As consoantes de cada ataque (`_onset`); as que não aparecem ("l", o "r" fraco) não têm ataque.
const ONSETS := {"stop": "ptkbdgcq", "fric": "szfvxjç", "nasal": "mn"}
const VMAP := {"a": "a", "á": "a", "à": "a", "â": "a", "ã": "a", "e": "e", "é": "e", "ê": "e", "i": "i", "í": "i", "o": "o", "ó": "o", "ô": "o", "õ": "o", "u": "u", "ú": "u"}

var streams: Dictionary = {}
var _temper_rng := RandomNumberGenerator.new()   ## o temperamento das emergências (`agitation`), fora do sorteio global
var _spoke := {}   ## voz -> ms (Time.get_ticks_msec) em que a última sílaba começa (no futuro, se está esperando)
var _takes := {}   # id -> quantas versões ele tem (`_take`), dos sons com "~1", "~2"...
var vol := VOL.duplicate()   ## o volume em uso; a mesa de som do debug mexe nele (o `VOL` é o padrão)
var pool: Array[AudioStreamPlayer] = []
var pool_2d: Array[AudioStreamPlayer2D] = []   # para `play_at` (som que vem de um lugar da tela)
var rain: AudioStreamPlayer
var breeze: AudioStreamPlayer
var crickets: AudioStreamPlayer
var hum: AudioStreamPlayer
var hiss: AudioStreamPlayer
var lamp_buzz: AudioStreamPlayer  # o zumbido da luminária, que acompanha a luz dela (`lamp`)
var _rain_db := -80.0             # o volume da chuva pedido pelo clima, antes das ondas
var _rain_gain := 0.0             # e o tanto a mais (ou a menos) pela força dela agora (`set_rain`)
var _lamp_on := false            # o ambiente da sala está tocando (o zumbido segue a luminária)
var _late := 0.0                  # quanto a noite já avançou (0..1): a cidade se calando
var _t := 0.0
var rub: AudioStreamPlayer        # atrito do fio no buraco, em loop: o fio (agarra e solta, corpo), rápido
var rub_slow: AudioStreamPlayer   # o mesmo devagar, com os estalos esparsos
var _rub_loops: Array[AudioStreamPlayer] = []   # os três loops do atrito, juntos
var rub_hi: AudioStreamPlayer     # e o agudo (fibras, rangido), com volume próprio
var _rub_speed := 0.0             # px/s pedidos desde o último quadro (zera a cada quadro: sem pedido, cala)
var _rub_v := 0.0                 # px/s, suavizado
var _rub_lp: AudioEffectLowPassFilter
var _rub_pan: AudioEffectPanner
var _rub_want := Vector3(0.5, 1.0, 0.0)   # pedido: x = lugar na tela (0..1), y = parte saindo, z = parte do FONE
var _rub_mood := Vector3(0.5, 1.0, 0.0)   # o mesmo, suavizado
var _rub_feel_want := Vector2(0.0, 1.0)   # pedido: x = parte do plug solto, y = tom do cabo (`Switchboard.CORD_TONE`)
var _rub_feel := Vector2(0.0, 1.0)        # o mesmo, suavizado
var _muffle_lp: AudioEffectLowPassFilter   # a pausa abafando tudo (`muffle`), no Master
var _muffle_amp: AudioEffectAmplify
var _rub_duck := 0.0                      # s que faltam para o atrito voltar depois de um `cord_tap`
var weather := ""   ## o clima da noite ("" = ainda sem noite: a mistura não mexe em nada)
var _hushed := false
var _ring_on := false
var _ring_timer: Timer
var _ring_player: AudioStreamPlayer2D
var _bells := {}       # linhas chamando -> lugar da tomada na tela (0..1)
var _ring_turn := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # o ambiente e os sons do menu seguem durante a pausa
	streams = SfxSynth.build()
	for key: String in streams:
		if "~" in key:
			var base := key.get_slice("~", 0)
			_takes[base] = maxi(int(_takes.get(base, 1)), int(key.get_slice("~", 1)) + 1)
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
	lamp_buzz = _make_loop("lamp_buzz")
	rub = _make_loop("rub")
	rub_slow = _make_loop("rub_slow")
	rub_hi = _make_loop("rub_hi")
	_rub_loops = [rub, rub_slow, rub_hi]
	for p in _rub_loops:
		p.bus = &"Rub"
	var bus := AudioServer.get_bus_index(&"Rub")
	_rub_lp = AudioServer.get_bus_effect(bus, 0)
	_rub_pan = AudioServer.get_bus_effect(bus, 1)
	_muffle_lp = AudioEffectLowPassFilter.new()
	_muffle_lp.cutoff_hz = MUFFLE_OPEN
	_muffle_amp = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(0, _muffle_lp)
	AudioServer.add_bus_effect(0, _muffle_amp)
	_ring_timer = Timer.new()
	_ring_timer.wait_time = 3.0
	add_child(_ring_timer)
	_ring_timer.timeout.connect(_ring_burst)


# ------------------------------------------------------------------ reprodução

## Ao fechar o jogo: para todos os sons, solta as gravações e dá ao áudio um instante para largar as reproduções
## paradas (fechando com som tocando, elas e os sons vazavam na saída: "ObjectDB instances leaked").
func _exit_tree() -> void:
	for p in get_children():
		if p is AudioStreamPlayer or p is AudioStreamPlayer2D:
			p.stop()
			p.stream = null
	streams.clear()
	OS.delay_msec(50)   # ponytail: o servidor de áudio só solta a reprodução parada no próximo passo da mixagem


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
	p.stream = streams[_take(id)]
	p.bus = SfxSynth.VOICE[id[2]]["bus"] if id.begins_with("s_") else (&"Voices" if id == "crackle" else &"Effects")
	if id in VARIED:
		db += randf_range(-VARY_DB, VARY_DB)
		pitch *= 1.0 + randf_range(-VARY_PITCH, VARY_PITCH)
	p.volume_db = vol.get(id, -10.0) + db
	p.pitch_scale = pitch
	p.play()
	if id == "cord_tap":
		_rub_duck = RUB_DUCK.y


## Uma das versões do som, sorteada: `id`, `id~1`, `id~2`... (as do carro, `SfxSynth.CAR_TAKES`; contadas em `_takes`).
func _take(id: String) -> String:
	var k := randi() % int(_takes.get(id, 1))
	return id if k == 0 else "%s~%d" % [id, k]


func later(t: float, id: String, db: float = 0.0) -> void:
	if t <= 0.0:
		play(id, db)
		return
	get_tree().create_timer(t).timeout.connect(play.bind(id, db))


func start_ambience(w: String) -> void:
	for p in [rain, breeze, crickets, hum, hiss, lamp_buzz]:
		p.play()
	fade(hum, HUM_DB, 2.0)
	_lamp_on = true
	set_weather(w, 2.0)


func stop_ambience(sec: float) -> void:
	_lamp_on = false
	for p in [breeze, crickets, hum, lamp_buzz]:
		fade(p, -80.0, sec)
	_tween(self, "_rain_db", -80.0, sec)
	fade(hiss, -80.0, minf(sec, 1.0))


## Troca o clima (os sons do anterior somem aos poucos).
func set_weather(w: String, sec: float = 4.0) -> void:
	weather = w
	_apply_mix(sec)


## A força da chuva agora (0..1, de garoa a forte): o volume dela acompanha, aos poucos.
func set_rain(level: float) -> void:
	_tween(self, "_rain_gain", lerpf(RAIN_GAIN.x, RAIN_GAIN.y, level), RAIN_GAIN.z)


## Quanto a noite já avançou (0..1, das 22h à meia-noite): os grilos sobem e a brisa baixa aos poucos.
func set_late(k: float) -> void:
	_late = k
	_apply_mix(8.0)


## A luz da luminária (0..1): o zumbido acompanha, e some com ela apagada.
func lamp(level: float) -> void:
	if _lamp_on:
		lamp_buzz.volume_db = LAMP_BUZZ + linear_to_db(maxf(level, 0.01))


## Abafa tudo (a pausa: o jogo como ouvido de longe) ou volta ao normal.
func muffle(on: bool) -> void:
	_tween(_muffle_lp, "cutoff_hz", MUFFLE.x if on else MUFFLE_OPEN, MUFFLE.z)
	_tween(_muffle_amp, "volume_db", MUFFLE.y if on else 0.0, MUFFLE.z)


## A noite está calada (antes da ligação desconhecida): nem os cachorros latem.
func hushed() -> bool:
	return _hushed


## Antes da ligação desconhecida a noite se cala: grilos param, chuva e brisa baixam.
func hush_nature(on: bool, sec: float) -> void:
	_hushed = on
	_apply_mix(sec)


func _apply_mix(sec: float) -> void:
	if not WEATHER_MIX.has(weather):   # o cenário avisa a hora (`set_late`) desde a introdução, antes de a noite começar
		return
	var mix: Dictionary = WEATHER_MIX[weather]
	for id in ["rain", "breeze", "crickets"]:
		var db: float = mix.get(id, -80.0)
		if db > -80.0:
			db += {"crickets": LATE_CRICKETS, "breeze": LATE_BREEZE}.get(id, 0.0) * _late
		if _hushed:
			db = -80.0 if id == "crickets" else db - 10.0
		if id == "rain":   # a chuva tem as ondas por cima (`_process`)
			_tween(self, "_rain_db", db, sec)
		else:
			fade(get(id), db, sec)


## O fio está passando pelo buraco a `speed` px/s: o atrito acompanha, mais alto e mais agudo quanto mais rápido.
## `screen_x` (0..1) é onde fica o buraco na tela (o som vem daquele lado); `out_share`, quanto do fio está saindo
## (puxado; o resto entra, recolhendo, mais liso); `fone_share`, quanto é o fio do FONE (mais macio); `loose_share`,
## quanto é de plug solto (sem mão puxando, frouxo); `tone`, o tom médio dos cabos (1 = o do FONE).
## Chamado a cada quadro pela mesa; parando de chamar (pausa), o som some.
func cord_rub(speed: float, screen_x := 0.5, out_share := 1.0, fone_share := 0.0, loose_share := 0.0,
		tone := 1.0) -> void:
	_rub_speed = speed
	if speed > 0.0:
		_rub_want = Vector3(screen_x, out_share, fone_share)
		_rub_feel_want = Vector2(loose_share, tone)


func _process(delta: float) -> void:
	_t += delta
	var wave := 0.0
	for w: Vector2 in RAIN_WAVES:
		wave += w.x * sin(TAU * _t / w.y)
	rain.volume_db = _rain_db + wave + _rain_gain
	_rub_v = lerpf(_rub_v, _rub_speed, minf(1.0, delta * 18.0))
	_rub_mood = _rub_mood.lerp(_rub_want, minf(1.0, delta * 10.0))
	_rub_feel = _rub_feel.lerp(_rub_feel_want, minf(1.0, delta * 10.0))
	_rub_speed = 0.0
	var level := clampf((_rub_v - RUB_MIN) / (RUB_FULL - RUB_MIN), 0.0, 1.0)
	if level < 0.01:
		for p in _rub_loops:
			p.stop()
		return
	if not rub.playing:   # cada arrasto começa num trecho diferente do loop
		for p in _rub_loops:
			p.play(randf() * p.stream.get_length())
	var smooth := 1.0 - _rub_mood.y   # parte recolhendo
	var soft := _rub_mood.z * lerpf(1.0, RUB_FONE["fast"], level)
	var loose := _rub_feel.x
	_rub_duck = maxf(_rub_duck - delta, 0.0)
	var db: float = vol["rub"] + linear_to_db(level) - RUB_DUCK.x * _rub_duck / RUB_DUCK.y + RUB_LOOSE["db"] * loose
	var dense := clampf((_rub_v - RUB_DENSE.x) / (RUB_DENSE.y - RUB_DENSE.x), 0.0, 1.0)
	# potência constante: os dois têm o mesmo corpo, que não deve afundar no meio da troca
	rub.volume_db = db + maxf(linear_to_db(sqrt(dense)), -80.0)
	rub_slow.volume_db = db + maxf(linear_to_db(sqrt(1.0 - dense)), -80.0)
	rub_hi.volume_db = db + _rub_hi_db(_rub_v) + RUB_IN["hi_db"] * smooth + RUB_FONE["hi_db"] * soft \
			+ RUB_LOOSE["hi_db"] * loose
	rub.pitch_scale = lerpf(RUB_PITCH.x, RUB_PITCH.y, level) * _blend("pitch", smooth, soft, loose) * _rub_feel.y
	rub_slow.pitch_scale = rub.pitch_scale
	rub_hi.pitch_scale = rub.pitch_scale
	var open := clampf((_rub_v - RUB_HI_FROM) / (RUB_HI_NORMAL - RUB_HI_FROM), 0.0, 1.0)
	# o corte abre em escala de oitavas, como o ouvido
	_rub_lp.cutoff_hz = RUB_LP.x * pow(RUB_LP.y / RUB_LP.x, open) * _blend("lp", smooth, soft, loose) * _rub_feel.y
	_rub_pan.pan = (_rub_mood.x * 2.0 - 1.0) * PAN


## Multiplicador de `key` ("pitch", "lp") para o fio recolhendo (`smooth`), o do FONE (`soft`) e o do plug solto
## (`loose`), todos 0..1.
func _blend(key: String, smooth: float, soft: float, loose: float) -> float:
	return lerpf(1.0, RUB_IN[key], smooth) * lerpf(1.0, RUB_FONE[key], soft) * lerpf(1.0, RUB_LOOSE[key], loose)


## Volume do agudo do atrito em relação ao fio, pela velocidade (px/s): mudo devagar, igual no médio, mais forte rápido.
func _rub_hi_db(v: float) -> float:
	if v < RUB_HI_NORMAL:
		return maxf(linear_to_db(clampf((v - RUB_HI_FROM) / (RUB_HI_NORMAL - RUB_HI_FROM), 0.0, 1.0)), -80.0)
	return RUB_HI_BOOST * clampf((v - RUB_HI_NORMAL) / (RUB_FULL - RUB_HI_NORMAL), 0.0, 1.0)


func fade(p: AudioStreamPlayer, db: float, t: float) -> void:
	_tween(p, "volume_db", db, t)


## Leva `prop` de `o` até `v` em `t` s, cancelando a mudança anterior do mesmo volume: duas ao mesmo tempo, a mais
## longa terminava por último e ganhava (o clima padrão, mixado antes da noite começar em 8 s, trocava os grilos de
## uma noite limpa pela chuva; o chiado da linha, ligado e desligado logo em seguida, podia ficar ligado).
var _tweens := {}
func _tween(o: Object, prop: String, v: float, t: float) -> void:
	var key := "%d:%s" % [o.get_instance_id(), prop]
	var old: Tween = _tweens.get(key)
	if old != null and old.is_valid():
		old.kill()
	var tw := create_tween()
	tw.tween_property(o, prop, v, t)
	_tweens[key] = tw


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


## Fala o caractere i de `text`: cada grupo de vogais dispara uma sílaba (ritmo de fala, estilo Papers, Please), com
## a entonação da frase (`_tone`). Devolve se o caractere é vogal (passe de volta em `prev_vowel`).
## `at`: de que lugar da tela vem a voz (como em `play_at`; -1 = do centro, como o fone). `pitch`: a altura da pessoa
## (`pitch_of`). `agitated`: de 0 a 1, o nervoso de quem liga numa emergência (`agitation`). `db`: mais baixa (a escuta).
func speak_char(voice: String, text: String, i: int, prev_vowel: bool, laugh: bool = false, at := -1.0, pitch := 1.0,
		agitated := 0.0, db := 0.0) -> bool:
	var lc := text[i].to_lower()
	if not VMAP.has(lc):
		return false
	if prev_vowel:
		return true
	var wait := _syllable_wait(voice)
	if wait < 0.0:
		return true
	var t := _tone(text, i)
	if laugh:
		t = [2, 1.13, 0.0]
	pitch *= 1.0 + agitated * (AGITATION["pitch"] + randf_range(-1.0, 1.0) * AGITATION["shake"])
	var sound := syllable.bind(voice, VMAP[lc] + ("n" if _nasal(text, i) else ""), _onset(text, i), t[0], pitch * t[1],
		t[2] + agitated * AGITATION["db"] + db, at)
	if wait == 0.0:
		sound.call()
	else:   # em tempo real, como `_syllable_wait` mede
		get_tree().create_timer(wait, false, false, true).timeout.connect(sound)
	return true


## Se a sílaba que começa em `i` é nasal: tem "ã"/"õ" ("não", "irmã") ou termina em "m"/"n" sem vogal depois
## ("também", "campo", "central"; "Benedito" não).
func _nasal(text: String, i: int) -> bool:
	var g := i
	while g < text.length() and VMAP.has(text[g].to_lower()):
		if text[g].to_lower() in "ãõ":
			return true
		g += 1
	if g >= text.length() or not text[g].to_lower() in "mn":
		return false
	return g + 1 >= text.length() or not VMAP.has(text[g + 1].to_lower()) and text[g + 1].to_lower() != "h"


## A consoante antes da sílaba que começa em `i`, pelo ataque (`SfxSynth.ATTACKS`): "stop", "fric", "nasal" ou ""
## (vogal sozinha, "l" e o "r" fraco). Nos encontros ("pr", "bl", "tr") vale a primeira; "ch" e "j" chiam, "nh" é
## nasal, "lh" é como "l", o "r" do começo da palavra e o "rr" chiam ("rua"), "c" e "g" antes de "e"/"i" também.
func _onset(text: String, i: int) -> String:
	var v := text[i].to_lower()
	var j := i - 1
	var c := text[j].to_lower() if j >= 0 else ""
	if c in ["r", "l"] and j > 0 and text[j - 1].to_lower() in ONSETS["stop"] + "fv":   # encontro: "pr", "bl", "fr"
		c = text[j - 1].to_lower()
		v = ""
	elif c == "h" and j > 0:   # "ch", "nh", "lh"
		return {"c": "fric", "n": "nasal"}.get(text[j - 1].to_lower(), "")
	elif c == "r" and (j == 0 or not _letter(text[j - 1]) or text[j - 1].to_lower() == "r"):
		return "fric"
	if c == "":
		return ""
	if c in "cg" and v != "" and v in "eiéêí":
		return "fric"
	for kind in ONSETS:
		if c in ONSETS[kind]:
			return kind
	return ""


## Quantos segundos a próxima sílaba da voz `v` espera: a anterior precisa ter tocado SYLLABLE_GAP da duração dela. A
## fala anda no ritmo das letras (`Conversation.say`), e duas vogais a duas letras uma da outra ("Alô", "sei o") vinham
## quase juntas, atropeladas. A que chega cedo espera a vez (0 = toca já); se já houver uma esperando, ela não toca
## (-1), para a fala não ir acumulando atraso. Marca o começo da nova.
func _syllable_wait(v: String) -> float:
	var now := Time.get_ticks_msec()
	var last := int(_spoke.get(v, -100000))   # o começo da última, que pode estar esperando (no futuro)
	if last > now:
		return -1.0
	var dur: float = SfxSynth.VOICE.get(v, SfxSynth.VOICE["m"])["dur"]
	var start := maxi(now, last + int(dur * SYLLABLE_GAP * 1000.0))
	_spoke[v] = start
	return (start - now) / 1000.0


## A altura de cada pessoa, pelo nome: a mesma pessoa sempre com a mesma voz (também quando liga de novo), e duas
## pessoas da mesma voz (`SfxSynth.VOICE`) soando diferentes (até PERSON_PITCH para cima ou para baixo).
static func pitch_of(who: String) -> float:
	return 1.0 + (float(hash(who) % 1001) / 500.0 - 1.0) * PERSON_PITCH


## O nervoso de quem liga na ligação `c`, de 0 a 1: só na emergência, pelo estágio da barra e o temperamento dela
## (`PhoneCall.temper`, sorteado na primeira fala: de 0, tranquila, a voz quase não muda, a 1, se agita toda). Sorteio
## próprio (`_temper_rng`), para não mudar a agenda de quem joga com `--seed`.
func agitation(c: PhoneCall) -> float:
	if c.kind != PhoneCall.Kind.EMERGENCY:
		return 0.0
	if c.temper < 0.0:
		c.temper = _temper_rng.randf()
	return AGITATION_STAGE[clampi(c.stage, 0, AGITATION_STAGE.size() - 1)] * c.temper


## A entonação da sílaba que começa em `i`: [curva (0 descendo, 1 reta, 2 subindo), altura, dB a mais], pelo jeito
## da frase (afirmação, pergunta ou exclamação; ver DECLINE). As do meio da frase sorteiam a curva.
func _tone(text: String, i: int) -> Array:
	var a := i   # a frase: do último ponto antes de i até o próximo
	while a > 0 and not text[a - 1] in ".!?":
		a -= 1
	var b := i
	while b < text.length() and not text[b] in ".!?":
		b += 1
	var end := text[b] if b < text.length() else "."
	var before := _syllables(text, a, i)
	var after := _syllables(text, i + 1, b)
	var pitch := 1.0 + randf_range(-JITTER, JITTER)
	if end != "?":
		pitch += DECLINE * (1.0 - 2.0 * before / maxf(1.0, before + after))
	var db := 0.0
	var stress := EXCLAIM_STRESS if end == "!" else 1.0
	if _stressed(text, i):
		pitch += STRESS * stress
		db = STRESS_DB * stress
	if end == "!":
		pitch *= EXCLAIM["pitch"]
		db += EXCLAIM["db"]
	if end == "?" and after < QUESTION_TAIL:
		var k := float(QUESTION_TAIL - after) / QUESTION_TAIL   # 1/3, 2/3, 1 na última
		return [2, pitch * lerpf(1.0, QUESTION_RISE, k), db]
	if after > 0:
		return [randi() % 3, pitch, db]
	return [0, pitch * (EXCLAIM_FALL if end == "!" else FINAL_FALL), db]


## Quantos grupos de vogais (sílabas faladas) começam em text[from, to); o que já vinha de antes de `from` não conta.
func _syllables(text: String, from: int, to: int) -> int:
	var n := 0
	var prev := from > 0 and VMAP.has(text[from - 1].to_lower())
	for j in range(from, to):
		var v := VMAP.has(text[j].to_lower())
		if v and not prev:
			n += 1
		prev = v
	return n


## Se a sílaba que começa em `i` é a tônica da palavra: a do acento, se houver; senão a última nas palavras
## terminadas em OXYTONE ("falar", "aqui") e a penúltima nas outras. Palavra de uma sílaba sem acento ("de", "o") é átona.
func _stressed(text: String, i: int) -> bool:
	var a := i
	while a > 0 and _letter(text[a - 1]):
		a -= 1
	var b := i
	while b < text.length() and _letter(text[b]):
		b += 1
	var word := text.substr(a, b - a).to_lower()
	var g := i   # o fim do grupo de vogais que começa em i
	while g < b and VMAP.has(text[g].to_lower()):
		g += 1
	for ch in word:
		if ch in ACCENTED:
			return text.substr(i, g - i).to_lower().contains(ch)
	var after := _syllables(text, g, b)
	if _syllables(text, a, b) < 2:
		return false
	return after == (0 if word.right(1) in OXYTONE else 1)


static func _letter(ch: String) -> bool:
	return ch.to_lower() != ch.to_upper()


## Toca uma sílaba: a vogal `vowel` ("a", "an" nasal...) com o ataque da consoante `onset` (`SfxSynth.ATTACKS`; ""
## sem). `contour`: a curva gravada (0 descendo, 1 reta, 2 subindo); `pitch` e `db` somam ao timbre.
func syllable(v: String, vowel: String, onset: String, contour: int, pitch := 1.0, db := 0.0, at := -1.0) -> void:
	if not SfxSynth.VOICE.has(v):
		v = "m"
	var vol := float(SfxSynth.VOICE[v]["db"]) + VOICE_GAIN + db + float(VOWEL_DB.get(vowel[0], 0.0))
	_sound("s_%s_%s_%d" % [v, vowel, contour], at, vol, pitch)
	if onset != "":
		_sound("s_%s_%s" % [v, onset], at, vol, pitch)
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
