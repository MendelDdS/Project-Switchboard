class_name Night
extends Resource
## Uma noite do jogo: o bilhete do começo, o ritmo das ligações sorteadas e o roteiro fixo (ligações da história e
## a ligação desconhecida). Fica em res://data/nights/, na ordem de GameContent.nights.
## Só o roteiro é fixo; o resto do turno (quem liga, quando, de que tipo) é sorteado.

@export var weekday := "Terça-feira"
## Bilhete do supervisor na tela inicial.
@export_multiline var note := ""
## Clima fixo da noite; vazio ("Sorteado") = sorteado.
@export_enum("Sorteado:", "rain", "fog", "clear") var weather := ""
## A primeira ligação da noite é uma transferência guiada passo a passo.
@export var tutorial := false

@export_group("Agenda")
## Minutos de jogo entre uma ligação sorteada e a próxima (o máximo é o maior silêncio possível).
## A primeira noite é calma e o ritmo sobe aos poucos de uma noite para a outra (medir com o robô `--human`).
@export var call_gap := Vector2(28.0, 42.0)
## Chance de a próxima ligação vir logo em seguida (2–6 min): duas linhas juntas.
@export_range(0.0, 1.0) var peak_chance := 0.05
## Ligações tocando ou em andamento (ainda não conectadas) ao mesmo tempo; com tantas, a próxima espera.
@export_range(1, 10) var max_live := 3
## Quantas emergências e quantos trotes entre as ligações sorteadas.
@export var emergencies := Vector2i(1, 2)
@export var pranks := Vector2i(0, 2)
## Ligações do roteiro: sempre as mesmas, no horário marcado.
@export var story: Array[StoryCall] = []
## Novidades da cidade nesta noite (conversa fiada): contadas antes dos assuntos gerais, uma vez por noite.
@export var smalltalk: Array[ChatTopic] = []

@export_group("Ligação desconhecida")
## O que se diz na ligação desconhecida (vazio = ela não toca nesta noite). Passos EFFECT: "static",
## "static_loud", "flick" (a lâmpada da mesa pisca).
@export var mystery: Array[PrankStep] = []
## Toca em algum momento entre estes minutos depois do início do turno, só com a mesa em silêncio.
@export var mystery_from := 240.0
@export var mystery_to := 330.0
