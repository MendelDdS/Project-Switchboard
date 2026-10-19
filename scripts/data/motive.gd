class_name Motive
extends Resource
## Um motivo para ligar a um contato da lista (`DirectoryEntry.motives`): o que quem liga diz ao operador e o que
## conversa com o lugar depois de conectado (o que se ouve na escuta, `Eavesdrop`). Os dois juntos, para a conversa
## nunca sair do assunto do pedido.

## O que quem liga diz ao pedir a ligação, uma frase (lacuna {reason} dos moldes). Serve para homem ou mulher.
@export var text := ""
## As conversas depois de conectados, uma sorteada por ligação (vira o `TransferCall.overheard` do molde): cada uma
## começa por quem ligou, logo depois do "alô" do lugar (`DirectoryEntry.hello`), e alterna; de 4 a 6 falas, com o
## que importa no meio (a primeira, quem ouve chegando atrasado perde). Sem dizer o tipo do lugar quando ele tem ramo:
## se ele não atender, quem atende é outro do mesmo ramo (`GameData.alternative`). Lacunas sorteadas por conversa
## (`TalkFill`: {hour}, {wait}...) mudam o que se ouve de uma vez para outra. Vazio: só o murmúrio.
@export var talks: Array[PackedStringArray] = []
