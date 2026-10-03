class_name Urgency
extends Node
## A barra de agravamento da emergência em andamento (`Main.em_call`; nó filho de Main). A situação piora até o socorro
## completo sair para o lugar certo (despacho incompleto ou no endereço errado não para a barra), mesmo com a ligação em
## espera ou já desligada; só para durante pergunta e resposta e na pausa do jogo. Com o operador fora da linha dela, o
## rádio inteiro avisa (`Radio.alert`). Cada estágio pode exigir unidades novas, mas só depois de alguém contar o que
## mudou (`told`); o último (perdida) já pune e piora o jornal, mas ainda dá para despachar. Quem liga de novo não tem
## barra. O estado fica na `PhoneCall` (`stage`, `urgency`, `told`); o desenho, em `UrgencyBar`.

var frozen := false   ## painel de debug: a barra não anda

@onready var main: Main = get_parent()


func _process(delta: float) -> void:
	if main.running:
		tick(delta)


## Anda `delta` segundos (os testes chamam à mão com o relógio parado).
func tick(delta: float) -> void:
	var c := main.em_call
	var away := ""   # fora da linha da emergência, o rádio inteiro avisa
	if c != null and c.urgent() and not c.on_line:
		var where := (c.data as EmergencyCall).address if c.ended else T.text(T.Key.STATUS_LINE) % c.line + " " + T.text(T.Key.STATUS_ON_HOLD)
		away = "%s\n%s · %s" % [T.text(T.Key.RADIO_INCIDENT_ON), where, T.text(UrgencyBar.NAMES[c.stage])]
	main.radio.alert(c.stage if c != null and c.urgent() else -1, away)
	if c == null or not c.urgent() or c.asking:
		return
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
	if c == main.em_call:
		main.dispatch.fleet.require((c.data as EmergencyCall).required(c.told))
