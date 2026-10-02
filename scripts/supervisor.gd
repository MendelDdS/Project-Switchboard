class_name Supervisor
extends Node
## As consequências do turno (nó filho de Main): o que vira advertência no relatório (`Main.report`), quem liga de
## novo e quem desiste de esperar. O Main avisa quando algo acontece (fim de ligação, despacho, chegada das unidades,
## registro no caderno); as regras ficam aqui. Tutorial, trotes e ligação desconhecida não geram advertência.

const HOLD_GIVE_UP := 120.0             # minutos de jogo que alguém aguenta em espera antes de desligar
const RETRY_AFTER := Vector2(15.0, 30.0)  # quem teve problema liga de novo depois de tantos minutos de jogo...
const RETRY_WAIT := 20.0                # ...esperando a mesa esvaziar por no máximo tantos minutos
const REDISPATCH_CHANCE := 0.6          # emergência sem socorro que liga de novo: chance de ainda dar para despachar
## Tipo que o supervisor espera ver no caderno para cada ligação.
const TYPE_OF := {
	PhoneCall.Kind.TRANSFER: T.Key.TYPE_COMMON, PhoneCall.Kind.INFO: T.Key.TYPE_COMMON,
	PhoneCall.Kind.EMERGENCY: T.Key.TYPE_EMERGENCY, PhoneCall.Kind.PRANK: T.Key.TYPE_PRANK,
}

@onready var main: Main = get_parent()


func fault(id: String, detail := "") -> void:
	main.report.add(id, Main.fmt(main.minutes), detail)


func who(c: PhoneCall) -> String:
	return "%s (%s)" % [tr(c.caller), T.text(T.Key.LINE_N) % c.line]


## O que o supervisor vai anotar e quem vai ligar de novo por causa de como a ligação terminou.
func call_ended(c: PhoneCall, reason: PhoneCall.End) -> void:
	if c == main.tut or c.kind in [PhoneCall.Kind.PRANK, PhoneCall.Kind.MYSTERY]:
		return
	var e: EmergencyCall = c.data if c.kind == PhoneCall.Kind.EMERGENCY else null
	if reason in [PhoneCall.End.MISSED, PhoneCall.End.GAVE_UP]:
		fault("missed" if reason == PhoneCall.End.MISSED else "hold", String(c.record["who"]))
		if e != null:
			main.report.trouble(e)
		call_again(c, PhoneCall.Retry.MISSED)
	elif e != null and not c.dispatched and not c.too_late and c.stage < 3:   # perdida já teve a advertência
		fault("emergency_dropped", who(c))
		main.report.trouble(e)
		call_again(c, PhoneCall.Retry.WORSE)
	elif c.kind == PhoneCall.Kind.INFO and c.info_ok == 0:
		fault("wrong_info", who(c))
		call_again(c, PhoneCall.Retry.WRONG_INFO)


## A mesma pessoa liga de novo mais tarde, irritada e com menos paciência (no máximo uma vez por motivo).
## Vale também para a ligação do tutorial (que só não gera advertência). Nunca fica para depois do fim do turno.
func call_again(c: PhoneCall, why: PhoneCall.Retry) -> void:
	if why in c.retried:
		return
	var n: PhoneCall
	match c.kind:
		PhoneCall.Kind.TRANSFER:
			n = PhoneCall.from_transfer(c.data)
		PhoneCall.Kind.EMERGENCY:
			n = PhoneCall.from_emergency(c.data)
			n.stage = c.stage   # a situação não melhora: valem as unidades (e as perguntas) de quando a ligação caiu
			n.told = c.told
			n.too_late = why == PhoneCall.Retry.WORSE and randf() >= REDISPATCH_CHANCE
		PhoneCall.Kind.INFO:
			n = PhoneCall.info(c.voice, c.caller, c.ask, c.about, c.answer)
		_:
			return
	n.retry = why
	n.retried = c.retried.duplicate()
	n.retried.append(why)
	var now := main.minutes
	n.at = minf(now + randf_range(RETRY_AFTER.x, RETRY_AFTER.y), maxf(now + 2.0, Main.SHIFT_END - 4.0))
	n.latest = n.at + RETRY_WAIT
	main.sched.append(n)
	main.sched.sort_custom(func(a: PhoneCall, b: PhoneCall): return a.at < b.at)


## Quem fica em espera tempo demais desiste.
func check_hold() -> void:
	for c in main.live.duplicate():
		if c.active and c != main.tut and c.kind != PhoneCall.Kind.MYSTERY and main.exchange.line(c.line) == Exchange.Line.HOLD \
				and main.minutes - c.hold_since > HOLD_GIVE_UP:
			main.end_call(c, PhoneCall.End.GAVE_UP)


## O socorro completo saiu para a emergência `c`: se a situação já piorava, uma advertência pelo estágio
## (a perdida já foi dada na hora).
func secured(c: PhoneCall) -> void:
	var e: EmergencyCall = c.data
	if c.stage > 0:
		fault("emergency_worse" if c.stage == 1 else "emergency_critical", e.address)
	if c.stage == 2:
		main.report.trouble(e)


## A emergência `c` chegou ao último estágio (perdida): gravíssima na hora e jornal ruim.
func lost(c: PhoneCall) -> void:
	var e: EmergencyCall = c.data
	fault("emergency_lost", e.address)
	main.report.failed(e)


## As unidades chegaram ao local marcado no despacho.
func on_arrived(e: EmergencyCall, result: String, occurrence: String, extra: Array) -> void:
	if e != null and occurrence != e.occurrence:
		fault("dispatch_type", T.text(T.Key.FAULT_DETAIL_CLASSIFIED) % [tr(occurrence), tr(e.occurrence)])
	if not extra.is_empty():
		fault("dispatch_extra", ", ".join(extra.map(func(u): return T.text(Dispatch.UNIT_NAMES[u]))))
	match result:
		"ok":
			main.report.resolved(e)
		"missing":
			if not main.report.faults.any(func(f): return f["id"] == "dispatch_missing" and f["detail"] == e.address):
				fault("dispatch_missing", e.address)
		"idle":
			fault("dispatch_idle")
		"wrong_place":
			fault("dispatch_wrong_place", e.address)
			main.report.trouble(e)
			if main.em_call != null and main.em_call.data == e:
				call_again(main.em_call, PhoneCall.Retry.WORSE)


## O supervisor confere o tipo registrado (não dá para saber o tipo de quem não foi atendido).
func on_registered(rec: Dictionary, type: T.Key) -> void:
	if rec["tut"] or rec["missed"] or not TYPE_OF.has(rec["kind"]):
		return
	if type != TYPE_OF[rec["kind"]]:
		main.report.add("register_wrong", rec["time"], rec["who"])


## Fim do turno: o que ficou sem registro no caderno.
func shift_over() -> void:
	var left: Array = main.notebook.queue.duplicate()
	if main.notebook.has_pending():
		left.append(main.notebook.pending)
	for rec in left:
		if not rec["tut"]:
			main.report.add("register_missing", rec["time"], rec["who"])
