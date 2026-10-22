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


## Uma advertência no relatório (a que entrou, ou vazio no treinamento); `sev` e `text` para as das burocracias.
func fault(id: String, detail := "", sev := -1, text := -1) -> Dictionary:
	if main.training.active:   # o treinamento não gera advertência
		return {}
	return main.report.add(id, Main.fmt(main.minutes), detail, sev, text)


## Um acerto do operador (`ShiftReport.CREDITS`); o treinamento não conta.
func credit(id: String, pts := -1) -> void:
	if not main.training.active:
		main.report.credit(id, Main.fmt(main.minutes), pts)


## Advertência que o supervisor só fica sabendo depois (a denúncia de um assinante): vai para o relatório da noite
## seguinte, com a hora de hoje (sem noite seguinte, para o de hoje; `Main.start_ending`).
func fault_later(id: String, detail := "") -> void:
	if not main.training.active:
		main.report.later.append({"id": id, "time": Main.fmt(main.minutes), "detail": detail})


func who(c: PhoneCall) -> String:
	return "%s (%s)" % [tr(c.caller), T.text(T.Key.LINE_N) % c.line]


## O que o supervisor vai anotar e quem vai ligar de novo por causa de como a ligação terminou.
func call_ended(c: PhoneCall, reason: PhoneCall.End) -> void:
	if c.lesson or c.kind in [PhoneCall.Kind.PRANK, PhoneCall.Kind.MYSTERY]:
		return
	var e: EmergencyCall = c.data if c.kind == PhoneCall.Kind.EMERGENCY else null
	if reason in [PhoneCall.End.MISSED, PhoneCall.End.GAVE_UP]:
		fault("missed" if reason == PhoneCall.End.MISSED else "hold", c.record.who)
		if e != null:
			main.report.trouble(e)
		call_again(c, PhoneCall.Retry.MISSED)
	elif e != null and not c.dispatched and not c.too_late and c.stage < 3:   # perdida já teve a advertência
		fault("emergency_dropped", who(c))
		main.report.trouble(e)
		call_again(c, PhoneCall.Retry.WORSE)
	elif reason == PhoneCall.End.SHIFT_OVER and not c.closing:   # já resolvida e se despedindo não conta
		fault("shift_hung_up", who(c))
	elif c.kind == PhoneCall.Kind.INFO and c.info_ok == 0:
		fault("wrong_info", who(c))
		call_again(c, PhoneCall.Retry.WRONG_INFO)
	if reason == PhoneCall.End.CONNECTED:
		credit("trunk" if GameData.is_trunk(c.dest_num) else "transfer")
	elif c.kind == PhoneCall.Kind.INFO and c.info_ok == 1:
		credit("info")


## A mesma pessoa liga de novo mais tarde, irritada e com menos paciência (no máximo uma vez por motivo).
## Vale também para a ligação do treinamento (que só não gera advertência). Nunca depois da última ligação
## (`Main.last_call`): se não couber, o Main a descarta.
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
			n.temper = c.temper   # a mesma pessoa, do mesmo jeito
			n.too_late = why == PhoneCall.Retry.WORSE and randf() >= REDISPATCH_CHANCE
		PhoneCall.Kind.INFO:
			n = PhoneCall.info(c.voice, c.caller, c.ask, c.about, c.answer)
		_:
			return
	n.retry = why
	n.retried = c.retried.duplicate()
	n.retried.append(why)
	var now := main.minutes
	n.at = minf(now + randf_range(RETRY_AFTER.x, RETRY_AFTER.y), maxf(now + 2.0, main.last_call - 4.0))
	n.latest = n.at + RETRY_WAIT
	main.sched.append(n)
	main.sched.sort_custom(func(a: PhoneCall, b: PhoneCall): return a.at < b.at)


## Quem fica em espera tempo demais desiste.
func check_hold() -> void:
	for c in main.live.duplicate():
		if c.active and not c.lesson and c.kind != PhoneCall.Kind.MYSTERY and main.exchange.line(c.line) == Exchange.Line.HOLD \
				and main.minutes - c.hold_since > HOLD_GIVE_UP:
			main.end_call(c, PhoneCall.End.GAVE_UP)


## O socorro completo saiu para a emergência `c`: se a situação já piorava, uma advertência pelo estágio
## (a perdida já foi dada na hora).
func secured(c: PhoneCall) -> void:
	var e: EmergencyCall = c.data
	if c.stage < 2:   # no crítico, nada: a grave do estágio já diz tudo
		credit("emergency_ok" if c.stage == 0 else "emergency_late")
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
func on_arrived(e: EmergencyCall, result: Fleet.Result, occurrence: String, extra: Array) -> void:
	if e != null and e == main.training.drill:   # a emergência de treino não conta (nem vai para o jornal)
		return
	if e != null and occurrence == "":   # cartão sem o tipo perfurado
		fault("dispatch_type", T.text(T.Key.FAULT_DETAIL_UNCLASSIFIED) % tr(e.occurrence))
	elif e != null and occurrence != e.occurrence:
		fault("dispatch_type", T.text(T.Key.FAULT_DETAIL_CLASSIFIED) % [tr(occurrence), tr(e.occurrence)])
	if not extra.is_empty():
		fault("dispatch_extra", ", ".join(extra.map(func(u): return T.text(Fleet.NAMES[u]))))
	match result:
		Fleet.Result.OK:
			main.report.resolved(e)
			if e != null and occurrence == e.occurrence:
				credit("occurrence")
		Fleet.Result.MISSING:
			if not main.report.faults.any(func(f): return f["id"] == "dispatch_missing" and f["detail"] == e.address):
				fault("dispatch_missing", e.address)
		Fleet.Result.IDLE:
			fault("dispatch_idle")
		Fleet.Result.WRONG_PLACE:
			fault("dispatch_wrong_place", e.address)
			main.report.trouble(e)
			var c := main.emergency_of(e)
			if c != null:
				call_again(c, PhoneCall.Retry.WORSE)


## O supervisor confere o tipo registrado (não dá para saber o tipo de quem não foi atendido).
func on_registered(rec: PhoneCall.Record, type: T.Key) -> void:
	if rec.tut or rec.missed or not TYPE_OF.has(rec.kind):
		return
	if type != TYPE_OF[rec.kind]:
		main.report.add("register_wrong", rec.time, rec.who)
	elif rec.kind == PhoneCall.Kind.PRANK:   # trote reconhecido
		credit("prank")


## Fim do turno: o que ficou sem registro no caderno e os bilhetes esquecidos na mesa do calculógrafo.
func shift_over() -> void:
	for t in main.toll.tickets():
		main.report.add("toll_forgotten", Main.fmt(t.end), t.detail())
	var left: Array[PhoneCall.Record] = main.notebook.queue.duplicate()
	if main.notebook.has_pending():
		left.append(main.notebook.pending)
	for rec in left:
		if not rec.tut and not rec.shift:   # cortada pelo fim do turno já teve a advertência
			main.report.add("register_missing", rec.time, rec.who)
