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
@export var call_gap := Vector2(12.0, 32.0)
## Quantas emergências e quantos trotes entre as ligações sorteadas.
@export var emergencies := Vector2i(1, 2)
@export var pranks := Vector2i(0, 2)
## Ligações do roteiro: sempre as mesmas, no horário marcado.
@export var story: Array[StoryCall] = []

@export_group("Ligação desconhecida")
## O que se diz na ligação desconhecida (vazio = ela não toca nesta noite). Passos EFFECT: "static",
## "static_loud", "flick" (a lâmpada da mesa pisca).
@export var mystery: Array[PrankStep] = []
## Toca em algum momento entre estes minutos depois do início do turno, só com a mesa em silêncio.
@export var mystery_from := 240.0
@export var mystery_to := 330.0
