class_name TransferCall
extends Resource
## Roteiro de um pedido de transferência: quem liga, o que diz e para qual número quer ir.

enum Group {
	ESTABLISHMENT,  ## pede um estabelecimento (pode ser a ligação do tutorial)
	PERSON,         ## pede uma pessoa com nome parecido na lista
	EXTRA,          ## outros pedidos
}

@export var group := Group.ESTABLISHMENT
## Timbre em Sfx.VOICE: f = mulher, m = homem, k = criança, w = homem mais velho/sussurro.
@export_enum("f", "m", "k", "w") var voice := "f"
@export var caller := ""
@export var opening: PackedStringArray = []
## Resposta para "Pode repetir, por favor?".
@export var repeat := ""
@export var target := ""
## Nome que vai para o caderno.
@export var destination := ""
@export var thanks := ""
## O que os dois conversam depois de conectados, para quem escutar a linha (`Eavesdrop`): uma fala por item,
## alternando quem ligou e quem atendeu, começando por quem ligou, logo depois do "alô" de quem atende
## (`DirectoryEntry.hello`; a primeira fala cumprimenta). Nos moldes, vem do motivo (`Motive.talks`, uma sorteada).
## Vazio: só o murmúrio das vozes, sem texto. A conversa anda ouvindo ou não: o que o operador não ouviu, perdeu; não
## acaba antes da última fala e, depois dela, eles se despedem e desligam.
@export var overheard: PackedStringArray = []
## Marcadores ligados (`StoryFlags.apply`) quando o operador ouve todas as falas de `overheard` (o roteiro sabe que
## aquela conversa foi ouvida).
@export var overheard_sets: PackedStringArray = []
## Na mesma ordem de `overheard`: o marcador ligado quando o operador ouve aquela fala ("nome" liga, "!nome" desliga,
## vazio nada). Para o roteiro saber se ele pegou a informação daquela fala (o nome, a hora, o lugar).
@export var overheard_flags: PackedStringArray = []
## Quão desconfiados os dois são da escuta: multiplica a subida da suspeita (2: percebem no dobro da velocidade;
## 0: nunca percebem).
@export_range(0.0, 3.0, 0.1) var wary := 1.0

## Interurbano (`target` é um tronco, `GameData.TRUNKS`): o número na outra cidade, que o operador passa à
## telefonista de lá.
@export var far_number := ""

@export_group("Se ninguém atender")
## Outro estabelecimento que o operador pode sugerir quando `target` não atende (sorteado: `PhoneCall.away`).
@export var alt_target := ""
@export var alt_destination := ""
@export var alt_ask := ""
@export var alt_yes := ""
