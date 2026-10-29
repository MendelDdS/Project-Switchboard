extends Resource
## Uma cena na rua da vista numa noite (`Night.street_events`, `PLANO_RUA.md`): qual (`kind`), quando começa (minutos
## depois do início do turno) e, se volta, de quantos em quantos minutos (`every`; 0 = uma vez). "beating": o policial
## que espanca um homem na boca do cruzamento (`Beating`; antes das 22h, com gente na calçada para assistir);
## "police": a viatura que para no hotel (`PATROL_*`); "lookout": o vigia no terraço do hotel (`LOOKOUT_*`); "curfew": o toque de recolher (`CURFEW_*`: a viatura varrendo as
## calçadas com o holofote, a rua esvaziando e ninguém mais depois).

@export_enum("beating", "police", "lookout", "curfew") var kind := "beating"
@export var at := 190.0
@export var every := 0.0
