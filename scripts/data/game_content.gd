class_name GameContent
extends Resource
## Todo o conteúdo do jogo: lista telefônica, cidade, roteiros das ligações e falas avulsas.
## Fica em res://data/content.tres; os roteiros de ligação são arquivos próprios em res://data/calls/.
## Para criar uma ligação nova: duplique um .tres em data/calls/, edite e arraste para a lista certa aqui.

@export_group("Lista telefônica e cidade")
## Em ordem alfabética (é a ordem da lista telefônica).
@export var directory: Array[DirectoryEntry] = []
@export var streets: Array[Street] = []
@export var block_labels: PackedStringArray = ["1–99", "100–199", "200–299"]
## Tipos de ocorrência no despacho.
@export var occurrences: PackedStringArray = []

@export_group("Agenda")
## Minutos depois das 22:00 em que tocam as 4 ligações principais
## (transferência de estabelecimento, transferência de pessoa, emergência, trote).
@export var main_call_at: PackedFloat32Array = [5, 38, 84, 170]

@export_group("Roteiros")
@export var transfers: Array[TransferCall] = []
@export var emergencies: Array[EmergencyCall] = []
@export var pranks: Array[PrankCall] = []

@export_group("Falas avulsas")
## Como o operador atende.
@export var greetings: PackedStringArray = []
## Conversa fiada que às vezes vem depois do pedido.
@export var smalltalk: PackedStringArray = []
## Solicitante esperando a transferência.
@export var waiting: PackedStringArray = []
## Solicitante de emergência esperando o despacho.
@export var emergency_waiting: PackedStringArray = []
## Resposta a "Um momento, vou conectar.".
@export var hold_ok: PackedStringArray = []
## Quando o destino errado atende.
@export var wrong_destination: PackedStringArray = []

@export_group("Pedidos de informação")
## "voz:nome", ex.: "f:Moradora".
@export var info_callers: PackedStringArray = []
## %s vira "do Hotel Estrela" (DirectoryEntry.spoken com "d" na frente).
@export var ask_number: PackedStringArray = []
@export var ask_time: PackedStringArray = []
@export var info_thanks: PackedStringArray = []
@export var info_doubt: PackedStringArray = []
