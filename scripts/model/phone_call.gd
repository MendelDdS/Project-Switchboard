class_name PhoneCall
extends RefCounted
## Uma ligação do turno: o roteiro que veio do conteúdo (TransferCall, EmergencyCall, PrankCall) e tudo o que
## acontece com ela enquanto toca, conversa e termina. O painel do telefone escuta os sinais para redesenhar.

signal transcript_changed
signal options_changed
signal state_changed

enum Kind { TRANSFER, EMERGENCY, PRANK, INFO, MYSTERY }
enum Phase { NONE, AWAIT, EMERGENCY, INFO }
enum End {
	OPERATOR,   ## o operador desligou (botão Desligar)
	CALLER,     ## quem ligou desligou
	MISSED,     ## ninguém atendeu e a pessoa desistiu
	CONNECTED,  ## transferência completa; segue conectada sem o operador
	MYSTERY,    ## a linha 07 caiu
}

var kind := Kind.TRANSFER
var data: Resource          ## roteiro (TransferCall, EmergencyCall ou PrankCall); nulo para informação e linha 07
var voice := "m"
var caller := ""
var main := -1              ## 0–3 = ligação principal (0 é a do tutorial); -1 = extra ou linha 07
var filler := false
var at := 0.0               ## minuto previsto (depois das 22:00)
var latest := INF           ## linha 07: a partir daqui toca mesmo com a mesa ocupada

var line := 0
var time := ""
var ringing := false
var active := false
var ended := false
var on_line := false        ## o FONE está na entrada desta ligação (só ela fala)
var talking := false
var phase := Phase.NONE
var last_talk := 0
var transcript: Array[Dictionary] = []   ## {"who", "text", "cls"}; cls: "" / "op" / "sys" / "ghost"
var options: Array[Dictionary] = []      ## {"label": String, "fn": Callable}
var record: Dictionary = {}              ## linha do caderno gerada quando a ligação termina

# transferência (o destino pode mudar quando o pedido não atende à noite)
var target := ""
var destination := ""
var repeat := ""
var said_wait := false
var no_answer := false
var alt_done := false
var connected := false
var dest_num := 0
# emergência
var asked: Array[int] = []
var dispatched := false
# pedido de informação
var ask := ""
var about := ""             ## "o Hotel Estrela"; vazio = perguntou as horas
var answer := ""
var info_ok := -1           ## -1 sem resposta, 0 errada, 1 certa


static func from_transfer(t: TransferCall) -> PhoneCall:
	var c := PhoneCall.new()
	c.kind = Kind.TRANSFER
	c.data = t
	c.voice = t.voice
	c.caller = t.caller
	c.target = t.target
	c.destination = t.destination
	c.repeat = t.repeat
	return c


static func from_emergency(e: EmergencyCall) -> PhoneCall:
	var c := PhoneCall.new()
	c.kind = Kind.EMERGENCY
	c.data = e
	c.voice = e.voice
	c.caller = e.caller
	return c


static func from_prank(p: PrankCall) -> PhoneCall:
	var c := PhoneCall.new()
	c.kind = Kind.PRANK
	c.data = p
	c.voice = p.voice
	c.caller = p.caller
	return c


static func info(voice_id: String, who: String, question: String, spoken := "", number := "") -> PhoneCall:
	var c := PhoneCall.new()
	c.kind = Kind.INFO
	c.voice = voice_id
	c.caller = who
	c.ask = question
	c.about = spoken
	c.answer = number
	return c


static func mystery() -> PhoneCall:
	var c := PhoneCall.new()
	c.kind = Kind.MYSTERY
	c.voice = "g"
	c.caller = "—"
	return c


func add_line(who: String, text: String, cls := "") -> int:
	transcript.append({"who": who, "text": text, "cls": cls})
	transcript_changed.emit()
	return transcript.size() - 1


func append_text(i: int, text: String) -> void:
	transcript[i]["text"] += text
	transcript_changed.emit()


func sys(text: String) -> void:
	add_line("", text, "sys")


func set_options(list: Array[Dictionary]) -> void:
	options = list
	options_changed.emit()


func set_talking(v: bool) -> void:
	talking = v
	state_changed.emit()
