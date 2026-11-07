class_name Night
extends Resource

const StreetEvent := preload("res://scripts/data/street_event.gd")
const DialCall := preload("res://scripts/data/dial_call.gd")
const StoryText := preload("res://scripts/data/story_text.gd")
## Uma noite do jogo: o bilhete do começo e o roteiro fixo (ligações da história). Fica em
## res://data/nights/, na ordem de GameContent.nights. Só o roteiro é fixo; o resto do turno (quem liga, quando, de que
## tipo) é sorteado no ritmo do nível em que o jogador está (`Pace`, que não depende da noite).

## Bilhete do supervisor na tela inicial...
@export_multiline var note := ""
## ...ou a primeira destas versões cujos marcadores batem (`note_for`).
@export var notes: Array[StoryText] = []
## A carta da noite, na mesa (em cima do jornal) desde o começo do turno: a primeira destas versões cujos marcadores
## batem (`letter_for`; nenhuma, sem carta). O jogador abre quando quiser (`Tools.LETTER`).
@export var letters: Array[StoryText] = []
## O texto da tela preta no fim do turno (`Ending`), depois do relatório: a primeira destas versões cujos marcadores
## batem (`ending_for`; nenhuma, o de toda noite). Os finais: o encontro com Sebastião na 15 e o fecho do epílogo.
@export var endings: Array[StoryText] = []
## Clima fixo da noite; vazio ("Sorteado") = sorteado.
@export_enum("Sorteado:", "rain", "fog", "clear") var weather := ""
## O fim do turno (minutos depois do início, às 18h): 360 = meia-noite; a última noite vai até as 6h (720).
@export var shift_end := 360.0
## A chuva ou a névoa vão parando até esta hora (minutos depois do início) e a noite fica limpa (-1 = nunca): na
## última noite, para o dia nascer de céu aberto.
@export var clears_at := -1.0
## Daqui em diante (minutos depois do início) nenhuma ligação sorteada, nem a da mesa vazia: só as do roteiro (-1 =
## nunca). A última noite, depois do veredito.
@export var quiet_from := -1.0

@export_group("Roteiro")
## Ligações do roteiro: sempre as mesmas, no horário marcado.
@export var story: Array[StoryCall] = []
## Ligações escritas desta noite que entram no sorteio, cada uma numa vaga sorteada no lugar de uma transferência
## (`Schedule._random_calls`): quem comenta a manchete do jornal, quem procura um parente preso. Do `StoryCall` valem
## só `call` e `requires` (conferido na hora de tocar: as versões de um mesmo assunto com marcadores opostos); não são
## missão do roteiro, não têm horário nem desfecho.
@export var calls: Array[StoryCall] = []
## Novidades da cidade nesta noite (conversa fiada): contadas antes dos assuntos gerais, uma vez por noite.
@export var smalltalk: Array[ChatTopic] = []

@export_group("Na rua")
## As cenas lá fora, na rua da vista, nesta noite (`StreetEvent`: qual, quando e se volta).
@export var street_events: Array[StreetEvent] = []

@export_group("Treinamento")
## Só a noite 0: a telefonista veterana que liga e ensina o serviço (`LessonStep`, conduzido pelo `Training`). O relógio
## só anda depois que ela termina; aí segue um turno calmo.
@export var teacher := ""
@export var teacher_voice := "f"
@export var lesson: Array[LessonStep] = []

@export_group("Jornal da manhã")
## A primeira página do jornal que está na mesa nesta noite (da segunda em diante), além das manchetes das emergências
## da noite anterior (`ShiftReport.news`). Tudo opcional: vazio, sai como sempre.
## A foto, desenhada em retícula (uma de `NewsView.PHOTOS`; vazio, a cidade de manhã); a manchete de `news_if` que
## traz a sua troca esta e a legenda (`photo_for`).
@export var news_photo := ""
## A legenda embaixo da foto (vazio = só o traço da legenda).
@export var news_caption := ""
## As matérias, uma por coluna: as duas embaixo das manchetes e a de baixo da foto, nessa ordem (as que passarem de
## três ficam de fora). A primeira linha de cada uma é o título; o que sobrar da coluna é letra miúda.
@export_multiline var news_stories: PackedStringArray = []
## Matérias que só saem com os marcadores certos, na frente das de sempre (`stories_for`).
@export var news_if: Array[StoryText] = []

@export_group("Ligações do operador")
## As ligações que o roteiro desta noite espera que o operador faça pelo discador (`DialCall`): discando o número,
## atendem elas no lugar do atendimento de sempre (as de qualquer noite ficam em `GameContent.dial`).
@export var dial: Array[DialCall] = []


## O bilhete do supervisor com os marcadores `f` (`notes`; nenhuma bate: `note`).
func note_for(f: StoryFlags) -> String:
	for v in notes:
		if f != null and f.allows(v.requires):
			return v.text
	return note


## O texto da carta com os marcadores `f` ("" sem carta).
func letter_for(f: StoryFlags) -> String:
	for v in letters:
		if f == null or f.allows(v.requires):
			return v.text
	return ""


## O texto do fim do turno com os marcadores `f` (null sem nenhum que bata).
func ending_for(f: StoryFlags) -> StoryText:
	for v in endings:
		if f.allows(v.requires):
			return v
	return null


## As matérias do jornal com os marcadores `f`: as de `news_if` que batem, depois as de sempre.
func stories_for(f: StoryFlags) -> PackedStringArray:
	var out := PackedStringArray()
	for v in news_if:
		if f != null and f.allows(v.requires):
			out.append(v.text)
	out.append_array(news_stories)
	return out


## A foto e a legenda do jornal com os marcadores `f`: as da manchete, se ela vier de `news_if` com foto; senão, as da noite.
func photo_for(f: StoryFlags) -> PackedStringArray:
	for v in news_if:
		if f != null and f.allows(v.requires):
			if v.photo != "":
				return PackedStringArray([v.photo, v.caption])
			break
	return PackedStringArray([news_photo, news_caption])
