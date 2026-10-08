class_name PhoneCall
extends RefCounted
## Uma ligação do turno: o roteiro que veio do conteúdo (TransferCall, EmergencyCall, PrankCall) e tudo o que
## acontece com ela enquanto toca, conversa e termina. O painel do telefone escuta os sinais para redesenhar.

signal transcript_changed
signal options_changed
signal state_changed

enum Kind { TRANSFER, EMERGENCY, PRANK, INFO, MYSTERY }

## Uma linha do caderno: o que se sabe da ligação quando ela termina (`Main._record`) e, depois de registrada, o tipo
## que o jogador carimbou.
class Record:
	var time := ""
	var who := ""
	var where := "—"
	var unit := "—"
	var card := 0              ## o número do cartão de despacho enviado (emergência)
	var obs := ""
	var kind := PhoneCall.Kind.TRANSFER
	var missed := false        ## não atendida: entra no livro sozinha
	var tut := false
	var shift := false         ## cortada pelo fim do turno (já teve a advertência)
	var type: int = -1         ## o carimbo (`T.Key.TYPE_*`), depois de registrada

	## A linha no livro: esta, com o carimbo `t` e a observação `note`.
	func stamped(t: T.Key, note: String) -> Record:
		var r := Record.new()
		for k: String in ["time", "who", "where", "unit", "card", "kind", "missed", "tut", "shift"]:
			r.set(k, get(k))
		r.obs = note
		r.type = t
		return r

enum Phase { NONE, AWAIT, EMERGENCY, INFO }
enum End {
	OPERATOR,   ## o operador desligou (botão Desligar)
	CALLER,     ## quem ligou desligou
	MISSED,     ## ninguém atendeu e a pessoa desistiu
	GAVE_UP,    ## ficou em espera tempo demais e desligou
	CONNECTED,  ## transferência completa; segue conectada sem o operador
	MYSTERY,    ## a ligação desconhecida caiu
	SHIFT_OVER, ## o operador encerrou o turno com ela na linha ou tocando
}
## Por que a pessoa está ligando de novo (liga de novo no máximo uma vez por motivo).
enum Retry {
	NONE,
	MISSED,      ## ninguém atendeu (ou desistiu na espera)
	WRONG_INFO,  ## o operador deu a informação errada
	WRONG_NUMBER,  ## foi conectada ao número errado sem o operador na linha
	WORSE,       ## emergência sem socorro: a situação piorou
}

const AWAY_CHANCE := 0.5    ## pedido com alternativa: chance de o destino pedido não atender

var kind := Kind.TRANSFER
var data: Resource          ## roteiro (TransferCall, EmergencyCall ou PrankCall); nulo para informação e ligação desconhecida
var voice := "m"
var caller := ""
var story := false          ## ligação do roteiro da noite (horário fixo; aguenta mais tempo tocando)
var requires := PackedStringArray()   ## marcadores que precisam bater na hora de tocar (StoryFlags.allows)
var at := 0.0               ## minuto previsto (depois do início do turno)
var latest := INF           ## ligação desconhecida e retornos: a partir daqui toca mesmo com a mesa ocupada
var retry := Retry.NONE
var retried: Array[Retry] = []   ## motivos pelos quais esta pessoa já ligou de novo
var too_late := false       ## emergência que liga de novo: já não adianta despachar

var line := 0
var time := ""
var ringing := false
var active := false
var ended := false
var on_line := false        ## o FONE está na entrada desta ligação (só ela fala)
var closing := false        ## já resolvida: a pessoa termina de falar e desliga mesmo sem o operador na linha
var talking := false
var phase := Phase.NONE
var last_talk := 0.0        ## Main.talk_clock da última fala (mede o silêncio na linha)
var chatted := false        ## já teve a chance de puxar conversa fiada enquanto esperava
var chat: ChatTopic         ## conversa fiada esperando resposta (nula = nenhuma)
var chatting := false       ## um assunto em andamento (sendo contado ou esperando resposta)
var chat_asked := false     ## o operador já puxou conversa (só uma vez por ligação)
var chats: Array[ChatTopic] = []   ## assuntos já puxados nesta ligação (não se repetem)
var hold_since := 0.0       ## minuto em que ficou em espera
var transcript: Array[Dictionary] = []   ## {"who", "text", "cls"}; cls: "" / "op" / "sys" / "ghost"
var options: Array[Dictionary] = []      ## {"label": String, "fn": Callable}
var record: Record                       ## linha do caderno gerada quando a ligação termina (nula antes)

# transferência (o destino pode mudar quando o pedido não atende à noite)
var target := ""
var destination := ""
var repeat := ""
var said_wait := false
var away := false           ## o destino pedido não vai atender (sorteado, só quando há alternativa)
var no_answer := false
var alt_done := false
var connected := false
var dest_num := 0
var wrong := 0              ## quantas vezes foi conectada ao número errado
# emergência
var asked: Array[int] = []
var dispatched := false
var secured := false        ## o socorro completo saiu para o lugar certo: a barra para de vez
var stage := 0              ## barra de agravamento: 0 inicial, 1 agravando, 2 agravada, 3 perdida
var told := 0               ## até que estágio a pessoa já contou o que mudou (libera as perguntas daquele estágio)
var urgency := 0.0          ## segundos que a barra já correu
var asking := false         ## pergunta e resposta em andamento: a barra para
# pedido de informação
var ask := ""
var about := ""             ## de quem pediu o número: "o Hotel Estrela"
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
	c.away = t.alt_target != "" and randf() < AWAY_CHANCE
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


## Ligação a partir de qualquer roteiro escrito (ligações do roteiro de uma noite).
static func from_script(r: Resource) -> PhoneCall:
	if r is EmergencyCall:
		return from_emergency(r)
	if r is PrankCall:
		return from_prank(r)
	return from_transfer(r)


static func info(voice_id: String, who: String, question: String, spoken: String, number: String) -> PhoneCall:
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


## A barra de agravamento está correndo: emergência atendida (ou já desligada depois de um despacho incompleto),
## sem o socorro completo a caminho e ainda não perdida. Quem liga de novo não tem barra.
func urgent() -> bool:
	return kind == Kind.EMERGENCY and retry == Retry.NONE and (active or dispatched) and not secured and stage < 3
