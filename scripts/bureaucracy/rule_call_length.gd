extends BureaucracyRule
## EXEMPLO (feito só pelo `BUREAUCRACY_RULES.md`, desligado): limite de duração da ligação. Do atendimento até o fim
## da ligação com o operador, no máximo `max_minutes` do relógio do jogo; passou, é advertência (a gravidade e o texto
## do `.tres`). Não mexe em transferência: mostra como uma regra usa só `call_started`, `call_ended` e `penalize`.
##
## Roteiro: `activate("exemplo_duracao")`; `update_params("exemplo_duracao", {"max_minutes": 5.0})`.

@export var max_minutes := 8.0


func call_started(c: PhoneCall) -> Array:
	c.meta["duracao_desde"] = desk.main.minutes
	return []


func call_ended(c: PhoneCall, _reason: PhoneCall.End) -> void:
	if not c.meta.has("duracao_desde"):
		return
	var took: float = desk.main.minutes - c.meta["duracao_desde"]
	if took > max_minutes:
		desk.penalize(self, c, severity, "ligação de %.0f min (máximo %.0f)" % [took, max_minutes], T.Key[fault_text])


func debug_info() -> String:
	return "máximo: %.0f min do relógio do jogo" % max_minutes
