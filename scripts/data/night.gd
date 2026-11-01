class_name Night
extends Resource

const StreetEvent := preload("res://scripts/data/street_event.gd")
const DialCall := preload("res://scripts/data/dial_call.gd")
const StoryText := preload("res://scripts/data/story_text.gd")
## Uma noite do jogo: o bilhete do começo e o roteiro fixo (ligações da história e a ligação desconhecida). Fica em
## res://data/nights/, na ordem de GameContent.nights. Só o roteiro é fixo; o resto do turno (quem liga, quando, de que
## tipo) é sorteado no ritmo do nível em que o jogador está (`Pace`, que não depende da noite).

## Bilhete do supervisor na tela inicial...
@export_multiline var note := ""
## ...ou a primeira destas versões cujos marcadores batem (`note_for`).
@export var notes: Array[StoryText] = []
## A carta da noite, na mesa (em cima do jornal) desde o começo do turno: a primeira destas versões cujos marcadores
## batem (`letter_for`; nenhuma, sem carta). O jogador abre quando quiser (`Tools.LETTER`).
@export var letters: Array[StoryText] = []
## Clima fixo da noite; vazio ("Sorteado") = sorteado.
@export_enum("Sorteado:", "rain", "fog", "clear") var weather := ""
## O fim do turno (minutos depois do início, às 18h): 360 = meia-noite; a última noite vai até as 6h (720).
@export var shift_end := 360.0
## A chuva ou a névoa vão parando até esta hora (minutos depois do início) e a noite fica limpa (-1 = nunca): na
## última noite, para o dia nascer de céu aberto.
@export var clears_at := -1.0

@export_group("Roteiro")
## Ligações do roteiro: sempre as mesmas, no horário marcado.
@export var story: Array[StoryCall] = []
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
## A foto (vazio = a cidade de manhã, desenhada em retícula), ajustada à coluna dela sem deformar.
@export var news_photo: Texture2D
## A legenda embaixo da foto (vazio = só o traço da legenda).
@export var news_caption := ""
## As matérias, uma por coluna: as duas embaixo das manchetes e a de baixo da foto, nessa ordem (as que passarem de
## três ficam de fora). A primeira linha de cada uma é o título; o que sobrar da coluna é letra miúda.
@export_multiline var news_stories: PackedStringArray = []
## Matérias que só saem com os marcadores certos, na frente das de sempre (`stories_for`).
@export var news_if: Array[StoryText] = []

@export_group("Ligação desconhecida")
## O que se diz na ligação desconhecida (vazio = ela não toca nesta noite). Passos EFFECT: "static",
## "static_loud", "flick" (a lâmpada da mesa pisca).
@export var mystery: Array[PrankStep] = []
## Toca em algum momento entre estes minutos depois do início do turno, só com a mesa em silêncio.
@export var mystery_from := 240.0
@export var mystery_to := 330.0

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


## As matérias do jornal com os marcadores `f`: as de `news_if` que batem, depois as de sempre.
func stories_for(f: StoryFlags) -> PackedStringArray:
	var out := PackedStringArray()
	for v in news_if:
		if f != null and f.allows(v.requires):
			out.append(v.text)
	out.append_array(news_stories)
	return out
