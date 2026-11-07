class_name BureaucracyRule
extends Resource
## Uma burocracia: norma que o supervisor e as autoridades impõem à telefonista, um `.tres` em `data/bureaucracy/`
## com um script que estende este. O `Bureaucracy` (o gerente) não conhece nenhuma regra: só chama os ganchos abaixo
## em todas as que valem agora (`applies`). Cada regra sobrescreve só os ganchos de que precisa; o padrão não faz nada.
## O jogador nunca é impedido: a regra devolve um `Verdict` e quem decide a advertência é o gerente (a maior da
## tentativa; todas vão para o registro de decisões). Como criar uma: `BUREAUCRACY_RULES.md`.
##
## Roteiro: `main.bureaucracy.activate("id")` liga a regra (vale de `from_night` a `to_night`); `deactivate` desliga;
## `update_params("id", {"campo": valor})` muda o que ela expõe (`@export` do script dela).

## O que a regra diz de uma tentativa de transferência (`before_transfer`).
class Verdict:
	enum Kind { ALLOWED, INFRACTION }   ## permitido / infração (vira advertência)
	var kind := Kind.ALLOWED
	var severity := ShiftReport.Severity.MEDIUM
	var reason := ""   ## o que aconteceu, em poucas palavras: o detalhe da advertência e o resultado no registro

	static func allowed(why := "") -> Verdict:
		var v := Verdict.new()
		v.reason = why
		return v

	static func infraction(sev: ShiftReport.Severity, why: String) -> Verdict:
		var v := Verdict.new()
		v.kind = Kind.INFRACTION
		v.severity = sev
		v.reason = why
		return v

## Identificador único (o registro de decisões e o roteiro usam este nome).
@export var id := ""
## Nome no painel de debug.
@export var title := ""
## Ligada: pelo roteiro (`Bureaucracy.activate`) ou pelo debug. Desligada, nenhum gancho dela roda.
@export var active := false
## Noites em que vale, se ligada (0 em `to_night`: sem fim).
@export var from_night := 1
@export var to_night := 0
## A gravidade da advertência dela (`ShiftReport.Severity`) e o texto no relatório (o nome de uma chave `T.Key`,
## como "FAULT_BUREAUCRACY").
@export var severity := ShiftReport.Severity.MEDIUM
@export var fault_text := "FAULT_BUREAUCRACY"
## A tarefa dela no diário de Maria (o nome de uma chave `T.Key`, como "DIARY_B1"; vazio: nenhuma), riscada no turno
## encerrado se a noite não teve advertência dela (`Diary`).
@export var task_text := ""
## Os equipamentos que ela traz para a mesa (`scenes/ui/equipment/<id>.tscn`, na prateleira embaixo do interurbano ou,
## com `metadata/side` na cena, na coluna do lado do painel, `Switchboard.side_rect`):
## chegam na primeira vez que ela vale (`Bureaucracy.unlock_equipment`) e ficam, a não ser que `keep_equipment` seja
## falso (aí saem quando ela é desligada).
@export var equipment := PackedStringArray()
@export var keep_equipment := true
## DADOS DE TESTE: ligações que o painel de debug toca, um botão por item (o nome do botão é o `resource_name`).
@export var tests: Array[TransferCall] = []

var desk: Bureaucracy   ## o gerente desta cena (posto por ele ao carregar a regra)


## Vale agora: ligada e dentro das noites dela.
func applies(night: int) -> bool:
	return active and night >= from_night and (to_night == 0 or night <= to_night)


## Uma infração com a gravidade e o texto da regra.
func infraction(why: String) -> Verdict:
	return Verdict.infraction(severity, why)


# ---------------------------------------------------------------- ganchos (sobrescreva os que usar)

## A noite começou (o turno) e terminou (antes do relatório).
func night_started() -> void:
	pass


func night_ended() -> void:
	pass


## A ligação foi atendida e o operador já disse o "alô" (`Conversation.greet`): as falas de agora, em ordem (o gerente
## diz): texto é de quem liga; {"op": texto}, do operador; {"sys": texto}, um aviso na conversa. Síncrono de
## propósito: um `await` dentro de um Resource às vezes devolvia o estado da corrotina (`GDScriptFunctionState`) para
## quem esperava, em vez do resultado.
func call_started(_c: PhoneCall) -> Array:
	return []


## Quem liga acabou de pedir a transferência (`TransferCall.opening`): as falas de agora, como em `call_started` (o
## código de autorização, o aviso de que o número está bloqueado).
func request_made(_c: PhoneCall) -> Array:
	return []


## Opções a mais para o operador enquanto o pedido de transferência espera (`Conversation.transfer_choices`):
## {"label": texto, "fn": Callable}. O texto é do operador: "[Ação]" ou a fala curta (`CHOICE_*`).
func choices(_c: PhoneCall) -> Array[Dictionary]:
	return []


## O operador apertou Transferir para o destino `d`. Nulo: a regra não tem nada a dizer desta tentativa.
func before_transfer(_c: PhoneCall, _d: int) -> Verdict:
	return null


## A transferência completou (os dois conectados).
func transfer_done(_c: PhoneCall) -> void:
	pass


func call_ended(_c: PhoneCall, _reason: PhoneCall.End) -> void:
	pass


## A chave de escuta da linha `n` subiu (`on`) ou desceu.
func listening(_n: int, _on: bool) -> void:
	pass


## Uma palavra-chave da escuta (`Clue`) foi ouvida inteira.
func clue_heard(_k: Clue) -> void:
	pass


## Quem falava em `c` percebeu a escuta e vai denunciar: verdadeiro se a regra cobra do jeito dela, no lugar da
## advertência por escuta (`Eavesdrop._denounce`).
func caught_listening(_c: PhoneCall) -> bool:
	return false


## O painel de debug mostra isto embaixo do nome da regra (o código do dia, a fila de recados...).
func debug_info() -> String:
	return ""


## Botões a mais no painel de debug: [[texto, Callable]]. As ligações de `tests` já ganham o delas.
func debug_actions() -> Array:
	return []
