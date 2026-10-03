class_name Street
extends Resource
## Uma rua do mapa. Cada folha (setor) tem a mesma grade, e a rua passa por uma folha com 3 trechos de numeração
## (1–99, 100–199, 200–299); se continua na folha vizinha, segue a numeração lá (300–599) com o mesmo nome.

@export var id := ""
@export var name := ""
## Setor (bairro) da folha onde a rua começa (trechos 1–299): cada setor é uma folha do mapa (CityMap.SHEETS).
@export var sector := 3
## Setor da folha vizinha para onde a rua continua (trechos 300–599); 0 = termina na folha dela.
@export var continues := 0
@export var horizontal := true
## y da rua (se horizontal) ou x (se vertical), em pixels da folha (600x440); é o mesmo nas duas folhas.
@export var pos := 0.0


func blocks() -> int:
	return 6 if continues != 0 else 3


## Setor do trecho `b` (0..blocks()-1).
func block_sector(b: int) -> int:
	return sector if b < 3 else continues


## "1–99", "100–199", ... do trecho `b`.
static func block_label(b: int) -> String:
	return "%d–%d" % [maxi(1, b * 100), b * 100 + 99]
