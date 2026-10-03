class_name Dispatch
extends Control
## Aba do mapa e despacho: o mapa da cidade ocupa a aba inteira (clicar na rua marca o local) e a ficha de despacho
## fica por cima, à direita: marcar o local imprime um cartão perfurado (`PunchCard`), em que o jogador perfura o tipo
## de ocorrência e as unidades (cada uma com o que a justifica, pelo protocolo; veja EmergencyCall.units), e o cartão
## levado ao transmissor envia (ou à trituradora, descarta). O tipo não marca unidades: quem decide é a conversa. O cartão só mostra o que fica aqui
## (`_location`, `_occurrence`, `_picked`). A ficha abre ao marcar um local ou quando chega uma emergência e se
## recolhe depois do envio (`Open` a reabre); abrir ou fechar não mexe no mapa. O transmissor aceita cartão incompleto:
## sem unidade, ninguém sai (`blank_card`, o supervisor pune); sem tipo, as unidades vão e a chegada é avaliada com o
## tipo vazio. Depois do envio, tudo volta limpo para a próxima. As regras das viaturas e da emergência em andamento
## ficam no `Fleet` (`fleet`); aqui ficam a tela, o rádio e o tempo das viagens.

## `complete`: tudo o que a emergência precisa agora está a caminho do lugar certo (contando envios anteriores).
## `card`: o número do cartão enviado (vai para o caderno).
signal sent(location: String, units_text: String, complete: bool, card: int)
## As unidades chegaram (`Fleet.arrive`). `e` é nulo em `IDLE`. `occurrence` é o tipo marcado no despacho;
## `extra`, as unidades que foram ao local certo sem ser necessárias.
signal arrived(e: EmergencyCall, result: Fleet.Result, occurrence: String, extra: Array)
## Um cartão entrou no transmissor sem nenhuma unidade perfurada: ninguém saiu.
signal blank_card(location: String)

const STAY := 12.0          # s no local atendendo, antes de voltar para a base
const QUICK_STAY := 0.8     # s até virar e voltar, depois de o rádio dizer que ela não era necessária...
const QUICK_WAIT := 3.0     # ...ou, com o rádio ainda ocupado com outras mensagens, depois de chegar

var radio: Radio
var fleet := Fleet.new()

var _location := {}          ## {"street", "block", "label"} marcado no mapa
var _occurrence := ""        ## tipo perfurado no cartão ("" = nenhum)
var _picked: Array = []      ## unidades perfuradas no cartão
var _open := false           ## a ficha aberta (fechando, ela some só quando as máquinas se recolhem)

@onready var city: CityMap = %City
@onready var machines: CardMachines = %Slip
@onready var _slip: Control = %Slip
@onready var _report: Label = %Report


func _ready() -> void:
	city.segment_selected.connect(set_location)
	machines.dispatch = self
	machines.inserted.connect(_send)
	machines.discarded.connect(_discard)
	machines.closed.connect(_hide_slip)
	%Open.pressed.connect(open_slip.bind(true))
	%Close.pressed.connect(open_slip.bind(false))
	resized.connect(_block)
	_slip.visible = false   # começa recolhida: o mapa livre até a primeira ocorrência
	%Open.visible = true
	_refresh()


## O idioma mudou nas configurações.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh()


## Marca o local: sai um cartão novo, em branco. Com um cartão ainda na mesa (é preciso enviar ou triturar antes),
## a impressora recusa e o mapa volta a marcar o local do cartão que está lá.
func set_location(street: String, block: int, label: String) -> void:
	open_slip(true)
	if not machines.print_card(label, GameData.street(street).block_sector(block) if GameData.street(street) != null else 0):
		city.sel = _location.duplicate()
		city.queue_redraw()
		return
	_location = {"street": street, "block": block, "label": label}
	_occurrence = ""
	_picked.clear()
	_refresh()


## Abre ou recolhe a ficha de despacho: as máquinas entram (ou saem) animadas, e ela some depois (`_hide_slip`).
func open_slip(on: bool) -> void:
	if _open == on:
		return
	_open = on
	if on:
		_slip.visible = true
		%Open.visible = false
	machines.set_open(on)
	Sfx.play("page")
	_block()


func _hide_slip() -> void:
	if not _open:
		_slip.visible = false
		%Open.visible = true
		_block()


## Onde há botões por cima do mapa (nenhum nome de rua ali).
func _block() -> void:
	if not is_node_ready():
		return
	var over: Array[Rect2] = []
	for c: Control in [%Open, %Fleet]:
		if c.visible:
			over.append(Rect2(c.get_global_rect().position - city.get_global_rect().position, c.size).grow(4.0))
	city.blocked = over


## Marca o tipo de ocorrência (como perfurar o cartão; "" desmarca, só nos testes e no debug).
func set_occurrence(o: String) -> void:
	_occurrence = o
	_refresh()


## Perfura a unidade no cartão (se estiver disponível).
func punch_unit(u: String) -> void:
	if fleet.is_free(u) and not u in _picked:
		_picked.append(u)
		_refresh()


func occurrence() -> String:
	return _occurrence


func picked() -> Array:
	return _picked


## Uma emergência começou a tocar (`Fleet.set_incident`): a ficha abre.
func set_incident(e: EmergencyCall, stage := 0) -> void:
	fleet.set_incident(e, stage)
	open_slip(true)


## Debug: todas as viaturas livres na hora (as que estavam a caminho não chegam mais) e nada marcado no despacho.
## `forget` também esquece a emergência em andamento.
func reset(forget := false) -> void:
	fleet.reset(forget)
	city.remove_units(Fleet.IDS)
	_location = {}
	_occurrence = ""
	_picked.clear()
	city.clear_selection()
	machines.clear()
	_refresh()


