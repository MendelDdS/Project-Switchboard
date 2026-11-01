extends Resource
## Uma cena na rua da vista numa noite (`Night.street_events`, `PLANO_RUA.md`): qual (`kind`), quando começa (minutos
## depois do início do turno) e, se volta, de quantos em quantos minutos (`every`; 0 = uma vez). "beating": o policial
## que espanca um homem na boca do cruzamento (`Beating`; antes das 22h, com gente na calçada para assistir);
## "police": a viatura que para no hotel (`PATROL_*`); "lookout": o vigia no terraço do hotel (`LOOKOUT_*`); "curfew": o toque de recolher (`CURFEW_*`: a viatura varrendo as
## calçadas com o holofote, a rua esvaziando e ninguém mais depois); "speaker": o carro de som (`SPEAKER_*`); "chase":
## a corrida (`Chase`); "flyers": os panfletos (`Flyers`); "graffiti" e "paint": a pichação e a tinta por cima
## (`Graffiti`); "newsstand": a banca esvaziada e lacrada (`Newsstand`, antes das 19h); "parade": o caminhão do
## exército (`ARMY_*`); "moving": a família do apartamento da varanda fugindo de Kombi (`Moving`, antes das 21h); "flare": o sinalizador
## vermelho atirado no céu e descendo devagar (`Flare`); "raid": a batida no hotel, o camburão e a viatura, cinco presos
## levados algemados (`Raid`); "stone": a pedra atirada da rua que trinca a janela da sala (`Stone`); "banner": a bandeira estendida na varanda do apartamento (`Banner`);
## "stranger": o homem de sobretudo embaixo do poste
## da esquina do prédio de tijolos por `MAN_STAY` min (`Background.stranger`).
## Pichação, tinta, banca, o apartamento vazio e o vidro trincado ficam nas noites seguintes (`Background.left_behind`).

@export_enum("beating", "police", "lookout", "curfew", "speaker", "chase", "flyers", "graffiti", "paint", "newsstand", "parade", "moving", "flare", "raid", "stone", "stranger", "banner") var kind := "beating"
@export var at := 190.0
@export var every := 0.0
## Só acontece se os marcadores baterem na hora dela (`StoryFlags.allows`; vazio: sempre): a pedra só com o fator
## sucesso médio ou baixo, a batida só com uma fita do hotel na polícia. Quando acontece, liga "rua_<kind>_<noite>"
## (o que ela deixa fica para as noites seguintes só assim, `Background.left_behind`).
@export var requires: PackedStringArray = []
