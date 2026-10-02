class_name GameContent
extends Resource
## Todo o conteúdo do jogo: lista telefônica, cidade, roteiros das ligações e falas avulsas.
## Fica em res://data/content.tres; os roteiros de ligação são arquivos próprios em res://data/calls/.
## Para criar uma ligação nova: duplique um .tres em data/calls/, edite e arraste para a lista certa aqui.
## Moldes (data/templates/) são roteiros com lacunas em inglês, preenchidas na hora (veja GameData.fill).
## Cada noite (data/nights/) tem a própria agenda e o roteiro fixo (veja Night).

@export_group("Lista telefônica e cidade")
## Em ordem alfabética (é a ordem da lista telefônica).
@export var directory: Array[DirectoryEntry] = []
@export var streets: Array[Street] = []
@export var block_labels: PackedStringArray = ["1–99", "100–199", "200–299"]
## Tipos de ocorrência no despacho.
@export var occurrences: PackedStringArray = []

@export_group("Noites")
## Em ordem; cada uma com a agenda e o roteiro fixo dela (data/nights/).
@export var nights: Array[Night] = []

@export_group("Roteiros")
@export var transfers: Array[TransferCall] = []
@export var emergencies: Array[EmergencyCall] = []
@export var pranks: Array[PrankCall] = []

@export_group("Moldes")
## Transferências com lacunas: {place} "o Hotel Estrela", {of_place} "do Hotel Estrela", {to_place} "pro Hotel Estrela",
## {street} rua do contato, {number} "305", {digits} "três, zero, cinco", {reason} um dos motivos do contato.
## Só vão para contatos com `spoken` e `reasons` que atendem à noite. Quem liga sai de `callers`.
@export var transfer_templates: Array[TransferCall] = []
## Agradecimento de quem foi transferido por molde (sem gênero: quem liga é sorteado).
@export var transfer_thanks: PackedStringArray = []
## Emergências com lacunas: {street} "Rua do Sol", {house} "145", {address} "Rua do Sol, 145" (rua e número sorteados).
## Rua, trecho e endereço do molde são ignorados; ocorrência e unidades valem.
@export var emergency_templates: Array[EmergencyCall] = []

@export_group("Falas avulsas")
## Como o operador atende.
@export var greetings: PackedStringArray = []
## Conversa fiada de quem espera a transferência: cada assunto com as respostas do operador (`ChatTopic`).
@export var smalltalk: Array[ChatTopic] = []
## Solicitante esperando a transferência.
@export var waiting: PackedStringArray = []
## Solicitante de emergência esperando o despacho.
@export var emergency_waiting: PackedStringArray = []
## Resposta a "Um momento, vou conectar.".
@export var hold_ok: PackedStringArray = []
## Quando o destino errado atende.
@export var wrong_destination: PackedStringArray = []

## Quem liga nos pedidos de informação e nos moldes: "voz:nome", ex.: "f:Moradora".
@export var callers: PackedStringArray = []

@export_group("Supervisor e consequências")
## Quem liga de novo porque ninguém atendeu.
@export var retry_missed: PackedStringArray = []
## Quem liga de novo porque recebeu a informação errada.
@export var retry_wrong_info: PackedStringArray = []
## Quem liga de novo porque foi conectado ao número errado (e pede o certo).
@export var retry_wrong_number: PackedStringArray = []
## Emergência que liga de novo: ninguém chegou e a situação piorou (ainda dá para despachar).
@export var retry_worse: PackedStringArray = []
## Emergência que liga de novo quando já não adianta.
@export var retry_too_late: PackedStringArray = []
## Quem atende no número errado, acordado no meio da noite.
@export var woken_up: PackedStringArray = []
## Solicitante que desiste depois da segunda conexão errada.
@export var gave_up: PackedStringArray = []
## Manchetes do jornal da manhã: {occurrence} e {address}.
@export var news_ok: PackedStringArray = []
@export var news_late: PackedStringArray = []
@export var news_bad: PackedStringArray = []
## O que o supervisor escreve no fim do relatório: turno bom, atenção, turno ruim.
@export var verdicts: PackedStringArray = []

@export_group("Pedidos de informação")
## %s vira "do Hotel Estrela" (DirectoryEntry.spoken com "d" na frente).
@export var ask_number: PackedStringArray = []
@export var info_thanks: PackedStringArray = []
@export var info_doubt: PackedStringArray = []
