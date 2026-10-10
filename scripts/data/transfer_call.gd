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

## Interurbano (`target` é um tronco, `GameData.TRUNKS`): o número na outra cidade, que o operador passa à
## telefonista de lá.
@export var far_number := ""

@export_group("Se ninguém atender")
## Outro estabelecimento que o operador pode sugerir quando `target` não atende (sorteado: `PhoneCall.away`).
@export var alt_target := ""
@export var alt_destination := ""
@export var alt_ask := ""
@export var alt_yes := ""
