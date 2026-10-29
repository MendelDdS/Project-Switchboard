extends RefCounted
## Os acordos de redirecionamento (`Bureaucracy.agreements`): alguém pediu que as ligações para um número (`from`)
## sejam passadas para outro (`to`) quando quem liga der um sinal combinado (`signal`: um estalo, um apito, uma
## palavra). Qualquer regra pode usar; a B2 propõe e cumpre. Ficam salvos entre as noites (`Bureaucracy.state`).

var items: Array[Dictionary] = []   ## {"from", "to", "signal", "night"}


func add(from: String, to: String, sig: String, night: int) -> void:
	remove(from)
	items.append({"from": from, "to": to, "signal": sig, "night": night})


func remove(from: String) -> void:
	items.assign(items.filter(func(a: Dictionary): return a["from"] != from))


## O acordo para quem pede o número `from` com o sinal `sig` (vazio se não há, ou se o sinal não bate).
func redirect(from: String, sig: String) -> Dictionary:
	for a in items:
		if a["from"] == from and sig != "" and a["signal"] == sig:
			return a
	return {}
