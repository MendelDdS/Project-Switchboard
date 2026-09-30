class_name Street
extends Resource
## Uma rua do mapa. Cada rua tem 3 trechos de numeração (1–99, 100–199, 200–299).

@export var id := ""
@export var name := ""
@export var horizontal := true
## y da rua (se horizontal) ou x (se vertical), em pixels do mapa de 600x440.
@export var pos := 0.0
