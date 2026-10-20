class_name GameContent
extends Resource
## Todo o conteúdo do jogo: lista telefônica, cidade, roteiros das ligações e falas avulsas.
## Fica em res://data/content.tres; os roteiros de ligação são arquivos próprios em res://data/calls/.
## Para criar uma ligação nova: duplique um .tres em data/calls/, edite e arraste para a lista certa aqui.
## Moldes (data/templates/) são roteiros com lacunas em inglês, preenchidas na hora (veja GameData.fill).
## Cada noite (data/nights/) tem o próprio roteiro fixo (veja Night); o ritmo vem dos níveis (`paces`).

@export_group("Lista telefônica e cidade")
## Em ordem alfabética (é a ordem da lista telefônica).
@export var directory: Array[DirectoryEntry] = []
@export var streets: Array[Street] = []
## Tipos de ocorrência no despacho.
@export var occurrences: PackedStringArray = []

@export_group("Noites")
## Em ordem; cada uma com o bilhete e o roteiro fixo dela (data/nights/).
@export var nights: Array[Night] = []
## A noite 0, antes da primeira: o treinamento (`Night.lesson`) e um turno calmo. Fica fora de `nights`.
@export var training: Night
## Níveis de ritmo das ligações sorteadas, do mais calmo ao limite (veja Pace): o 1 é o da primeira noite e o último
## vale para todas as noites depois de chegar nele.
@export var paces: Array[Pace] = []

@export_group("Sala")
## O que muda na sala do operador ao longo das noites, pelos marcadores do roteiro.
@export var room: Array[RoomChange] = []

@export_group("Roteiros")
@export var transfers: Array[TransferCall] = []
@export var emergencies: Array[EmergencyCall] = []
@export var pranks: Array[PrankCall] = []

@export_group("Moldes")
## Transferências com lacunas: {place} "o Hotel Estrela", {of_place} "do Hotel Estrela", {to_place} "pro Hotel Estrela",
## {street} rua do contato, {number} "305", {digits} "três, zero, cinco", {reason} um dos motivos do contato.
## Só vão para contatos com `spoken` e `motives` que atendem à noite (a conversa depois de conectados vem do motivo).
## Quem liga sai de `callers`.
@export var transfer_templates: Array[TransferCall] = []
## Agradecimento de quem foi transferido por molde (sem gênero: quem liga é sorteado).
@export var transfer_thanks: PackedStringArray = []
## Interurbanos com lacunas: {to_city} "pra Capital" (`trunk_to`) e {far} o número na outra cidade. Vão para um
## tronco sorteado (`GameData.trunk_transfer`).
@export var trunk_templates: Array[TransferCall] = []
## "pra Capital", "pro Norte"...: uma por tronco, na ordem de `GameData.TRUNKS`.
@export var trunk_to: PackedStringArray = []
## Emergências com lacunas: {street} "Rua do Sol", {house} "145", {address} "Rua do Sol, 145" (rua e número sorteados).
## Rua, trecho e endereço do molde são ignorados; ocorrência e unidades valem.
@export var emergency_templates: Array[EmergencyCall] = []
## Às vezes (`GameData.LANDMARK_CHANCE`) quem liga não diz o número, mas a rua e um lugar do mapa: {street} "Rua do Sol",
## {landmark} "do posto" (`MAP_*_OF`). A primeira forma também vai para o rádio e o caderno ("Rua do Sol, perto do posto").
@export var address_landmark: PackedStringArray = []

@export_group("Falas avulsas")
## Como o operador atende.
@export var greetings: PackedStringArray = []
## Conversa fiada de quem espera a transferência: cada assunto com as respostas do operador (`ChatTopic`).
@export var smalltalk: Array[ChatTopic] = []
## Primeira resposta a "E aí, como vai a noite?", antes de puxar o assunto.
@export var chat_bridge: PackedStringArray = []
## Solicitante esperando a transferência.
@export var waiting: PackedStringArray = []
## Solicitante de emergência esperando o despacho.
@export var emergency_waiting: PackedStringArray = []
## Resposta a "Um momento, vou conectar.".
@export var hold_ok: PackedStringArray = []
## Quem aceita o outro estabelecimento que o operador sugeriu (moldes; os roteiros escritos têm `alt_yes`).
@export var alt_accepted: PackedStringArray = []
## Quando o destino errado atende.
@export var wrong_destination: PackedStringArray = []

## A telefonista da outra cidade atende o tronco (o operador então passa o número)...
@export var trunk_hello: PackedStringArray = []
## ...e vai chamar lá.
@export var trunk_wait: PackedStringArray = []
## No tronco errado, o número não é de lá.
@export var trunk_unknown: PackedStringArray = []

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
## Escuta (`Eavesdrop`): o "alô" de quem atende sem `DirectoryEntry.hello` (as pessoas)...
@export var overheard_hello: PackedStringArray = []
## ...e o cumprimento de quem ligou, quando a conversa não tem falas escritas...
@export var overheard_greet: PackedStringArray = []
## ...as lacunas das falas escritas ({hour}, {wait}...; `TalkFill`; {street} e {house} vêm do mapa)...
@export var talk_fills: Array[TalkFill] = []
## ...a despedida de quem fala depois da última fala escrita e a resposta do outro (servem para os dois lados)...
@export var overheard_bye: PackedStringArray = []
@export var overheard_bye_back: PackedStringArray = []
## ...um desconfia que tem alguém na linha e pergunta ao outro...
@export var overheard_ask: PackedStringArray = []
## ...e, com o operador ainda ouvindo, o outro responde e os dois ficam sabendo (na mesma ordem de `overheard_ask`:
## cada resposta é a da sua pergunta)...
@export var overheard_sure: PackedStringArray = []
## ...e, tendo certeza, desliga para denunciar a telefonista.
@export var overheard_caught: PackedStringArray = []
## Manchetes do jornal da manhã: {occurrence} e {address}.
@export var news_ok: PackedStringArray = []
@export var news_late: PackedStringArray = []
@export var news_bad: PackedStringArray = []
## O que o supervisor escreve no fim do relatório, um por conceito (`ShiftReport.Grade`: Ótimo a Insuficiente).
@export var verdicts: PackedStringArray = []
## O parecer da noite da demissão (a segunda seguida abaixo do mínimo), no lugar do do conceito.
@export_multiline var verdict_fired := ""
## O lembrete no bilhete da noite seguinte a uma Insuficiente: esta decide.
@export_multiline var low_warning := ""

@export_group("Pedidos de informação")
## %s vira "do Hotel Estrela" (DirectoryEntry.spoken com "d" na frente).
@export var ask_number: PackedStringArray = []
@export var info_thanks: PackedStringArray = []
@export var info_doubt: PackedStringArray = []
