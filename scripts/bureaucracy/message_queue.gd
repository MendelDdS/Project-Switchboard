extends RefCounted
## A fila de recados (`Bureaucracy.messages`): quem não quis ligar deixa um recado para um número da lista, e ele
## espera até o operador ter a chance de repassar (quem é desse número liga, ou recebe uma ligação). Qualquer regra
## pode usar; a B1 deixa os anônimos. Fica salva entre as noites (`Bureaucracy.state`).

## {"to": número, "text", "from": quem deixou ("" = anônimo), "night", "time", "reply": a resposta de quem recebe}
var items: Array[Dictionary] = []


func add(to: String, text: String, from: String, night: int, time: String, reply := "") -> Dictionary:
	var m := {"to": to, "text": text, "from": from, "night": night, "time": time, "reply": reply}
	items.append(m)
	return m


## Os recados esperando o número `to`.
func waiting(to: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if to != "":
		out.assign(items.filter(func(m: Dictionary): return m["to"] == to))
	return out


## O recado foi repassado (ou jogado fora): sai da fila.
func take(m: Dictionary) -> void:
	items.erase(m)
