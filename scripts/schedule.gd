class_name Schedule
extends RefCounted
## Monta a agenda de uma noite: as ligações do roteiro (horário fixo; a condição é conferida na hora de tocar), a
## ligação desconhecida e as sorteadas. Não depende da cena: noite + semente → as mesmas ligações.
## Quando cada uma toca de fato (mesa cheia, emergência em curso...) é decidido pelo Main (`_run_schedule`).

const EMERGENCY_GAP := 60.0     # minutos de jogo entre duas emergências sorteadas (em andamento, no máximo `Main.MAX_EMERGENCIES`)
const STORY_GAP := 8.0          # as ligações sorteadas ficam a tantos minutos das do roteiro
const STORY_WAIT := 30.0        # a do roteiro espera a mesa silenciar por no máximo tantos minutos (toca sozinha)
const TEMPLATE_CHANCE := 0.5    # chance de uma transferência ou emergência vir de um molde e não de um roteiro escrito
const TRANSFER_SHARE := 0.85    # das ligações comuns, quantas são transferências (o resto, pedidos de informação)
const TRUNK_SHARE := 0.2        # das transferências, quantas são interurbanos (pelo banco INTERURBANO; nunca no treinamento)
const MYSTERY_WAIT := 30.0      # a ligação desconhecida espera a mesa silenciar por no máximo tantos minutos...
const MYSTERY_MARGIN := 10.0    # ...e toca no máximo tantos minutos antes da última ligação, para acabar antes do
                                # botão Encerrar turno (que só aparece depois dela)

var calls: Array[PhoneCall] = []   ## em ordem de horário
var mystery_at := INF              ## horário sorteado da ligação desconhecida (INF = não toca nesta noite)
var targets := []                  ## os destinos já pedidos nesta noite (um número por noite; `filler` também usa)


## Agenda da noite `night` no ritmo `pace`; as ligações sorteadas vão até o minuto `last_call`.
static func build(night: Night, pace: Pace, last_call: float) -> Schedule:
	var s := Schedule.new()
	var fixed: Array[PhoneCall] = []
	for st in night.story:
		var c := PhoneCall.from_script(st.call)
		c.at = st.at
		c.story = true
		c.requires = st.requires
		c.latest = minf(st.at + STORY_WAIT, last_call)
		fixed.append(c)
	if not night.mystery.is_empty():
		var myst := PhoneCall.mystery()
		myst.at = randf_range(night.mystery_from, night.mystery_to)
		myst.latest = minf(myst.at + MYSTERY_WAIT, last_call - MYSTERY_MARGIN)
		s.mystery_at = myst.at
		fixed.append(myst)
	s.calls = fixed.duplicate()
	s.calls.append_array(s._random_calls(night, pace, last_call, fixed))
	s.calls.sort_custom(func(a: PhoneCall, b: PhoneCall): return a.at < b.at)
	return s


## Ligações sorteadas pelo turno todo: entre uma e a próxima, `Pace.call_gap` minutos (o máximo é o maior
## silêncio possível); de vez em quando (`Pace.peak_chance`) a próxima vem logo em seguida. O tipo também é sorteado:
## `Pace.emergencies` emergências (espaçadas por EMERGENCY_GAP), `Pace.pranks` trotes, e o resto
## transferências ou pedidos de informação.
func _random_calls(night: Night, pace: Pace, last_call: float, fixed: Array[PhoneCall]) -> Array[PhoneCall]:
	var C := GameData.CONTENT
	var ats := []
	var t := randf_range(3.0, 10.0)
	while t < last_call:
		if not fixed.any(func(f: PhoneCall): return absf(t - f.at) < STORY_GAP):
			ats.append(t)
		t += randf_range(Pace.PEAK_GAP.x, Pace.PEAK_GAP.y) if randf() < pace.peak_chance else randf_range(pace.call_gap.x, pace.call_gap.y)
	var kinds := []
	kinds.resize(ats.size())
	var free := range(ats.size())
	free.shuffle()
	var em_ats := []
	var em_count := randi_range(pace.emergencies.x, pace.emergencies.y)
	for i in free.duplicate():
		if em_ats.size() < em_count and em_ats.all(func(x): return absf(ats[i] - x) >= EMERGENCY_GAP):
			kinds[i] = PhoneCall.Kind.EMERGENCY
			em_ats.append(ats[i])
			free.erase(i)
	for i in free.slice(0, randi_range(pace.pranks.x, pace.pranks.y)):
		kinds[i] = PhoneCall.Kind.PRANK
	var used := fixed.map(func(f: PhoneCall): return f.caller)
	targets = fixed.map(func(f: PhoneCall): return f.target)
	var transfers := C.transfers.filter(func(x): return not x.caller in used and GameData.serves(x))
	var emergencies := C.emergencies.filter(func(e: EmergencyCall): return GameData.street(e.street).block_sector(e.block) in GameData.sectors)
	var pranks := C.pranks.duplicate()
	for pool in [transfers, emergencies, pranks]:
		pool.shuffle()
	var out: Array[PhoneCall] = []
	for i in ats.size():
		var c: PhoneCall
		if kinds[i] == PhoneCall.Kind.EMERGENCY:
			var written := randf() >= TEMPLATE_CHANCE and not emergencies.is_empty()
			c = PhoneCall.from_emergency(GameData.with_case(emergencies.pop_back()) if written else GameData.template_emergency())
		elif kinds[i] == PhoneCall.Kind.PRANK and not pranks.is_empty():
			c = PhoneCall.from_prank(pranks.pop_back())
		elif randf() < TRANSFER_SHARE:
			# um número por noite: duas pessoas pedindo o mesmo destino ficariam esperando uma pela outra
			var fresh := transfers.filter(func(x: TransferCall): return not x.target in targets and not x.alt_target in targets)
			var tc: TransferCall = GameData.trunk_transfer(targets) if night.lesson.is_empty() and randf() < TRUNK_SHARE else null
			if tc == null:
				tc = fresh.back() if randf() >= TEMPLATE_CHANCE and not fresh.is_empty() else GameData.template_transfer(targets)
			if tc == null and not fresh.is_empty():
				tc = fresh.back()
			if tc != null:
				transfers.erase(tc)   # (o interurbano nem está na lista)
				c = PhoneCall.from_transfer(tc)
				targets.append(tc.alt_target)
		if c == null:   # pedido de informação (ou nenhum número livre para transferir nesta noite)
			c = info_call()
		if c.kind != PhoneCall.Kind.INFO:   # (o pedido de informação não chama ninguém: não ocupa o número)
			targets.append(c.target)
		c.at = ats[i]
		out.append(c)
	return out


## A ligação a mais da mesa vazia (`Main._fill_quiet`): uma transferência (de um molde) para um número ainda não
## pedido nesta noite; sem número livre, um pedido de informação.
func filler() -> PhoneCall:
	var tc := GameData.template_transfer(targets)
	if tc == null:
		return info_call()
	targets.append_array([tc.target, tc.alt_target])
	return PhoneCall.from_transfer(tc)


## Pedido de informação: alguém quer o número de um lugar da lista (dos setores atendidos).
static func info_call() -> PhoneCall:
	var C := GameData.CONTENT
	var who := GameData.pick(C.callers).split(":")
	var e: DirectoryEntry = C.directory.filter(func(d): return d.spoken != "" and GameData.in_service(d.number)).pick_random()
	return PhoneCall.info(who[0], who[1], String(TranslationServer.translate(GameData.pick(C.ask_number))) % TranslationServer.translate("d" + e.spoken), e.spoken, e.number)
