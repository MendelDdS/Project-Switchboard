class_name Schedule
extends RefCounted
## Monta a agenda de uma noite: as ligações do roteiro (horário fixo; a condição é conferida na hora de tocar), a
## ligação desconhecida e as sorteadas. Não depende da cena: noite + semente → as mesmas ligações.
## Quando cada uma toca de fato (mesa cheia, emergência em curso...) é decidido pelo Main (`_run_schedule`).

const EMERGENCY_GAP := 60.0     # minutos de jogo entre duas emergências (o despacho cuida de uma por vez)
const STORY_GAP := 8.0          # as ligações sorteadas ficam a tantos minutos das do roteiro
const TEMPLATE_CHANCE := 0.5    # chance de uma transferência ou emergência vir de um molde e não de um roteiro escrito
const TRANSFER_SHARE := 0.65    # das ligações comuns, quantas são transferências (o resto, pedidos de informação)

var calls: Array[PhoneCall] = []   ## em ordem de horário
var tut: PhoneCall                 ## primeira ligação da noite com tutorial (guiada passo a passo)
var mystery_at := INF              ## horário sorteado da ligação desconhecida (INF = não toca nesta noite)


## Agenda da noite `night` para um turno de `shift_end` minutos.
static func build(night: Night, shift_end: float) -> Schedule:
	var s := Schedule.new()
	var fixed: Array[PhoneCall] = []
	for st in night.story:
		var c := PhoneCall.from_script(st.call)
		c.at = st.at
		c.story = true
		c.requires = st.requires
		fixed.append(c)
	if not night.mystery.is_empty():
		var myst := PhoneCall.mystery()
		myst.at = randf_range(night.mystery_from, night.mystery_to)
		myst.latest = myst.at + 30.0   # não espera a mesa silenciar para sempre
		s.mystery_at = myst.at
		fixed.append(myst)
	s.calls = fixed.duplicate()
	s.calls.append_array(s._random_calls(night, shift_end, fixed))
	s.calls.sort_custom(func(a: PhoneCall, b: PhoneCall): return a.at < b.at)
	return s


## Ligações sorteadas pelo turno todo: entre uma e a próxima, `Night.call_gap` minutos (o máximo é o maior
## silêncio possível); de vez em quando (`Night.peak_chance`) a próxima vem logo em seguida. O tipo também é sorteado:
## `Night.emergencies` emergências (espaçadas por EMERGENCY_GAP), `Night.pranks` trotes, e o resto
## transferências ou pedidos de informação. Na noite com tutorial, a primeira é uma transferência guiada.
func _random_calls(night: Night, shift_end: float, fixed: Array[PhoneCall]) -> Array[PhoneCall]:
	var C := GameData.CONTENT
	var ats := []
	var t := randf_range(3.0, 10.0)
	while t < shift_end - 10.0:
		if not fixed.any(func(f: PhoneCall): return absf(t - f.at) < STORY_GAP):
			ats.append(t)
		t += randf_range(2.0, 6.0) if randf() < night.peak_chance else randf_range(night.call_gap.x, night.call_gap.y)
	var kinds := []
	kinds.resize(ats.size())
	var free := range(1 if night.tutorial else 0, ats.size())
	free.shuffle()
	var em_ats := []
	var em_count := randi_range(night.emergencies.x, night.emergencies.y)
	for i in free.duplicate():
		if em_ats.size() < em_count and em_ats.all(func(x): return absf(ats[i] - x) >= EMERGENCY_GAP):
			kinds[i] = PhoneCall.Kind.EMERGENCY
			em_ats.append(ats[i])
			free.erase(i)
	for i in free.slice(0, randi_range(night.pranks.x, night.pranks.y)):
		kinds[i] = PhoneCall.Kind.PRANK
	var used := fixed.map(func(f: PhoneCall): return f.caller)
	var targets := fixed.map(func(f: PhoneCall): return f.target)
	var transfers := C.transfers.filter(func(x): return not x.caller in used)
	var emergencies := C.emergencies.duplicate()
	var pranks := C.pranks.duplicate()
	for pool in [transfers, emergencies, pranks]:
		pool.shuffle()
	var out: Array[PhoneCall] = []
	for i in ats.size():
		var c: PhoneCall
		if i == 0 and night.tutorial:
			var first: TransferCall = GameData.transfers(TransferCall.Group.ESTABLISHMENT).pick_random()
			transfers.erase(first)
			c = PhoneCall.from_transfer(first)
			targets.append(first.alt_target)
			tut = c
		elif kinds[i] == PhoneCall.Kind.EMERGENCY:
			var written := randf() >= TEMPLATE_CHANCE and not emergencies.is_empty()
			c = PhoneCall.from_emergency(GameData.with_case(emergencies.pop_back()) if written else GameData.template_emergency())
		elif kinds[i] == PhoneCall.Kind.PRANK and not pranks.is_empty():
			c = PhoneCall.from_prank(pranks.pop_back())
		elif randf() < TRANSFER_SHARE:
			# um número por noite: duas pessoas pedindo o mesmo destino ficariam esperando uma pela outra
			var fresh := transfers.filter(func(x: TransferCall): return not x.target in targets and not x.alt_target in targets)
			var tc: TransferCall = fresh.back() if randf() >= TEMPLATE_CHANCE and not fresh.is_empty() else GameData.template_transfer(targets)
			transfers.erase(tc)
			c = PhoneCall.from_transfer(tc)
			targets.append(tc.alt_target)
		else:
			c = info_call()
		targets.append(c.target)
		c.at = ats[i]
		out.append(c)
	return out


## Pedido de informação: alguém quer o número de um lugar da lista.
static func info_call() -> PhoneCall:
	var C := GameData.CONTENT
	var who := GameData.pick(C.callers).split(":")
	var e: DirectoryEntry = C.directory.filter(func(d): return d.spoken != "").pick_random()
	return PhoneCall.info(who[0], who[1], String(TranslationServer.translate(GameData.pick(C.ask_number))) % TranslationServer.translate("d" + e.spoken), e.spoken, e.number)
