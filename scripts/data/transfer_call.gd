class_name TransferCall
extends Resource
## Roteiro de um pedido de transferência: quem liga, o que diz e para qual número quer ir.

## B1: como quem liga responde à identificação obrigatória: diz o nome sozinho, recusa sempre, recusa e cede se o
## operador insistir, ou diz quando o operador pede.
enum Identify { YES, NO, IF_PRESSED, WHEN_ASKED }

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

@export_group("Burocracias")
## B1, identificação: nome e sobrenome de quem liga. O chat mostra `caller` até ele dizer o nome (`name_line`) e este
## dali em diante; o registro de decisões usa.
@export var caller_name := ""
## B1: como responde à identificação (`Identify`); como diz o nome ("Aqui é Lúcia Pereira."), como recusa ("Meu nome
## não interessa.") e, com NO, como recusa de novo quando o operador insiste.
@export var identify := Identify.YES
@export var name_line := ""
@export var refuse_line := ""
@export var refuse_again_line := ""
## B1, recado: o texto que quem liga deixa (dito na abertura, `opening`) para o número `message_to`; o operador anota
## ou recusa, e mais tarde repassa ou não (`Bureaucracy.messages`).
@export var message := ""
@export var message_to := ""
## B1: o que quem recebe este recado responde quando o operador repassa (escrito junto com o recado, para fazer
## sentido); vazio, fica calado.
@export var message_reply := ""
## B1 e B2: a reação de quem liga quando o operador nega o que ele pediu (o recado recusado, o acordo recusado, o
## número bloqueado), antes de desligar ("Pois então esquece. Boa noite."). Aceito o recado ou o acordo, ele agradece
## (`thanks`) e desliga.
@export var refused_line := ""
## O número de onde a pessoa liga (o recado deixado para ele chega a ela). Vazio: não se sabe.
@export var from_number := ""
## B2: pedido urgente (um parente no hospital...): para um número bloqueado, o operador aceita (transfere, com a
## advertência) ou nega (avisa o bloqueio); as duas são decisão moral no registro. `urgency_reason` resume o motivo.
@export var urgent := false
@export var urgency_reason := ""
## B2: o sinal combinado que quem liga dá logo depois do "alô": "estalos" (três estalos de dedo, no ritmo da noite,
## `rule_blocked.gd`) ou outro texto, dito como fala (uma palavra, "(um assobio)"). Com um acordo de redirecionamento para o número pedido com este sinal, o
## destino certo passa a ser o do acordo.
@export var secret_signal := ""
## B2, quem propõe o acordo: as ligações para `deal_from` vão para `deal_to` quando quem ligar der `deal_signal`.
@export var deal_from := ""
@export var deal_to := ""
@export var deal_signal := ""
## B4: marcada pelas autoridades para gravar (as palavras-chave são as marcas `[tipo:texto]` de `overheard`, `Clue`).
@export var suspicious := false
## B3, o código de autorização que quem liga diz logo depois do pedido (só com a regra valendo): com {code}, diz o
## certo da noite ("Autorização {code}."); com outro escrito no lugar, diz esse (errado); vazio, não tem nenhum (se o
## operador pedir, reage, `refused_line` ou uma reação da regra, e desliga).
@export var code_line := ""
## B3: tem o código, mas só lembra de dizer quando o operador pede ([Pedir a autorização]).
@export var code_when_asked := false
## B3: pede ao operador o próximo código de autorização (ele pode revelar ou recusar).
@export var wants_next_code := false