## Local, tipo e ao menos uma unidade marcados (a luz verde do transmissor; incompleto também entra).
func can_send() -> bool:
	return not _location.is_empty() and _occurrence != "" and not fleet.available(_picked).is_empty()


func _refresh() -> void:
	if not is_node_ready():
		return
	machines.refresh()
	var busy := fleet.busy()
	_report.text = "  ·  ".join(PackedStringArray(busy.map(func(u): return "%s: %s" % [T.text(Fleet.NAMES[u]), T.text(Fleet.STATUS[fleet.units[u]])])))
	if %Fleet.visible != not busy.is_empty():
		%Fleet.visible = not busy.is_empty()
		_block.call_deferred()   # a faixa muda de tamanho só no quadro seguinte


## O cartão entrou no transmissor.
func _send() -> void:
	if _location.is_empty():
		return
	var us := fleet.available(_picked)
	var target := _location.duplicate()
	target["occurrence"] = _occurrence
	Sfx.static_burst(0.0, radio.screen_x())
	if us.is_empty():   # nenhuma unidade perfurada: a central recebe a ficha e ninguém sai
		_clean()
		blank_card.emit(String(target["label"]))
		await get_tree().create_timer(1.8, false).timeout
		radio.say(T.text(T.Key.RADIO_BLANK_CARD))
		return
	var names := PackedStringArray()
	var travel := 0.0   # quem vem de mais longe (o Centro fica num canto da cidade) chega por último
	for u in us:
		travel = maxf(travel, city.trip(u, target))
		names.append(T.text(Fleet.NAMES[u]))
	var complete := fleet.send(us, target)
	_clean()
	sent.emit(String(target["label"]), ", ".join(names), complete, machines.serial())
	var gen := fleet.gen
	await get_tree().create_timer(1.8, false).timeout
	if gen != fleet.gen:
		return
	radio.say(T.text([T.Key.RADIO_ON_WAY, T.Key.RADIO_COPY].pick_random()))
	await get_tree().create_timer(maxf(travel - 1.8, 0.5), false).timeout
	if gen == fleet.gen:
		_arrive(us, target)


## O cartão foi para a trituradora: local e furos se perdem, nada sai, e a impressora espera outro local.
func _discard() -> void:
	_location = {}
	_occurrence = ""
	_picked.clear()
	city.clear_selection()
	_refresh()


## Limpo para a próxima emergência (local e tipo não ficam de uma para outra); a ficha se recolhe.
func _clean() -> void:
	_location = {}
	_occurrence = ""
	_picked.clear()
	city.clear_selection()
	machines.clear()
	_refresh()
	open_slip(false)


## Na chegada, o rádio diz o que encontraram; quem não era necessário volta logo, o resto depois de `STAY`.
func _arrive(us: Array, target: Dictionary) -> void:
	var got := fleet.arrive(us, target)
	_refresh()
	var and_ := " %s " % T.text(T.Key.AND)
	var lower := func(list: Array) -> String: return and_.join(PackedStringArray(list.map(func(u): return T.text(Fleet.NAMES[u]).to_lower())))
	var msg: String
	match got["result"]:
		Fleet.Result.IDLE:
			msg = T.text(T.Key.RADIO_NOTHING)
		Fleet.Result.WRONG_PLACE:
			msg = T.text(T.Key.RADIO_WRONG_PLACE) % String(target["label"]).split(",")[0]
		Fleet.Result.MISSING:
			msg = T.text(T.Key.RADIO_NEED) % [lower.call(got["missing"]), fleet.incident["addr"]]
		_:
			msg = T.text(T.Key.RADIO_UNDER_CONTROL)
	radio.say(msg)
	var complaint := msg if got["result"] in [Fleet.Result.IDLE, Fleet.Result.WRONG_PLACE] else ""
	if not got["extra"].is_empty():
		complaint = T.text(T.Key.RADIO_NOT_NEEDED) % lower.call(got["extra"])
		radio.say(complaint)
	var e: EmergencyCall = null if got["result"] == Fleet.Result.IDLE else fleet.incident["call"]
	arrived.emit(e, got["result"], target["occurrence"], got["extra"])
	# quem não era necessário volta assim que o rádio termina de dizer isso
	_return(got["unneeded"], QUICK_STAY, complaint)
	_return(us.filter(func(u): return not u in got["unneeded"]), STAY)


## Depois de `stay` s no local, as unidades voltam para a base pelo mapa e só então ficam disponíveis. Com `after`, os
## `stay` s contam de quando o rádio termina de dizer isso (no máximo `QUICK_WAIT` s depois de chegar).
func _return(us: Array, stay: float, after := "") -> void:
	if us.is_empty():
		return
	var gen := fleet.gen
	if after != "":
		var heard := [false]   # lista: a função abaixo não altera uma variável daqui
		var hear := func(t: String): heard[0] = heard[0] or t == after
		radio.said.connect(hear)
		var cap := get_tree().create_timer(QUICK_WAIT, false)
		while not heard[0] and cap.time_left > 0.0:
			await get_tree().process_frame
		radio.said.disconnect(hear)
	await get_tree().create_timer(stay, false).timeout
	if gen != fleet.gen:
		return
	var back := 0.0
	for u in fleet.leave(us):
		back = maxf(back, city.go_home(u))
	_refresh()
	await get_tree().create_timer(back, false).timeout
	if gen != fleet.gen:
		return
	fleet.home(us)
	city.remove_units(us)
	_refresh()
