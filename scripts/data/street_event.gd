extends Resource
## Uma cena na rua da vista numa noite (`Night.street_events`, `PLANO_RUA.md`): qual (`kind`), quando começa (minutos
## depois do início do turno) e, se volta, de quantos em quantos minutos (`every`; 0 = uma vez). "beating": o policial
## que espanca um homem na boca do cruzamento (`Beating`; antes das 22h, com gente na calçada para assistir);
## "police": a viatura que para no hotel (`PATROL_*`); "lookout": o vigia no terraço do hotel (`LOOKOUT_*`); "curfew": o toque de recolher (`CURFEW_*`: a viatura varrendo as
## calçadas com o holofote, a rua esvaziando e ninguém mais depois); "speaker": o carro de som (`SPEAKER_*`); "chase":
## a corrida (`Chase`); "flyers": os panfletos (`Flyers`); "graffiti" e "paint": a pichação e a tinta por cima
## (`Graffiti`); "newsstand": a banca esvaziada e lacrada (`Newsstand`, antes das 19h); "parade": o caminhão do
## exército (`ARMY_*`). Pichação, tinta e banca ficam nas noites seguintes (`Background.left_behind`).

@export_enum("beating", "police", "lookout", "curfew", "speaker", "chase", "flyers", "graffiti", "paint", "newsstand", "parade") var kind := "beating"
@export var at := 190.0
@export var every := 0.0
