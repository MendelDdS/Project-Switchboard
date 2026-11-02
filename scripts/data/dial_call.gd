extends Resource
## Uma ligação que o operador faz e que o roteiro precisa (o discador, `Dialing`): discando `number` (que pode nem
## estar na lista telefônica), com os marcadores batendo e dentro do horário, atende este roteiro no lugar do
## atendimento de sempre do lugar (`DirectoryEntry.answers`). Fica em `Night.dial` (só naquela noite) ou em
## `GameContent.dial` (em qualquer uma). Feita até o fim, liga os marcadores `sets` e, com `once`, o marcador
## `discou_<nome do arquivo>` (`done_flag`), que a tira da vez nas noites seguintes.
## Sem `class_name` (como as cenas da rua): quem usa faz `preload` (classe nova só vale depois de reimportar).

@export var number := ""
## Só atende se os marcadores baterem (StoryFlags.allows): todos ligados; com "!" na frente, desligados.
@export var requires: PackedStringArray = []
## Atende de `from` até `to` (minutos depois das 18h); fora disso, o número atende como sempre.
@export var from := 0.0
@export var to := 720.0
## Quem atende: o nome na conversa e a voz (`SfxSynth.VOICE`). Vazios: os do lugar na lista.
@export var caller := ""
@export_enum("Do lugar:", "f", "m", "k", "w") var voice := ""
## O roteiro falado, no formato dos trotes (CALLER, OPERATOR com `sets`, PAUSE, END, EFFECT).
@export var steps: Array[PrankStep] = []
## Marcadores ligados ("nome") ou desligados ("!nome") quando a conversa vai até o fim.
@export var sets: PackedStringArray = []
## Uma vez só: feita até o fim, o número volta ao atendimento de sempre.
@export var once := true


## O marcador que diz que ela já foi feita (`once`): um por ligação, também as de dentro de uma noite
## ("night_15.tres::D_ser" dá `discou_night_15_D_ser`; antes todas da noite davam o mesmo e a primeira calava as outras).
func done_flag() -> String:
	return "discou_" + resource_path.get_file().replace(".tres", "").replace("::", "_")
