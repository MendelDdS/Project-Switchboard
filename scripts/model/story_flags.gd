class_name StoryFlags
extends RefCounted
## Marcadores do roteiro: nomes ligados por escolhas do jogador ou pelo próprio jogo, que valem na noite atual e
## ficam salvos para as seguintes (Progress.flags). Qualquer sistema pode consultar (`allows`) ou alterar (`apply`).
##
## Condição (`requires` nos Resources): lista de nomes; todos precisam estar ligados, e com "!" na frente,
## desligados. Ex.: ["prometeu_quermesse", "!senha_hotel_4"]. Lista vazia = sempre vale.
## Alteração (`apply`): "nome" liga, "!nome" desliga, vazio não faz nada.

signal changed(name: String, on: bool)

var _on := {}   ## nome -> true


func _init(names: PackedStringArray = []) -> void:
	for n in names:
		_on[n] = true


func has(name: String) -> bool:
	return _on.has(name)


## A condição bate?
func allows(requires: PackedStringArray) -> bool:
	for r in requires:
		if r.begins_with("!") == has(r.trim_prefix("!")):
			return false
	return true


## Liga ("nome") ou desliga ("!nome") um marcador.
func apply(change: String) -> void:
	var on := not change.begins_with("!")
	var name := change.trim_prefix("!")
	if name == "" or has(name) == on:
		return
	if on:
		_on[name] = true
	else:
		_on.erase(name)
	changed.emit(name, on)


func names() -> PackedStringArray:
	return PackedStringArray(_on.keys())
