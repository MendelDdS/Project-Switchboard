class_name Urgency
extends Node
## As barras de agravamento das emergências em andamento (`Main.emergencies`, até duas; nó filho de Main). A situação piora até o socorro
## completo sair para o lugar certo (despacho incompleto ou no endereço errado não para a barra), mesmo com a ligação em
## espera ou já desligada; só para durante pergunta e resposta e na pausa do jogo. Com o operador fora da linha dela, o
## rádio inteiro avisa (`Radio.alert`). Cada estágio pode exigir unidades novas, mas só depois de alguém contar o que
## mudou (`told`); o último (perdida) já pune e piora o jornal, mas ainda dá para despachar. Quem liga de novo não tem
## barra. O estado fica na `PhoneCall` (`stage`, `urgency`, `told`); o desenho, em `UrgencyBar` (a da linha do FONE).
## Com duas, o rádio mostra a pior e avisa da que está fora da linha.

var frozen := false   ## painel de debug: a barra não anda

@onready var main: Main = get_parent()


func _process(delta: float) -> void:
	if main.running:
		tick(delta)


## Anda `delta` segundos (os testes chamam à mão com o relógio parado).
func tick(delta: float) -> void:
	var worst := -1
	var off: PhoneCall = null   # fora da linha de uma emergência, o rádio inteiro avisa (a pior das que estão fora)
	var attending: PhoneCall = null
	for c: PhoneCall in main.emergencies:
		if c.on_line:
			attending = c
		if c.urgent():
			worst = maxi(worst, c.stage)
			if not c.on_line and (off == null or c.stage > off.stage):
				off = c
	var away := ""
	if off != null:
		var where := (off.data as EmergencyCall).address if off.ended else T.text(T.Key.STATUS_LINE) % off.line + " " + T.text(T.Key.STATUS_ON_HOLD)
		away = "%s\n%s · %s" % [T.text(T.Key.RADIO_INCIDENT_ON), where, T.text(UrgencyBar.NAMES[off.stage])]
	main.radio.alert(worst, away)
	main.phone.urgency.call = attending
	main.dispatch.attending = null if attending == null else attending.data
	main.dispatch.set_spare(main.in_progress().size() >= Main.MAX_EMERGENCIES)
	for c: PhoneCall in main.emergencies.duplicate():
		if c.urgent() and not c.asking:
			_advance(c, delta)


## A barra de `c` anda; ao mudar de estágio, quem está na linha (ou o rádio) conta o que piorou.
func _advance(c: PhoneCall, delta: float) -> void:
	var e: EmergencyCall = c.data
	if not frozen:
		c.urgency += delta
	if c.urgency < [e.stage_sec.x, e.stage_sec.x + e.stage_sec.y, e.stage_sec.x + e.stage_sec.y + e.stage_sec.z][c.stage]:
		return
	c.stage += 1
	main.radio.chirp(c.stage)
	if c.stage == 3:
		main.supervisor.lost(c)
	if not c.dispatched:
		main.conversation.emergency_worse(c, c.stage)
		return
	# quem ligou já desligou (ou está se despedindo): quem avisa é o rádio, com o que passou a precisar
	var more := Array(e.required(c.stage)).filter(func(u): return not u in e.required(c.told))
	var msg := T.text(T.Key.RADIO_LOST if c.stage == 3 else T.Key.RADIO_WORSE) % e.address
	if not more.is_empty():
		var names := PackedStringArray(more.map(func(u): return T.text(Fleet.NAMES[u]).to_lower()))
		msg += " " + T.text(T.Key.RADIO_SEND_MORE) % (" %s " % T.text(T.Key.AND)).join(names)
	main.radio.say(msg)
	told(c, c.stage)


## Alguém contou o que mudou até o estágio `stage` (a pessoa na linha ou o rádio): só agora o despacho passa a
## exigir as unidades dele; ninguém é cobrado pelo que não tinha como saber.
func told(c: PhoneCall, stage: int) -> void:
	c.told = maxi(c.told, stage)
	main.dispatch.fleet.require(c.data, (c.data as EmergencyCall).required(c.told))
